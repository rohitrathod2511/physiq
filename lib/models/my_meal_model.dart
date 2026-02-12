import 'package:cloud_firestore/cloud_firestore.dart';

class MealItem {
  final String foodId;
  final String foodName;
  final double quantity;
  final String servingLabel;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  MealItem({
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.servingLabel,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MealItem.fromMap(Map<String, dynamic> map) {
    return MealItem(
      foodId: map['foodId'] ?? '',
      foodName: map['foodName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      servingLabel: map['servingLabel'] ?? '',
      calories: (map['calories'] ?? 0).toDouble(),
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'quantity': quantity,
      'servingLabel': servingLabel,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class MyMeal {
  final String id;
  final String name;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final DateTime createdAt;
  final List<MealItem> items;

  MyMeal({
    required this.id,
    required this.name,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.createdAt,
    required this.items,
  });

  factory MyMeal.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MyMeal(
      id: doc.id,
      name: data['name'] ?? '',
      totalCalories: (data['totalCalories'] ?? 0).toDouble(),
      totalProtein: (data['totalProtein'] ?? 0).toDouble(),
      totalCarbs: (data['totalCarbs'] ?? 0).toDouble(),
      totalFat: (data['totalFat'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => MealItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'createdAt': Timestamp.fromDate(createdAt),
      'items': items.map((e) => e.toMap()).toList(),
    };
  }
}
