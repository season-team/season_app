import 'package:flutter/material.dart';

class AppColors {
  // 🎨 Primary Palette
  static const Color primary = Color(0xff092C4C);
  static const Color secondary = Color(0xffe69146);

  // 🌙 Backgrounds
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);

  // 🖋️ Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Colors.white;

  // 🚨 Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFca2727);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // 🧱 Borders
  static const Color border = Color(0xFFE0E0E0);

  // 🎒 Bag Page Colors (derived from primary palette)
  static const Color bagGradientStart = primary;
  static const Color bagGradientEnd = secondary;
  static const Color bagPrimaryButton = primary;
  static const Color bagSecondaryButtonBackground = Color(0xFFFFF3E0);
  static const Color bagSecondaryButtonText = secondary;
  static const Color bagTipsBackground = Color(0xFFEAF2F8);
  static const Color bagTipsText = primary;
}
