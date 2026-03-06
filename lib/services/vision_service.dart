import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class VisionService {
  //  function URL 
  static const String _url =
      "https://asia-south1-culinaai-948b4.cloudfunctions.net/detectIngredients";

  static Future<List<String>> detect(Uint8List bytes) async {
    final b64 = base64Encode(bytes);

    final resp = await http.post(
      Uri.parse(_url),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "imageBase64": b64, 
      }),
    );

    //  print what the backend actually returns
    print("VISION STATUS: ${resp.statusCode}");
    print("VISION BODY: ${resp.body}");

    if (resp.statusCode != 200) {
      throw Exception("Vision failed: ${resp.statusCode} ${resp.body}");
    }

    final decoded = jsonDecode(resp.body);

    // ✅ Support multiple possible response shapes
    // Option A: { labels: ["egg", "food", ...] }
    if (decoded is Map && decoded["labels"] is List) {
      return (decoded["labels"] as List).map((e) => e.toString()).toList();
    }

    // Option B: { ingredients: ["egg", "rice"] }
    if (decoded is Map && decoded["ingredients"] is List) {
      return (decoded["ingredients"] as List).map((e) => e.toString()).toList();
    }

    // Option C: [ "egg", "rice" ]
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }

    // If backend returned something unexpected
    return [];
  }
}