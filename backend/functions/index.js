const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const cors = require("cors")({ origin: true });

require("dotenv").config();

exports.detectIngredients = onRequest(
  { region: "asia-south1" },
  (req, res) => {
    cors(req, res, async () => {
      try {
        if (req.method !== "POST") {
          return res.status(405).json({ error: "Use POST" });
        }

        const { imageBase64 } = req.body || {};
        if (!imageBase64 || typeof imageBase64 !== "string") {
          return res.status(400).json({ error: "Missing imageBase64" });
        }

        const apiKey = process.env.GOOGLE_VISION_KEY;
        if (!apiKey) {
          return res.status(500).json({ error: "Missing GOOGLE_VISION_KEY in .env" });
        }

        const url = `https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`;

        const payload = {
          requests: [
            {
              image: { content: imageBase64 },
              features: [
                { type: "LABEL_DETECTION", maxResults: 10 },
                { type: "OBJECT_LOCALIZATION", maxResults: 10 },
                { type: "WEB_DETECTION", maxResults: 10 },
              ],
            },
          ],
        };

        const r = await fetch(url, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        const data = await r.json();

        //  log backend response (super important for debugging)
        logger.info("Vision raw response", data);

        if (!r.ok) {
          return res.status(r.status).json({ error: "Vision API error", data });
        }

        const resp = data?.responses?.[0] || {};

        // Extract labels
        const labels =
          (resp.labelAnnotations || [])
            .map((x) => x.description)
            .filter(Boolean);

        //  Extract objects
        const objects =
          (resp.localizedObjectAnnotations || [])
            .map((x) => x.name)
            .filter(Boolean);

        //  Extract web entities (sometimes best for food)
        const web =
          (resp.webDetection?.webEntities || [])
            .map((x) => x.description)
            .filter(Boolean);

        //  Combine + dedupe
        const combined = Array.from(new Set([...labels, ...objects, ...web]))
          .filter(Boolean)
          .slice(0, 15);

        return res.json({ labels: combined });
      } catch (e) {
        logger.error("detectIngredients failed", e);
        return res.status(500).json({ error: e?.message || String(e) });
      }
    });
  }
);

// ------------------ OPENAI RECIPE ------------------
exports.generateRecipe = onRequest({ region: "asia-south1" }, (req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== "POST") {
        return res.status(405).json({ error: "POST only" });
      }

      const { ingredients, preference, attempt, avoidRecipe, modification } = req.body || {};

      if (!Array.isArray(ingredients) || ingredients.length === 0) {
        return res.status(400).json({ error: "ingredients[] required" });
      }

      const apiKey = process.env.OPENAI_API_KEY;
      if (!apiKey) {
        return res.status(500).json({ error: "Missing OPENAI_API_KEY" });
      }

      // Stronger variation logic
      const variationInstruction =
        attempt > 1 && !modification
          ? `This is regeneration attempt #${attempt}.
Generate a COMPLETELY DIFFERENT recipe than before.
Use a different cuisine style, cooking technique, flavor profile, and presentation.
Avoid repeating similar structure or method.`
          : "";

      const modificationInstruction = modification
          ? `The user want the following modification:
        "${modification}"
      Adjust the recipe accordingly while keeping the core ingredients.`
      :"";    

      const avoidInstruction = avoidRecipe
        ? `Avoid making something similar to this previous recipe:
${avoidRecipe.substring(0, 500)}`
        : "";

      const prompt = `
You are a professional chef.

Create ONE high-quality recipe using these ingredients:
${ingredients.join(", ")}

User preference: ${preference || "none"}

${variationInstruction}
${modificationInstruction}
${avoidInstruction}

You may add basic pantry items like salt, oil, water.

STRICT FORMAT:

RECIPE NAME:
...

INGREDIENTS:
- item 1
- item 2

STEPS:
1. Step one
2. Step two

COOKING TIME:
...

CHEF TIPS:
...
`.trim();

      const r = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: "gpt-4.1-mini",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.9, // higher creativity for variation
        }),
      });

      const data = await r.json();
      const text = data?.choices?.[0]?.message?.content;

      if (!text) {
        return res.status(500).json({ error: "OpenAI returned no text", raw: data });
      }

      return res.json({ recipe: text });

    } catch (e) {
      return res.status(500).json({ error: String(e) });
    }
  });
});