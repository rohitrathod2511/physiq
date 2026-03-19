import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/services/cloud_functions_client.dart';
import 'package:uuid/uuid.dart';

class AiFoodService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudFunctionsClient _cloudFunctions = CloudFunctionsClient();
  final _uuid = const Uuid();

  Future<Meal?> processAndEnrichMealAsync(
    String userId,
    String mealId,
    File imageFile,
  ) async {
    try {
      debugPrint('STEP 1: Starting meal analysis flow');

      final imageUrl = await _uploadMealImage(userId, mealId, imageFile);
      final jsonResponse = await _recognizeMeal(imageFile);

      debugPrint('Parsed JSON (Gemini): $jsonResponse');
      final initialMeal = _parseGeminiResponse(
        mealId: mealId,
        imageUrl: imageUrl,
        jsonResponse: jsonResponse,
      );

      debugPrint(
        'STEP 5: Parsed ${initialMeal.ingredients.length} ingredients for ${initialMeal.title}',
      );

      final enrichedMeal = await _buildEnrichedMeal(initialMeal);
      await _saveMealToFirestore(userId, enrichedMeal);

      debugPrint('Final calculated data: ${enrichedMeal.toJson()}');
      return enrichedMeal;
    } catch (error) {
      debugPrint('Process and enrich error: $error');
      return null;
    }
  }

  Future<String> _uploadMealImage(
    String userId,
    String mealId,
    File imageFile,
  ) async {
    try {
      debugPrint('STEP 2: Uploading image to Storage');
      final storageRef = _storage.ref().child('meal_images/$userId/$mealId.jpg');
      final uploadTask = await storageRef.putFile(imageFile);
      final imageUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('Image uploaded: $imageUrl');
      return imageUrl;
    } catch (error) {
      debugPrint('Image upload failed, continuing with local file: $error');
      return '';
    }
  }

  Future<Map<String, dynamic>> _recognizeMeal(File imageFile) async {
    final base64Image = base64Encode(await imageFile.readAsBytes());

    try {
      debugPrint('STEP 3: Calling Gemini image recognition');
      final jsonResponse = await _cloudFunctions.recognizeMealImage(base64Image);
      debugPrint('Gemini normalized response: $jsonResponse');
      return jsonResponse;
    } catch (error) {
      debugPrint('Gemini analysis failed, using fallback response: $error');
      return _buildFallbackResponse();
    }
  }

  Meal _parseGeminiResponse({
    required String mealId,
    required String imageUrl,
    required Map<String, dynamic> jsonResponse,
  }) {
    try {
      final rawItems = jsonResponse['items'] ?? jsonResponse['ingredients'];
      final itemsList = rawItems is List ? rawItems : const <dynamic>[];

      final ingredients = <MealIngredient>[];
      for (final item in itemsList) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);
        final ingredientName = _cleanIngredientName(
          map['ingredient'] ?? map['name'],
        );

        if (ingredientName.isEmpty) {
          continue;
        }

        ingredients.add(
          MealIngredient(
            name: ingredientName,
            amount: _resolveAmount(map),
            servingSize: _safeString(
              map['serving_size'] ?? map['servingSize'],
              '100g',
            ),
            caloriesEstimate: _safeDouble(
              map['calories_estimate'] ?? map['calories'],
            ),
            proteinEstimate: _safeDouble(
              map['protein_estimate'] ?? map['protein'],
            ),
            carbsEstimate: _safeDouble(
              map['carbs_estimate'] ?? map['carbs'],
            ),
            fatEstimate: _safeDouble(map['fat_estimate'] ?? map['fat']),
            source: _safeString(map['source'], 'gemini_estimate'),
            estimatedGrams: _safeDouble(
              map['estimated_grams'] ?? map['estimatedGrams'],
            ),
          ),
        );
      }

      if (ingredients.isEmpty) {
        return _buildFallbackMeal(
          mealId: mealId,
          imageUrl: imageUrl,
        );
      }

      final detectedTitle = _safeString(
        jsonResponse['meal_title'] ?? jsonResponse['mealName'] ?? jsonResponse['title'],
        '',
      );
      final title = detectedTitle.isNotEmpty && !_isGenericIngredientName(detectedTitle)
          ? detectedTitle
          : ingredients.map((ingredient) => ingredient.name).take(3).join(', ');

      return Meal(
        id: mealId,
        imageUrl: imageUrl,
        title: title.isEmpty ? 'Scanned Meal' : title,
        container: _safeString(
          jsonResponse['serving_container'] ??
              jsonResponse['servingContainer'] ??
              jsonResponse['container'],
          'plate',
        ),
        ingredients: ingredients,
        createdAt: DateTime.now(),
        logged: true,
      );
    } catch (error) {
      debugPrint('Error parsing Gemini response: $error');
      return _buildFallbackMeal(mealId: mealId, imageUrl: imageUrl);
    }
  }

  String _resolveAmount(Map<String, dynamic> map) {
    final explicitAmount = _safeString(
      map['estimated_amount'] ?? map['amount'],
      '',
    );
    if (explicitAmount.isNotEmpty) {
      return explicitAmount;
    }

    final quantity = _safeDouble(map['quantity']);
    if (quantity > 0) {
      final servingLabel = _safeString(
        map['servingSize'] ?? map['serving_size'],
        '',
      );

      if (servingLabel.isNotEmpty) {
        return '${_formatQuantity(quantity)} $servingLabel';
      }

      return quantity == 1 ? '1 serving' : '${_formatQuantity(quantity)} servings';
    }

    return '1 serving';
  }

  Future<Meal> _buildEnrichedMeal(Meal meal) async {
    debugPrint('STEP 6: Starting USDA/OFF enrichment');

    final enrichedIngredients = <MealIngredient>[];
    for (final ingredient in meal.ingredients) {
      enrichedIngredients.add(await _enrichIngredient(ingredient));
    }

    return Meal(
      id: meal.id,
      imageUrl: meal.imageUrl,
      title: meal.title,
      container: meal.container,
      ingredients: enrichedIngredients,
      createdAt: meal.createdAt,
      bookmarked: meal.bookmarked,
      logged: meal.logged,
    );
  }

  Future<MealIngredient> _enrichIngredient(MealIngredient ingredient) async {
    try {
      debugPrint('USDA/OFF lookup: ${ingredient.name}');

      final nutritionData = await _cloudFunctions.enrichMealItem(ingredient.name);
      debugPrint('USDA/OFF response for ${ingredient.name}: $nutritionData');

      if (nutritionData == null) {
        return _buildFallbackIngredient(ingredient, source: 'safe_fallback');
      }

      final servingOptions = _parseServingOptions(
        nutritionData['servingOptions'] ?? nutritionData['serving_options'],
      );
      final nutritionPer100g = _parseNutritionMap(
        nutritionData['nutritionPer100g'] ?? nutritionData['nutrition_per_100g'],
      );
      final estimatedGrams = _resolveEstimatedGrams(ingredient, servingOptions);

      final caloriesPer100g = nutritionPer100g['calories'];
      final proteinPer100g = nutritionPer100g['protein'];
      final carbsPer100g = nutritionPer100g['carbs'];
      final fatPer100g = nutritionPer100g['fat'];

      final calories = caloriesPer100g != null
          ? _calculateNutrient(estimatedGrams, caloriesPer100g)
          : _safeDouble(ingredient.caloriesEstimate);
      final protein = proteinPer100g != null
          ? _calculateNutrient(estimatedGrams, proteinPer100g)
          : _safeDouble(ingredient.proteinEstimate);
      final carbs = carbsPer100g != null
          ? _calculateNutrient(estimatedGrams, carbsPer100g)
          : _safeDouble(ingredient.carbsEstimate);
      final fat = fatPer100g != null
          ? _calculateNutrient(estimatedGrams, fatPer100g)
          : _safeDouble(ingredient.fatEstimate);

      return MealIngredient(
        name: _safeString(nutritionData['name'], ingredient.name),
        amount: ingredient.amount,
        servingSize: ingredient.servingSize,
        caloriesEstimate: calories,
        proteinEstimate: protein,
        carbsEstimate: carbs,
        fatEstimate: fat,
        servingOptions: servingOptions,
        nutritionPer100g: nutritionPer100g.isEmpty ? null : nutritionPer100g,
        source: _safeString(nutritionData['source'], 'enriched'),
        fdcId: _stringOrNull(nutritionData['fdcId'] ?? nutritionData['fdc_id']),
        estimatedGrams: estimatedGrams,
      );
    } catch (error) {
      debugPrint('Error enriching ingredient ${ingredient.name}: $error');
      return _buildFallbackIngredient(ingredient, source: 'safe_fallback');
    }
  }

  MealIngredient _buildFallbackIngredient(
    MealIngredient ingredient, {
    required String source,
  }) {
    final estimatedGrams = _resolveEstimatedGrams(ingredient, const <ServingOption>[]);

    return MealIngredient(
      name: ingredient.name,
      amount: ingredient.amount,
      servingSize: ingredient.servingSize,
      caloriesEstimate: _safeDouble(ingredient.caloriesEstimate),
      proteinEstimate: _safeDouble(ingredient.proteinEstimate),
      carbsEstimate: _safeDouble(ingredient.carbsEstimate),
      fatEstimate: _safeDouble(ingredient.fatEstimate),
      source: source,
      estimatedGrams: estimatedGrams,
      nutritionPer100g: ingredient.nutritionPer100g,
      servingOptions: ingredient.servingOptions,
      fdcId: ingredient.fdcId,
    );
  }

  List<ServingOption> _parseServingOptions(dynamic raw) {
    if (raw is! List) {
      return const [ServingOption(label: '100g', grams: 100)];
    }

    final options = raw
        .whereType<Map>()
        .map((option) => ServingOption.fromJson(Map<String, dynamic>.from(option)))
        .where((option) => option.grams > 0)
        .toList();

    if (options.any((option) => option.label.toLowerCase() == '100g')) {
      return options;
    }

    return [
      const ServingOption(label: '100g', grams: 100),
      ...options,
    ];
  }

  Map<String, double> _parseNutritionMap(dynamic raw) {
    if (raw is! Map) {
      return const {};
    }

    final nutritionMap = <String, double>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) {
        continue;
      }

      final value = _safeDouble(entry.value);
      final normalizedKey = _normalizeNutritionKey(key);
      nutritionMap[normalizedKey] = value;
    }

    if (!nutritionMap.containsKey('calories') && nutritionMap.containsKey('energy')) {
      nutritionMap['calories'] = nutritionMap['energy']!;
    }

    return nutritionMap;
  }

  String _normalizeNutritionKey(String key) {
    final normalized = key.trim().toLowerCase();
    switch (normalized) {
      case 'energy':
      case 'calories':
      case 'energy_kcal':
        return 'calories';
      case 'protein':
        return 'protein';
      case 'carbs':
      case 'carbohydrates':
        return 'carbs';
      case 'fat':
      case 'fats':
        return 'fat';
      default:
        return normalized;
    }
  }

  double _resolveEstimatedGrams(
    MealIngredient ingredient,
    List<ServingOption> servingOptions,
  ) {
    if (ingredient.estimatedGrams > 0) {
      return ingredient.estimatedGrams;
    }

    final text = '${ingredient.amount} ${ingredient.servingSize}'.toLowerCase();
    final explicitWeight = _extractExplicitWeightInGrams(text);
    if (explicitWeight > 0) {
      return explicitWeight;
    }

    final quantity = _extractQuantity(text);
    final matchedOption = _matchServingOption(text, servingOptions);
    if (matchedOption != null) {
      return matchedOption.grams * quantity;
    }

    final heuristicWeight = _heuristicServingWeight(text);
    if (heuristicWeight > 0) {
      return heuristicWeight * quantity;
    }

    final fallbackOption = servingOptions.firstWhere(
      (option) => option.grams > 0 && option.label.toLowerCase() != '100g',
      orElse: () => const ServingOption(label: '100g', grams: 100),
    );

    return fallbackOption.grams * quantity;
  }

  double _extractExplicitWeightInGrams(String text) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*(kg|kilogram|kilograms|g|gram|grams|ml|l|oz|ounce|ounces)\b',
    ).firstMatch(text);

    if (match == null) {
      return 0;
    }

    final value = double.tryParse(match.group(1) ?? '') ?? 0;
    final unit = (match.group(2) ?? '').toLowerCase();

    switch (unit) {
      case 'kg':
      case 'kilogram':
      case 'kilograms':
        return value * 1000;
      case 'l':
        return value * 1000;
      case 'oz':
      case 'ounce':
      case 'ounces':
        return value * 28.3495;
      default:
        return value;
    }
  }

  double _extractQuantity(String text) {
    if (text.contains('half')) {
      return 0.5;
    }
    if (text.contains('quarter')) {
      return 0.25;
    }

    final fractionMatch = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(text);
    if (fractionMatch != null) {
      final numerator = double.tryParse(fractionMatch.group(1) ?? '') ?? 0;
      final denominator = double.tryParse(fractionMatch.group(2) ?? '') ?? 0;
      if (denominator > 0) {
        return numerator / denominator;
      }
    }

    final numberMatch = RegExp(r'(^|\s)(\d+(?:\.\d+)?)(?=\s|$)').firstMatch(text);
    if (numberMatch != null) {
      return double.tryParse(numberMatch.group(2) ?? '') ?? 1;
    }

    const wordMap = <String, double>{
      'a': 1,
      'an': 1,
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
    };

    final words = text.split(RegExp(r'[^a-z]+'));
    for (final entry in wordMap.entries) {
      if (words.contains(entry.key)) {
        return entry.value;
      }
    }

    return 1;
  }

  ServingOption? _matchServingOption(
    String text,
    List<ServingOption> servingOptions,
  ) {
    final textTokens = _tokenize(text);
    ServingOption? bestMatch;
    int bestScore = 0;

    for (final option in servingOptions) {
      if (option.grams <= 0 || option.label.toLowerCase() == '100g') {
        continue;
      }

      int score = 0;
      final optionLabel = option.label.toLowerCase();
      if (text.contains(optionLabel) || optionLabel.contains(text)) {
        score += 5;
      }

      final optionTokens = _tokenize(optionLabel);
      score += optionTokens.intersection(textTokens).length;

      if (score > bestScore) {
        bestScore = score;
        bestMatch = option;
      }
    }

    return bestScore > 0 ? bestMatch : null;
  }

  Set<String> _tokenize(String text) {
    const ignored = <String>{
      'a',
      'an',
      'the',
      'of',
      'serving',
      'servings',
      'small',
      'medium',
      'large',
    };

    return text
        .split(RegExp(r'[^a-z0-9]+'))
        .map((part) => part.trim())
        .where((part) => part.length > 1 && !ignored.contains(part))
        .toSet();
  }

  double _heuristicServingWeight(String text) {
    if (text.contains('bowl')) {
      return 200;
    }
    if (text.contains('plate')) {
      return 250;
    }
    if (text.contains('glass') || text.contains('cup')) {
      return 250;
    }
    if (text.contains('tbsp') || text.contains('tablespoon')) {
      return 15;
    }
    if (text.contains('tsp') || text.contains('teaspoon')) {
      return 5;
    }
    if (text.contains('piece') ||
        text.contains('slice') ||
        text.contains('leg') ||
        text.contains('fillet')) {
      return 100;
    }

    return 0;
  }

  double _calculateNutrient(double grams, double per100gValue) {
    return (grams / 100) * per100gValue;
  }

  String _cleanIngredientName(dynamic value) {
    final name = _safeString(value, '');
    if (name.isEmpty || _isGenericIngredientName(name)) {
      return '';
    }
    return name;
  }

  bool _isGenericIngredientName(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'food' ||
        normalized == 'meal' ||
        normalized == 'dish' ||
        normalized == 'item' ||
        normalized == 'food item';
  }

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
          'estimated_grams': 100,
        },
      ],
    };
  }

  Meal _buildFallbackMeal({
    String? mealId,
    String imageUrl = '',
  }) {
    return Meal(
      id: mealId ?? _uuid.v4(),
      imageUrl: imageUrl,
      title: 'Scanned Meal',
      container: 'plate',
      ingredients: const [
        MealIngredient(
          name: 'Food item',
          amount: '1 serving',
          servingSize: '100g',
          caloriesEstimate: 200,
          proteinEstimate: 8,
          carbsEstimate: 25,
          fatEstimate: 8,
          estimatedGrams: 100,
          source: 'gemini_fallback',
        ),
      ],
      createdAt: DateTime.now(),
      logged: true,
    );
  }

  String _safeString(dynamic value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  String? _stringOrNull(dynamic value) {
    if (value is num) {
      return value.toString();
    }
    final stringValue = _safeString(value, '');
    return stringValue.isEmpty ? null : stringValue;
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  double _safeDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
    }
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

  Future<void> updateMealBookmark(
    String userId,
    String mealId,
    bool bookmarked,
  ) async {
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

  Future<Meal> enrichMeal(String userId, Meal meal) async {
    final enrichedMeal = await _buildEnrichedMeal(meal);

    try {
      await _saveMealToFirestore(userId, enrichedMeal);
    } catch (error) {
      debugPrint('Failed to save enriched meal to Firestore: $error');
    }

    return enrichedMeal;
  }
}
