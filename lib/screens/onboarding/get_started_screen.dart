
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/auth_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/providers/preferences_provider.dart';
import 'package:physiq/l10n/app_localizations.dart';

class GetStartedScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<Locale>(
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, size: 18, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          Localizations.localeOf(context).languageCode == 'en' ? 'English' : 'Hindi',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  onSelected: (Locale locale) {
                    ref.read(preferencesProvider.notifier).setLocale(locale);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                    const PopupMenuItem<Locale>(
                      value: Locale('en'),
                      child: Text('English'),
                    ),
                    const PopupMenuItem<Locale>(
                      value: Locale('hi'),
                      child: Text('Hindi'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Headline
              Text(
                l10n.getStartedTitle,
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
                    l10n.getStartedButton,
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
                    l10n.alreadyHaveAccount,
                    style: AppTextStyles.body.copyWith(color: AppColors.secondaryText, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () => _showSignInSheet(context),
                    child: Text(
                      l10n.signIn,
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
    try {
      // 🎯 CORRECT SIGN-IN Logic:
      // Force sign-out to ensure Google account chooser is shown (fixes auto-login issue)
      await _authService.disconnectGoogle();

      // No name, no onboardingData passed. Just pure sign-in.
      final user = await _authService.signInWithGoogle();
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          // 🎯 CORRECT NAVIGATION:
          // 1. Close the bottom sheet first
          Navigator.pop(context);
          // 2. Clear stack and go to Home
          context.go('/home'); 
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _handleEmailSignIn() {
    Navigator.pop(context); // Close basic options sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _EmailSignInSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.welcomeBack,
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
              label: Text(l10n.continueWithGoogle),
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
              child: Text(l10n.continueWithEmail),
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

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🎯 CORRECT SIGN-IN Logic:
      // Regular email/password sign in. No creating new users here.
      final user = await _authService.signInWithEmail(email, password);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          // 🎯 CORRECT NAVIGATION:
          // 1. Close the bottom sheet first
          Navigator.pop(context);
          // 2. Clear stack and go to Home
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
         );
      }
    }
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forgot Password functionality coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Handling keyboard overlap
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
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
                  color: Colors.grey[300], 
                  borderRadius: BorderRadius.circular(2),
                ), 
                margin: const EdgeInsets.only(bottom: 24),
              ),
            ),
            Text(
              l10n.signInTitle,
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.emailLabel, 
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: l10n.passwordLabel, 
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            if (_isLoading)
               const Center(child: CircularProgressIndicator())
            else
               ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.signIn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

             const SizedBox(height: 16),

             TextButton(
               onPressed: _forgotPassword,
               child: Text(
                 l10n.forgotPassword,
                 style: AppTextStyles.body.copyWith(color: Colors.grey),
               ),
             ),
             const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
