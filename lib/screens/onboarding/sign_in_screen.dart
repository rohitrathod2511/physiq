import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/services/firestore_service.dart';
import 'package:physiq/theme/design_system.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  Future<void> _handleSignIn(Future<AuthUser?> signInMethod, BuildContext context) async {
    final user = await signInMethod;
    if (user != null) {
      if (!AppConfig.useMockBackend) {
        final firestoreService = FirestoreService();
        // await firestoreService.saveInitialUser(user.uid, user.displayName);
      }
      if (context.mounted) {
        // CORRECTED: Navigate to the onboarding flow after sign-in.
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata, color: Colors.white), // Placeholder
              label: const Text('Sign in with Google'),
              onPressed: () => _handleSignIn(authService.signInWithGoogle(), context),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.email_outlined, color: Colors.white),
              label: const Text('Sign in with Email'),
              onPressed: () {
                _handleSignIn(authService.signInWithEmail('test@test.com', 'password'), context);
              },
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => _handleSignIn(authService.signInAnonymously(), context),
              child: const Text('Skip for now', style: TextStyle(color: AppColors.secondaryText)),
            ),
          ],
        ),
      ),
    );
  }
}
