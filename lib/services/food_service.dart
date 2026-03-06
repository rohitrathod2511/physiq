import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/food_model.dart';

class MealRecognitionResult {
  final Food meal;
  final List<Food> detectedFoods;

  const MealRecognitionResult({
    required this.meal,
    required this.detectedFoods,
  });
}

class _ParsedUserInput {
  final String query;
  final double quantity;
  final String? unit;
  final double gramsPerUnit;

  const _ParsedUserInput({
    required this.query,
    required this.quantity,
    this.unit,
    required this.gramsPerUnit,
  });
}

class FoodService {
  static const String _searchBaseUrl =
      'https://world.openfoodfacts.org/cgi/search.pl';
  static const String _barcodeBaseUrl =
      'https://world.openfoodfacts.org/api/v2/product';

  static const Map<String, double> _unitToGrams = {
    'cup': 240.0,
    'cups': 240.0,
    'bowl': 250.0,
    'bowls': 250.0,
    'glass': 200.0,
    'glasses': 200.0,
    'ml': 1.0,
    'l': 1000.0,
    'liter': 1000.0,
    'litre': 1000.0,
    'g': 1.0,
    'gram': 1.0,
    'grams': 1.0,
    'kg': 1000.0,
    'oz': 28.35,
    'serving': 100.0,
    'servings': 100.0,
    'slice': 30.0,
    'slices': 30.0,
    'piece': 80.0,
    'pieces': 80.0,
    'plate': 300.0,
    'plates': 300.0,
  };

  static const Map<String, double> _countBasedWeights = {
    'apple': 182.0,
    'banana': 118.0,
    'orange': 131.0,
    'egg': 50.0,
    'pizza': 120.0,
    'roti': 40.0,
    'chapati': 40.0,
  };

  static const Set<String> _queryStopWords = {
    'and',
    'with',
    'of',
    'the',
    'a',
    'an',
    'to',
    'for',
    'in',
    'on',
    'x',
  };

  static const String _offFields =
      'product_name,product_name_en,brands,code,serving_size,serving_quantity,nutriments,popularity_key,image_front_small_url';

  final http.Client _client;

  FoodService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => const {
    'User-Agent': 'Physiq/1.0 (support@physiq.app)',
    'Accept': 'application/json',
  };

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0.0;
    }
    return 0.0;
  }

  String _formatQuantity(double quantity) {
    if (quantity % 1 == 0) return quantity.toInt().toString();
    return quantity.toStringAsFixed(1);
  }

  String _normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _extractProductName(Map<String, dynamic> product) {
    final productName = (product['product_name'] ?? '').toString().trim();
    final productNameEn = (product['product_name_en'] ?? '').toString().trim();
    if (productName.isNotEmpty) return productName;
    if (productNameEn.isNotEmpty) return productNameEn;
    return '';
  }

  List<String> _tokenizeQuery(String query) {
    return query
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where(
          (token) => token.length >= 2 && !_queryStopWords.contains(token),
        )
        .toList();
  }

  String _extractMainFoodKeyword(String input) {
    if (input.trim().isEmpty) return '';

    const unitPattern =
        r'(cup|cups|bowl|bowls|glass|glasses|ml|l|liter|litre|g|gram|grams|kg|oz|serving|servings|slice|slices|piece|pieces|plate|plates)';

    var cleaned = input.toLowerCase();
    cleaned = cleaned.replaceAll(RegExp(r'[\(\)\[\],]+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\d+(?:\.\d+)?'), ' ');
    cleaned = cleaned.replaceAll(RegExp('\b$unitPattern\b'), ' ');
    cleaned = cleaned
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty && !_queryStopWords.contains(token))
        .join(' ');
    return cleaned.trim();
  }

  _ParsedUserInput _parseInput(String input) {
    final raw = input.trim();
    if (raw.isEmpty) {
      return const _ParsedUserInput(query: '', quantity: 1, gramsPerUnit: 0);
    }

    const unitPattern =
        r'(cup|cups|bowl|bowls|glass|glasses|ml|l|liter|litre|g|gram|grams|kg|oz|serving|servings|slice|slices|piece|pieces|plate|plates)';

    double quantity = 1.0;
    String remaining = raw;
    String? unit;
    double gramsPerUnit = 0;

    final trailingQtyUnitMatch = RegExp(
      '^(.+?)\\s+(\\d+(?:\\.\\d+)?)\\s*$unitPattern\\b',
      caseSensitive: false,
    ).firstMatch(remaining);
    if (trailingQtyUnitMatch != null) {
      quantity = _toDouble(trailingQtyUnitMatch.group(2));
      unit = (trailingQtyUnitMatch.group(3) ?? '').toLowerCase();
      gramsPerUnit = _unitToGrams[unit] ?? 0;
      remaining = (trailingQtyUnitMatch.group(1) ?? '').trim();
    }

    if (unit == null) {
      final leadingQtyUnitMatch = RegExp(
        '^(\\d+(?:\\.\\d+)?)\\s*$unitPattern\\b\\s+(.+)\$',
        caseSensitive: false,
      ).firstMatch(remaining);
      if (leadingQtyUnitMatch != null) {
        quantity = _toDouble(leadingQtyUnitMatch.group(1));
        unit = (leadingQtyUnitMatch.group(2) ?? '').toLowerCase();
        gramsPerUnit = _unitToGrams[unit] ?? 0;
        remaining = (leadingQtyUnitMatch.group(3) ?? '').trim();
      }
    }

    if (unit == null) {
      final qtyMatch = RegExp(r'^(\d+(?:\.\d+)?)\s+(.+)$').firstMatch(
        remaining,
      );
      if (qtyMatch != null) {
        quantity = _toDouble(qtyMatch.group(1));
        remaining = (qtyMatch.group(2) ?? '').trim();
      }
    }

    if (unit == null) {
      final leadingUnitMatch = RegExp(
        '^$unitPattern\\b',
        caseSensitive: false,
      ).firstMatch(remaining);
      if (leadingUnitMatch != null) {
        unit = (leadingUnitMatch.group(1) ?? '').toLowerCase();
        gramsPerUnit = _unitToGrams[unit] ?? 0;
        remaining = remaining.substring(leadingUnitMatch.end).trim();
        if (remaining.toLowerCase().startsWith('of ')) {
          remaining = remaining.substring(3).trim();
        }
      }
    }

    if (unit == null) {
      final trailingUnitMatch = RegExp(
        '^(.+?)\\s+$unitPattern\\b',
        caseSensitive: false,
      ).firstMatch(remaining);
      if (trailingUnitMatch != null) {
        unit = (trailingUnitMatch.group(2) ?? '').toLowerCase();
        gramsPerUnit = _unitToGrams[unit] ?? 0;
        remaining = (trailingUnitMatch.group(1) ?? '').trim();
      }
    }

    final query = _extractMainFoodKeyword(
      remaining.isNotEmpty ? remaining : raw,
    );

    return _ParsedUserInput(
      query: query.isNotEmpty ? query : raw,
      quantity: quantity > 0 ? quantity : 1,
      unit: unit,
      gramsPerUnit: gramsPerUnit,
    );
  }

  bool _containsJunkKeyword(String nameLower) {
    return nameLower.contains('water') || nameLower.contains('eau');
  }

  bool _queryWantsJunkKeyword(String queryLower) {
    return queryLower.contains('water') || queryLower.contains('eau');
  }

  bool _isLikelyJunkProduct(
    Map<String, dynamic> product,
    _ParsedUserInput parsed,
  ) {
    final normalizedName = _normalizeText(_extractProductName(product));
    if (normalizedName.isEmpty) return true;

    final normalizedQuery = _normalizeText(parsed.query);
    if (_containsJunkKeyword(normalizedName) &&
        !_queryWantsJunkKeyword(normalizedQuery)) {
      return true;
    }

    final tokens = _tokenizeQuery(normalizedQuery);
    if (tokens.isEmpty) return false;

    final tokenHits = tokens.where(normalizedName.contains).length;
    return tokenHits == 0;
  }

  double _extractServingQuantity(Map<String, dynamic> product) {
    final fromField = _toDouble(product['serving_quantity']);
    if (fromField > 0) return fromField;

    final servingSize = (product['serving_size'] ?? '').toString();
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(servingSize);
    if (match == null) return 0;
    return _toDouble(match.group(1));
  }

  double _energyKcal100g(Map<String, dynamic> nutriments) {
    final kcal100 =
        _toDouble(nutriments['energy-kcal_100g']) > 0
        ? _toDouble(nutriments['energy-kcal_100g'])
        : _toDouble(nutriments['energy_kcal_100g']);
    if (kcal100 > 0) return kcal100;

    final kcal = _toDouble(nutriments['energy-kcal']);
    if (kcal > 0) return kcal;

    final kj100 = _toDouble(nutriments['energy_100g']);
    if (kj100 > 0) return kj100 / 4.184;

    return 0;
  }

  double _defaultPieceWeightForQuery(String query) {
    final q = query.toLowerCase();
    for (final entry in _countBasedWeights.entries) {
      if (q.contains(entry.key)) return entry.value;
    }
    return 0;
  }

  String _buildServingLabel(
    _ParsedUserInput parsed,
    String servingSize,
    double servingQuantity,
    double inferredPieceWeight,
  ) {
    if (parsed.unit != null) {
      return '${_formatQuantity(parsed.quantity)} ${parsed.unit}';
    }

    if (parsed.quantity > 1 && servingSize.isNotEmpty) {
      return '${_formatQuantity(parsed.quantity)} x $servingSize';
    }

    if (servingSize.isNotEmpty) {
      return servingSize;
    }

    if (servingQuantity > 0) {
      if (parsed.quantity == 1) return '1 serving';
      return '${_formatQuantity(parsed.quantity)} servings';
    }

    if (inferredPieceWeight > 0) {
      if (parsed.quantity == 1) return '1 piece (${inferredPieceWeight.toInt()}g)';
      return '${_formatQuantity(parsed.quantity)} pieces';
    }

    if (parsed.quantity == 1) return '100g';
    return '${_formatQuantity(parsed.quantity)} x 100g';
  }

  double _weightForInput(
    _ParsedUserInput parsed,
    double servingQuantity,
    double inferredPieceWeight,
  ) {
    if (parsed.gramsPerUnit > 0) return parsed.quantity * parsed.gramsPerUnit;
    if (servingQuantity > 0) return parsed.quantity * servingQuantity;
    if (inferredPieceWeight > 0) return parsed.quantity * inferredPieceWeight;
    return parsed.quantity * 100.0;
  }

  int _relevanceScore(Map<String, dynamic> product, _ParsedUserInput parsed) {
    final name = _normalizeText(_extractProductName(product));
    final brand = _normalizeText((product['brands'] ?? '').toString());
    final tokens = _tokenizeQuery(parsed.query);
    final fullQuery = _normalizeText(parsed.query);
    final nutriments =
        (product['nutriments'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    int score = 0;
    int tokenHits = 0;

    if (name.isEmpty) return -999;
    if (name == fullQuery) score += 35;
    if (name.contains(fullQuery)) score += 24;

    for (final token in tokens) {
      if (name.contains(token)) {
        score += 10;
        tokenHits++;
      } else if (brand.contains(token)) {
        score += 4;
        tokenHits++;
      } else {
        score -= 3;
      }
    }

    if (tokens.length >= 2 && tokenHits >= 2) score += 10;
    if (tokenHits == 0 && tokens.isNotEmpty) score -= 20;

    if (_energyKcal100g(nutriments) > 0) {
      score += 4;
    } else {
      score -= 4;
    }

    if (_extractServingQuantity(product) > 0) score += 2;

    final popularity = _toDouble(product['popularity_key']);
    if (popularity > 1000000) {
      score += 8;
    } else if (popularity > 100000) {
      score += 6;
    } else if (popularity > 10000) {
      score += 4;
    } else if (popularity > 1000) {
      score += 2;
    }

    if (_containsJunkKeyword(name) && !_queryWantsJunkKeyword(fullQuery)) {
      score -= 50;
    }

    return score;
  }

  Food _mapProductToFood(
    Map<String, dynamic> product,
    _ParsedUserInput parsed,
  ) {
    final nutriments =
        (product['nutriments'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final servingQuantity = _extractServingQuantity(product);
    final inferredPieceWeight = _defaultPieceWeightForQuery(parsed.query);
    final totalWeightG = _weightForInput(
      parsed,
      servingQuantity,
      inferredPieceWeight,
    );
    final scale = totalWeightG / 100.0;

    final calories100 = _energyKcal100g(nutriments);
    final protein100 = _toDouble(nutriments['proteins_100g']);
    final carbs100 = _toDouble(nutriments['carbohydrates_100g']);
    final fat100 = _toDouble(nutriments['fat_100g']);

    final servingSize = (product['serving_size'] ?? '').toString().trim();
    final name = _extractProductName(product);
    final code = (product['code'] ?? '').toString().trim();
    final brand = (product['brands'] ?? '').toString().trim();

    return Food(
      id: code.isEmpty
          ? 'off_${DateTime.now().millisecondsSinceEpoch}'
          : 'off_$code',
      name: name.isEmpty ? parsed.query : name,
      category: brand.isNotEmpty ? brand : 'Open Food Facts',
      unit: _buildServingLabel(
        parsed,
        servingSize,
        servingQuantity,
        inferredPieceWeight,
      ),
      baseWeightG: totalWeightG > 0 ? totalWeightG : 100.0,
      calories: calories100 * scale,
      protein: protein100 * scale,
      carbs: carbs100 * scale,
      fat: fat100 * scale,
      source: 'open_food_facts',
      saturatedFat: _toDouble(nutriments['saturated-fat_100g']) * scale,
      polyunsaturatedFat:
          _toDouble(nutriments['polyunsaturated-fat_100g']) * scale,
      monounsaturatedFat:
          _toDouble(nutriments['monounsaturated-fat_100g']) * scale,
      cholesterol: _toDouble(nutriments['cholesterol_100g']) * scale,
      sodium: _toDouble(nutriments['sodium_100g']) * scale,
      fiber: _toDouble(nutriments['fiber_100g']) * scale,
      sugar: _toDouble(nutriments['sugars_100g']) * scale,
      potassium: _toDouble(nutriments['potassium_100g']) * scale,
      calcium: _toDouble(nutriments['calcium_100g']) * scale,
      iron: _toDouble(nutriments['iron_100g']) * scale,
      vitaminA: _toDouble(nutriments['vitamin-a_100g']) * scale,
      vitaminC: _toDouble(nutriments['vitamin-c_100g']) * scale,
    );
  }

  Future<List<Food>> searchFoods(String userInput) async {
    final parsed = _parseInput(userInput);
    if (parsed.query.isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(parsed.query);
    final url =
        '$_searchBaseUrl?search_terms=$encodedQuery&search_simple=1&action=process&json=1&page_size=50&sort_by=popularity_key&fields=$_offFields';
    debugPrint('OFF search URL: $url');

    final response = await _client.get(Uri.parse(url), headers: _headers);
    debugPrint('OFF search status: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Open Food Facts search failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];

    final productsRaw = decoded['products'];
    if (productsRaw is! List) return [];

    final products = productsRaw
        .whereType<Map>()
        .map((product) => Map<String, dynamic>.from(product))
        .toList();

    final scored = products
        .where((product) => !_isLikelyJunkProduct(product, parsed))
        .map(
          (product) => (
            product: product,
            score: _relevanceScore(product, parsed),
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final seenNames = <String>{};
    final resultFoods = <Food>[];

    void collectFoods(int minScore) {
      for (final entry in scored) {
        if (entry.score < minScore) continue;

        final mappedFood = _mapProductToFood(entry.product, parsed);
        final normalizedName = _normalizeText(mappedFood.name);
        if (normalizedName.isEmpty || normalizedName == 'unknown food') {
          continue;
        }
        if (seenNames.contains(normalizedName)) continue;

        seenNames.add(normalizedName);
        resultFoods.add(mappedFood);

        if (resultFoods.length >= 10) break;
      }
    }

    collectFoods(4);
    if (resultFoods.isEmpty) {
      collectFoods(-5);
    }

    return resultFoods;
  }

  Future<List<Food>> searchByBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return [];

    final url = '$_barcodeBaseUrl/$code.json';
    debugPrint('OFF barcode URL: $url');
    final response = await _client.get(Uri.parse(url), headers: _headers);
    debugPrint('OFF barcode status: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Open Food Facts barcode lookup failed: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];
    final product = decoded['product'];
    if (product is! Map) return [];

    final parsed = _parseInput('1 serving');
    return [_mapProductToFood(Map<String, dynamic>.from(product), parsed)];
  }

  Future<Food?> getFoodById(String id) async {
    final code = id.startsWith('off_') ? id.substring(4) : id;
    if (code.isEmpty) return null;
    final results = await searchByBarcode(code);
    return results.isEmpty ? null : results.first;
  }

  Food _getMealNutrition(
    List<Food> detectedFoods,
    List<String> detectedLabels,
  ) {
    if (detectedFoods.isEmpty) {
      return Food(
        id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Detected Meal',
        category: 'Scanned Meal',
        unit: 'serving',
        baseWeightG: 100,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        source: 'open_food_facts_scan',
      );
    }

    double sum(double Function(Food food) selector) {
      return detectedFoods.fold(0.0, (total, food) => total + selector(food));
    }

    double sumNullable(double? Function(Food food) selector) {
      return detectedFoods.fold(
        0.0,
        (total, food) => total + (selector(food) ?? 0.0),
      );
    }

    final ingredients = detectedFoods
        .map((food) => food.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final labelsForTitle = detectedLabels.isNotEmpty
        ? detectedLabels
        : ingredients;
    final title = labelsForTitle.isEmpty
        ? 'Detected Meal'
        : 'Detected Meal: ${labelsForTitle.join(', ')}';

    return Food(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      name: title,
      category: 'Scanned Meal',
      unit: 'serving',
      baseWeightG: 100,
      calories: sum((food) => food.calories),
      protein: sum((food) => food.protein),
      carbs: sum((food) => food.carbs),
      fat: sum((food) => food.fat),
      aliases: ingredients,
      source: 'open_food_facts_scan',
      saturatedFat: sumNullable((food) => food.saturatedFat),
      polyunsaturatedFat: sumNullable((food) => food.polyunsaturatedFat),
      monounsaturatedFat: sumNullable((food) => food.monounsaturatedFat),
      cholesterol: sumNullable((food) => food.cholesterol),
      sodium: sumNullable((food) => food.sodium),
      fiber: sumNullable((food) => food.fiber),
      sugar: sumNullable((food) => food.sugar),
      potassium: sumNullable((food) => food.potassium),
      vitaminA: sumNullable((food) => food.vitaminA),
      vitaminC: sumNullable((food) => food.vitaminC),
      calcium: sumNullable((food) => food.calcium),
      iron: sumNullable((food) => food.iron),
    );
  }

  Future<MealRecognitionResult?> getMealNutritionFromLabels(
    List<String> labels,
  ) async {
    final cleanedLabels = labels
        .map((label) => label.trim().toLowerCase())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();

    if (cleanedLabels.isEmpty) return null;

    final detectedFoods = <Food>[];
    final seenFoodNames = <String>{};

    for (final label in cleanedLabels.take(8)) {
      final results = await searchFoods(label);
      if (results.isEmpty) continue;

      final bestMatch = results.first;
      final normalizedName = _normalizeText(bestMatch.name);
      if (normalizedName.isEmpty || seenFoodNames.contains(normalizedName)) {
        continue;
      }

      seenFoodNames.add(normalizedName);
      detectedFoods.add(bestMatch);
    }

    if (detectedFoods.isEmpty) return null;

    final meal = _getMealNutrition(detectedFoods, cleanedLabels);
    return MealRecognitionResult(meal: meal, detectedFoods: detectedFoods);
  }
}
