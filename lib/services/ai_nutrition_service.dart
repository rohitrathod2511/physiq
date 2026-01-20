import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AiNutritionService {
  // ☁️ Firebase Cloud Function URL
  static const String _functionUrl = 
      'https://estimatenutrition-y4efoq7ega-uc.a.run.app';

  // ---------------------------------------------------------------------------
  // 1. ESTIMATE FROM TEXT
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> estimateFromText(String text) async {
    final body = {
      "type": "text",
      "input": text,
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
    final mimeType = _getMimeType(imagePath);

    final body = {
      "type": "image",
      "image": base64Image,
      "mimeType": mimeType,
    };

    return _callCloudFunction(body);
  }

  String _getMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg'; // Default fallback
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
      ).timeout(const Duration(seconds: 60)); // Vertex AI can take time

      if (response.statusCode != 200) {
        throw Exception('Server Error (${response.statusCode}): ${response.body}');
      }

      // Backend now returns pure JSON object
      final data = jsonDecode(response.body);

      // Validate structure just in case
      final requiredKeys = ['meal_name', 'calories', 'protein_g', 'carbs_g', 'fat_g'];
      if (data is! Map) throw Exception("Invalid JSON format from AI");

      for (var key in requiredKeys) {
        if (!data.containsKey(key)) {
           // Fallback for safety, but typically the function should guarantee this
           if (key == 'meal_name') data['meal_name'] = 'Unknown Meal';
           else data[key] = 0;
        }
      }

      return Map<String, dynamic>.from(data);

    } catch (e) {
      print('❌ AI Service Failed: $e');
      rethrow;
    }
  }
}
