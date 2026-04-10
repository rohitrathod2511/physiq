import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/screens/home_screen.dart';
import 'package:physiq/screens/onboarding/get_started_screen.dart';
import 'package:physiq/screens/onboarding/splash_screen.dart';
import 'package:physiq/widgets/scaffold_with_nav_bar.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          // If the user is unauthenticated, they shouldn't just be stuck on AuthGate 
          // but we should push them into the actual GoRouter flow so that deep navigation works.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (GoRouterState.of(context).uri.path != '/get-started') {
              context.go('/get-started');
            }
          });
          return const SplashScreen();
        }

        // Optional: Check if Firestore user document exists before showing Home
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (GoRouterState.of(context).uri.path != '/home') {
                context.go('/home');
              }
            });
            return const SplashScreen();
          },
        );
      },
    );
  }
}
