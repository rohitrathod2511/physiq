import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/services/cloud_functions_client.dart';
class AiFoodService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudFunctionsClient _cloudFunctions = CloudFunctionsClient();

  Future<Meal?> processMealImage(File imageFile, Function(String) onProgress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final mealId = const Uuid().v4();

      // Step 1: Upload image
      onProgress('Uploading image...');
      String imageUrl = '';
      try {
        final storageRef = _storage.ref().child('meal_images/${user.uid}/$mealId.jpg');
        final uploadTask = await storageRef.putFile(imageFile);
        imageUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        print('Image upload failed (non-fatal): $e');
        // Continue even if upload fails — image URL is optional
      }

      // Step 2: Analyze meal with Gemini
      onProgress('Analyzing meal...');
      final base64Image = base64Encode(await imageFile.readAsBytes());

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = await _cloudFunctions.recognizeMealImage(base64Image);
      } catch (e) {
        print('Gemini analysis failed, using fallback: $e');
        jsonResponse = _buildFallbackResponse();
      }

      // Step 3: Parse the response safely
      onProgress('Detecting ingredients...');
      final meal = _parseGeminiResponse(
        mealId: mealId,
        imageUrl: imageUrl,
        jsonResponse: jsonResponse,
      );

      // Step 4: Save to Firestore
      onProgress('Preparing meal preview...');
      try {
        await _saveMealToFirestore(user.uid, meal);
      } catch (e) {
        print('Firestore save failed (non-fatal): $e');
        // Continue — the meal data is still usable for preview
      }

      return meal;
    } catch (e) {
      print('Error processing meal image: $e');
      // Instead of crashing, return a fallback meal
      return _buildFallbackMeal();
    }
  }

  Future<Meal?> processAndEnrichMealAsync(String userId, String mealId, File imageFile) async {
    try {
      // 1. Upload image
      String imageUrl = '';
      try {
        final storageRef = _storage.ref().child('meal_images/$userId/$mealId.jpg');
        final uploadTask = await storageRef.putFile(imageFile);
        imageUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        print('Image upload failed (non-fatal): $e');
      }

      // 2. Analyze meal with Gemini
      final base64Image = base64Encode(await imageFile.readAsBytes());
      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = await _cloudFunctions.recognizeMealImage(base64Image);
      } catch (e) {
        print('Gemini analysis failed, using fallback: $e');
        jsonResponse = _buildFallbackResponse();
      }

      // 3. Parse Gemini response safely
      final initialMeal = _parseGeminiResponse(
        mealId: mealId,
        imageUrl: imageUrl, 
        jsonResponse: jsonResponse,
      );

      // 4. Enrich and Update 
      final enrichedIngredients = <MealIngredient>[];

      for (final ingredient in initialMeal.ingredients) {
        try {
          final nutritionData = await _cloudFunctions.enrichMealItem(ingredient.name);
          if (nutritionData != null) {
            final optionsRaw = nutritionData['servingOptions'] ?? nutritionData['serving_options'] ?? [];
            final options = (optionsRaw as List).map((o) => ServingOption.fromJson(Map<String, dynamic>.from(o))).toList();
            
            final nutriments = nutritionData['nutritionPer100g'] ?? nutritionData['nutrition_per_100g'];
            final Map<String, double> nutMap = {};
            if (nutriments is Map) {
              nutMap['calories'] = _safeDouble(nutriments['calories'] ?? nutriments['energy']);
              nutMap['protein'] = _safeDouble(nutriments['protein']);
              nutMap['carbs'] = _safeDouble(nutriments['carbs']);
              nutMap['fat'] = _safeDouble(nutriments['fat']);
            }

            double cal = _safeDouble(ingredient.caloriesEstimate);
            double prot = _safeDouble(ingredient.proteinEstimate);
            double carb = _safeDouble(ingredient.carbsEstimate);
            double fat = _safeDouble(ingredient.fatEstimate);
            double estimatedGrams = _safeDouble(ingredient.estimatedGrams);

            if (nutMap.containsKey('calories') && estimatedGrams > 0) {
              final scale = estimatedGrams / 100.0;
              cal = _safeDouble(nutMap['calories']! * scale);
              prot = _safeDouble((nutMap['protein'] ?? 0) * scale);
              carb = _safeDouble((nutMap['carbs'] ?? 0) * scale);
              fat = _safeDouble((nutMap['fat'] ?? 0) * scale);
            }

            enrichedIngredients.add(MealIngredient(
              name: _safeString(nutritionData['name'], ingredient.name),
              amount: ingredient.amount,
              servingSize: ingredient.servingSize,
              caloriesEstimate: cal,
              proteinEstimate: prot,
              carbsEstimate: carb,
              fatEstimate: fat,
              servingOptions: options,
              nutritionPer100g: nutMap,
              source: _safeString(nutritionData['source'], 'enriched'),
              fdcId: nutritionData['fdcId']?.toString() ?? nutritionData['fdc_id']?.toString(),
              estimatedGrams: estimatedGrams,
            ));
          } else {
             // Fallback
             enrichedIngredients.add(MealIngredient(
               name: ingredient.name,
               amount: ingredient.amount,
               servingSize: ingredient.servingSize,
               caloriesEstimate: 0.0,
               proteinEstimate: 0.0,
               carbsEstimate: 0.0,
               fatEstimate: 0.0,
               source: 'safe_fallback',
               estimatedGrams: _safeDouble(ingredient.estimatedGrams),
            ));
          }
        } catch (e) {
             enrichedIngredients.add(MealIngredient(
               name: ingredient.name,
               amount: ingredient.amount,
               servingSize: ingredient.servingSize,
               caloriesEstimate: 0.0,
               proteinEstimate: 0.0,
               carbsEstimate: 0.0,
               fatEstimate: 0.0,
               source: 'safe_fallback',
               estimatedGrams: _safeDouble(ingredient.estimatedGrams),
            ));
        }
      }

      final enrichedMeal = Meal(
        id: initialMeal.id,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : initialMeal.imageUrl,
        title: initialMeal.title,
        container: initialMeal.container,
        ingredients: enrichedIngredients,
        createdAt: initialMeal.createdAt,
        bookmarked: initialMeal.bookmarked,
        logged: initialMeal.logged,
      );

      // UPDATE LOADING CARD
      await _saveMealToFirestore(userId, enrichedMeal);

      return enrichedMeal;

    } catch(e) {
      print('Process and enrich error: $e');
      return null;
    }
  }

  /// Parses the Gemini response into a [Meal] object with full validation.
  /// Handles missing keys, wrong types, and partial data gracefully.
  Meal _parseGeminiResponse({
    required String mealId,
    required String imageUrl,
    required Map<String, dynamic> jsonResponse,
  }) {
    try {
      final title = _safeString(jsonResponse['meal_title'], 'Scanned Meal');
      final container = _safeString(jsonResponse['serving_container'], 'plate');

      final rawItems = jsonResponse['items'];
      final List<dynamic> itemsList;

      if (rawItems is List) {
        itemsList = rawItems;
      } else {
        itemsList = [];
      }

      final ingredients = <MealIngredient>[];

      for (final item in itemsList) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);

        final name = _safeString(
          map['ingredient'] ?? map['name'],
          '',
        );
        if (name.isEmpty) continue;

        ingredients.add(MealIngredient(
          name: name,
          amount: _safeString(
            map['estimated_amount'] ?? map['amount'],
            '1 serving',
          ),
          servingSize: _safeString(map['serving_size'], '100g'),
          caloriesEstimate: _safeDouble(map['calories_estimate']),
          proteinEstimate: _safeDouble(map['protein_estimate']),
          carbsEstimate: _safeDouble(map['carbs_estimate']),
          fatEstimate: _safeDouble(map['fat_estimate']),
          source: _safeString(map['source'], 'gemini_estimate'),
          estimatedGrams: _safeDouble(map['estimated_grams'] ?? map['estimatedGrams']),
        ));
      }

      // If no valid ingredients were parsed, add a generic one
      if (ingredients.isEmpty) {
        ingredients.add(MealIngredient(
          name: 'Food item',
          amount: '1 serving',
          servingSize: '100g',
          caloriesEstimate: 200,
          proteinEstimate: 8,
          carbsEstimate: 25,
          fatEstimate: 8,
          source: 'gemini_fallback',
          estimatedGrams: 100,
        ));
      }

      return Meal(
        id: mealId,
        imageUrl: imageUrl,
        title: title,
        container: container,
        ingredients: ingredients,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Gemini response: $e');
      return _buildFallbackMeal();
    }
  }

  /// Builds a fallback raw response map (mimics what the cloud function returns).
  Map<String, dynamic> _buildFallbackResponse() {
    return {
      'meal_title': 'Scanned Meal',
      'serving_container': 'plate',
      'items': [
        {
          'ingredient': 'Food item',
          'estimated_amount': '1 serving',
          'serving_size': '100g',
          'calories_estimate': 200,
          'protein_estimate': 8,
          'carbs_estimate': 25,
          'fat_estimate': 8,
        }
      ],
    };
  }

  /// Builds a fallback Meal object when everything else fails.
  Meal _buildFallbackMeal() {
    return Meal(
      id: const Uuid().v4(),
      imageUrl: '',
      title: 'Scanned Meal',
      container: 'plate',
      ingredients: [
        MealIngredient(
          name: 'Food item',
          amount: '1 serving',
          servingSize: '100g',
          caloriesEstimate: 200,
          proteinEstimate: 8,
          carbsEstimate: 25,
          fatEstimate: 8,
        ),
      ],
      createdAt: DateTime.now(),
    );
  }

  String _safeString(dynamic value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  double _safeDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
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

  /// Asynchronously enriches each ingredient in a meal with detailed USDA/OFF data.
  /// Updates Firestore once all items are processed.
  Future<Meal> enrichMeal(String userId, Meal meal) async {
    final enrichedIngredients = <MealIngredient>[];

    for (final ingredient in meal.ingredients) {
      try {
        final nutritionData = await _cloudFunctions.enrichMealItem(ingredient.name);
        if (nutritionData != null) {
          final optionsRaw = nutritionData['servingOptions'] ?? nutritionData['serving_options'] ?? [];
          final options = (optionsRaw as List).map((o) => ServingOption.fromJson(Map<String, dynamic>.from(o))).toList();
          
          final nutriments = nutritionData['nutritionPer100g'] ?? nutritionData['nutrition_per_100g'];
          final Map<String, double> nutMap = {};
          if (nutriments is Map) {
            nutMap['calories'] = _safeDouble(nutriments['calories'] ?? nutriments['energy']);
            nutMap['protein'] = _safeDouble(nutriments['protein']);
            nutMap['carbs'] = _safeDouble(nutriments['carbs']);
            nutMap['fat'] = _safeDouble(nutriments['fat']);
          }

          // Recalculate estimates based on nutrition data and Gemini's gram estimate
          double calories = ingredient.caloriesEstimate;
          double protein = ingredient.proteinEstimate;
          double carbs = ingredient.carbsEstimate;
          double fat = ingredient.fatEstimate;

          if (nutMap.containsKey('calories') && ingredient.estimatedGrams > 0) {
            final scale = ingredient.estimatedGrams / 100.0;
            calories = nutMap['calories']! * scale;
            protein = (nutMap['protein'] ?? 0) * scale;
            carbs = (nutMap['carbs'] ?? 0) * scale;
            fat = (nutMap['fat'] ?? 0) * scale;
          }

          enrichedIngredients.add(MealIngredient(
            name: _safeString(nutritionData['name'], ingredient.name),
            amount: ingredient.amount,
            servingSize: ingredient.servingSize,
            caloriesEstimate: calories,
            proteinEstimate: protein,
            carbsEstimate: carbs,
            fatEstimate: fat,
            servingOptions: options,
            nutritionPer100g: nutMap,
            source: _safeString(nutritionData['source'], 'enriched'),
            fdcId: nutritionData['fdcId']?.toString() ?? nutritionData['fdc_id']?.toString(),
            estimatedGrams: ingredient.estimatedGrams,
          ));
        } else {
          enrichedIngredients.add(MealIngredient(
            name: ingredient.name,
            amount: ingredient.amount,
            servingSize: ingredient.servingSize,
            caloriesEstimate: 0.0,
            proteinEstimate: 0.0,
            carbsEstimate: 0.0,
            fatEstimate: 0.0,
            source: 'safe_fallback',
            estimatedGrams: _safeDouble(ingredient.estimatedGrams),
          ));
        }
      } catch (e) {
        print('Error enriching ingredient ${ingredient.name}: $e');
        enrichedIngredients.add(MealIngredient(
            name: ingredient.name,
            amount: ingredient.amount,
            servingSize: ingredient.servingSize,
            caloriesEstimate: 0.0,
            proteinEstimate: 0.0,
            carbsEstimate: 0.0,
            fatEstimate: 0.0,
            source: 'safe_fallback',
            estimatedGrams: _safeDouble(ingredient.estimatedGrams),
        ));
      }
    }

    final enrichedMeal = Meal(
      id: meal.id,
      imageUrl: meal.imageUrl,
      title: meal.title,
      container: meal.container,
      ingredients: enrichedIngredients,
      createdAt: meal.createdAt,
      bookmarked: meal.bookmarked,
      logged: meal.logged,
    );

    try {
      await _saveMealToFirestore(userId, enrichedMeal);
    } catch (e) {
      print('Failed to save enriched meal to Firestore: $e');
    }

    return enrichedMeal;
  }
}
