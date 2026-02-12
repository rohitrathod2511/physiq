import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/models/custom_food_model.dart';
import 'package:physiq/services/firestore_service.dart';

class CustomFoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  String? get uid => _auth.currentUser?.uid;

  Future<void> createCustomFood(CustomFood food) async {
    if (uid == null) return;
    try {
      await _firestore.collection('custom_foods').doc(food.id).set({
        ...food.toJson(),
        'userId': uid, // Ensure user ID is correct
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating custom food: $e');
      rethrow;
    }
  }

  Stream<List<CustomFood>> getUserCustomFoods() {
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('custom_foods')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final foods = snapshot.docs.map((doc) {
        return CustomFood.fromJson(doc.data(), doc.id);
      }).toList();
      // Sort client-side to avoid composite index requirement
      foods.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return foods;
    });
  }

  Future<void> updateCustomFood(CustomFood food) async {
    if (uid == null) return;
    try {
      await _firestore.collection('custom_foods').doc(food.id).update(food.toJson());
    } catch (e) {
      print('Error updating custom food: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomFood(String foodId) async {
    if (uid == null) return;
    try {
      await _firestore.collection('custom_foods').doc(foodId).delete();
    } catch (e) {
      print('Error deleting custom food: $e');
      rethrow;
    }
  }

  // Reuse existing logging logic
  Future<void> logCustomFood(CustomFood food, DateTime date) async {
    if (uid == null) return;
    
    final mealData = {
      'name': food.description, // Use description as primary name
      'brand': food.brandName,
      'calories': food.nutrition.calories.toInt(),
      'proteinG': food.nutrition.protein.toInt(),
      'carbsG': food.nutrition.carbs.toInt(),
      'fatG': food.nutrition.fat.toInt(),
      'quantity': 1, // Default to 1 serving
      'unit': food.servingSize,
      'source': 'custom_food',
      'originalId': food.id,
    };

    await _firestoreService.logMeal(uid!, mealData, date);
  }
}
