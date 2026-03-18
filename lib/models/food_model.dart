import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_model.dart';

class Food {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double baseWeightG;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> aliases;
  final bool isIndian;
  final String source;
  final String? fdcId;
  final bool isPartial;
  final List<ServingOption> servingOptions;

  final double? saturatedFat;
  final double? polyunsaturatedFat;
  final double? monounsaturatedFat;
  final double? cholesterol;
  final double? sodium;
  final double? fiber;
  final double? sugar;
  final double? vitaminD;
  final double? calcium;
  final double? iron;
  final double? potassium;
  final double? vitaminA;
  final double? vitaminC;

  Food({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.baseWeightG,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.aliases = const [],
    this.isIndian = false,
    this.source = 'internal',
    this.fdcId,
    this.isPartial = false,
    this.servingOptions = const [],
    this.saturatedFat,
    this.polyunsaturatedFat,
    this.monounsaturatedFat,
    this.cholesterol,
    this.sodium,
    this.fiber,
    this.sugar,
    this.vitaminD,
    this.calcium,
    this.iron,
    this.potassium,
    this.vitaminA,
    this.vitaminC,
  });

  factory Food.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Food.fromJson(data, doc.id);
  }

  factory Food.fromJson(Map<String, dynamic> data, String id) {
    final nutrition = data['nutrition_per_unit'] as Map<String, dynamic>? ?? {};
    final nutrition100 = data['nutrition_per_100g'] as Map<String, dynamic>? ?? data['nutritionPer100g'] as Map<String, dynamic>? ?? {};
    
    final options = (data['serving_options'] as List? ?? data['servingOptions'] as List? ?? [])
        .map((o) => ServingOption.fromJson(Map<String, dynamic>.from(o)))
        .toList();

    return Food(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'General',
      unit: data['unit'] ?? '1 unit',
      baseWeightG: _safeDouble(
        data['base_weight_g'] ??
            data['baseWeightG'] ??
            (nutrition100.isNotEmpty ? 100.0 : 0.0),
      ),
      calories: _safeDouble(nutrition['calories'] ?? nutrition100['calories']),
      protein: _safeDouble(nutrition['protein'] ?? nutrition100['protein']),
      carbs: _safeDouble(nutrition['carbs'] ?? nutrition100['carbs']),
      fat: _safeDouble(nutrition['fat'] ?? nutrition100['fat']),
      aliases: List<String>.from(data['aliases'] ?? []),
      isIndian: data['isIndian'] ?? false,
      source: data['source'] ?? 'internal',
      fdcId: data['fdcId']?.toString(),
      isPartial: data['isPartial'] ?? false,
      servingOptions: options,
      saturatedFat: _safeNullableDouble(
        nutrition['saturatedFat'] ??
            nutrition['saturated_fat'] ??
            nutrition100['saturatedFat'],
      ),
      polyunsaturatedFat: _safeNullableDouble(
        nutrition['polyunsaturatedFat'] ??
            nutrition['polyunsaturated_fat'] ??
            nutrition100['polyunsaturatedFat'],
      ),
      monounsaturatedFat: _safeNullableDouble(
        nutrition['monounsaturatedFat'] ??
            nutrition['monounsaturated_fat'] ??
            nutrition100['monounsaturatedFat'],
      ),
      cholesterol: _safeNullableDouble(
        nutrition['cholesterol'] ?? nutrition100['cholesterol'],
      ),
      sodium: _safeNullableDouble(
        nutrition['sodium'] ??
            nutrition100['sodium'] ??
            nutrition100['sodium_mg'],
      ),
      fiber: _safeNullableDouble(
        nutrition['fiber'] ?? nutrition['dietary_fiber'] ?? nutrition100['fiber'],
      ),
      sugar: _safeNullableDouble(
        nutrition['sugar'] ?? nutrition['sugars'] ?? nutrition100['sugar'],
      ),
      vitaminD: _safeNullableDouble(
        nutrition['vitaminD'] ?? nutrition['vitamin_d'],
      ),
      calcium: _safeNullableDouble(
        nutrition['calcium'] ?? nutrition100['calcium'],
      ),
      iron: _safeNullableDouble(
        nutrition['iron'] ?? nutrition100['iron'],
      ),
      potassium: _safeNullableDouble(
        nutrition['potassium'] ?? nutrition100['potassium'],
      ),
      vitaminA: _safeNullableDouble(
        nutrition['vitaminA'] ?? nutrition['vitamin_a'],
      ),
      vitaminC: _safeNullableDouble(
        nutrition['vitaminC'] ?? nutrition['vitamin_c'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'base_weight_g': baseWeightG,
      'fdcId': fdcId,
      'isPartial': isPartial,
      'serving_options': servingOptions.map((o) => o.toJson()).toList(),
      'nutrition_per_unit': {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        if (saturatedFat != null) 'saturatedFat': saturatedFat,
        if (polyunsaturatedFat != null) 'polyunsaturatedFat': polyunsaturatedFat,
        if (monounsaturatedFat != null) 'monounsaturatedFat': monounsaturatedFat,
        if (cholesterol != null) 'cholesterol': cholesterol,
        if (sodium != null) 'sodium': sodium,
        if (fiber != null) 'fiber': fiber,
        if (sugar != null) 'sugar': sugar,
        if (vitaminD != null) 'vitaminD': vitaminD,
        if (calcium != null) 'calcium': calcium,
        if (iron != null) 'iron': iron,
        if (potassium != null) 'potassium': potassium,
        if (vitaminA != null) 'vitaminA': vitaminA,
        if (vitaminC != null) 'vitaminC': vitaminC,
      },
      'aliases': aliases,
      'isIndian': isIndian,
      'source': source,
    };
  }

  Food copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? baseWeightG,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    List<String>? aliases,
    bool? isIndian,
    String? source,
    String? fdcId,
    bool? isPartial,
    List<ServingOption>? servingOptions,
    double? saturatedFat,
    double? polyunsaturatedFat,
    double? monounsaturatedFat,
    double? cholesterol,
    double? sodium,
    double? fiber,
    double? sugar,
    double? vitaminD,
    double? calcium,
    double? iron,
    double? potassium,
    double? vitaminA,
    double? vitaminC,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      baseWeightG: baseWeightG ?? this.baseWeightG,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      aliases: aliases ?? this.aliases,
      isIndian: isIndian ?? this.isIndian,
      source: source ?? this.source,
      fdcId: fdcId ?? this.fdcId,
      isPartial: isPartial ?? this.isPartial,
      servingOptions: servingOptions ?? this.servingOptions,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      polyunsaturatedFat: polyunsaturatedFat ?? this.polyunsaturatedFat,
      monounsaturatedFat: monounsaturatedFat ?? this.monounsaturatedFat,
      cholesterol: cholesterol ?? this.cholesterol,
      sodium: sodium ?? this.sodium,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      vitaminD: vitaminD ?? this.vitaminD,
      calcium: calcium ?? this.calcium,
      iron: iron ?? this.iron,
      potassium: potassium ?? this.potassium,
      vitaminA: vitaminA ?? this.vitaminA,
      vitaminC: vitaminC ?? this.vitaminC,
    );
  }

  static double _safeDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0.0;
    return 0.0;
  }

  static double? _safeNullableDouble(dynamic value) {
    if (value == null) return null;
    return _safeDouble(value);
  }
}
