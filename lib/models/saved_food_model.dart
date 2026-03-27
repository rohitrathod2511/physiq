import 'package:cloud_firestore/cloud_firestore.dart';

class SavedFood {
  final String id;
  final String userId;
  final String name;
  final String type;
  final String sourceType;
  final String servingSize;
  final double servingAmount;
  final SavedFoodNutrition nutrition;
  final DateTime createdAt;
  final String originalId;
  final Map<String, dynamic>? sourceData;

  SavedFood({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.sourceType,
    required this.servingSize,
    required this.servingAmount,
    required this.nutrition,
    required this.createdAt,
    this.originalId = '',
    this.sourceData,
  });

  factory SavedFood.fromJson(Map<String, dynamic> json, String id) {
    final sourceType = _safeString(json['sourceType'], fallback: 'database');

    return SavedFood(
      id: id,
      userId: _safeString(json['userId']),
      name: _safeString(json['name']),
      type: _resolveType(json['type'], sourceType),
      sourceType: sourceType,
      servingSize: _safeString(json['servingSize'], fallback: '1 serving'),
      servingAmount: _safeDouble(json['servingAmount'], fallback: 1),
      nutrition: SavedFoodNutrition.fromJson(
        _safeMap(json['nutrition']) ?? const <String, dynamic>{},
      ),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      originalId: _safeString(json['originalId']),
      sourceData: _normalizeDynamicMap(
        _safeMap(json['sourceData']) ?? _safeMap(json['data']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'sourceType': sourceType,
      'servingSize': servingSize,
      'servingAmount': servingAmount,
      'nutrition': nutrition.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'originalId': originalId,
      if (sourceData != null) 'sourceData': sourceData,
    };
  }

  static String _resolveType(dynamic rawType, String sourceType) {
    final normalizedType = _safeString(rawType).toLowerCase();
    final normalizedSource = sourceType.toLowerCase();

    if (normalizedType == 'meal' || normalizedSource == 'meal') {
      return 'meal';
    }
    if (normalizedType == 'custom_food' || normalizedSource == 'custom_food') {
      return 'custom_food';
    }
    if (normalizedType == 'usda_food' || normalizedSource == 'usda_food') {
      return 'usda_food';
    }
    if (normalizedType == 'scan' || normalizedSource == 'scan') {
      return 'scan';
    }

    switch (normalizedSource) {
      case 'custom_meal':
        return 'meal';
      case 'database':
      case 'usda':
      case 'off':
      case 'all':
        return 'usda_food';
      case 'snap':
      case 'gemini_vision':
      case 'saved_scan':
        return 'scan';
      default:
        return normalizedType.isNotEmpty ? normalizedType : 'usda_food';
    }
  }

  static String _safeString(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static double _safeDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static Map<String, dynamic>? _safeMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _normalizeDynamicValue(nestedValue),
        ),
      );
    }
    return null;
  }

  static Map<String, dynamic>? _normalizeDynamicMap(Map<String, dynamic>? value) {
    if (value == null) return null;
    return value.map(
      (key, nestedValue) =>
          MapEntry(key.toString(), _normalizeDynamicValue(nestedValue)),
    );
  }

  static dynamic _normalizeDynamicValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _normalizeDynamicValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_normalizeDynamicValue).toList();
    }
    if (value is num) {
      return value.toDouble();
    }
    return value;
  }
}

class SavedFoodNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double saturatedFat;
  final double polyunsaturatedFat;
  final double monounsaturatedFat;
  final double cholesterol;
  final double sodium;
  final double potassium;
  final double sugar;
  final double fiber;
  final double vitaminA;
  final double calcium;
  final double iron;
  final double transFat;

  SavedFoodNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.saturatedFat = 0,
    this.polyunsaturatedFat = 0,
    this.monounsaturatedFat = 0,
    this.transFat = 0,
    this.cholesterol = 0,
    this.sodium = 0,
    this.potassium = 0,
    this.sugar = 0,
    this.fiber = 0,
    this.vitaminA = 0,
    this.calcium = 0,
    this.iron = 0,
  });

  factory SavedFoodNutrition.fromJson(Map<String, dynamic> json) {
    return SavedFoodNutrition(
      calories: _safeDouble(json['calories']),
      protein: _safeDouble(json['protein']),
      carbs: _safeDouble(json['carbs']),
      fat: _safeDouble(json['fat']),
      saturatedFat: _safeDouble(json['saturatedFat']),
      polyunsaturatedFat: _safeDouble(json['polyunsaturatedFat']),
      monounsaturatedFat: _safeDouble(json['monounsaturatedFat']),
      transFat: _safeDouble(json['transFat']),
      cholesterol: _safeDouble(json['cholesterol']),
      sodium: _safeDouble(json['sodium']),
      potassium: _safeDouble(json['potassium']),
      sugar: _safeDouble(json['sugar']),
      fiber: _safeDouble(json['fiber']),
      vitaminA: _safeDouble(json['vitaminA']),
      calcium: _safeDouble(json['calcium']),
      iron: _safeDouble(json['iron']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'saturatedFat': saturatedFat,
      'polyunsaturatedFat': polyunsaturatedFat,
      'monounsaturatedFat': monounsaturatedFat,
      'transFat': transFat,
      'cholesterol': cholesterol,
      'sodium': sodium,
      'potassium': potassium,
      'sugar': sugar,
      'fiber': fiber,
      'vitaminA': vitaminA,
      'calcium': calcium,
      'iron': iron,
    };
  }

  static double _safeDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0.0;
    return 0.0;
  }
}
