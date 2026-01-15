
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
import 'package:physiq/screens/onboarding/result_message_screen.dart';
import 'package:physiq/screens/onboarding/diet_preference_screen.dart';
import 'package:physiq/screens/onboarding/notification_screen.dart';
import 'package:physiq/screens/onboarding/referral_screen.dart';
import 'package:physiq/screens/onboarding/generate_plan_screen.dart';
import 'package:physiq/screens/onboarding/loading_screen.dart';
import 'package:physiq/screens/onboarding/review_screen.dart';
import 'package:physiq/screens/onboarding/motivational_quote_screen.dart';
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
  bool? onboardingCompleted; // null = loading/unknown, false = new user, true = existing

  AuthSubscription() {
    // 1. Listen to Auth State
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      currentUser = user;
      
      // 2. If user exists, listen to their Firestore document
      if (user != null) {
        _userSubscription?.cancel(); // Cancel any previous listener
        _userSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          
          if (snapshot.exists) {
            final data = snapshot.data();
            // Default to TRUE if field is missing (LEGACY USER SUPPORT)
            // Default to FALSE only if explicitly false (NEW USER)
            onboardingCompleted = data?['onboardingCompleted'] ?? true;
          } else {
             // Doc doesn't exist yet (creating...)
             onboardingCompleted = false; 
          }
          notifyListeners();
        });
      } else {
        // User logged out
        _userSubscription?.cancel();
        _userSubscription = null;
        onboardingCompleted = null; // Reset
        notifyListeners();
      }
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
      final isProtected = location.startsWith('/home') ||
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
       // Optional: Could redirect to a dedicated loading screen if stuck too long
       // But usually letting it pass or showing splash is fine.
       // For safety, if on home, maybe show loading?
       // For now, let's allow them to stay where they are or go to loading if critical.
       if (location == '/home') {
          return '/onboarding/loading'; 
       }
       return null; 
    }

    // ----------------------------------------------------
    // 3. Authenticated AND Onboarding INCOMPLETE (New User)
    // ----------------------------------------------------
    if (!isOnboardingComplete) {
      // Allowed routes for new users (The Onboarding Flow)
      final allowedOnboardingRoutes = [
        '/onboarding/motivational-quote',
        '/onboarding/paywall-free',
        '/onboarding/paywall-notification',
        '/onboarding/paywall-main',
        '/onboarding/paywall-spinner',
        '/onboarding/paywall-offer',
        '/review',
        '/onboarding/loading',  // Allow loading screen
        if(location.startsWith('/onboarding') && !location.contains('/motivational-quote')) location // Allow other onboarding steps if they are backtracking/in-flow?
                                                                                             // Actually, it's safer to only allow specific post-signup flow.
      ];

      // Checking if strictly within the ALLOWED set or strictly blocked from Home
      // Strategy: If trying to go Home, force them to start of Post-Signup flow.
      if (location == '/home' || location == '/' || location == '/sign-in' || location == '/get-started') {
        return '/onboarding/motivational-quote';
      }
      
      // Otherwise, let them navigate within the onboarding screens they are in.
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
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
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
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/get-started',
      builder: (context, state) => const GetStartedScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignUpScreen(),
    ),
    
    // Onboarding Flow
    GoRoute(path: '/onboarding/name', builder: (context, state) => const NameScreen()),
    GoRoute(path: '/onboarding/gender', builder: (context, state) => const GenderScreen()),
    GoRoute(path: '/onboarding/birthyear', builder: (context, state) => const BirthYearScreen()),
    GoRoute(path: '/onboarding/height-weight', builder: (context, state) => const HeightWeightScreen()),
    GoRoute(path: '/onboarding/activity', builder: (context, state) => const ActivityLifestyleScreen()),
    GoRoute(path: '/onboarding/goal', builder: (context, state) => const GoalScreen()),
    GoRoute(path: '/onboarding/target-weight', builder: (context, state) => const TargetWeightScreen()),
    GoRoute(path: '/onboarding/motivational-message', builder: (context, state) => const GeneratePlanScreen()),
    GoRoute(path: '/onboarding/timeframe', builder: (context, state) => const TimeframeScreen()),
    GoRoute(path: '/onboarding/result-message', builder: (context, state) => const ResultMessageScreen()),
    GoRoute(path: '/onboarding/diet-preference', builder: (context, state) => const DietPreferenceScreen()),
    GoRoute(path: '/onboarding/notification', builder: (context, state) => const NotificationScreen()),
    GoRoute(path: '/onboarding/referral', builder: (context, state) => const ReferralScreen()),
    GoRoute(path: '/onboarding/generate-plan', builder: (context, state) => const MotivationalMessageScreen()),
    GoRoute(path: '/onboarding/loading', builder: (context, state) => const LoadingScreen()),
    
    // Review & Paywall
    GoRoute(path: '/review', builder: (context, state) => const ReviewScreen()),
    GoRoute(path: '/onboarding/motivational-quote', builder: (context, state) => const MotivationalQuoteScreen()),
    GoRoute(path: '/onboarding/paywall-free', builder: (context, state) => const PaywallFreeScreen()),
    GoRoute(path: '/onboarding/paywall-notification', builder: (context, state) => const PaywallNotificationScreen()),
    GoRoute(path: '/onboarding/paywall-main', builder: (context, state) => const PaywallMainScreen()),
    GoRoute(path: '/onboarding/paywall-spinner', builder: (context, state) => const PaywallSpinnerScreen()),
    GoRoute(path: '/onboarding/paywall-offer', builder: (context, state) => const PaywallOfferScreen()),

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
