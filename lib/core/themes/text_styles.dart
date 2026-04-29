import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  // General Text Theme for Light Mode
  static TextTheme textTheme = TextTheme(
    displayLarge: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    displayMedium: const TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.grey[800],
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Colors.grey[700],
    ),
    labelLarge: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: AppColors.primary,
    ),
  );

  // Text Theme for Dark Mode
  static TextTheme textThemeDark = TextTheme(
    displayLarge: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    displayMedium: const TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.grey[300],
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Colors.grey[400],
    ),
    labelLarge: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: AppColors.primary,
    ),
  );
}
