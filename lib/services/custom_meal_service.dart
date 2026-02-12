import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/custom_meal_model.dart';

class CustomMealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Add a new custom meal
  Future<void> saveCustomMeal(CustomMeal meal) async {
    if (_userId == null) return;
    
    // If id is empty, generate one
    final docRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('custom_meals')
        .doc(meal.id.isEmpty ? null : meal.id);

    final mealWithId = CustomMeal(
      id: docRef.id, 
      name: meal.name, 
      items: meal.items, 
      totalNutrition: meal.totalNutrition
    );

    await docRef.set(mealWithId.toJson());
  }

  // Get all custom meals for the user
  Stream<List<CustomMeal>> getCustomMeals() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('custom_meals')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomMeal.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Delete
  Future<void> deleteCustomMeal(String mealId) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('custom_meals')
        .doc(mealId)
        .delete();
  }
}
