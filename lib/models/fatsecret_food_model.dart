import 'package:physiq/models/fatsecret_serving_model.dart';

class FatSecretFood {
  final String id;
  final String name;
  final String brandName;
  final String type; // 'Generic' or 'Brand'
  final List<FatSecretServing> servings;
  final double? calories; // Optional for search results
  final String? description; // Optional for search results

  FatSecretFood({
    required this.id,
    required this.name,
    this.brandName = '',
    this.type = 'Generic',
    required this.servings,
    this.calories,
    this.description,
  });

  factory FatSecretFood.fromJson(Map<String, dynamic> json) {
    // The cloud function now normalizes 'servings' to an array of objects
    // directly. But let's be robust and check if it's the raw nested version or cleaned.
    
    List<dynamic> list = [];
    if (json['servings'] is List) {
       list = json['servings'];
    } else if (json['servings'] != null && json['servings']['serving'] != null) {
       // Legacy/Raw handling just in case
        var s = json['servings']['serving'];
        list = (s is List) ? s : [s];
    }
    
    List<FatSecretServing> servingList = list
        .map((i) => FatSecretServing.fromJson(i))
        .toList();

    return FatSecretFood(
      id: json['id']?.toString() ?? json['food_id']?.toString() ?? '',
      name: json['name'] ?? json['food_name'] ?? 'Unknown Food',
      brandName: json['brand'] ?? json['brand_name'] ?? '',
      type: json['type'] ?? json['food_type'] ?? 'Generic',
      servings: servingList,
      calories: (json['calories'] is num) ? (json['calories'] as num).toDouble() : null,
      description: json['description'] ?? json['food_description'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brandName,
      'type': type,
      'servings': servings.map((s) => s.toJson()).toList(),
      'calories': calories,
      'description': description,
    };
  }
}
