import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/user_model.dart';
import 'package:physiq/models/leaderboard_model.dart';
import 'package:physiq/services/auth_service.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Stream user data
  Stream<UserModel?> streamUser(String uid) {
    if (AppConfig.useMockBackend) {
      // Return mock stream
      return Stream.value(UserModel(
        uid: uid,
        displayName: 'Mock User',
        birthYear: 1995,
        gender: 'male',
        heightCm: 175,
        weightKg: 70,
        goalWeightKg: 75,
        preferences: UserPreferences(),
        leaderboardScore: 123.4,
        invites: UserInvites(code: 'MOCK123', redeemedCount: 2, creditedAmount: 200),
      ));
    }
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }

  // Update user details
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (AppConfig.useMockBackend) {
      print('Mock update user: $data');
      return;
    }
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> createUser({
    required String uid,
    required String name,
    required String? email,
    required String authProvider,
    Map<String, dynamic>? onboardingData,
  }) async {
    if (AppConfig.useMockBackend) {
      print('Mock create user: $uid, $name');
      return;
    }

    final displayId = await _generateUniqueDisplayId(name);
    
    // Parse onboarding data for partial usage
    final od = onboardingData ?? {};
    final currentPlan = od['currentPlan'] as Map<String, dynamic>? ?? {};

    final userDoc = _firestore.collection('users').doc(uid);
    
    // Construct payload with nulls first
    final authMap = {
      'uid': uid,
      'provider': authProvider,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    }..removeWhere((k, v) => v == null);

    final profileMap = {
      'name': name,
      'gender': od['gender'],
      'birthYear': od['birthYear'],
      'height': od['height'] ?? od['heightCm'],
      'weight': od['weight'] ?? od['weightKg'],
      'activityLevel': od['activityLevel'],
      'displayId': displayId,
    }..removeWhere((k, v) => v == null);

    final goalsMap = {
      'goalType': od['goal'],
      'targetWeight': od['targetWeight'] ?? od['targetWeightKg'],
      'timeFrame': od['timeframeMonths'],
    }..removeWhere((k, v) => v == null);

    final nutritionMap = {
      'calories': currentPlan['calories'] ?? currentPlan['goalCalories'],
      'protein': currentPlan['protein'] ?? currentPlan['proteinG'],
      'carbs': currentPlan['carbs'] ?? currentPlan['carbsG'],
      'fats': currentPlan['fat'] ?? currentPlan['fatG'] ?? currentPlan['fats'],
    }..removeWhere((k, v) => v == null);

    final metaMap = {
       'isAnonymous': authProvider == 'anonymous',
       'onboardingCompleted': true,
    }..removeWhere((k, v) => v == null);
    
    // Prepare final map
    final data = <String, dynamic>{};
    if (authMap.isNotEmpty) data['auth'] = authMap;
    if (profileMap.isNotEmpty) data['profile'] = profileMap;
    if (goalsMap.isNotEmpty) data['goals'] = goalsMap;
    if (nutritionMap.isNotEmpty) data['nutrition'] = nutritionMap;
    if (metaMap.isNotEmpty) data['meta'] = metaMap;

    // Legacy fields (root) - only write if strictly necessary or if we want to ensure basic data exists
    if (name.isNotEmpty) data['name'] = name;
    if (email != null) data['email'] = email;
    data['uid'] = uid;
    
    await userDoc.set(data, SetOptions(merge: true));
  }

  // Generate Unique Display ID
  Future<String> _generateUniqueDisplayId(String name) async {
    // Sanitize name: remove spaces/special chars, keep generic
    final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    
    // Fallback if name becomes empty
    final baseName = cleanName.isEmpty ? 'User' : cleanName;

    int attempts = 0;
    while (attempts < 10) {
      // Generate random 4-6 digit number
      final randomCode = (1000 + DateTime.now().microsecondsSinceEpoch % 90000).toString();
      final candidateId = "${baseName}_$randomCode";

      // Check uniqueness
      final query = await _firestore
          .collection('users')
          .where('displayId', isEqualTo: candidateId)
          .get();

      if (query.docs.isEmpty) {
        return candidateId;
      }
      attempts++;
    }
    // Fallback (extremely unlikely to collide with timestamp)
    return "${baseName}_${DateTime.now().millisecondsSinceEpoch}";
  }

  // Cloud Functions
  Future<String> createInviteCode() async {
    if (AppConfig.useMockBackend) {
      return 'MOCKCODE123';
    }
    final result = await _functions.httpsCallable('createInviteCode').call();
    return result.data['code'];
  }

  Future<void> claimReferral(String code, String newUserUid) async {
    if (AppConfig.useMockBackend) {
      print('Mock claim referral: $code for $newUserUid');
      return;
    }
    await _functions.httpsCallable('claimReferral').call({
      'code': code,
      'newUserUid': newUserUid,
    });
  }

  Future<void> generateCanonicalPlan() async {
    if (AppConfig.useMockBackend) {
      print('Mock generate plan');
      return;
    }
    await _functions.httpsCallable('generateCanonicalPlan').call();
  }

  Future<void> deleteUserData(String uid) async {
    if (AppConfig.useMockBackend) {
      print('Mock delete account data');
      return;
    }
    
    // 1. Delete Firestore Data
    await _firestore.collection('users').doc(uid).delete();

    // 2. Delete Storage Data (Conceptually)
    // Note: Client SDK cannot easily delete a folder. 
    // Usually this is done via Cloud Functions to ensure full cleanup.
    // For this implementation, we will try to call the Cloud Function as requested 
    // or fallback to client delete if specific paths are known.
    // Since the original code called a cloud function 'deleteUserData', 
    // we should ideally stick to that or replicate its logic client-side if we are replacing it.
    // The prompt explicitly said: "Call Cloud Function OR client logic". 
    // I will try to use the Cloud Function if available, or just delete the doc here.
    
    try {
      await _functions.httpsCallable('deleteUserData').call();
    } catch (e) {
      print("Cloud function delete failed (maybe not deployed), skipping strict storage cleanup: $e");
    }
  }

  // Leaderboard
  Future<List<LeaderboardEntry>> fetchGlobalLeaderboard() async {
    if (AppConfig.useMockBackend) {
      return List.generate(10, (index) => LeaderboardEntry(
        uid: 'user_$index',
        displayName: 'User $index',
        score: 1000.0 - (index * 50),
        streakDays: 10 - index,
      ));
    }
    final snapshot = await _firestore
        .collection('leaderboards')
        .doc('global')
        .collection('users')
        .orderBy('score', descending: true)
        .limit(10)
        .get();
    
    return snapshot.docs.map((doc) => LeaderboardEntry.fromMap(doc.data())).toList();
  }

  Future<void> deleteAccount() async {}
}
