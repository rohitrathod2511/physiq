import 'dart:async'; // Added for StreamSubscription
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for FirebaseAuth
import 'package:physiq/screens/home_screen.dart';
import 'package:physiq/screens/progress_screen.dart';
import 'package:physiq/screens/exercise/exercise_list_screen.dart';
import 'package:physiq/screens/settings/settings_screen.dart';
import 'package:physiq/screens/meal_history_screen.dart';
import 'package:physiq/screens/onboarding/splash_screen.dart';
import 'package:physiq/screens/onboarding/get_started_screen.dart';
import 'package:physiq/screens/onboarding/sign_up_screen.dart';
import 'package:physiq/screens/onboarding/name_screen.dart';
import 'package:physiq/screens/onboarding/gender_screen.dart';
import 'package:physiq/screens/onboarding/birthyear_screen.dart';
import 'package:physiq/screens/onboarding/height_weight_screen.dart';
import 'package:physiq/screens/onboarding/activity_lifestyle_screen.dart';
import 'package:physiq/screens/onboarding/goal_screen.dart';
import 'package:physiq/screens/onboarding/target_weight_screen.dart';
import 'package:physiq/screens/onboarding/motivational_message_screen.dart';
import 'package:physiq/screens/onboarding/timeframe_screen.dart';
import 'package:physiq/screens/onboarding/potential_screen.dart';
import 'package:physiq/screens/onboarding/result_message_screen.dart';
import 'package:physiq/screens/onboarding/diet_preference_screen.dart';
import 'package:physiq/screens/onboarding/notification_screen.dart';
import 'package:physiq/screens/onboarding/referral_screen.dart';
import 'package:physiq/screens/onboarding/generate_plan_screen.dart';
import 'package:physiq/screens/onboarding/loading_screen.dart';
import 'package:physiq/screens/onboarding/review_screen.dart';
import 'package:physiq/screens/onboarding/rodrigo_transformation_screen.dart';
import 'package:physiq/screens/onboarding/lucas_transformation_screen.dart';
import 'package:physiq/screens/onboarding/success_stories_screen.dart';

import 'package:physiq/screens/onboarding/paywall_free_screen.dart';
import 'package:physiq/screens/onboarding/paywall_notification_screen.dart';
import 'package:physiq/screens/onboarding/paywall_main_screen.dart';
import 'package:physiq/screens/onboarding/paywall_spinner_screen.dart';
import 'package:physiq/screens/onboarding/paywall_offer_screen.dart';
import 'package:physiq/screens/macro_adjustment_screen.dart';
import 'package:physiq/widgets/scaffold_with_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AuthSubscription extends ChangeNotifier {
  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  User? currentUser;
  bool?
  onboardingCompleted; // null = loading/unknown, false = new user, true = existing

  AuthSubscription() {
    // 1. Initialize with current values if available synchronously
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _startUserSubscription(currentUser!);
    }

    // 2. Listen to Auth State changes for future events
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      if (currentUser?.uid != user?.uid) {
        currentUser = user;
        if (user != null) {
          _startUserSubscription(user);
        } else {
          _userSubscription?.cancel();
          _userSubscription = null;
          onboardingCompleted = null;
          notifyListeners();
        }
      }
    });
  }

  void _startUserSubscription(User user) {
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            onboardingCompleted = data?['onboardingCompleted'] ?? true;
          } else {
            onboardingCompleted = false;
          }
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}

final authSubscription = AuthSubscription();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  refreshListenable: authSubscription,
  initialLocation: '/',
  redirect: (context, state) {
    final isAuthenticated = authSubscription.currentUser != null;
    final isOnboardingComplete = authSubscription.onboardingCompleted;
    final location = state.uri.path;

    // ----------------------------------------------------
    // 1. If NOT authenticated
    // ----------------------------------------------------
    if (!isAuthenticated) {
      // Protected routes logic
      final isProtected =
          location.startsWith('/home') ||
          location.startsWith('/settings') ||
          location.startsWith('/progress') ||
          location.startsWith('/exercise') ||
          location.startsWith('/meal-history');

      // If trying to access protected route, kick to Get Started
      if (isProtected) {
        return '/get-started';
      }
      return null; // Allow public access (splash, onboarding start, etc)
    }

    // ----------------------------------------------------
    // 2. If Authenticated but Firestore data still loading
    // ----------------------------------------------------
    if (isOnboardingComplete == null) {
      // Stay on current screen while loading
      return null;
    }

    // ----------------------------------------------------

    // 3. Authenticated AND Onboarding INCOMPLETE (New User)
    // ----------------------------------------------------
    if (!isOnboardingComplete) {
      final isProtected =
          location.startsWith('/home') ||
          location.startsWith('/settings') ||
          location.startsWith('/progress') ||
          location.startsWith('/exercise') ||
          location.startsWith('/meal-history');

      // Enforce paywall/onboarding completion before app shell access.
      if (isProtected || location == '/' || location == '/get-started') {
        return '/onboarding/paywall-free';
      }
      return null;
    }

    // ----------------------------------------------------
    // 4. Authenticated AND Onboarding COMPLETE (Returning User)
    // ----------------------------------------------------
    if (isOnboardingComplete) {
      // Redirect away from auth/onboarding screens to Home
      if (location == '/sign-in' ||
          location == '/get-started' ||
          location == '/' ||
          location.startsWith('/onboarding') ||
          location == '/review') {
        return '/home';
      }
    }

    return null;
  },
  routes: <RouteBase>[
    // The main app shell with bottom navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressScreen(),
        ),
        GoRoute(
          path: '/exercise',
          builder: (context, state) => const ExerciseListScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    // Standalone routes that sit outside the main shell
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/get-started',
      builder: (context, state) => const GetStartedScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignUpScreen(),
    ),

    // Onboarding Flow
    // Name Screen removed from flow per user request (still available in settings if implemented there, but removed from router)
    // GoRoute(path: '/onboarding/name', builder: (context, state) => const NameScreen()),
    GoRoute(
      path: '/onboarding/gender',
      builder: (context, state) => const GenderScreen(),
    ),
    GoRoute(
      path: '/onboarding/birthyear',
      builder: (context, state) => const BirthYearScreen(),
    ),
    GoRoute(
      path: '/onboarding/height-weight',
      builder: (context, state) => const HeightWeightScreen(),
    ),
    GoRoute(
      path: '/onboarding/activity',
      builder: (context, state) => const ActivityLifestyleScreen(),
    ),
    GoRoute(
      path: '/onboarding/goal',
      builder: (context, state) => const GoalScreen(),
    ),
    GoRoute(
      path: '/onboarding/target-weight',
      builder: (context, state) => const TargetWeightScreen(),
    ),
    GoRoute(
      path: '/onboarding/motivational-message',
      builder: (context, state) => const MotivationalMessageScreen(),
    ),
    GoRoute(
      path: '/onboarding/timeframe',
      builder: (context, state) => const TimeframeScreen(),
    ),
    GoRoute(
      path: '/onboarding/potential',
      builder: (context, state) => const PotentialScreen(),
    ),
    GoRoute(
      path: '/onboarding/result-message',
      builder: (context, state) => const ResultMessageScreen(),
    ),
    GoRoute(
      path: '/onboarding/diet-preference',
      builder: (context, state) => const DietPreferenceScreen(),
    ),
    GoRoute(
      path: '/onboarding/notification',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/onboarding/referral',
      builder: (context, state) => const ReferralScreen(),
    ),
    GoRoute(
      path: '/onboarding/generate-plan',
      builder: (context, state) => const GeneratePlanScreen(),
    ),
    GoRoute(
      path: '/onboarding/loading',
      builder: (context, state) => const LoadingScreen(),
    ),

    // Review & Paywall
    GoRoute(path: '/review', builder: (context, state) => const ReviewScreen()),

    GoRoute(
      path: '/onboarding/transformation-rodrigo',
      builder: (context, state) => const RodrigoTransformationScreen(),
    ),
    GoRoute(
      path: '/onboarding/transformation-lucas',
      builder: (context, state) => const LucasTransformationScreen(),
    ),
    GoRoute(
      path: '/onboarding/success-stories',
      builder: (context, state) => const SuccessStoriesScreen(),
    ),

    GoRoute(
      path: '/onboarding/paywall-free',
      builder: (context, state) => const PaywallFreeScreen(),
    ),
    GoRoute(
      path: '/onboarding/paywall-notification',
      builder: (context, state) => const PaywallNotificationScreen(),
    ),
    GoRoute(
      path: '/onboarding/paywall-main',
      builder: (context, state) => const PaywallMainScreen(),
    ),
    GoRoute(
      path: '/onboarding/paywall-spinner',
      builder: (context, state) => const PaywallSpinnerScreen(),
    ),
    GoRoute(
      path: '/onboarding/paywall-offer',
      builder: (context, state) => const PaywallOfferScreen(),
    ),

    GoRoute(
      path: '/meal-history',
      builder: (context, state) => const MealHistoryScreen(),
    ),
    GoRoute(
      path: '/mealDetail/:id',
      builder: (BuildContext context, GoRouterState state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Meal Detail')),
          body: Center(
            child: Text('Meal Detail Screen: ${state.pathParameters['id']}'),
          ),
        );
      },
    ),
    // Route for the macro adjustment screen
    GoRoute(
      path: '/settings/adjust-macros',
      builder: (context, state) => const MacroAdjustmentScreen(),
    ),
  ],
);
