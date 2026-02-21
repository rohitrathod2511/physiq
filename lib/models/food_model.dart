import 'package:cloud_firestore/cloud_firestore.dart';

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
    
    return Food(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'General',
      unit: data['unit'] ?? '1 unit',
      baseWeightG: (data['base_weight_g'] ?? 0).toDouble(),
      calories: (nutrition['calories'] ?? 0).toDouble(),
      protein: (nutrition['protein'] ?? 0).toDouble(),
      carbs: (nutrition['carbs'] ?? 0).toDouble(),
      fat: (nutrition['fat'] ?? 0).toDouble(),
      aliases: List<String>.from(data['aliases'] ?? []),
      isIndian: data['isIndian'] ?? false,
      source: data['source'] ?? 'internal',
      saturatedFat: (nutrition['saturatedFat'] ?? nutrition['saturated_fat'])?.toDouble(),
      polyunsaturatedFat: (nutrition['polyunsaturatedFat'] ?? nutrition['polyunsaturated_fat'])?.toDouble(),
      monounsaturatedFat: (nutrition['monounsaturatedFat'] ?? nutrition['monounsaturated_fat'])?.toDouble(),
      cholesterol: (nutrition['cholesterol'])?.toDouble(),
      sodium: (nutrition['sodium'])?.toDouble(),
      fiber: (nutrition['fiber'] ?? nutrition['dietary_fiber'])?.toDouble(),
      sugar: (nutrition['sugar'] ?? nutrition['sugars'])?.toDouble(),
      vitaminD: (nutrition['vitaminD'] ?? nutrition['vitamin_d'])?.toDouble(),
      calcium: (nutrition['calcium'])?.toDouble(),
      iron: (nutrition['iron'])?.toDouble(),
      potassium: (nutrition['potassium'])?.toDouble(),
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
