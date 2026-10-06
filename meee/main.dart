import 'package:flutter/material.dart';
import 'constants.dart';
import 'login_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kGreen,
        scaffoldBackgroundColor: kBg,
      ),
      home: const LoginPage(),
    );
  }
}