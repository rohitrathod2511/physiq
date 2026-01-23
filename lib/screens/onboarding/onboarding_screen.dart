import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/services/local_storage.dart';
import 'package:physiq/utils/design_system.dart'; // Using the correct, more complete design system.

// Step imports
import 'gender_step.dart';
import 'birthyear_step.dart';
import 'height_weight_step.dart';
import 'activity_step.dart';
import 'goal_step.dart';
import 'target_weight_step.dart';
import 'timeframe_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final LocalStorageService _localStorage = LocalStorageService();

  Map<String, dynamic> _draft = {};
  int _currentStep = 0;
  bool _isMetric = false; // Defaulting to Imperial as requested

  final int _stepCount = 7; // Adjusted to the number of steps

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await _localStorage.loadOnboardingDraft();
    if (draft != null && mounted) {
      setState(() {
        _draft = draft;
        _isMetric = _draft['isMetric'] ?? false;
      });
    }
  }

  /// Safely converts a dynamic value from the draft into a double?
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _saveDraft() async {
    _draft['isMetric'] = _isMetric;
    await _localStorage.saveOnboardingDraft(_draft);
  }

  void _onNext() {
    if (_currentStep < _stepCount - 1) {
      _saveDraft();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onComplete();
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/sign-in');
    }
  }

  Future<void> _onComplete() async {
    await _saveDraft();
    await _localStorage.clearOnboardingDraft();
    if (mounted) context.go('/loading');
  }

  void _updateDraft(String key, dynamic value) {
    setState(() {
      _draft[key] = value;
    });
  }

  Widget _buildStep(int index) {
    switch (index) {
      case 0:
        return GenderStep(
          gender: _draft['gender'],
          onChanged: (v) => _updateDraft('gender', v),
        );
      case 1:
        return BirthYearStep(
          birthYear: _toInt(_draft['birthYear']),
          onChanged: (v) => _updateDraft('birthYear', v),
        );
      case 2:
        return HeightWeightStep(
          height: _toDouble(_draft['height']), // FIXED: Use safe converter
          weight: _toDouble(_draft['weight']), // FIXED: Use safe converter
          isMetric: _isMetric, // FIXED: Pass down the isMetric state
          onChanged: (h, w) {
            _updateDraft('height', h);
            _updateDraft('weight', w);
          },
          onUnitChanged: (val) => setState(() => _isMetric = val),
        );
      case 3:
        return ActivityStep(
          activityLevel: _draft['activityLevel'],
          onChanged: (v) => _updateDraft('activityLevel', v),
        );
      case 4:
        return GoalStep(
          goal: _draft['goal'],
          onChanged: (v) => _updateDraft('goal', v),
        );
      case 5:
        return TargetWeightStep(
          targetWeight: _toDouble(
            _draft['targetWeight'],
          ), // FIXED: Use safe converter
          isMetric: _isMetric, // FIXED: Pass down the isMetric state
          onChanged: (v) => _updateDraft('targetWeight', v),
          onUnitChanged: (val) => setState(() => _isMetric = val),
        );
      case 6:
        return TimeframeScreen(
          timeframe: _draft['timeframe'],
          onChanged: (v) => _updateDraft('timeframe', v),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _onBack,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back, color: AppColors.primaryText),
            ),
          ),
        ),
        title: LinearProgressIndicator(
          value: (_currentStep + 1) / _stepCount,
          backgroundColor: Colors.grey[200],
          color: AppColors.accent,
          minHeight: 6,
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _stepCount,
        onPageChanged: (index) => setState(() => _currentStep = index),
        itemBuilder: (context, index) => _buildStep(index),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: _onNext,
          child: Text(
            'Continue',
            style: AppTextStyles.button.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
