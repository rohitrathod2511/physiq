import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:physiq/services/onboarding_store.dart';

/// A simple configuration class to toggle between mock and real backends.
class AppConfig {
  static const bool useMockBackend = false;
  static const bool mockDelete = true;
  static const int referralReward = 100;
  static const int referralBonusAt = 5;
}

/// A custom user class to abstract the Firebase User object from the UI.
class AuthUser {
  final String uid;
  final String? displayName;
  final String? email;
  final double? goalWeightKg;
  final int? birthYear;

  AuthUser({
    required this.uid,
    this.displayName,
    this.email,
    this.goalWeightKg,
    this.birthYear,
  });
}

/// A service to handle all authentication-related tasks.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Listen to auth state changes (Single Source of Truth)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Returns the current user as a custom [AuthUser] object.
  AuthUser? getCurrentUser() {
    if (AppConfig.useMockBackend) {
      return AuthUser(
        uid: 'mock_user_id',
        displayName: 'Test User',
        email: 'test@user.com',
        goalWeightKg: 75.0,
        birthYear: 1995,
      );
    }

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    return _userFromFirebase(firebaseUser);
  }

  // 1️⃣ RESET PASSWORD (FORGOT PASSWORD)

  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      throw 'Please enter a valid email address.';
    }
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'No user found for this email.';
      } else if (e.code == 'invalid-email') {
        throw 'The email address is invalid.';
      } else {
        throw e.message ?? 'An error occurred while sending reset email.';
      }
    } catch (e) {
      throw 'Failed to send reset email. Please try again.';
    }
  }

  // 2️⃣ UPDATE USERNAME (DISPLAY NAME)

  Future<void> updateUsername(String newName) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw 'No user signed in.';

    try {
      // Update Firebase Auth displayName
      await user.updateDisplayName(newName);

      // Update Firestore: users/{uid}.profile.name
      await _firestore.collection('users').doc(user.uid).set({
        'profile': {'name': newName},
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update username: $e';
    }
  }

  // 3️⃣ EMAIL SIGN-IN FLOW

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // After success: Ensure Firestore user document exists
      if (credential.user != null) {
        await _ensureUserDocumentExists(
          credential.user!,
          authProvider: 'email',
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      // Throw meaningful error messages for UI to catch
      if (e.code == 'user-not-found')
        throw 'No account found. Please sign up first.';
      if (e.code == 'wrong-password') throw 'Wrong password provided.';
      if (e.code == 'invalid-credential') throw 'Invalid email or password.';
      if (e.code == 'invalid-email') throw 'The email address is invalid.';
      if (e.code == 'user-disabled')
        throw 'This user account has been disabled.';
      throw e.message ?? 'Sign in failed.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'An unexpected error occurred: $e';
    }
  }

  Future<UserCredential?> signUpWithEmail(
    String email,
    String password, {
    required String name,
    Map<String, dynamic>? onboardingData,
  }) async {
    // Validate password length
    if (password.length < 6) {
      throw 'Password must be at least 6 characters.';
    }

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update display name immediately
        await user.updateDisplayName(name);

        // Ensure Firestore user document exists (Create account)
        await _ensureUserDocumentExists(
          user,
          defaultName: name,
          authProvider: 'email',
          onboardingData: onboardingData,
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') throw 'The password provided is too weak.';
      if (e.code == 'email-already-in-use')
        throw 'The account already exists for that email.';
      throw e.message ?? 'Sign up failed.';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // 4️⃣ GOOGLE SIGN-IN

  Future<UserCredential?> signInWithGoogle({
    bool allowCreate = true,
    String? name,
    Map<String, dynamic>? onboardingData,
  }) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        // If allowCreate is false, we check if this is a new user
        if (!allowCreate &&
            (userCredential.additionalUserInfo?.isNewUser ?? false)) {
          // New user created when we didn't want one. Delete and sign out.
          await user.delete();
          await _googleSignIn.signOut();
          throw 'No account found. Please sign up first.';
        }

        // Creates Firestore user if not exists (or updates metadata)
        await _ensureUserDocumentExists(
          user,
          defaultName: name ?? user.displayName ?? 'User',
          authProvider: 'google',
          onboardingData: onboardingData,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw 'This email is registered with a different sign-in method.';
      }
      throw e.message ?? 'Google Sign-In failed.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Google Sign-In failed: $e';
    }
  }

  // 5️⃣ ANONYMOUS USER SUPPORT

  Future<UserCredential?> signInAnonymously({
    String? name,
    Map<String, dynamic>? onboardingData,
  }) async {
    try {
      // 1. Authenticate anonymously
      final userCredential = await _firebaseAuth.signInAnonymously();
      final user = userCredential.user;

      // 2. Ensure Firestore document
      if (user != null) {
        await _ensureUserDocumentExists(
          user,
          defaultName: name ?? 'Guest',
          authProvider: 'anonymous',
          isAnonymous: true,
          onboardingData: onboardingData,
        );
      }

      return userCredential;
    } catch (e) {
      throw 'Anonymous Sign-In failed: $e';
    }
  }

  // UTILITIES & HELPERS

  Future<List<String>> _lookupSignInMethodsForEmail(String email) async {
    final apiKey = _firebaseAuth.app.options.apiKey;
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=$apiKey',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': email.trim(),
        'continueUri': 'http://localhost',
      }),
    );

    if (response.statusCode != 200) {
      throw 'Unable to verify account. Please try again.';
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rawMethods =
        body['signinMethods'] ?? body['allProviders'] ?? <dynamic>[];
    if (rawMethods is! List) {
      return <String>[];
    }
    return rawMethods.map((method) => method.toString()).toList();
  }

  Future<void> _ensureUserDocumentExists(
    User user, {
    String? defaultName,
    String? authProvider,
    bool isAnonymous = false,
    Map<String, dynamic>? onboardingData,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    final dataToSave = {
      if (!snapshot.exists)
        'profile': {
          'name': defaultName ?? user.displayName ?? 'User',
          'email': user.email,
        },
      'meta': {
        if (!snapshot.exists) 'created_at': FieldValue.serverTimestamp(),
        'isAnonymous': isAnonymous,
        'last_login': FieldValue.serverTimestamp(),
        if (authProvider != null) 'auth_provider': authProvider,
      },
      if (!snapshot.exists) 'onboardingCompleted': false,
      if (onboardingData != null) ...onboardingData,
    };

    // Use SetOptions(merge: true) to enable merging even with simple maps
    await docRef.set(dataToSave, SetOptions(merge: true));
  }

  AuthUser _userFromFirebase(User user) {
    return AuthUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      goalWeightKg: null,
      birthYear: null,
    );
  }

  Future<void> signOut() async {
    try {
      await OnboardingStore.clearResumeState();
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
    } catch (e) {
      print("Sign Out Error: $e");
    }
  }

  Future<void> deleteUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disconnectGoogle() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }
      await _firebaseAuth.signOut();
    } catch (e) {
      print("Disconnect Error: $e");
    }
  }

  Future<void> completeOnboarding() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      // Use set with merge to be safe in case the document somehow doesn't exist or is partial
      await _firestore.collection('users').doc(user.uid).set({
        'onboardingCompleted': true,
      }, SetOptions(merge: true));
      await OnboardingStore.clearResumeState();
    }
  }
}
