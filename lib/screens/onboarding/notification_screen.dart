
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _mealReminders = true;
  bool _waterReminders = true;
  bool _weighInReminders = true;

  void _onContinue() {
    final store = ref.read(onboardingProvider);
    store.saveStepData('mealReminders', _mealReminders);
    store.saveStepData('waterReminders', _waterReminders);
    store.saveStepData('weighInReminders', _weighInReminders);
    
    context.push('/sign-in');
  }

  Widget _buildToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.bodyBold),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.black,
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
            children: [
              // Progress Bar removed
              const Spacer(),
              const Spacer(),
              Text(
                "Reach your goals with\nnotifications",
                style: AppTextStyles.h1.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              
              // iOS Style Card
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5EA).withOpacity(0.9), // iOS light grey
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text(
                            "Physiq would like to send you Notifications",
                            style: TextStyle(
                              fontSize: 17, 
                              fontWeight: FontWeight.w600, 
                              color: Colors.black,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Notifications may include alerts, sounds, and icon badges. These can be configured in Settings.",
                            style: TextStyle(fontSize: 13, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                                // "Don't Allow" - proceed without saving true? 
                                // Or Just proceed. The user wants visual UI.
                                // Logic unchanged means we probably shouldn't break flow.
                                setState(() {
                                    _mealReminders = false;
                                    _waterReminders = false;
                                    _weighInReminders = false;
                                });
                                _onContinue();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: const Text(
                                "Don't Allow",
                                style: TextStyle(fontSize: 17, color: Colors.blue),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 50, color: Colors.grey),
                        Expanded(
                          child: InkWell(
                            onTap: _onContinue, // Allow
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: const Text(
                                "Allow",
                                style: TextStyle(fontSize: 17, color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Continue Button (Hidden/Removed per requirement? 
              // The reference shows ONLY the iOS card and a hand pointer. 
              // There is a "Continue" button at the VERY bottom of the reference image though (black button). 
              // Wait, looking at "uploaded_image_3_1768061894152.jpg":
              // Title top, iOS Card center, Continue button bottom.
              // So I should keep the bottom Continue button purely as fallback or part of layout?
              // The prompt says "iOS-style permission card... 'Don't Allow' / 'Allow' buttons".
              // The card itself acts as the interaction. 
              // BUT the image shows a "Continue" button at the bottom too.
              // If the user clicks "Allow" on the card, does it proceed? Or do they click Allow then Continue?
              // Usually the iOS Prompt is a system dialog that appears OVER the screen. 
              // Here it's drawn AS the screen content.
              // If I click Allow in the mock, I should probably proceed.
              // I will keep the Continue button at the bottom as per image, which seems to be the standard "Continue" enabled.
              // Clicking "Allow" on the mock card might just toggle the internal switch? 
              // But the reference image shows a hand clicking "Allow".
              // I'll make the mock buttons function as controls, and the bottom Continue button as the final action?
              // Or maybe clicking Allow acts as Continue.
              // Given "Continue button remains unchanged" in other screens, I'll keep it.
              // I will make the mock "Allow" button just visually "select" or do nothing? 
              // No, user expects interaction.
              // I will make Mock permissions card behave like the toggles: 
              // 'Allow' -> Sets vars to true. 'Don't Allow' -> Sets vars to false. 
              // AND maybe auto-continue? 
              // I'll leave auto-continue out for now, let user click Continue at bottom.
              // Actually, looking at the image, the hand is clicking "Allow".
              // I'll make the buttons interactive.
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

}
