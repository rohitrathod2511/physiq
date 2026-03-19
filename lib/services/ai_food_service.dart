import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/services/cloud_functions_client.dart';
import 'package:uuid/uuid.dart';

class AiFoodService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudFunctionsClient _cloudFunctions = CloudFunctionsClient();
  final _uuid = const Uuid();


  Future<Meal?> processAndEnrichMealAsync(String userId, String mealId, File imageFile) async {
    try {
      print('🚀 STEP 1: Starting Meal Analysis Flow');

      // 1. Upload image
      String imageUrl = '';
      try {
        print('📸 STEP 2: Uploading image to Storage...');
        final storageRef = _storage.ref().child('meal_images/$userId/$mealId.jpg');
        final uploadTask = await storageRef.putFile(imageFile);
        imageUrl = await uploadTask.ref.getDownloadURL();
        print('✅ Image uploaded: $imageUrl');
      } catch (e) {
        print('⚠️ Image upload failed (non-fatal): $e');
      }

      // 2. Analyze meal with Gemini
      print('🤖 STEP 3: Calling Gemini API for image recognition...');
      final base64Image = base64Encode(await imageFile.readAsBytes());
      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = await _cloudFunctions.recognizeMealImage(base64Image);
        print('✅ Gemini responded. Status: ${jsonResponse.isNotEmpty ? "SUCCESS" : "EMPTY"}');
      } catch (e) {
        print('❌ Gemini analysis failed, using fallback: $e');
        jsonResponse = _buildFallbackResponse();
      }

      // 3. Parse Gemini response safely
      print('📦 STEP 4: Parsing Gemini JSON Response...');
      print('Parsed JSON (Gemini): $jsonResponse');
      final initialMeal = _parseGeminiResponse(
        mealId: mealId,
        imageUrl: imageUrl, 
        jsonResponse: jsonResponse,
      );
      print('✅ Parsed meal: ${initialMeal.title} with ${initialMeal.ingredients.length} items');

      // 4. Enrich and Update 
      print('🍎 STEP 5: Starting USDA/OFF Enrichment for each item...');
      final enrichedIngredients = <MealIngredient>[];

      for (final ingredient in initialMeal.ingredients) {
        try {
          print('🔍 Searching nutrition for: ${ingredient.name}');
          final nutritionData = await _cloudFunctions.enrichMealItem(ingredient.name);
          print('USDA/OFF Response for ${ingredient.name}: $nutritionData');
          
          if (nutritionData != null) {
            print('✅ Nutrition data received for: ${ingredient.name} from ${nutritionData['source']}');
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

            if (estimatedGrams <= 0) {
              final amt = ingredient.amount.toLowerCase();
              final size = ingredient.servingSize.toLowerCase();
              print('❓ Grams not provided for [${ingredient.name}], attempting mapping...');
              if (amt.contains('bowl') || size.contains('bowl')) {
                estimatedGrams = 200.0;
              } else if (amt.contains('glass') || size.contains('glass')) {
                estimatedGrams = 250.0;
              } else if (amt.contains('piece') || size.contains('piece') || amt.contains('slice') || size.contains('slice')) {
                estimatedGrams = 100.0;
              } else {
                if (options.length > 1 && options[1].grams > 0) {
                  estimatedGrams = options[1].grams.toDouble();
                } else {
                  estimatedGrams = 100.0; 
                }
              }
              print('⚖️ Calculated grams for [${ingredient.name}]: $estimatedGrams');
            }

            if (nutMap.containsKey('calories')) {
              final scale = estimatedGrams / 100.0;
              cal = _safeDouble(nutMap['calories']! * scale);
              prot = _safeDouble((nutMap['protein'] ?? 0) * scale);
              carb = _safeDouble((nutMap['carbs'] ?? 0) * scale);
              fat = _safeDouble((nutMap['fat'] ?? 0) * scale);
            }

            print('Final calculated data for ${ingredient.name}: calories: $cal, protein: $prot, carbs: $carb, fat: $fat, grams: $estimatedGrams');

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
             print('⚠️ No enrichment found for: ${ingredient.name}, using safe fallback');
             double estimatedGrams = _safeDouble(ingredient.estimatedGrams);
             if (estimatedGrams <= 0) estimatedGrams = 100.0;

             print('Fallback data for ${ingredient.name} as APIs failed');

             enrichedIngredients.add(MealIngredient(
               name: ingredient.name,
               amount: ingredient.amount,
               servingSize: ingredient.servingSize,
               caloriesEstimate: _safeDouble(ingredient.caloriesEstimate),
               proteinEstimate: _safeDouble(ingredient.proteinEstimate),
               carbsEstimate: _safeDouble(ingredient.carbsEstimate),
               fatEstimate: _safeDouble(ingredient.fatEstimate),
               source: 'safe_fallback',
               estimatedGrams: estimatedGrams,
            ));
          }
        } catch (e) {
             print('❌ Error enriching [${ingredient.name}]: $e');
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
      id: _uuid.v4(),
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

          double calories = _safeDouble(ingredient.caloriesEstimate);
          double protein = _safeDouble(ingredient.proteinEstimate);
          double carbs = _safeDouble(ingredient.carbsEstimate);
          double fat = _safeDouble(ingredient.fatEstimate);
          double estimatedGrams = _safeDouble(ingredient.estimatedGrams);

          if (estimatedGrams <= 0) {
            final amt = ingredient.amount.toLowerCase();
            final size = ingredient.servingSize.toLowerCase();
            if (amt.contains('bowl') || size.contains('bowl')) {
              estimatedGrams = 200.0;
            } else if (amt.contains('glass') || size.contains('glass')) {
              estimatedGrams = 250.0;
            } else if (amt.contains('piece') || size.contains('piece') || amt.contains('slice') || size.contains('slice')) {
              estimatedGrams = 100.0;
            } else {
              if (options.length > 1 && options[1].grams > 0) {
                estimatedGrams = options[1].grams.toDouble();
              } else {
                estimatedGrams = 100.0; 
              }
            }
          }

          if (nutMap.containsKey('calories')) {
            final scale = estimatedGrams / 100.0;
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
            estimatedGrams: estimatedGrams,
          ));
        } else {
          double estimatedGrams = _safeDouble(ingredient.estimatedGrams);
          if (estimatedGrams <= 0) estimatedGrams = 100.0;

          enrichedIngredients.add(MealIngredient(
            name: ingredient.name,
            amount: ingredient.amount,
            servingSize: ingredient.servingSize,
            caloriesEstimate: _safeDouble(ingredient.caloriesEstimate),
            proteinEstimate: _safeDouble(ingredient.proteinEstimate),
            carbsEstimate: _safeDouble(ingredient.carbsEstimate),
            fatEstimate: _safeDouble(ingredient.fatEstimate),
            source: 'safe_fallback',
            estimatedGrams: estimatedGrams,
          ));
        }
      } catch (e) {
        print('Error enriching ingredient ${ingredient.name}: $e');
        double estimatedGrams = _safeDouble(ingredient.estimatedGrams);
        if (estimatedGrams <= 0) estimatedGrams = 100.0;

        enrichedIngredients.add(MealIngredient(
            name: ingredient.name,
            amount: ingredient.amount,
            servingSize: ingredient.servingSize,
            caloriesEstimate: _safeDouble(ingredient.caloriesEstimate),
            proteinEstimate: _safeDouble(ingredient.proteinEstimate),
            carbsEstimate: _safeDouble(ingredient.carbsEstimate),
            fatEstimate: _safeDouble(ingredient.fatEstimate),
            source: 'safe_fallback',
            estimatedGrams: estimatedGrams,
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
