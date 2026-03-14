import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:physiq/models/meal_model.dart';
import 'package:uuid/uuid.dart';

class AiFoodService {
  // Replace with your actual Gemini API Key
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String _geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey';

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Meal?> processMealImage(File imageFile, Function(String) onProgress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final mealId = const Uuid().v4();

      // Step 1: Uploading image...
      onProgress('Uploading image...');
      final storageRef = _storage.ref().child('meal_images/${user.uid}/$mealId.jpg');
      final uploadTask = await storageRef.putFile(imageFile);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Step 2: Analyzing meal...
      onProgress('Analyzing meal...');
      final base64Image = base64Encode(await imageFile.readAsBytes());
      
      final response = await _callGeminiVision(base64Image);
      final jsonResponse = _parseGeminiResponse(response);

      // Step 3: Detecting ingredients...
      onProgress('Detecting ingredients...');
      // (This is implicitly done by Gemini, but we show the step for UX)
      
      final meal = Meal(
        id: mealId,
        imageUrl: imageUrl,
        title: jsonResponse['meal_title'] ?? 'Unknown Meal',
        container: jsonResponse['serving_container'] ?? 'plate',
        ingredients: (jsonResponse['items'] as List? ?? [])
            .map((item) => MealIngredient.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        createdAt: DateTime.now(),
      );

      // Step 4: Preparing meal preview...
      onProgress('Preparing meal preview...');
      await _saveMealToFirestore(user.uid, meal);

      return meal;
    } catch (e) {
      print('Error processing meal image: $e');
      rethrow;
    }
  }

  Future<String> _callGeminiVision(String base64Image) async {
    const systemPrompt = """
You are a highly accurate food recognition AI used in a nutrition tracking mobile application.
Your task is to analyze the food in the image and extract a clear structured description of the meal.

Rules:
1. Identify the main meal title.
2. Identify all visible food ingredients in the meal.
3. Estimate realistic serving amounts based on visual size.
4. Identify the container type (plate, bowl, glass, cup, tray, etc.).
5. If multiple foods exist, list them separately.
6. Do NOT estimate calories or nutrition.
7. Return structured JSON only.

Important:
• Be visually accurate.
• Do not hallucinate ingredients that are not visible.
• If unsure, estimate conservatively.

Output JSON format:
{
 "meal_title": "short descriptive name of the meal",
 "serving_container": "plate | bowl | glass | cup | tray | other",
 "items":[
  {
   "ingredient": "ingredient name",
   "estimated_amount": "amount estimate",
   "serving_size": "description of serving"
  }
 ]
}
Return ONLY JSON.
""";

    final body = {
      "contents": [
        {
          "parts": [
            {"text": systemPrompt},
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "response_mime_type": "application/json",
      }
    };

    final response = await http.post(
      Uri.parse(_geminiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API call failed: ${response.body}');
    }

    return response.body;
  }

  Map<String, dynamic> _parseGeminiResponse(String responseBody) {
    final decoded = jsonDecode(responseBody);
    final text = decoded['candidates'][0]['content']['parts'][0]['text'];
    
    // Clean up potential markdown formatting if Gemini didn't respect response_mime_type
    String jsonStr = text.toString().trim();
    if (jsonStr.startsWith('```json')) {
      jsonStr = jsonStr.substring(7, jsonStr.length - 3).trim();
    } else if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.substring(3, jsonStr.length - 3).trim();
    }

    return jsonDecode(jsonStr);
  }

  Future<void> _saveMealToFirestore(String userId, Meal meal) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(meal.id)
        .set(meal.toJson());
  }

  Future<void> updateMealBookmark(String userId, String mealId, bool bookmarked) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId)
        .update({'bookmarked': bookmarked});
  }

  Future<void> logMeal(String userId, String mealId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId)
        .update({'logged': true});
  }
}
