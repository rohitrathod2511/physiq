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
import 'package:physiq/screens/onboarding/obstacles_screen.dart';
import 'package:physiq/screens/onboarding/target_weight_screen.dart';
import 'package:physiq/screens/onboarding/motivational_message_screen.dart';
import 'package:physiq/screens/onboarding/long_term_results_screen.dart';
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
import 'package:physiq/services/onboarding_store.dart';
import 'package:physiq/widgets/scaffold_with_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AuthSubscription extends ChangeNotifier {
  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  User? currentUser;
  String? resumeRoute;
  bool?
  onboardingCompleted; // null = loading/unknown, false = new user, true = existing

  AuthSubscription() {
    _loadResumeRoute();

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

  Future<void> _loadResumeRoute() async {
    await OnboardingStore.loadResumeState();
    resumeRoute = OnboardingStore.currentResumeRoute;
    notifyListeners();
  }

  Future<void> updateResumeRoute(String route) async {
    if (!OnboardingStore.isOnboardingRoute(route)) return;
    if (resumeRoute == route) return;

    await OnboardingStore.saveResumeRoute(route);
    resumeRoute = route;
    notifyListeners();
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
    final resumeRoute = OnboardingStore.currentResumeRoute;

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
      if ((location == '/' || location == '/get-started') &&
          resumeRoute != null &&
          resumeRoute != location) {
        return resumeRoute;
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

      // Keep incomplete users in the onboarding flow instead of jumping ahead to paywall.
      if (isProtected || location == '/') {
        if (resumeRoute != null && resumeRoute != location) {
          return resumeRoute;
        }
        return '/get-started';
      }
      if (location == '/get-started' &&
          resumeRoute != null &&
          resumeRoute != location) {
        return resumeRoute;
      }
      return null;
    }

    // ----------------------------------------------------
    // 4. Authenticated AND Onboarding COMPLETE (Returning User)
    // ----------------------------------------------------
    if (isOnboardingComplete) {
      // Redirect away from auth/onboarding screens to Home
      if (location == '/sign-in' ||
          location == '/signup' ||
          location == '/rodrigo' ||
          location == '/lucas' ||
          location == '/success' ||
          location == '/paywall' ||
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
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/get-started',
        child: GetStartedScreen(),
      ),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/sign-in',
        child: SignUpScreen(),
      ),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/signup',
        child: SignUpScreen(),
      ),
    ),
    GoRoute(
      path: '/rodrigo',
      redirect: (context, state) {
        return '/onboarding/transformation-rodrigo';
      },
      builder: (context, state) => const SizedBox.shrink(),
    ),
    GoRoute(
      path: '/lucas',
      redirect: (context, state) {
        return '/onboarding/transformation-lucas';
      },
      builder: (context, state) => const SizedBox.shrink(),
    ),
    GoRoute(
      path: '/success',
      redirect: (context, state) {
        return '/onboarding/success-stories';
      },
      builder: (context, state) => const SizedBox.shrink(),
    ),
    GoRoute(
      path: '/paywall',
      redirect: (context, state) {
        return '/onboarding/paywall-free';
      },
      builder: (context, state) => const SizedBox.shrink(),
    ),

    // Onboarding Flow
    // Name Screen removed from flow per user request (still available in settings if implemented there, but removed from router)
    // GoRoute(path: '/onboarding/name', builder: (context, state) => const NameScreen()),
    GoRoute(
      path: '/onboarding/gender',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/gender',
        child: GenderScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/birthyear',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/birthyear',
        child: BirthYearScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/height-weight',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/height-weight',
        child: HeightWeightScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/activity',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/activity',
        child: ActivityLifestyleScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/goal',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/goal',
        child: GoalScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/obstacles',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/obstacles',
        child: ObstaclesScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/target-weight',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/target-weight',
        child: TargetWeightScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/motivational-message',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/motivational-message',
        child: MotivationalMessageScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/referral',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/referral',
        child: LongTermResultsScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/timeframe',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/timeframe',
        child: TimeframeScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/potential',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/potential',
        child: PotentialScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/result-message',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/result-message',
        child: ResultMessageScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/diet-preference',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/diet-preference',
        child: DietPreferenceScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/notification',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/notification',
        child: NotificationScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/referral-step',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/referral-step',
        child: ReferralScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/generate-plan',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/generate-plan',
        child: GeneratePlanScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/loading',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/loading',
        child: LoadingScreen(),
      ),
    ),

    // Review & Paywall
    GoRoute(
      path: '/review',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/review',
        child: ReviewScreen(),
      ),
    ),

    GoRoute(
      path: '/onboarding/transformation-rodrigo',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/transformation-rodrigo',
        child: RodrigoTransformationScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/transformation-lucas',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/transformation-lucas',
        child: LucasTransformationScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/success-stories',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/success-stories',
        child: SuccessStoriesScreen(),
      ),
    ),

    GoRoute(
      path: '/onboarding/paywall-free',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/paywall-free',
        child: PaywallFreeScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/paywall-notification',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/paywall-notification',
        child: PaywallNotificationScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/paywall-main',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/paywall-main',
        child: PaywallMainScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/paywall-spinner',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/paywall-spinner',
        child: PaywallSpinnerScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/paywall-offer',
      builder: (context, state) => const _TrackedOnboardingRoute(
        route: '/onboarding/paywall-offer',
        child: PaywallOfferScreen(),
      ),
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

class _TrackedOnboardingRoute extends StatefulWidget {
  final String route;
  final Widget child;

  const _TrackedOnboardingRoute({
    required this.route,
    required this.child,
  });

  @override
  State<_TrackedOnboardingRoute> createState() => _TrackedOnboardingRouteState();
}

class _TrackedOnboardingRouteState extends State<_TrackedOnboardingRoute> {
  @override
  void initState() {
    super.initState();
    _persistRoute();
  }

  @override
  void didUpdateWidget(covariant _TrackedOnboardingRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route != widget.route) {
      _persistRoute();
    }
  }

  void _persistRoute() {
    Future.microtask(() => authSubscription.updateResumeRoute(widget.route));
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
