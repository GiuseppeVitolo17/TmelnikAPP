import 'package:flutter/material.dart';

/// Centralized theme system for TmelnikAPP
/// Provides reusable color, radius, and shadow constants
class AppColors {
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color secondaryYellow = Color(0xFFFFC107);
  static const Color backgroundGrey = Color(0xFFF5F6FA);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.grey;
  static const Color cardBackground = Colors.white;
}

class AppRadius {
  static BorderRadius large = BorderRadius.circular(20);
  static BorderRadius medium = BorderRadius.circular(12);
}

class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Builds the main app theme configuration
ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.backgroundGrey,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

