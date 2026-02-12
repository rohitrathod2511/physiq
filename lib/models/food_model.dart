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
      },
      'aliases': aliases,
      'isIndian': isIndian,
      'source': source,
    };
  }
}
