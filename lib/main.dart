import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/routes/app_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Physiq',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        textTheme: TextTheme(
          bodyMedium: AppTextStyles.body,
        ),
      ),
      routerConfig: router,
    );
  }
}
