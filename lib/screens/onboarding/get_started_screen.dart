
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/auth_service.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  void _showSignInSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SignInOptionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              const Spacer(),
              // Headline
              Text(
                'Build Your Dream Body',
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 40),
              
              // Primary Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/name'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sign In Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: AppTextStyles.body.copyWith(color: AppColors.secondaryText, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () => _showSignInSheet(context),
                    child: Text(
                      'Sign in',
                      style: AppTextStyles.button.copyWith(color: Colors.blue, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInOptionsSheet extends StatefulWidget {
  const _SignInOptionsSheet();

  @override
  State<_SignInOptionsSheet> createState() => _SignInOptionsSheetState();
}

class _SignInOptionsSheetState extends State<_SignInOptionsSheet> {
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, 
              height: 4, 
              decoration: BoxDecoration(
                color: Colors.grey[300], 
                borderRadius: BorderRadius.circular(2),
              ), 
              margin: const EdgeInsets.only(bottom: 24),
            ),
          ),
          Text(
            "Sign In",
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
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
                  borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Continue with Email'),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
