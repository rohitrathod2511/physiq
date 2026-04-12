import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/screens/onboarding/forgot_password_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class GetStartedScreen extends ConsumerWidget {
  const GetStartedScreen({super.key});

  void _showSignInSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => const _SignInOptionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Physique Image
              Expanded(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.85,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 50,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.90, 1.0],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstIn,
                        child: Image.asset(
                          'assets/Physique.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Headline
              Text(
                'Build Your Strongest Self',
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),

              // Primary Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/gender'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTextStyles.button.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 16,
                    ),
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
                    style: AppTextStyles.body.copyWith(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showSignInSheet(context),
                    child: Text(
                      'Sign in',
                      style: AppTextStyles.button.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                      ),
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
    try {
      // 🎯 CORRECT SIGN-IN Logic:
      // Force sign-out to ensure Google account chooser is shown
      await _authService.disconnectGoogle();

      final userCredential = await _authService.signInWithGoogle(
        allowCreate: false,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (userCredential != null) {
          // 🎯 CORRECT NAVIGATION:
          // 1. Close the bottom sheet first
          Navigator.pop(context);
          // 2. Clear stack and go to Home (Router will handle final destination based on onboarding state)
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleEmailSignIn() {
    Navigator.pop(context); // Close basic options sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => const _EmailSignInSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 24),
            ),
          ),
          Text(
            'Welcome Back',
            style: AppTextStyles.h2.copyWith(color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Google Button
            ElevatedButton.icon(
              onPressed: _handleGoogleSignIn,
              icon: Icon(
                Icons.g_mobiledata,
                size: 28,
                color: theme.colorScheme.onPrimary,
              ),
              label: Text(
                'Continue with Google',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email Button
            ElevatedButton(
              onPressed: _handleEmailSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue with Email',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _EmailSignInSheet extends StatefulWidget {
  const _EmailSignInSheet();

  @override
  State<_EmailSignInSheet> createState() => _EmailSignInSheetState();
}

class _EmailSignInSheetState extends State<_EmailSignInSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleForgotPassword() {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ForgotPasswordScreen(prefilledEmail: email.isEmpty ? null : email),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🎯 CORRECT SIGN-IN Logic:
      final userCredential = await _authService.signInWithEmail(
        email,
        password,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (userCredential != null) {
          // 🎯 CORRECT NAVIGATION:
          // 1. Close the bottom sheet first
          Navigator.pop(context);
          // 2. Clear stack and go to Home (Router will handle final destination based on onboarding state)
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    // Handling keyboard overlap
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Correct place for mainAxisSize
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 24),
              ),
            ),
            Text(
              'Sign In',
              style: AppTextStyles.h2.copyWith(color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _emailController,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              cursorColor: theme.colorScheme.primary,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              cursorColor: theme.colorScheme.primary,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              obscureText: true,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: AppTextStyles.button.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Sign in',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
