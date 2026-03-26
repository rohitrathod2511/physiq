import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/theme/design_system.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  static const EdgeInsets _optionButtonPadding = EdgeInsets.symmetric(vertical: 16);
  static const double _optionButtonRadius = 30;

  String _getNextRoute() {
    return '/onboarding/paywall-free';
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      // Force sign-out to ensure Google account chooser is shown
      await _authService.disconnectGoogle();

      final store = ref.read(onboardingProvider);
      final name = store.name;
      final user = await _authService.signInWithGoogle(
        name: name,
        onboardingData: store.data,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          context.pushReplacement(_getNextRoute());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ), // clean up error slightly
        );
      }
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    setState(() => _isLoading = true);

    // 1. Set Local Guest Flag
    final store = ref.read(onboardingProvider);
    store.saveStepData('isGuest', true);

    // 2. Try Anonymous Auth (Best Effort)
    try {
      final name = store.name ?? 'Guest';
      await _authService.signInAnonymously(
        name: name,
        onboardingData: store.data,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Anonymous sign-in error (continuing anyway): $e"),
          ),
        );
      }
    }

    // 3. Navigate Immediately
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.pushReplacement(_getNextRoute());
  }

  void _handleEmailSignIn() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Sign Up with Email',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              final password = passwordController.text.trim();
              if (email.isEmpty || password.isEmpty) return;

              Navigator.pop(context); // Close dialog
              setState(() => _isLoading = true);

              try {
                final store = ref.read(onboardingProvider);
                final name = store.name ?? 'User';
                final user = await _authService.signUpWithEmail(
                  email,
                  password,
                  name: name,
                  onboardingData: store.data,
                );

                setState(() => _isLoading = false);

                if (user != null && mounted) {
                  context.pushReplacement(_getNextRoute());
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  TextStyle _filledOptionTextStyle() {
    return AppTextStyles.button.copyWith(
      color: Colors.white,
      fontSize: 16,
    );
  }

  TextStyle _outlinedOptionTextStyle() {
    return AppTextStyles.button.copyWith(
      color: AppColors.primaryText,
      fontSize: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create an Account',
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
                  label: Text(
                    'Continue with Google',
                    style: _filledOptionTextStyle(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: _optionButtonPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_optionButtonRadius),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 16),

                // Email Button
                OutlinedButton(
                  onPressed: _handleEmailSignIn,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryText,
                    padding: _optionButtonPadding,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_optionButtonRadius),
                    ),
                  ),
                  child: Text(
                    'Continue with Email',
                    style: _outlinedOptionTextStyle(),
                  ),
                ),
                const SizedBox(height: 16),

                // Skip Button (Styled to match)
                OutlinedButton(
                  onPressed: _handleAnonymousSignIn,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryText,
                    padding: _optionButtonPadding,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_optionButtonRadius),
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: _outlinedOptionTextStyle(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
