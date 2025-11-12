import 'package:flutter/material.dart';
import 'package:g_one/screens/connect_screen.dart';
import 'package:g_one/screens/home_screen.dart';
import 'package:g_one/screens/settings_screen.dart';
import 'package:g_one/screens/splash_screen.dart';
import 'package:g_one/screens/translate_screen.dart';
import 'package:g_one/theme/app_theme.dart';
import 'package:g_one/utils/constants.dart';

void main() {
  runApp(const GOneApp());
}

class GOneApp extends StatelessWidget {
  const GOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.dark,
      initialRoute: AppConstants.routeSplash,
      routes: {
        AppConstants.routeSplash: (_) => const SplashScreen(),
        AppConstants.routeHome: (_) => const HomeScreen(),
        AppConstants.routeConnect: (_) => const ConnectScreen(),
        AppConstants.routeTranslate: (_) => const TranslateScreen(),
        AppConstants.routeSettings: (_) => const SettingsScreen(),
      },
    );
  }
}
