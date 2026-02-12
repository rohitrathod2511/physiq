import 'package:cloud_firestore/cloud_firestore.dart';

class SavedFood {
  final String id;
  final String userId;
  final String name;
  final String sourceType; // "database", "scan", "describe", "custom_meal", "custom_food"
  final String servingSize; // e.g., "1 cup", "100g", "1 slice"
  final double servingAmount; // user's selected quantity, e.g., 1.5
  final SavedFoodNutrition nutrition;
  final DateTime createdAt;

  SavedFood({
    required this.id,
    required this.userId,
    required this.name,
    required this.sourceType,
    required this.servingSize,
    required this.servingAmount,
    required this.nutrition,
    required this.createdAt,
  });

  factory SavedFood.fromJson(Map<String, dynamic> json, String id) {
    return SavedFood(
      id: id,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      sourceType: json['sourceType'] ?? 'database',
      servingSize: json['servingSize'] ?? '1 serving',
      servingAmount: (json['servingAmount'] ?? 1).toDouble(),
      nutrition: SavedFoodNutrition.fromJson(json['nutrition'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'sourceType': sourceType,
      'servingSize': servingSize,
      'servingAmount': servingAmount,
      'nutrition': nutrition.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    };
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

  SavedFoodNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.saturatedFat = 0,
    this.polyunsaturatedFat = 0,
    this.monounsaturatedFat = 0,
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
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      saturatedFat: (json['saturatedFat'] ?? 0).toDouble(),
      polyunsaturatedFat: (json['polyunsaturatedFat'] ?? 0).toDouble(),
      monounsaturatedFat: (json['monounsaturatedFat'] ?? 0).toDouble(),
      cholesterol: (json['cholesterol'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      potassium: (json['potassium'] ?? 0).toDouble(),
      sugar: (json['sugar'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      vitaminA: (json['vitaminA'] ?? 0).toDouble(),
      calcium: (json['calcium'] ?? 0).toDouble(),
      iron: (json['iron'] ?? 0).toDouble(),
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
}
