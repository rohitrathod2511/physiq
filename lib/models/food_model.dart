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
      baseWeightG: (data['base_weight_g'] ?? data['baseWeightG'] ?? (nutrition100.isNotEmpty ? 100.0 : 0.0)).toDouble(),
      calories: (nutrition['calories'] ?? nutrition100['calories'] ?? 0).toDouble(),
      protein: (nutrition['protein'] ?? nutrition100['protein'] ?? 0).toDouble(),
      carbs: (nutrition['carbs'] ?? nutrition100['carbs'] ?? 0).toDouble(),
      fat: (nutrition['fat'] ?? nutrition100['fat'] ?? 0).toDouble(),
      aliases: List<String>.from(data['aliases'] ?? []),
      isIndian: data['isIndian'] ?? false,
      source: data['source'] ?? 'internal',
      fdcId: data['fdcId']?.toString(),
      isPartial: data['isPartial'] ?? false,
      servingOptions: options,
      saturatedFat: (nutrition['saturatedFat'] ?? nutrition['saturated_fat'] ?? nutrition100['saturatedFat'])?.toDouble(),
      polyunsaturatedFat: (nutrition['polyunsaturatedFat'] ?? nutrition['polyunsaturated_fat'] ?? nutrition100['polyunsaturatedFat'])?.toDouble(),
      monounsaturatedFat: (nutrition['monounsaturatedFat'] ?? nutrition['monounsaturated_fat'] ?? nutrition100['monounsaturatedFat'])?.toDouble(),
      cholesterol: (nutrition['cholesterol'] ?? nutrition100['cholesterol'])?.toDouble(),
      sodium: (nutrition['sodium'] ?? nutrition100['sodium'] ?? nutrition100['sodium_mg'])?.toDouble(),
      fiber: (nutrition['fiber'] ?? nutrition['dietary_fiber'] ?? nutrition100['fiber'])?.toDouble(),
      sugar: (nutrition['sugar'] ?? nutrition['sugars'] ?? nutrition100['sugar'])?.toDouble(),
      vitaminD: (nutrition['vitaminD'] ?? nutrition['vitamin_d'])?.toDouble(),
      calcium: (nutrition['calcium'] ?? nutrition100['calcium'])?.toDouble(),
      iron: (nutrition['iron'] ?? nutrition100['iron'])?.toDouble(),
      potassium: (nutrition['potassium'] ?? nutrition100['potassium'])?.toDouble(),
      vitaminA: (nutrition['vitaminA'] ?? nutrition['vitamin_a'])?.toDouble(),
      vitaminC: (nutrition['vitaminC'] ?? nutrition['vitamin_c'])?.toDouble(),
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
}
