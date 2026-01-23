import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/utils/validators.dart';

class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    final existingName = ref.read(onboardingProvider).name;
    if (existingName != null) {
      _nameController.text = existingName;
      _isValid = Validators.validateName(existingName) == null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    setState(() {
      _isValid = Validators.validateName(value) == null;
    });
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (Validators.validateName(name) == null) {
      // Save the name
      await ref.read(onboardingProvider).saveStepData('name', name);
      
      // Navigate to next screen
      if (mounted) {
        context.push('/onboarding/gender');
      }
    }
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                "What's your name?",
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              TextField(
                controller: _nameController,
                onChanged: _onNameChanged,
                autofocus: true,
                keyboardType: TextInputType.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.h2,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: "Enter your name",
                  hintStyle: AppTextStyles.h2.copyWith(
                    color: AppColors.secondaryText.withOpacity(0.5)
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isValid ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
                    disabledForegroundColor: Colors.white.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: _isValid ? 4 : 0,
                    shadowColor: AppColors.shadow.withOpacity(0.3),
                  ),
                  child: Text(
                    'Continue',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
