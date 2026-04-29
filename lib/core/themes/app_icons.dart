import 'package:flutter/widgets.dart';

/// لو عندك Font Icon مخصص، استخدم ده.
/// مثال: أضفت ملف ttf اسمه `AppIcons.ttf` في assets/fonts
/// وسجلته في pubspec.yaml:
///
/// flutter:
///   fonts:
///     - family: AppIcons
///       fonts:
///         - asset: assets/fonts/AppIcons.ttf

class AppIcons {
  AppIcons._();

  static const String _fontFamily = 'AppIcons';

  static const IconData home = IconData(0xe900, fontFamily: _fontFamily);
  static const IconData user = IconData(0xe901, fontFamily: _fontFamily);
  static const IconData settings = IconData(0xe902, fontFamily: _fontFamily);
  static const IconData logout = IconData(0xe903, fontFamily: _fontFamily);
  static const IconData heart = IconData(0xe904, fontFamily: _fontFamily);
}
