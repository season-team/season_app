import 'package:flutter/material.dart';
import 'package:season_app/core/themes/text_styles.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Cairo',
    textTheme: AppTextStyles.textTheme.copyWith(
      bodyLarge:const TextStyle(fontFamily: 'Cairo'),
      bodyMedium:const TextStyle(fontFamily: 'Cairo'),
      bodySmall:const TextStyle(fontFamily: 'Cairo'),
      displayLarge:const TextStyle(fontFamily: 'Cairo'),
      displayMedium:const TextStyle(fontFamily: 'Cairo'),
      displaySmall:const TextStyle(fontFamily: 'Cairo'),
      headlineLarge:const TextStyle(fontFamily: 'Cairo'),
      headlineMedium:const TextStyle(fontFamily: 'Cairo'),
      headlineSmall:const TextStyle(fontFamily: 'Cairo'),
      titleLarge:const TextStyle(fontFamily: 'Cairo'),
      titleMedium:const TextStyle(fontFamily: 'Cairo'),
      titleSmall:const TextStyle(fontFamily: 'Cairo'),

    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,

      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',  // هنا برضو بنحدد الخط في الـ AppBar
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    primaryColor: AppColors.primary,
    fontFamily: 'Cairo',  // هنا برضو بنحدد الخط الافتراضي لكل النصوص
    textTheme: AppTextStyles.textThemeDark.copyWith(
      bodyLarge:const TextStyle(fontFamily: 'Cairo'),
      bodyMedium:const TextStyle(fontFamily: 'Cairo'),
      bodySmall:const TextStyle(fontFamily: 'Cairo'),
      displayLarge:const TextStyle(fontFamily: 'Cairo'),
      displayMedium:const TextStyle(fontFamily: 'Cairo'),
      displaySmall:const TextStyle(fontFamily: 'Cairo'),
      headlineLarge:const TextStyle(fontFamily: 'Cairo'),
      headlineMedium:const TextStyle(fontFamily: 'Cairo'),
      headlineSmall:const TextStyle(fontFamily: 'Cairo'),
      titleLarge:const TextStyle(fontFamily: 'Cairo'),
      titleMedium:const TextStyle(fontFamily: 'Cairo'),
      titleSmall:const TextStyle(fontFamily: 'Cairo'),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,

    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
  );
}
