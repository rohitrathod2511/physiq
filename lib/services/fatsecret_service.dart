import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:physiq/models/fatsecret_food_model.dart';

class FatSecretService {
  FatSecretService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final Duration _cacheTtl = const Duration(days: 30);

  Future<void> _ensureAuthenticatedUser() async {
    User? user = _auth.currentUser;
    if (user == null) {
      final credential = await _auth.signInAnonymously();
      user = credential.user;
    }

    if (user == null) {
      throw Exception('Unable to authenticate user for FatSecret functions.');
    }

    try {
      await user.getIdToken();
    } catch (_) {
      await user.getIdToken(true);
    }
  }

  bool _isCacheFresh(dynamic cachedAt) {
    if (cachedAt is! Timestamp) return false;
    return DateTime.now().difference(cachedAt.toDate()) < _cacheTtl;
  }

  List<dynamic> _extractFoodsFromSearch(dynamic rawData) {
    if (rawData is! Map) return const [];

    final foodsNode = rawData['foods'];
    if (foodsNode is List) return foodsNode;
    if (foodsNode is Map) {
      final nested = foodsNode['food'];
      if (nested is List) return nested;
      if (nested != null) return [nested];
    }
    return const [];
  }

  List<dynamic> _extractServings(dynamic servingsNode) {
    if (servingsNode is List) return servingsNode;
    if (servingsNode is Map) {
      final nested = servingsNode['serving'];
      if (nested is List) return nested;
      if (nested != null) return [nested];
    }
    return const [];
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> _normalizeServing(Map<String, dynamic> serving) {
    final carbs = _toDouble(serving['carbohydrate']) > 0
        ? _toDouble(serving['carbohydrate'])
        : _toDouble(serving['carbs']);

    return {
      'serving_id':
          serving['serving_id']?.toString() ?? serving['id']?.toString() ?? '',
      'serving_description':
          serving['serving_description']?.toString() ??
          serving['description']?.toString() ??
          'Serving',
      'metric_serving_amount': _toDouble(serving['metric_serving_amount']),
      'metric_serving_unit': serving['metric_serving_unit']?.toString() ?? 'g',
      'calories': _toDouble(serving['calories']),
      'protein': _toDouble(serving['protein']),
      'carbohydrate': carbs,
      'fat': _toDouble(serving['fat']),
      'saturated_fat': _toDouble(serving['saturated_fat']),
      'polyunsaturated_fat': _toDouble(serving['polyunsaturated_fat']),
      'monounsaturated_fat': _toDouble(serving['monounsaturated_fat']),
      'cholesterol': _toDouble(serving['cholesterol']),
      'sodium': _toDouble(serving['sodium']),
      'fiber': _toDouble(serving['fiber']),
      'sugar': _toDouble(serving['sugar']),
      'potassium': _toDouble(serving['potassium']),
      'vitamin_a': _toDouble(serving['vitamin_a']),
      'vitamin_c': _toDouble(serving['vitamin_c']),
      'calcium': _toDouble(serving['calcium']),
      'iron': _toDouble(serving['iron']),
    };
  }

  Map<String, dynamic> _normalizeFoodData(dynamic rawData) {
    final root = (rawData is Map)
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    final dynamic foodNode = root['food'];
    final food = (foodNode is Map) ? Map<String, dynamic>.from(foodNode) : root;

    final servings = _extractServings(food['servings'])
        .whereType<Map>()
        .map((entry) => _normalizeServing(Map<String, dynamic>.from(entry)))
        .toList();

    return {
      'id': food['id']?.toString() ?? food['food_id']?.toString() ?? '',
      'name':
          food['name']?.toString() ??
          food['food_name']?.toString() ??
          'Unknown Food',
      'brand':
          food['brand']?.toString() ?? food['brand_name']?.toString() ?? '',
      'type':
          food['type']?.toString() ??
          food['food_type']?.toString() ??
          'Generic',
      'servings': servings,
    };
  }

  Exception _callableException(String functionName, Object error) {
    if (error is FirebaseFunctionsException) {
      final message = error.message ?? 'No message from Cloud Function.';
      return Exception('$functionName failed (${error.code}): $message');
    }
    return Exception('$functionName failed: $error');
  }

  Future<List<FatSecretFood>> searchFoods(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      await _ensureAuthenticatedUser();
      final callable = _functions.httpsCallable('searchFood');
      final result = await callable.call({'query': trimmed});
      final foodsRaw = _extractFoodsFromSearch(result.data);

      return foodsRaw.whereType<Map>().map((entry) {
        final map = Map<String, dynamic>.from(entry);
        return FatSecretFood(
          id: map['id']?.toString() ?? '',
          name: map['name']?.toString() ?? '',
          brandName: map['brand']?.toString() ?? '',
          type: map['type']?.toString() ?? 'Generic',
          servings: const [],
          calories: _toDouble(map['calories']),
          description: map['description']?.toString(),
        );
      }).toList();
    } catch (error) {
      throw _callableException('searchFood', error);
    }
  }

  Future<FatSecretFood> getFoodDetails(String foodId) async {
    try {
      final cacheDoc = await _firestore
          .collection('food_cache')
          .doc(foodId)
          .get();
      if (cacheDoc.exists && cacheDoc.data() != null) {
        final cache = cacheDoc.data()!;
        if (_isCacheFresh(cache['cachedAt'])) {
          final dynamic payload = cache['data'] ?? cache;
          if (payload is Map) {
            final cachedFood = FatSecretFood.fromJson(
              Map<String, dynamic>.from(payload),
            );
            if (cachedFood.servings.isNotEmpty) {
              return cachedFood;
            }
          }
        }
      }

      await _ensureAuthenticatedUser();
      final callable = _functions.httpsCallable('getFoodDetails');
      final result = await callable.call({'foodId': foodId});

      final normalized = _normalizeFoodData(result.data);
      final food = FatSecretFood.fromJson(normalized);
      if (food.servings.isEmpty) {
        throw Exception('Food details returned without servings.');
      }

      await _firestore.collection('food_cache').doc(foodId).set({
        'schemaVersion': 2,
        'cachedAt': FieldValue.serverTimestamp(),
        'data': normalized,
      }, SetOptions(merge: true));

      return food;
    } catch (error) {
      throw _callableException('getFoodDetails', error);
    }
  }
}
