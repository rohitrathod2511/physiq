
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/theme/design_system.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final user = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);
    if (user != null && mounted) {
      context.push('/onboarding/motivational-quote');
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    setState(() => _isLoading = true);
    final user = await _authService.signInAnonymously();
    setState(() => _isLoading = false);
    if (user != null && mounted) {
      context.push('/onboarding/motivational-quote');
    }
  }

  void _handleEmailSignIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Sign In'),
        content: const Text('Email sign in flow would go here.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Mock success for now
              _authService.signInWithEmail('test@example.com', 'password').then((user) {
                 if (user != null && mounted) {
                    context.push('/onboarding/motivational-quote');
                 }
              });
            },
            child: const Text('Mock Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign In',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Google Button
                ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 28), 
                  label: const Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Email Button
                OutlinedButton(
                  onPressed: _handleEmailSignIn,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Continue with Email'),
                ),
                const SizedBox(height: 16),
                
                // Skip Button (Styled to match)
                OutlinedButton(
                  onPressed: _handleAnonymousSignIn,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ],
              const Spacer(), // Ensure content is pushed towards center if needed, or balanced
            ],
          ),
        ),
      ),
    );
  }
}
