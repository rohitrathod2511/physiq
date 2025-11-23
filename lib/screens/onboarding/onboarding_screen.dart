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
    _draft = {
      'height_metric': 160.0,
      'weight_metric': 60.0,
    };
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
          // Ensure legacy values are handled. New structure has separate metric/imperial keys.
          if (!_draft.containsKey('height_metric')) {
            _draft['height_metric'] = 160.0;
            _draft['weight_metric'] = 60.0;
          }

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
      _autoConvert(key, value);
      // Re-initialize steps to pass down the new state
      _initializeSteps();
    });
  }

  void _autoConvert(String updatedKey, dynamic value) {
    const double kgToLbs = 2.20462;
    const double cmToInches = 0.393701;

    if (value is! double) return;

    switch (updatedKey) {
      case 'height_metric':
        _draft['height_imperial'] = value * cmToInches;
        break;
      case 'height_imperial':
        _draft['height_metric'] = value / cmToInches;
        break;
      case 'weight_metric':
        _draft['weight_imperial'] = value * kgToLbs;
        break;
      case 'weight_imperial':
        _draft['weight_metric'] = value / kgToLbs;
        break;
      case 'targetWeight_metric':
        _draft['targetWeight_imperial'] = value * kgToLbs;
        break;
      case 'targetWeight_imperial':
        _draft['targetWeight_metric'] = value / kgToLbs;
        break;
    }
  }

  bool _isStepValid() {
    // Simple validation: check if the key for the current step exists in the draft.
    // For height/weight, we check the metric key as it's the base.
    const stepKeys = ['gender', 'birthYear', 'height_metric', 'activityLevel', 'goal', 'targetWeight_metric', 'timeframe'];
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
        height: _isMetric ? _draft['height_metric'] : _draft['height_imperial'],
        weight: _isMetric ? _draft['weight_metric'] : _draft['weight_imperial'],
        isMetric: _isMetric,
        onChanged: (h, w) {
          if (_isMetric) {
            _updateDraft('height_metric', h);
            _updateDraft('weight_metric', w);
          } else {
            _updateDraft('height_imperial', h);
            _updateDraft('weight_imperial', w);
          }
        },
        onUnitChanged: (val) {
          setState(() {
            _isMetric = val;
            _initializeSteps();
          });
        },
      ),
      ActivityStep(activityLevel: _draft['activityLevel'], onChanged: (v) => _updateDraft('activityLevel', v)),
      GoalStep(goal: _draft['goal'], onChanged: (v) => _updateDraft('goal', v)),
      TargetWeightStep(
        targetWeight: _isMetric ? _draft['targetWeight_metric'] : _draft['targetWeight_imperial'],
        isMetric: _isMetric,
        onChanged: (v) {
          if (_isMetric) {
            _updateDraft('targetWeight_metric', v);
          } else {
            _updateDraft('targetWeight_imperial', v);
          }
        },
        onUnitChanged: (val) {
          setState(() {
            // Auto-populate target weight if empty when switching units
            if (!_draft.containsKey('targetWeight_metric')) _draft['targetWeight_metric'] = _draft['weight_metric'];
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
