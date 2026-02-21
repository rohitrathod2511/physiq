import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/food_model.dart';

class MealRecognitionResult {
  final Food meal;
  final List<Food> detectedFoods;

  const MealRecognitionResult({
    required this.meal,
    required this.detectedFoods,
  });
}

/// FatSecret is the only food provider for search/details/barcode.
class FoodService {
  FoodService({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  bool _isAuthCallableError(FirebaseFunctionsException error) {
    return error.code == 'unauthenticated' || error.code == 'permission-denied';
  }

  Future<T> _runCallableWithAuthRetry<T>(Future<T> Function() action) async {
    await _ensureAuthenticatedUser();
    try {
      return await action();
    } on FirebaseFunctionsException catch (error) {
      if (!_isAuthCallableError(error)) rethrow;

      // Token can expire/revoke between app start and function call. Refresh once and retry.
      final user = await _ensureAuthenticatedUser();
      await user.getIdToken(true);
      return await action();
    }
  }

  Future<User> _ensureAuthenticatedUser() async {
    User? user = _auth.currentUser;
    if (user == null) {
      final credential = await _auth.signInAnonymously();
      user = credential.user;
    }

    if (user == null) {
      throw Exception('Unable to authenticate user for food functions.');
    }

    try {
      await user.getIdToken();
    } catch (_) {
      await user.getIdToken(true);
    }

    return user;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  Map<String, double> _parseDescriptionMacros(String description) {
    double parse(String label) {
      final match = RegExp(
        '$label:\\s*([\\d.]+)',
        caseSensitive: false,
      ).firstMatch(description);
      if (match == null) return 0;
      return double.tryParse(match.group(1) ?? '0') ?? 0;
    }

    return {
      'calories': parse('Calories'),
      'protein': parse('Protein'),
      'carbs': parse('Carbs'),
      'fat': parse('Fat'),
    };
  }

  String _extractServingSummary(String description) {
    final match = RegExp(
      r'^Per\s+(.+?)\s*-',
      caseSensitive: false,
    ).firstMatch(description);
    return (match?.group(1)?.trim().isNotEmpty ?? false)
        ? match!.group(1)!.trim()
        : 'serving';
  }

  List<dynamic> _extractFoodListFromNode(dynamic node) {
    if (node is List) return node;
    if (node is Map) {
      final nested = node['food'];
      if (nested is List) return nested;
      if (nested != null) return [nested];
    }
    return const [];
  }

  List<dynamic> _extractFoodsFromResponse(dynamic rawData) {
    if (rawData is! Map) return const [];

    final primary = _extractFoodListFromNode(rawData['foods']);
    if (primary.isNotEmpty) return primary;

    final foodsSearch = rawData['foods_search'];
    if (foodsSearch is Map) {
      final resultsNode = foodsSearch['results'];
      final fromResults = _extractFoodListFromNode(resultsNode);
      if (fromResults.isNotEmpty) return fromResults;
    }

    final fallbackResults = _extractFoodListFromNode(rawData['results']);
    if (fallbackResults.isNotEmpty) return fallbackResults;

    final directFood = rawData['food'];
    if (directFood is Map) return [directFood];

    return const [];
  }

  List<dynamic> _extractServingsFromDetails(Map<String, dynamic> foodNode) {
    final servingsNode = foodNode['servings'];
    if (servingsNode is List) return servingsNode;

    if (servingsNode is Map) {
      final nested = servingsNode['serving'];
      if (nested is List) return nested;
      if (nested != null) return [nested];
    }

    return const [];
  }

  Map<String, dynamic>? _pickDefaultServing(
    List<Map<String, dynamic>> servings,
  ) {
    if (servings.isEmpty) return null;
    for (final serving in servings) {
      if (_toBool(serving['is_default'])) {
        return serving;
      }
    }
    return servings.first;
  }

  Food _mapSearchFood(Map<String, dynamic> map) {
    final description = map['description']?.toString() ?? '';
    final parsed = _parseDescriptionMacros(description);
    final servings = _extractServingsFromDetails(map)
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    final defaultServing = _pickDefaultServing(servings);

    double pick(String key, {String? altKey}) {
      final fromResponse = _toDouble(map[key]);
      if (fromResponse > 0) return fromResponse;
      if (altKey != null) {
        final fromAltResponse = _toDouble(map[altKey]);
        if (fromAltResponse > 0) return fromAltResponse;
      }
      if (defaultServing != null) {
        final fromServing = _toDouble(defaultServing[key]);
        if (fromServing > 0) return fromServing;
        if (altKey != null) {
          final fromServingAlt = _toDouble(defaultServing[altKey]);
          if (fromServingAlt > 0) return fromServingAlt;
        }
      }
      return parsed[key] ?? 0;
    }

    final rawId = map['id']?.toString() ?? map['food_id']?.toString() ?? '';
    final servingSummary = map['serving_summary']?.toString().trim();
    final servingDescription = defaultServing?['serving_description']
        ?.toString()
        .trim();
    final unit = (servingSummary != null && servingSummary.isNotEmpty)
        ? servingSummary
        : ((servingDescription != null && servingDescription.isNotEmpty)
              ? servingDescription
              : _extractServingSummary(description));

    return Food(
      id: 'fs_$rawId',
      name:
          map['name']?.toString() ?? map['food_name']?.toString() ?? 'Unknown',
      category:
          map['type']?.toString() ?? map['food_type']?.toString() ?? 'General',
      unit: unit,
      baseWeightG: _toDouble(defaultServing?['metric_serving_amount']),
      calories: pick('calories'),
      protein: pick('protein'),
      carbs: pick('carbs', altKey: 'carbohydrate'),
      fat: pick('fat'),
      source: 'fatsecret',
      isIndian: false,
      saturatedFat: _toDouble(defaultServing?['saturated_fat']),
      polyunsaturatedFat: _toDouble(defaultServing?['polyunsaturated_fat']),
      monounsaturatedFat: _toDouble(defaultServing?['monounsaturated_fat']),
      cholesterol: _toDouble(defaultServing?['cholesterol']),
      sodium: _toDouble(defaultServing?['sodium']),
      potassium: _toDouble(defaultServing?['potassium']),
      fiber: _toDouble(defaultServing?['fiber']),
      sugar: _toDouble(defaultServing?['sugar']),
      vitaminA: _toDouble(defaultServing?['vitamin_a']),
      vitaminC: _toDouble(defaultServing?['vitamin_c']),
      calcium: _toDouble(defaultServing?['calcium']),
      iron: _toDouble(defaultServing?['iron']),
    );
  }

  Future<List<Food>> searchFoods(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final callable = _functions.httpsCallable('searchFood');
      final result = await _runCallableWithAuthRetry(
        () => callable.call({
          'query': trimmed,
          'region': 'US',
          'language': 'en',
        }),
      );
      final foodsRaw = _extractFoodsFromResponse(result.data);

      return foodsRaw
          .whereType<Map>()
          .map((entry) => _mapSearchFood(Map<String, dynamic>.from(entry)))
          .where((food) => food.id != 'fs_')
          .toList();
    } on FirebaseFunctionsException {
      rethrow;
    } catch (error) {
      throw Exception('searchFood failed: $error');
    }
  }

  Future<Food?> getFoodById(String id) async {
    try {
      if (id.startsWith('fs_')) {
        return _getFatSecretDetails(id.substring(3));
      }
      return null;
    } catch (error) {
      throw Exception('getFoodById failed: $error');
    }
  }

  Future<Food?> _getFatSecretDetails(String fsId) async {
    try {
      final callable = _functions.httpsCallable('getFoodDetails');
      final result = await _runCallableWithAuthRetry(
        () => callable.call({
          'foodId': fsId,
          'region': 'US',
          'language': 'en',
        }),
      );

      final raw = (result.data is Map)
          ? Map<String, dynamic>.from(result.data as Map)
          : <String, dynamic>{};
      final dynamic foodNodeRaw = raw['food'];
      final foodNode = (foodNodeRaw is Map)
          ? Map<String, dynamic>.from(foodNodeRaw)
          : raw;

      final servings = _extractServingsFromDetails(foodNode)
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();

      if (servings.isEmpty) {
        return null;
      }

      final serving = _pickDefaultServing(servings) ?? servings.first;
      final carbsValue = _toDouble(serving['carbohydrate']) > 0
          ? _toDouble(serving['carbohydrate'])
          : _toDouble(serving['carbs']);

      return Food(
        id: 'fs_${foodNode['id']?.toString() ?? foodNode['food_id']?.toString() ?? fsId}',
        name:
            foodNode['name']?.toString() ??
            foodNode['food_name']?.toString() ??
            'Unknown',
        category:
            foodNode['type']?.toString() ??
            foodNode['food_type']?.toString() ??
            'General',
        unit:
            serving['serving_description']?.toString() ??
            serving['description']?.toString() ??
            serving['metric_serving_unit']?.toString() ??
            'serving',
        baseWeightG: _toDouble(serving['metric_serving_amount']),
        calories: _toDouble(serving['calories']),
        protein: _toDouble(serving['protein']),
        carbs: carbsValue,
        fat: _toDouble(serving['fat']),
        source: 'fatsecret',
        isIndian: false,
        saturatedFat: _toDouble(serving['saturated_fat']),
        polyunsaturatedFat: _toDouble(serving['polyunsaturated_fat']),
        monounsaturatedFat: _toDouble(serving['monounsaturated_fat']),
        cholesterol: _toDouble(serving['cholesterol']),
        sodium: _toDouble(serving['sodium']),
        potassium: _toDouble(serving['potassium']),
        fiber: _toDouble(serving['fiber']),
        sugar: _toDouble(serving['sugar']),
        vitaminA: _toDouble(serving['vitamin_a']),
        vitaminC: _toDouble(serving['vitamin_c']),
        calcium: _toDouble(serving['calcium']),
        iron: _toDouble(serving['iron']),
      );
    } on FirebaseFunctionsException {
      rethrow;
    } catch (error) {
      throw Exception('getFoodDetails failed: $error');
    }
  }

  Food _mapRecognizedFood(Map<String, dynamic> map, int index) {
    final rawId = map['id']?.toString() ?? map['food_id']?.toString() ?? '';
    final servingDescription = map['serving_description']?.toString().trim();
    final carbs = _toDouble(map['carbs']) > 0
        ? _toDouble(map['carbs'])
        : _toDouble(map['carbohydrate']);

    return Food(
      id: rawId.isNotEmpty ? 'fs_$rawId' : 'scan_item_$index',
      name:
          map['name']?.toString() ??
          map['food_name']?.toString() ??
          map['food_entry_name']?.toString() ??
          'Detected food',
      category:
          map['type']?.toString() ??
          map['food_type']?.toString() ??
          'Scanned',
      unit:
          (servingDescription != null && servingDescription.isNotEmpty)
          ? servingDescription
          : 'serving',
      baseWeightG: _toDouble(map['total_metric_amount']),
      calories: _toDouble(map['calories']),
      protein: _toDouble(map['protein']),
      carbs: carbs,
      fat: _toDouble(map['fat']),
      source: 'fatsecret_scan',
      isIndian: false,
      saturatedFat: _toDouble(map['saturated_fat']),
      polyunsaturatedFat: _toDouble(map['polyunsaturated_fat']),
      monounsaturatedFat: _toDouble(map['monounsaturated_fat']),
      cholesterol: _toDouble(map['cholesterol']),
      sodium: _toDouble(map['sodium']),
      potassium: _toDouble(map['potassium']),
      fiber: _toDouble(map['fiber']),
      sugar: _toDouble(map['sugar']),
      vitaminA: _toDouble(map['vitamin_a']),
      vitaminC: _toDouble(map['vitamin_c']),
      calcium: _toDouble(map['calcium']),
      iron: _toDouble(map['iron']),
    );
  }

  Future<MealRecognitionResult?> recognizeMealFromImageBytes(
    Uint8List imageBytes, {
    List<Map<String, dynamic>> eatenFoods = const [],
  }) async {
    if (imageBytes.isEmpty) return null;

    final imageB64 = base64Encode(imageBytes);
    if (imageB64.isEmpty) return null;

    try {
      final callable = _functions.httpsCallable('recognizeMealImage');
      final result = await _runCallableWithAuthRetry(
        () => callable.call({
          'imageB64': imageB64,
          'includeFoodData': true,
          if (eatenFoods.isNotEmpty) 'eatenFoods': eatenFoods,
          'region': 'US',
          'language': 'en',
        }),
      );

      final raw = (result.data is Map)
          ? Map<String, dynamic>.from(result.data as Map)
          : <String, dynamic>{};

      final detectedFoodsRaw = _extractFoodsFromResponse(raw);
      final detectedFoods = <Food>[];
      for (var i = 0; i < detectedFoodsRaw.length; i++) {
        final entry = detectedFoodsRaw[i];
        if (entry is Map) {
          detectedFoods.add(
            _mapRecognizedFood(Map<String, dynamic>.from(entry), i),
          );
        }
      }

      if (detectedFoods.isEmpty) {
        return null;
      }

      double sum(double Function(Food) pick) =>
          detectedFoods.fold(0.0, (total, food) => total + pick(food));

      final mealNode = (raw['meal'] is Map)
          ? Map<String, dynamic>.from(raw['meal'] as Map)
          : <String, dynamic>{};

      final mealName = mealNode['name']?.toString().trim();
      final meal = Food(
        id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        name: (mealName != null && mealName.isNotEmpty)
            ? mealName
            : detectedFoods.first.name,
        category: 'Scanned Meal',
        unit: 'serving',
        baseWeightG: 0,
        calories: _toDouble(mealNode['calories']) > 0
            ? _toDouble(mealNode['calories'])
            : sum((f) => f.calories),
        protein: _toDouble(mealNode['protein']) > 0
            ? _toDouble(mealNode['protein'])
            : sum((f) => f.protein),
        carbs: _toDouble(mealNode['carbs']) > 0
            ? _toDouble(mealNode['carbs'])
            : sum((f) => f.carbs),
        fat: _toDouble(mealNode['fat']) > 0
            ? _toDouble(mealNode['fat'])
            : sum((f) => f.fat),
        source: 'fatsecret_scan',
        isIndian: false,
        saturatedFat: _toDouble(mealNode['saturated_fat']) > 0
            ? _toDouble(mealNode['saturated_fat'])
            : sum((f) => f.saturatedFat ?? 0),
        polyunsaturatedFat: _toDouble(mealNode['polyunsaturated_fat']) > 0
            ? _toDouble(mealNode['polyunsaturated_fat'])
            : sum((f) => f.polyunsaturatedFat ?? 0),
        monounsaturatedFat: _toDouble(mealNode['monounsaturated_fat']) > 0
            ? _toDouble(mealNode['monounsaturated_fat'])
            : sum((f) => f.monounsaturatedFat ?? 0),
        cholesterol: _toDouble(mealNode['cholesterol']) > 0
            ? _toDouble(mealNode['cholesterol'])
            : sum((f) => f.cholesterol ?? 0),
        sodium: _toDouble(mealNode['sodium']) > 0
            ? _toDouble(mealNode['sodium'])
            : sum((f) => f.sodium ?? 0),
        potassium: _toDouble(mealNode['potassium']) > 0
            ? _toDouble(mealNode['potassium'])
            : sum((f) => f.potassium ?? 0),
        fiber: _toDouble(mealNode['fiber']) > 0
            ? _toDouble(mealNode['fiber'])
            : sum((f) => f.fiber ?? 0),
        sugar: _toDouble(mealNode['sugar']) > 0
            ? _toDouble(mealNode['sugar'])
            : sum((f) => f.sugar ?? 0),
        vitaminA: _toDouble(mealNode['vitamin_a']) > 0
            ? _toDouble(mealNode['vitamin_a'])
            : sum((f) => f.vitaminA ?? 0),
        vitaminC: _toDouble(mealNode['vitamin_c']) > 0
            ? _toDouble(mealNode['vitamin_c'])
            : sum((f) => f.vitaminC ?? 0),
        calcium: _toDouble(mealNode['calcium']) > 0
            ? _toDouble(mealNode['calcium'])
            : sum((f) => f.calcium ?? 0),
        iron: _toDouble(mealNode['iron']) > 0
            ? _toDouble(mealNode['iron'])
            : sum((f) => f.iron ?? 0),
      );

      return MealRecognitionResult(meal: meal, detectedFoods: detectedFoods);
    } on FirebaseFunctionsException {
      rethrow;
    } catch (error) {
      throw Exception('recognizeMealImage failed: $error');
    }
  }

  Future<List<Food>> searchByBarcode(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return [];

    try {
      final callable = _functions.httpsCallable('searchBarcode');
      final result = await _runCallableWithAuthRetry(
        () => callable.call({
          'barcode': trimmed,
          'region': 'US',
          'language': 'en',
        }),
      );
      final foodsRaw = _extractFoodsFromResponse(result.data);

      return foodsRaw
          .whereType<Map>()
          .map((entry) => _mapSearchFood(Map<String, dynamic>.from(entry)))
          .where((food) => food.id != 'fs_')
          .toList();
    } on FirebaseFunctionsException {
      rethrow;
    } catch (error) {
      throw Exception('searchBarcode failed: $error');
    }
  }
}
