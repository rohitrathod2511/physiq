import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class OnboardingStore extends ChangeNotifier {
  static const String _storageKey = 'onboarding_draft';
  static const String _goalStorageKey = 'onboarding_goal';
  static const String _stepStorageKey = 'onboarding_step';
  static const String _routeStorageKey = 'onboarding_route';
  static const Map<String, int> _routeToStep = {
    '/get-started': 0,
    '/signup': 1,
    '/sign-in': 1,
    '/review': 2,
    '/onboarding/gender': 3,
    '/onboarding/birthyear': 4,
    '/onboarding/height-weight': 5,
    '/onboarding/activity': 6,
    '/onboarding/goal': 7,
    '/onboarding/obstacles': 8,
    '/onboarding/target-weight': 9,
    '/onboarding/result-message': 10,
    '/onboarding/timeframe': 11,
    '/onboarding/potential': 12,
    '/onboarding/diet-preference': 13,
    '/onboarding/motivational-message': 14,
    '/onboarding/notification': 15,
    '/onboarding/referral': 16,
    '/onboarding/referral-step': 17,
    '/onboarding/generate-plan': 18,
    '/onboarding/loading': 19,
    '/onboarding/transformation-rodrigo': 20,
    '/onboarding/transformation-lucas': 21,
    '/onboarding/success-stories': 22,
    '/onboarding/paywall-free': 23,
    '/onboarding/paywall-notification': 24,
    '/onboarding/paywall-main': 25,
    '/onboarding/paywall-spinner': 26,
    '/onboarding/paywall-offer': 27,
  };
  Map<String, dynamic> _data = {};
  late final Future<void> _loadFuture;
  static String? _currentResumeRoute;
  static int? _currentResumeStep;

  OnboardingStore() {
    _loadFuture = loadDraft();
  }

  Map<String, dynamic> get data => _data;
  static String? get currentResumeRoute => _currentResumeRoute;
  static int? get currentResumeStep => _currentResumeStep;

  // Helper getters
  bool get isGuest => _data['isGuest'] ?? false;

  Future<void> ensureLoaded() => _loadFuture;

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        _data = json.decode(jsonString);
        notifyListeners();
      } catch (e) {
        print('Error loading draft: $e');
      }
    }
  }

  Future<void> saveStepData(String stepKey, dynamic value) async {
    _data[stepKey] = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(_data));
    if (stepKey == 'goal') {
      if (value == null) {
        await prefs.remove(_goalStorageKey);
      } else {
        await prefs.setString(_goalStorageKey, value.toString());
      }
    }
  }

  Future<void> clearDraft() async {
    _data = {};
    notifyListeners();
    await clearPersistedDraft();
  }

  static Future<void> clearPersistedDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_goalStorageKey);
    await clearResumeState();
  }

  Future<String?> getStoredGoal() async {
    await ensureLoaded();
    final inMemoryGoal = _data['goal']?.toString();
    if (inMemoryGoal != null && inMemoryGoal.isNotEmpty) {
      return inMemoryGoal;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_goalStorageKey);
  }

  // Helper getters for common fields
  String? get name => _data['name'];
  String? get gender => _data['gender'];
  int? get birthYear => _data['birthYear'];
  double? get heightCm => _data['heightCm'];
  double? get weightKg => _data['weightKg'];
  String? get activityLevel => _data['activityLevel'];
  String? get goal => _data['goal'];
  double? get targetWeightKg => _data['targetWeightKg'];
  String? get dietPreference => _data['dietPreference'];

  // Helper to check if essential data is present for plan generation
  bool get canGeneratePlan {
    return gender != null &&
        birthYear != null &&
        heightCm != null &&
        weightKg != null &&
        activityLevel != null &&
        goal != null;
  }

  static bool isOnboardingRoute(String route) {
    return _routeToStep.containsKey(route);
  }

  static Future<void> loadResumeState() async {
    final prefs = await SharedPreferences.getInstance();
    _currentResumeRoute = prefs.getString(_routeStorageKey);
    _currentResumeStep = prefs.getInt(_stepStorageKey);

    if (_currentResumeRoute == null && _currentResumeStep != null) {
      for (final entry in _routeToStep.entries) {
        if (entry.value == _currentResumeStep) {
          _currentResumeRoute = entry.key;
          break;
        }
      }
    }
  }

  static Future<void> saveResumeRoute(String route) async {
    if (!isOnboardingRoute(route)) return;

    _currentResumeRoute = route;
    _currentResumeStep = _routeToStep[route];

    final prefs = await SharedPreferences.getInstance();
    if (_currentResumeStep != null) {
      await prefs.setInt(_stepStorageKey, _currentResumeStep!);
    }
    await prefs.setString(_routeStorageKey, route);
  }

  static Future<void> clearResumeState() async {
    _currentResumeRoute = null;
    _currentResumeStep = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stepStorageKey);
    await prefs.remove(_routeStorageKey);
  }
}
