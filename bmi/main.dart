import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bmi_colors.dart';
import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = GoogleFonts.sarabunTextTheme();
    final display = GoogleFonts.kanitTextTheme();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BMI Checker',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: BmiColors.bgLight,
        colorScheme: ColorScheme.fromSeed(seedColor: BmiColors.teal, brightness: Brightness.light, surface: BmiColors.bgLight),
        textTheme: body.copyWith(
          headlineSmall: display.headlineSmall?.copyWith(color: BmiColors.inkLight, fontWeight: FontWeight.w600),
          titleLarge: display.titleLarge?.copyWith(color: BmiColors.inkLight),
          titleMedium: display.titleMedium?.copyWith(color: BmiColors.inkLight),
          bodyMedium: body.bodyMedium?.copyWith(color: BmiColors.inkLight),
          bodySmall: body.bodySmall?.copyWith(color: BmiColors.inkFaintLight),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: BmiColors.bgLight,
          elevation: 0,
          foregroundColor: BmiColors.inkLight,
          titleTextStyle: display.titleLarge?.copyWith(color: BmiColors.inkLight, fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: BmiColors.bgLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: BmiColors.borderLight)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: BmiColors.borderLight)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: BmiColors.teal, width: 1.6)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: BmiColors.bgDark,
        colorScheme: ColorScheme.fromSeed(seedColor: BmiColors.teal, brightness: Brightness.dark, surface: BmiColors.bgDark),
        textTheme: body.copyWith(
          headlineSmall: display.headlineSmall?.copyWith(color: BmiColors.inkDark, fontWeight: FontWeight.w600),
          titleLarge: display.titleLarge?.copyWith(color: BmiColors.inkDark),
          titleMedium: display.titleMedium?.copyWith(color: BmiColors.inkDark),
          bodyMedium: body.bodyMedium?.copyWith(color: BmiColors.inkDark),
          bodySmall: body.bodySmall?.copyWith(color: BmiColors.inkFaintDark),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: BmiColors.bgDark,
          elevation: 0,
          foregroundColor: BmiColors.inkDark,
          titleTextStyle: display.titleLarge?.copyWith(color: BmiColors.inkDark, fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: BmiColors.cardDark,
          hintStyle: const TextStyle(color: BmiColors.inkFaintDark),
          suffixStyle: const TextStyle(color: BmiColors.inkDark),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: BmiColors.borderDark)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: BmiColors.borderDark)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: BmiColors.teal, width: 1.6)),
        ),
      ),
      home: HomePage(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}