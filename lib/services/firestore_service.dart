// lib/services/firestore_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiq/services/cloud_functions_client.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudFunctionsClient _cloudFunctions = CloudFunctionsClient();

  FirestoreService();

  // ----------------------------
  // Update User Profile (Personal Details)
  // ----------------------------
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      // 1. Log the change
      await _logSettingsChange(uid, updates);

      // 2. Update Firestore (merge)
      await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));

      // 3. Fetch the latest profile and trigger canonical plan generation
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        try {
          await _cloudFunctions.generateCanonicalPlan(
            uid: uid,
            profile: userDoc.data()!,
            clientPlanVersion: 1,
          );
        } catch (e) {
          // non-blocking: log and continue
          print('Error generating plan (cloud function): $e');
        }
      }
    } catch (e) {
      print('updateUserProfile error: $e');
      rethrow;
    }
  }

  // ----------------------------
  // Update Macros
  // ----------------------------
  Future<void> updateMacros(String uid, Map<String, dynamic> macros) async {
    try {
      final data = {
        ...macros,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      await _logSettingsChange(uid, {'macros': macros});

      // Save to a subcollection document users/{uid}/macros/current
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('macros')
          .doc('current')
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('updateMacros error: $e');
      rethrow;
    }
  }

  // ----------------------------
  // Stream Daily Summary
  // - Tries to listen to users/{uid}/daily_summaries/{yyyy-MM-dd} (if you store summaries)
  // - If summary doc does not exist, computes summary from meals subcollection for that day
  // ----------------------------
  Stream<Map<String, dynamic>> streamDailySummary(String uid, DateTime date) async* {
    final dateId = _formatDateId(date);
    final summaryDocRef =
        _firestore.collection('users').doc(uid).collection('daily_summaries').doc(dateId);

    // Listen to changes on the summary doc; if it exists yield it.
    // If it doesn't exist, compute summary from meals and yield that.
    await for (final snap in summaryDocRef.snapshots()) {
      try {
        if (snap.exists && snap.data() != null) {
          yield Map<String, dynamic>.from(snap.data()!);
        } else {
          // compute summary from meals for the given day
          final start = DateTime(date.year, date.month, date.day);
          final end = start.add(const Duration(days: 1));

          final mealsSnap = await _firestore
              .collection('users')
              .doc(uid)
              .collection('meals')
              .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
              .where('timestamp', isLessThan: Timestamp.fromDate(end))
              .get();

          // aggregate fields (defensive: handle missing fields)
          int calories = 0;
          int protein = 0;
          int carbs = 0;
          int fat = 0;

          for (final doc in mealsSnap.docs) {
            final data = doc.data();
            calories += _toIntSafe(data['calories']);
            protein += _toIntSafe(data['protein']);
            carbs += _toIntSafe(data['carbs']);
            fat += _toIntSafe(data['fat']);
          }

          yield {
            'date': dateId,
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
            'computedFromMeals': true,
          };
        }
      } catch (e) {
        print('streamDailySummary error: $e');
        // yield a safe default so listeners won't crash
        yield {
          'date': dateId,
          'calories': 0,
          'protein': 0,
          'carbs': 0,
          'fat': 0,
          'error': e.toString(),
        };
      }
    }
  }

  // ----------------------------
  // Log Meal
  // ----------------------------
  Future<void> logMeal(String uid, Map<String, dynamic> mealData, DateTime date) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Add meal to meals subcollection
      final mealRef = _firestore.collection('users').doc(uid).collection('meals').doc();
      batch.set(mealRef, {
        ...mealData,
        'id': mealRef.id, // Ensure ID is saved
        'timestamp': Timestamp.fromDate(date), // Ensure timestamp is set
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Daily Summary for the specific date
      final dateId = _formatDateId(date);
      final summaryRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('daily_summaries')
          .doc(dateId);

      // Use set with merge to create if not exists, but we want to increment
      // If doc doesn't exist, we need to set initial values then increment, 
      // or just set the values if we trust we are the source of truth.
      // Firestore set with merge and increment works fine if doc exists or not (counters start at 0).
      batch.set(summaryRef, {
        'date': dateId,
        'calories': FieldValue.increment(mealData['calories'] ?? 0),
        'protein': FieldValue.increment(mealData['proteinG'] ?? 0), // Note: Mapping 'proteinG' to 'protein' to match usage
        'carbs': FieldValue.increment(mealData['carbsG'] ?? 0),
        'fat': FieldValue.increment(mealData['fatG'] ?? 0),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      print('logMeal error: $e');
      rethrow;
    }
  }

  // ----------------------------
  // Fetch Recent Meals
  // - Returns latest N meals from users/{uid}/meals ordered by timestamp desc
  // ----------------------------
  Future<List<Map<String, dynamic>>> fetchRecentMeals(String uid, {int limit = 10}) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('meals')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['id'] = d.id;
        return m;
      }).toList();
    } catch (e) {
      print('fetchRecentMeals error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // ----------------------------
  // Audit Log helper
  // ----------------------------
  Future<void> _logSettingsChange(String uid, Map<String, dynamic> changes) async {
    try {
      await _firestore
          .collection('logs')
          .doc('settingsChanges')
          .collection(uid)
          .add({
        'changes': changes,
        'changedAt': FieldValue.serverTimestamp(),
        'source': 'mobile',
        'changedByUid': uid,
      });
    } catch (e) {
      print('Failed to log setting change: $e');
    }
  }

  // ----------------------------
  // Helpers
  // ----------------------------
  static String _formatDateId(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // ----------------------------
  // Water & Streak
  // ----------------------------
  Future<void> logWater(String uid, int amountMl, DateTime date) async {
     final dateId = _formatDateId(date);
     // Use set with merge to create/update
     await _firestore.collection('users').doc(uid).collection('daily_summaries').doc(dateId).set({
       'waterMl': FieldValue.increment(amountMl),
       'waterConsumed': FieldValue.increment(amountMl), // Legacy field kept for safety
       'updatedAt': FieldValue.serverTimestamp(),
       'date': dateId,
     }, SetOptions(merge: true));
  }

  Future<void> updateWaterGoal(String uid, int goalMl, DateTime date) async {
    final dateId = _formatDateId(date);
    await _firestore.collection('users').doc(uid).collection('daily_summaries').doc(dateId).set({
      'waterGoal': goalMl,
    }, SetOptions(merge: true));
  }

  Future<int> calculateStreak(String uid) async {
    try {
      // Fetch last 60 days summaries
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('daily_summaries')
          .orderBy('date', descending: true)
          .limit(60)
          .get();
      
      final activeDates = <String>{};
      for (var doc in snap.docs) {
         final d = doc.data();
         // Check activity (Calories, Water, Steps)
         if (_toIntSafe(d['calories']) > 0 || 
             _toIntSafe(d['caloriesConsumed']) > 0 ||
             _toIntSafe(d['waterConsumed']) > 0 || 
             _toIntSafe(d['steps']) > 0) {
           activeDates.add(doc.id);
         }
      }
      
      int streak = 0;
      int misses = 0;
      DateTime check = DateTime.now();
      
      // Iterate back strictly
      for (int i = 0; i < 60; i++) {
        final id = _formatDateId(check);
        if (activeDates.contains(id)) {
          streak++;
          misses = 0;
        } else {
          misses++;
          // If today is empty, it doesn't break the streak immediately if yesterday was active
          // But strict logic: "Resets after 3 consecutive missed days".
          if (misses >= 3) break;
        }
        check = check.subtract(const Duration(days: 1));
      }
      
      return streak;
    } catch (e) {
      print('Streak calculation error: $e');
      return 0;
    }
  }

  static int _toIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
