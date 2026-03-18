import 'package:cloud_firestore/cloud_firestore.dart';

class ServingOption {
  final String label;
  final double grams;

  ServingOption({required this.label, required this.grams});

  factory ServingOption.fromJson(Map<String, dynamic> json) {
    return ServingOption(
      label: _str(json['label'], 'Custom'),
      grams: _num(json['grams']),
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'grams': grams};

  static String _str(dynamic value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class MealIngredient {
  final String name;
  final String amount;
  final String servingSize;
  final double caloriesEstimate;
  final double proteinEstimate;
  final double carbsEstimate;
  final double fatEstimate;
  final List<ServingOption> servingOptions;
  final Map<String, double>? nutritionPer100g;

  MealIngredient({
    required this.name,
    required this.amount,
    required this.servingSize,
    this.caloriesEstimate = 0,
    this.proteinEstimate = 0,
    this.carbsEstimate = 0,
    this.fatEstimate = 0,
    this.servingOptions = const [],
    this.nutritionPer100g,
  });

  factory MealIngredient.fromJson(Map<String, dynamic> json) {
    final options = (json['serving_options'] as List? ?? json['servingOptions'] as List? ?? [])
        .map((o) => ServingOption.fromJson(Map<String, dynamic>.from(o)))
        .toList();

    final nutritionMapRaw = json['nutrition_per_100g'] ?? json['nutritionPer100g'];
    Map<String, double>? nutritionMap;
    if (nutritionMapRaw is Map) {
      nutritionMap = {
        'calories': _num(nutritionMapRaw['calories']),
        'protein': _num(nutritionMapRaw['protein']),
        'carbs': _num(nutritionMapRaw['carbs']),
        'fat': _num(nutritionMapRaw['fat']),
      };
    }

    return MealIngredient(
      name: _str(json['ingredient'] ?? json['name'], 'Food item'),
      amount: _str(json['estimated_amount'] ?? json['amount'], '1 serving'),
      servingSize: _str(json['serving_size'], '100g'),
      caloriesEstimate: _num(json['calories_estimate'] ?? json['calories']),
      proteinEstimate: _num(json['protein_estimate'] ?? json['protein']),
      carbsEstimate: _num(json['carbs_estimate'] ?? json['carbs']),
      fatEstimate: _num(json['fat_estimate'] ?? json['fat']),
      servingOptions: options,
      nutritionPer100g: nutritionMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'serving_size': servingSize,
      'calories_estimate': caloriesEstimate,
      'protein_estimate': proteinEstimate,
      'carbs_estimate': carbsEstimate,
      'fat_estimate': fatEstimate,
      'serving_options': servingOptions.map((o) => o.toJson()).toList(),
      'nutrition_per_100g': nutritionPer100g,
    };
  }

  static String _str(dynamic value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}


class Meal {
  final String id;
  final String imageUrl;
  final String title;
  final String container;
  final List<MealIngredient> ingredients;
  final DateTime createdAt;
  final bool bookmarked;
  final bool logged;

  Meal({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.container,
    required this.ingredients,
    required this.createdAt,
    this.bookmarked = false,
    this.logged = false,
  });

  factory Meal.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meal.fromJson(data, doc.id);
  }

  factory Meal.fromJson(Map<String, dynamic> data, String id) {
    return Meal(
      id: id,
      imageUrl: data['image_url'] ?? '',
      title: data['meal_title'] ?? data['title'] ?? '',
      container: data['container'] ?? 'plate',
      ingredients: (data['ingredients'] as List? ?? [])
          .map((i) => MealIngredient.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bookmarked: data['bookmarked'] ?? false,
      logged: data['logged'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'meal_title': title,
      'container': container,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'created_at': Timestamp.fromDate(createdAt),
      'bookmarked': bookmarked,
      'logged': logged,
    };
  }
}

class MealModel {
  final String id;
  final String userId;
  final String name;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final DateTime timestamp;
  final String? imageUrl;
  final String source;
  final String? servingDescription;
  final double? servingAmount;
  final Map<String, dynamic>? fullNutritionMap;

  MealModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.timestamp,
    this.imageUrl,
    this.source = 'internal',
    this.servingDescription,
    this.servingAmount,
    this.fullNutritionMap,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'source': source,
      'servingDescription': servingDescription,
      'servingAmount': servingAmount,
      'fullNutritionMap': fullNutritionMap,
    };
  }

  factory MealModel.fromMap(Map<String, dynamic> map, String id) {
    return MealModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      calories: (map['calories'] ?? 0).toInt(),
      proteinG: (map['proteinG'] ?? 0).toInt(),
      carbsG: (map['carbsG'] ?? 0).toInt(),
      fatG: (map['fatG'] ?? 0).toInt(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      source: map['source'] ?? 'internal',
      servingDescription: map['servingDescription'],
      servingAmount: (map['servingAmount'] ?? 0).toDouble(),
      fullNutritionMap: map['fullNutritionMap'],
    );
  }
}
