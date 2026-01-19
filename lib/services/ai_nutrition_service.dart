import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AiNutritionService {
  // ☁️ Firebase Cloud Function Endpoint
  // Replace <project-id> and <region> if different from default.
  // Based on firebase_options.dart, projectId is 'physiq-5811f'.
  static const String _functionUrl = 
      'https://us-central1-physiq-5811f.cloudfunctions.net/estimateNutrition';

  // ---------------------------------------------------------------------------
  // 1. ESTIMATE FROM TEXT
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> estimateFromText(String text) async {
    // Prompt structure
    final prompt = '''
      Analyze this meal description: "$text".
      Estimate the nutrition facts.
      Return ONLY a valid JSON object with exactly these keys:
      {
        "meal_name": "Short descriptive name",
        "calories": 0,
        "protein_g": 0,
        "carbs_g": 0,
        "fat_g": 0
      }
      Do not include markdown formatting (like ```json). Just the raw JSON.
    ''';

    final body = {
      "prompt": prompt,
    };

    return _callCloudFunction(body);
  }

  // ---------------------------------------------------------------------------
  // 2. ESTIMATE FROM IMAGE
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> estimateFromImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found at $imagePath');
    }

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    final prompt = '''
      Identify this food/meal. Estimate the nutrition facts for a standard serving size visible or implied.
      Return ONLY a valid JSON object with exactly these keys:
      {
        "meal_name": "Short descriptive name",
        "calories": 0,
        "protein_g": 0,
        "carbs_g": 0,
        "fat_g": 0
      }
      Do not include markdown formatting. Just the raw JSON.
    ''';

    // Send base64 image + prompt to backend
    final body = {
      "prompt": prompt,
      "image": base64Image,
      "mimeType": "image/jpeg", 
    };

    return _callCloudFunction(body);
  }

  // ---------------------------------------------------------------------------
  // BACKEND COMMUNICATION
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> _callCloudFunction(Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse(_functionUrl);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 45)); // Extra time for Cold Starts

      if (response.statusCode != 200) {
        throw Exception('Cloud Function Error (${response.statusCode}): ${response.body}');
      }

      final rawText = response.body;
      if (rawText.isEmpty) {
        throw Exception('Server returned empty response.');
      }

      return _cleanAndParseJson(rawText);

    } catch (e) {
      print('❌ AI Service Failed: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _cleanAndParseJson(String rawText) {
    try {
      // 1. Remove Markdown code blocks if present ( ```json ... ``` )
      var clean = rawText.replaceAll(RegExp(r'```json'), '').replaceAll(RegExp(r'```'), '').trim();
      
      // 2. Find the first '{' and last '}' to extract just the JSON object
      final startIndex = clean.indexOf('{');
      final endIndex = clean.lastIndexOf('}');
      
      if (startIndex != -1 && endIndex != -1) {
        clean = clean.substring(startIndex, endIndex + 1);
      }

      final jsonMap = jsonDecode(clean);

      // 3. Validate Keys
      final requiredKeys = ['meal_name', 'calories', 'protein_g', 'carbs_g', 'fat_g'];
      for (var key in requiredKeys) {
        if (!jsonMap.containsKey(key)) {
           // Fallback defaults
           if (key == 'meal_name') jsonMap['meal_name'] = 'Unknown Meal';
           else jsonMap[key] = 0;
        }
      }

      return Map<String, dynamic>.from(jsonMap);

    } catch (e) {
      print('❌ JSON Parse Error on text: $rawText');
      throw Exception('Failed to parse AI response: $e');
    }
  }
}
