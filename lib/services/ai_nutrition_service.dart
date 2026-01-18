import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AiNutritionService {
  // 🔐 API KEY - Replaced with the Real Key provided by User
  static const String AI_API_KEY = 'AIzaSyB1z1_W2yDVcKftqZPxKIwaMTWezvIR238'; // Replace if needed

 static const String _geminiEndpoint =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  


  // ---------------------------------------------------------------------------
  // 1. ESTIMATE FROM TEXT
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> estimateFromText(String text) async {
    _validateApiKey();

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

    return _callGeminiApi(prompt);
  }

  // ---------------------------------------------------------------------------
  // 2. ESTIMATE FROM IMAGE
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> estimateFromImage(String imagePath) async {
    _validateApiKey();

    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found at $imagePath');
    }

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Prompt for Gemini Vision
    final body = {
      "contents": [
        {
          "parts": [
            {
              "text": '''
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
              '''
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg", // Assuming JPEG for camera/picker
                "data": base64Image
              }
            }
          ]
        }
      ]
    };

    return _performHttpCall(body);
  }

  // ---------------------------------------------------------------------------
  // CORE API LOGIC
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _callGeminiApi(String textPrompt) async {
    final body = {
      "contents": [
        {
          "parts": [
            {"text": textPrompt}
          ]
        }
      ]
    };
    return _performHttpCall(body);
  }

  Future<Map<String, dynamic>> _performHttpCall(Map<String, dynamic> requestBody) async {
    try {
      final uri = Uri.parse('$_geminiEndpoint?key=$AI_API_KEY');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15)); // ⏱️ Timeout 15s

      if (response.statusCode != 200) {
        throw Exception('AI Service Error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      
      // Parse Gemini Response Structure
      // candidates[0].content.parts[0].text
      if (data['candidates'] == null || (data['candidates'] as List).isEmpty) {
         throw Exception('AI returned no candidates. Possibly blocked content.');
      }
      
      final candidate = data['candidates'][0];
      final parts = candidate['content']['parts'] as List;
      final rawText = parts[0]['text'] as String;

      return _cleanAndParseJson(rawText);

    } catch (e) {
      print('❌ AI API Call Failed: $e');
      rethrow; // Re-throw so UI stops loading and shows error
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
           // Default missing keys to 0 or simple fallback to prevent crash
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
void _validateApiKey() {
  if (AI_API_KEY.isEmpty) {
    throw Exception(
      'API Key is missing. Please add your Gemini API Key.',
    );
  }
}

}
