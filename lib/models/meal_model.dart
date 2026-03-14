import 'package:cloud_firestore/cloud_firestore.dart';

class MealIngredient {
  final String name;
  final String amount;
  final String servingSize;

  MealIngredient({
    required this.name,
    required this.amount,
    required this.servingSize,
  });

  factory MealIngredient.fromJson(Map<String, dynamic> json) {
    return MealIngredient(
      name: json['ingredient'] ?? json['name'] ?? '',
      amount: json['estimated_amount'] ?? json['amount'] ?? '',
      servingSize: json['serving_size'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'serving_size': servingSize,
    };
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
