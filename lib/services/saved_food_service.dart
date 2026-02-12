import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/models/saved_food_model.dart';
import 'package:physiq/services/firestore_service.dart';

class SavedFoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  String? get uid => _auth.currentUser?.uid;

  Future<void> saveFood(SavedFood food) async {
    if (uid == null) return;
    try {
      // Create a new document in the saved_foods collection
      await _firestore.collection('saved_foods').add({
        ...food.toJson(),
        'userId': uid, // Ensure user ID is set correctly
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving food: $e');
      rethrow;
    }
  }

  Stream<List<SavedFood>> getUserSavedFoods() {
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('saved_foods')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final foods = snapshot.docs.map((doc) {
            final data = doc.data();
            // Handle null createdAt gracefully
            data['createdAt'] ??= Timestamp.now();
            return SavedFood.fromJson(data, doc.id);
          }).toList();
          
          // Client-side sort by createdAt descending
          foods.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return foods;
        });
  }

  Future<void> deleteSavedFood(String id) async {
    if (uid == null) return;
    try {
      await _firestore.collection('saved_foods').doc(id).delete();
    } catch (e) {
      print('Error deleting saved food: $e');
      rethrow;
    }
  }

  // Reuse existing logging logic
  Future<void> logSavedFood(SavedFood food, DateTime date) async {
    if (uid == null) return;

    final mealData = {
      'name': food.name,
      'source': 'saved_scan', // or original source type
      'calories': food.nutrition.calories.toInt(),
      'proteinG': food.nutrition.protein.toInt(),
      'carbsG': food.nutrition.carbs.toInt(),
      'fatG': food.nutrition.fat.toInt(),
      'quantity': food.servingAmount, // Using stored quantity directly
      'unit': food.servingSize, // Using stored unit
      'originalId': food.id,
    };

    await _firestoreService.logMeal(uid!, mealData, date);
  }
}
