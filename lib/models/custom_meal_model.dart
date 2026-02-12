class CustomMeal {
  final String id;
  final String name;
  final List<CustomMealItem> items;
  final Map<String, double> totalNutrition;

  CustomMeal({
    required this.id,
    required this.name,
    required this.items,
    required this.totalNutrition,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((e) => e.toJson()).toList(),
      'total_nutrition': totalNutrition,
    };
  }

  factory CustomMeal.fromJson(Map<String, dynamic> json, String id) {
    return CustomMeal(
      id: id,
      name: json['name'] ?? 'Unnamed Meal',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CustomMealItem.fromJson(e))
              .toList() ??
          [],
      totalNutrition: Map<String, double>.from(json['total_nutrition'] ?? {}),
    );
  }
}

class CustomMealItem {
  final String foodId;
  final String foodName; // Store name for display without fetch
  final double quantity;
  final String unit; // Store unit for display

  CustomMealItem({
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory CustomMealItem.fromJson(Map<String, dynamic> json) {
    return CustomMealItem(
      foodId: json['foodId'] ?? '',
      foodName: json['foodName'] ?? 'Unknown Food',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
    );
  }
}
