import 'package:cloud_firestore/cloud_firestore.dart';

class CustomFood {
  final String id;
  final String userId;
  final String brandName;
  final String description;
  final String servingSize;
  final double servingPerContainer;
  final CustomFoodNutrition nutrition;
  final DateTime createdAt;

  CustomFood({
    required this.id,
    required this.userId,
    required this.brandName,
    required this.description,
    required this.servingSize,
    required this.servingPerContainer,
    required this.nutrition,
    required this.createdAt,
  });

  factory CustomFood.fromJson(Map<String, dynamic> json, String id) {
    return CustomFood(
      id: id,
      userId: json['userId'] ?? '',
      brandName: json['brandName'] ?? '',
      description: json['description'] ?? '',
      servingSize: json['servingSize'] ?? '',
      servingPerContainer: (json['servingPerContainer'] ?? 1).toDouble(),
      nutrition: CustomFoodNutrition.fromJson(json['nutrition'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'brandName': brandName,
      'description': description,
      'servingSize': servingSize,
      'servingPerContainer': servingPerContainer,
      'nutrition': nutrition.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class CustomFoodNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double saturatedFat;
  final double polyunsaturatedFat;
  final double monounsaturatedFat;
  final double transFat;
  final double cholesterol;
  final double sodium;
  final double potassium;
  final double sugar;
  final double fiber;
  final double vitaminA;
  final double calcium;
  final double iron;

  CustomFoodNutrition({
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

  factory CustomFoodNutrition.fromJson(Map<String, dynamic> json) {
    return CustomFoodNutrition(
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      saturatedFat: (json['saturatedFat'] ?? 0).toDouble(),
      polyunsaturatedFat: (json['polyunsaturatedFat'] ?? 0).toDouble(),
      monounsaturatedFat: (json['monounsaturatedFat'] ?? 0).toDouble(),
      transFat: (json['transFat'] ?? 0).toDouble(),
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
}
