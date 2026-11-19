import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for sleek White & Black theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const TrackyApp());
}

/// TrackyApp is the root widget for Tracky gym workout tracking application.
class TrackyApp extends StatelessWidget {
  const TrackyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracky',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.whiteAndBlackTheme,
      home: const HomeScreen(),
    );
  }
}
