class FatSecretServing {
  final String id;
  final String description; // e.g. "1 tbsp" or "100g"
  final String metricServingAmount; // e.g. "16.00"
  final String metricServingUnit; // e.g. "g" or "ml"
  
  // Macros
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  
  // Micros & Details
  final double saturatedFat;
  final double polyunsaturatedFat;
  final double monounsaturatedFat;
  final double cholesterol;
  final double sodium;
  final double fiber;
  final double sugar;
  final double potassium;
  final double vitaminA;
  final double vitaminC;
  final double calcium;
  final double iron;

  FatSecretServing({
    required this.id,
    required this.description,
    this.metricServingAmount = "0",
    this.metricServingUnit = "g",
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.saturatedFat = 0,
    this.polyunsaturatedFat = 0,
    this.monounsaturatedFat = 0,
    this.cholesterol = 0,
    this.sodium = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.potassium = 0,
    this.vitaminA = 0,
    this.vitaminC = 0,
    this.calcium = 0,
    this.iron = 0,
  });

  factory FatSecretServing.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return FatSecretServing(
      id: json['serving_id']?.toString() ?? '',
      description: json['serving_description'] ?? 'Serving',
      metricServingAmount: json['metric_serving_amount']?.toString() ?? '0',
      metricServingUnit: json['metric_serving_unit'] ?? 'g',
      calories: parseDouble(json['calories']),
      protein: parseDouble(json['protein']),
      carbs: parseDouble(json['carbohydrate']),
      fat: parseDouble(json['fat']),
      saturatedFat: parseDouble(json['saturated_fat']),
      polyunsaturatedFat: parseDouble(json['polyunsaturated_fat']),
      monounsaturatedFat: parseDouble(json['monounsaturated_fat']),
      cholesterol: parseDouble(json['cholesterol']),
      sodium: parseDouble(json['sodium']),
      fiber: parseDouble(json['fiber']),
      sugar: parseDouble(json['sugar']),
      potassium: parseDouble(json['potassium']),
      vitaminA: parseDouble(json['vitamin_a']),
      vitaminC: parseDouble(json['vitamin_c']),
      calcium: parseDouble(json['calcium']),
      iron: parseDouble(json['iron']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'serving_id': id,
      'serving_description': description,
      'metric_serving_amount': metricServingAmount,
      'metric_serving_unit': metricServingUnit,
      'calories': calories,
      'protein': protein,
      'carbohydrate': carbs,
      'fat': fat,
      'saturated_fat': saturatedFat,
      'polyunsaturated_fat': polyunsaturatedFat,
      'monounsaturated_fat': monounsaturatedFat,
      'cholesterol': cholesterol,
      'sodium': sodium,
      'fiber': fiber,
      'sugar': sugar,
      'potassium': potassium,
      'vitamin_a': vitaminA,
      'vitamin_c': vitaminC,
      'calcium': calcium,
      'iron': iron,
    };
  }
}
