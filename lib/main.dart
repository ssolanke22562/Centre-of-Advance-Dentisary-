import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/db_helper.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations & status bar overlay style
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize SQLite database and seed defaults
  await DatabaseHelper.instance.database;

  runApp(
    const ProviderScope(
      child: DrPatilDentistryApp(),
    ),
  );
}

class DrPatilDentistryApp extends StatelessWidget {
  const DrPatilDentistryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dr. Patil's Dentistry",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
