import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/models/my_meal_model.dart';
import 'package:physiq/services/firestore_service.dart';

class MyMealsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // ----------------------------------
  // Create / Edit My Meal (Template)
  // ----------------------------------
  Future<void> saveMyMeal(MyMeal meal) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Save to users/{uid}/myMeals/{mealId}
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('myMeals')
        .doc(meal.id)
        .set(meal.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMyMeal(String mealId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('myMeals')
        .doc(mealId)
        .delete();
  }

  Stream<List<MyMeal>> streamMyMeals() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('myMeals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MyMeal.fromSnapshot(doc)).toList();
    });
  }

  // ----------------------------------
  // Log My Meal (Eat it)
  // ----------------------------------
  Future<void> logMyMeal(MyMeal meal, DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final batch = _firestore.batch();
    
    // 1. Save to users/{uid}/mealLogs/{today}/entries/{entryId} (New System)
    final dateId = _formatDateId(date);
    final entryRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('mealLogs')
        .doc(dateId)
        .collection('entries')
        .doc();

    final logData = {
      "type": "customMeal",
      "mealId": meal.id,
      "name": meal.name,
      "totalCalories": meal.totalCalories,
      "protein": meal.totalProtein,
      "carbs": meal.totalCarbs,
      "fat": meal.totalFat,
      "loggedAt": Timestamp.now(),
      "timestamp": Timestamp.now(), // Ensure timestamp exists for queries
    };

    batch.set(entryRef, logData);

    // 2. Also save to users/{uid}/meals for backward compatibility with Home Screen
    // "Recently Uploaded" reads from here.
    final legacyRef = _firestore.collection('users').doc(uid).collection('meals').doc();
    batch.set(legacyRef, {
      ...logData,
      'id': legacyRef.id,
      'calories': meal.totalCalories, // Legacy expects 'calories'
      'proteinG': meal.totalProtein,  // Legacy expects 'proteinG'
      'carbsG': meal.totalCarbs,      // Legacy expects 'carbsG'
      'fatG': meal.totalFat,          // Legacy expects 'fatG'
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Update Daily Summary (Aggregates)
    // Using FirestoreService logic manually or via batch
    final summaryRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_summaries')
        .doc(dateId);

    batch.set(summaryRef, {
      'date': dateId,
      'calories': FieldValue.increment(meal.totalCalories),
      'protein': FieldValue.increment(meal.totalProtein),
      'carbs': FieldValue.increment(meal.totalCarbs),
      'fat': FieldValue.increment(meal.totalFat),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  static String _formatDateId(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
