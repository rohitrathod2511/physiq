import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:physiq/models/user_model.dart';
import 'package:physiq/services/auth_service.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream user data
  Stream<UserModel?> streamUser(String uid) {
    if (AppConfig.useMockBackend) {
      // Return mock stream
      return Stream.value(
        UserModel(
          uid: uid,
          displayName: 'Mock User',
          birthYear: 1995,
          gender: 'male',
          heightCm: 175,
          weightKg: 70,
          goalWeightKg: 75,
          preferences: UserPreferences(),
          invites: UserInvites(
            code: 'MOCK123',
            redeemedCount: 2,
            creditedAmount: 200,
          ),
        ),
      );
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
      final randomCode = (1000 + DateTime.now().microsecondsSinceEpoch % 90000)
          .toString();
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

    if (_auth.currentUser?.uid != uid) {
      throw 'You must be signed in as the account you are trying to delete.';
    }

    // Legacy entry-point kept for compatibility with older call sites.
    await _functions.httpsCallable('deleteUserData').call();
  }

  // Re-authenticates the current user, refreshes the ID token, and then lets the
  // client delete Auth after the correct provider-specific re-authentication.
  Future<String> deleteAccount({String? currentPassword}) async {
    debugPrint('🗑️ DELETE_ACCOUNT: Starting deletion process');
    if (AppConfig.useMockBackend) {
      debugPrint('🗑️ DELETE_ACCOUNT: Using mock backend, returning success');
      return 'Mock account deletion completed successfully.';
    }

    final user = _auth.currentUser;
    debugPrint('🗑️ DELETE_ACCOUNT: Current user: ${user?.uid}');
    if (user == null) {
      throw 'No authenticated user found.';
    }

    try {
      debugPrint(
        '🗑️ DELETE_ACCOUNT: Starting re-authentication for ${user.uid}.',
      );
      await _reauthenticateBeforeDelete(user, currentPassword: currentPassword);
      debugPrint(
        '🗑️ DELETE_ACCOUNT: Re-auth successful, deleting Firestore doc',
      );

      await _firestore.collection('users').doc(user.uid).delete().catchError((
        _,
      ) {
        debugPrint(
          '🗑️ DELETE_ACCOUNT: User document already missing for ${user.uid}.',
        );
      });
      debugPrint(
        '🗑️ DELETE_ACCOUNT: Firestore doc deleted, deleting Auth user',
      );

      await user.delete();
      debugPrint('🗑️ DELETE_ACCOUNT: Auth user deleted');

      if (await _googleSignIn.isSignedIn()) {
        debugPrint('🗑️ DELETE_ACCOUNT: Signing out Google SignIn');
        await _googleSignIn.signOut();
      }

      return 'Account deleted successfully.';
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '🗑️ DELETE_ACCOUNT: FirebaseAuthException: ${e.code} - ${e.message}',
      );
      if (e.code == 'requires-recent-login') {
        throw 'Please re-login to confirm deletion.';
      }
      throw e.message ?? 'Please re-login to confirm deletion.';
    } catch (e) {
      debugPrint('🗑️ DELETE_ACCOUNT: Generic error: $e');
      if (e is String) {
        rethrow;
      }
      throw 'Something went wrong. Please try again.';
    }
  }

  Future<void> _reauthenticateBeforeDelete(
    User user, {
    String? currentPassword,
  }) async {
    // A linked account can re-authenticate with any linked provider; we prefer
    // password when supplied, otherwise fall back to Google for Google accounts.
    final providerIds = user.providerData
        .map((provider) => provider.providerId)
        .where((providerId) => providerId.isNotEmpty)
        .toSet();

    try {
      // Anonymous users do not have reusable credentials to prompt for here.
      // We still rely on the authenticated callable + server-side validation.
      if (user.isAnonymous || providerIds.contains('anonymous')) {
        return;
      }

      if (providerIds.contains('password') &&
          currentPassword != null &&
          currentPassword.trim().isNotEmpty) {
        final email = user.email;
        if (email == null || email.isEmpty) {
          throw 'Your email address is missing. Please sign in again and retry.';
        }

        final credential = EmailAuthProvider.credential(
          email: email,
          password: currentPassword.trim(),
        );
        await user.reauthenticateWithCredential(credential);
        return;
      }

      if (providerIds.contains('google.com')) {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw 'Google re-authentication was cancelled.';
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
        return;
      }

      if (providerIds.contains('password')) {
        throw 'Enter your current password to permanently delete your account.';
      }

      throw 'Re-authentication is not supported for this sign-in method. Please sign in again and retry.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'The current password is incorrect.';
      }
      if (e.code == 'user-mismatch') {
        throw 'The selected account does not match the current signed-in user.';
      }
      if (e.code == 'too-many-requests') {
        throw 'Too many attempts. Please wait a moment and try again.';
      }
      throw e.message ?? 'Re-authentication failed. Please try again.';
    }
  }
}
