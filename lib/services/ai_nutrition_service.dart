
import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';

class AiNutritionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // 1. ANALYZE FROM TEXT
  // Returns { meal_name: String, quantity: num, unit: String }
  Future<Map<String, dynamic>> estimateFromText(String text) async {
    try {
      final callable = _functions.httpsCallable('analyzeFoodText');
      final result = await callable.call({'text': text});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('❌ AI Text Analysis Failed: $e');
      // Fallback
      return {'meal_name': text, 'quantity': 1, 'unit': 'serving'};
    }
  }

  // 2. ANALYZE FROM IMAGE
  // Returns { meal_name: String, quantity: num, unit: String }
  Future<Map<String, dynamic>> estimateFromImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found at $imagePath');
    }

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    // mimeType detection is good but for simplicity send as jpeg or detect
    String mimeType = 'image/jpeg';
    if (imagePath.toLowerCase().endsWith('.png')) mimeType = 'image/png';
    // ... others

    try {
      final callable = _functions.httpsCallable('analyzeFoodImage');
      final result = await callable.call({
        'image': base64Image,
        'mimeType': mimeType,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('❌ AI Image Analysis Failed: $e');
      rethrow;
    }
  }
}
