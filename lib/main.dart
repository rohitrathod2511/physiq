import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:physiq/routes/app_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/providers/preferences_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPrefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Physiq',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, // Ensure Material 3 is active for the theme to work
        scaffoldBackgroundColor: AppColors.background,
        textTheme: TextTheme(bodyMedium: AppTextStyles.body),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          // REDUCE HEIGHT HERE: Default is 80, 60 is compact
          height: 60,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.black.withOpacity(0.05),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          iconTheme: MaterialStateProperty.all(
            const IconThemeData(size: 22),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
