import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/services/firestore_service.dart';
import 'package:physiq/services/local_storage.dart';
import 'package:physiq/theme/design_system.dart';

// Importing all the individual step widgets
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
  final AuthService _authService = AuthService();

  Map<String, dynamic> _draft = {};
  int _currentStep = 0;
  late List<Widget> _steps;

  bool _isMetric = true; // Default to metric

  @override
  void initState() {
    super.initState();
    _initializeSteps();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await _localStorage.loadOnboardingDraft();
    if (draft != null && mounted) {
      setState(() {
        _draft = draft;
        // Restore isMetric if saved, otherwise default
        if (_draft.containsKey('isMetric')) {
          _isMetric = _draft['isMetric'];
        }
        _initializeSteps();
      });
    }
  }

  Future<void> _saveDraft() async {
    _draft['isMetric'] = _isMetric; // Save unit preference
    await _localStorage.saveOnboardingDraft(_draft);
    final user = _authService.getCurrentUser();
    if (user != null && !AppConfig.useMockBackend) {
      // In a real app, you'd save this to Firestore.
    }
  }

  void _onNext() {
    if (!_isStepValid()) return;

    if (_currentStep < _steps.length - 1) {
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
      context.pop();
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
      // Re-initialize steps to pass down the new state
      _initializeSteps();
    });
  }

  bool _isStepValid() {
    // Simple validation: check if the key for the current step exists in the draft.
    const stepKeys = ['gender', 'birthYear', 'height', 'activityLevel', 'goal', 'targetWeight', 'timeframe'];
    if (_currentStep < stepKeys.length) {
        return _draft.containsKey(stepKeys[_currentStep]);
    }
    return false;
  }

  void _initializeSteps() {
    _steps = [
      GenderStep(gender: _draft['gender'], onChanged: (v) => _updateDraft('gender', v)),
      BirthYearStep(birthYear: _draft['birthYear'], onChanged: (v) => _updateDraft('birthYear', v)),
      HeightWeightStep(
        height: _draft['height'],
        weight: _draft['weight'],
        isMetric: _isMetric,
        onChanged: (h, w) {
          _updateDraft('height', h);
          _updateDraft('weight', w);
        },
        onUnitChanged: (val) {
          setState(() {
            _isMetric = val;
            // Optional: Convert existing values when switching units
            // For now, we just switch the view mode
            _initializeSteps();
          });
        },
      ),
      ActivityStep(activityLevel: _draft['activityLevel'], onChanged: (v) => _updateDraft('activityLevel', v)),
      GoalStep(goal: _draft['goal'], onChanged: (v) => _updateDraft('goal', v)),
      TargetWeightStep(
        targetWeight: _draft['targetWeight'], 
        isMetric: _isMetric,
        onChanged: (v) => _updateDraft('targetWeight', v),
        onUnitChanged: (val) {
          setState(() {
            _isMetric = val;
            _initializeSteps();
          });
        },
      ),
      TimeframeStep(timeframe: _draft['timeframe'], onChanged: (v) => _updateDraft('timeframe', v)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isStepComplete = _isStepValid();

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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.primary),
            ),
          ),
        ),
        title: LinearProgressIndicator(
          value: (_currentStep + 1) / _steps.length,
          backgroundColor: Colors.grey[200],
          color: AppColors.primary,
          minHeight: 6,
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _steps.length,
        onPageChanged: (index) => setState(() => _currentStep = index),
        itemBuilder: (context, index) => _steps[index],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isStepComplete ? AppColors.primary : Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: isStepComplete ? _onNext : null, // Disable button if step is not complete
          child: Text(
            'Continue',
            style: AppTextStyles.button.copyWith(
              color: isStepComplete ? Colors.white : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}
