import 'package:cloud_firestore/cloud_firestore.dart';

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
    required this.source,
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
    };
  }

  factory MealModel.fromMap(Map<String, dynamic> map) {
    return MealModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Unknown Meal',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      proteinG: (map['proteinG'] as num?)?.toInt() ?? 0,
      carbsG: (map['carbsG'] as num?)?.toInt() ?? 0,
      fatG: (map['fatG'] as num?)?.toInt() ?? 0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      source: map['source'] ?? 'manual',
    );
  }
}
