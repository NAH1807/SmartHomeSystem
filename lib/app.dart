import 'package:flutter/material.dart';
import 'screens/main.dart';
import 'theme/app.dart';

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Home',
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}