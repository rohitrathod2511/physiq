import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:physiq/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:physiq/routes/app_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/providers/preferences_provider.dart';
import 'package:physiq/services/messaging_service.dart';
import 'firebase_options.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Firebase Messaging
  await MessagingService().initialize();

  final sharedPrefs = await SharedPreferences.getInstance();
  
  // Load saved theme
  final savedTheme = sharedPrefs.getString('app_theme');
  if (savedTheme == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPrefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep watching preferencesProvider for Locale
    final prefs = ref.watch(preferencesProvider); 

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp.router(
          title: 'Physiq AI',
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
          ],
          locale: prefs.locale,
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            // Light Theme Definition
            // Even if AppColors is dynamic, we define the structure here.
            // When in Light Mode, AppColors returns Light values, so this is correct.
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              surface: AppColors.background,
              onSurface: AppColors.primaryText,
              secondary: AppColors.accent,
            ),
            textTheme: TextTheme(
              bodyMedium: AppTextStyles.body,
              bodyLarge: AppTextStyles.body,
              titleLarge: AppTextStyles.heading1,
              titleMedium: AppTextStyles.heading2,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF5F1ED),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF000000)),
              titleTextStyle: TextStyle(color: Color(0xFF000000), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 60,
              backgroundColor: const Color(0xFFF5F1ED),
              surfaceTintColor: Colors.transparent,
              indicatorColor: Colors.black.withOpacity(0.05),
              labelTextStyle: MaterialStateProperty.all(
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              iconTheme: MaterialStateProperty.all(
                const IconThemeData(size: 22),
              ),
            ),
            cardColor: Colors.white,
            dividerColor: Colors.grey[300],
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            // Explicit Dark Theme Colors
            scaffoldBackgroundColor: const Color(0xFF121212),
            canvasColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            dividerColor: const Color(0xFF2C2C2C),
            
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E), // Surfaces like Cards
              onSurface: Colors.white,
              background: Color(0xFF121212),
              onBackground: Colors.white,
              secondary: Colors.white,
              onSecondary: Colors.black,
              error: Color(0xFFCF6679),
            ),
             
            iconTheme: const IconThemeData(color: Colors.white),
            primaryIconTheme: const IconThemeData(color: Colors.white),
            
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            
            navigationBarTheme: NavigationBarThemeData(
              height: 60,
              backgroundColor: const Color(0xFF1E1E1E),
              surfaceTintColor: Colors.transparent,
              indicatorColor: Colors.white.withOpacity(0.1),
              labelTextStyle: MaterialStateProperty.all(
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70),
              ),
              iconTheme: MaterialStateProperty.all(
                const IconThemeData(size: 22, color: Colors.white70),
              ),
            ),
            
            textTheme: TextTheme(
              bodyMedium: AppTextStyles.body.copyWith(color: Colors.white),
              bodyLarge: AppTextStyles.body.copyWith(color: Colors.white),
              titleLarge: AppTextStyles.heading1.copyWith(color: Colors.white),
              titleMedium: AppTextStyles.heading2.copyWith(color: Colors.white),
              labelLarge: AppTextStyles.button.copyWith(color: Colors.white),
              displayLarge: AppTextStyles.largeNumber.copyWith(color: Colors.white),
            ).apply(
              bodyColor: Colors.white, 
              displayColor: Colors.white,
            ),

            cardTheme: const CardThemeData(
              color: Color(0xFF1E1E1E),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              margin: EdgeInsets.all(0),
            ),
            
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              surfaceTintColor: Colors.transparent,
              titleTextStyle: AppTextStyles.heading2.copyWith(color: Colors.white),
              contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white70),
            ),
            
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              surfaceTintColor: Colors.transparent,
              modalBackgroundColor: Color(0xFF1E1E1E),
            ),
            
            popupMenuTheme: PopupMenuThemeData(
              color: const Color(0xFF1E1E1E),
              surfaceTintColor: Colors.transparent,
              textStyle: AppTextStyles.body.copyWith(color: Colors.white),
              iconColor: Colors.white,
            ),
            
            datePickerTheme: DatePickerThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              headerBackgroundColor: const Color(0xFF2C2C2C),
              surfaceTintColor: Colors.transparent,
              dayForegroundColor: MaterialStateProperty.all(Colors.white),
              yearForegroundColor: MaterialStateProperty.all(Colors.white),
              dayStyle: AppTextStyles.body,
              weekdayStyle: AppTextStyles.smallLabel.copyWith(color: Colors.white70),
            ),

            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Color(0xFF333333),
              contentTextStyle: TextStyle(color: Colors.white),
            ),
            
            inputDecorationTheme: const InputDecorationTheme(
              fillColor: Color(0xFF2C2C2C),
              filled: true,
              hintStyle: TextStyle(color: Colors.white38),
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          routerConfig: router,
        );
      },
    );
  }
}
