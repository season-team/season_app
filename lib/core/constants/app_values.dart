import 'package:flutter/widgets.dart';

class AppValues {
  // 📏 Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // 📐 Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;

  // 🧱 Spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 32.0;

  // ⬛ Shadows
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 6,
    offset: Offset(0, 2),
  );

  // 🔠 Font Sizes
  static const double fontSmall = 12;
  static const double fontMedium = 16;
  static const double fontLarge = 20;
}
