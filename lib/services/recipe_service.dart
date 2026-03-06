import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeService {
  static const String url =
      "https://asia-south1-culinaai-948b4.cloudfunctions.net/generateRecipe";

  /// attempt = 1 for first recipe, 2/3/... for regenerated recipes
  static Future<String> generate(
    List<String> ingredients,
    String preference, {
    int? attempt,
    String? avoidRecipe,
    String? modification, 
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ingredients": ingredients,
        "preference": preference,
        "attempt": attempt,
        "avoidRecipe": avoidRecipe,
        "modification": modification,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Recipe generation failed: ${response.body}");
    }

    final data = jsonDecode(response.body);
    return (data["recipe"] ?? "").toString();
  }
}