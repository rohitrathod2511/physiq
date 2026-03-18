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
      quantity: _safeDouble(map['quantity']),
      servingLabel: map['servingLabel'] ?? '',
      calories: _safeDouble(map['calories']),
      protein: _safeDouble(map['protein']),
      carbs: _safeDouble(map['carbs']),
      fat: _safeDouble(map['fat']),
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

  static double _safeDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0.0;
    return 0.0;
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
      totalCalories: MealItem._safeDouble(data['totalCalories']),
      totalProtein: MealItem._safeDouble(data['totalProtein']),
      totalCarbs: MealItem._safeDouble(data['totalCarbs']),
      totalFat: MealItem._safeDouble(data['totalFat']),
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
