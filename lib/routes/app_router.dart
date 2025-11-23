import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/screens/home_screen.dart';
import 'package:physiq/screens/progress_screen.dart';
import 'package:physiq/screens/exercise_screen.dart';
import 'package:physiq/screens/settings_screen.dart';
import 'package:physiq/screens/onboarding/paywall_screen.dart';
import 'package:physiq/screens/meal_history_screen.dart';
import 'package:physiq/screens/onboarding/splash_screen.dart';
import 'package:physiq/screens/onboarding/get_started_screen.dart';
import 'package:physiq/screens/onboarding/sign_in_screen.dart';
import 'package:physiq/screens/onboarding/onboarding_screen.dart';
import 'package:physiq/screens/onboarding/loading_screen.dart';
import 'package:physiq/screens/onboarding/review_screen.dart';
import 'package:physiq/screens/macro_adjustment_screen.dart'; // Import added
import 'package:physiq/widgets/scaffold_with_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/', // Start at the splash screen
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
          builder: (context, state) => const ExerciseScreen(),
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
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/loading',
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) => const ReviewScreen(),
    ),
    GoRoute(
      path: '/paywall',
      builder: (context, state) => const PaywallScreen(),
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
