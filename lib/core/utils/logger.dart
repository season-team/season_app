import 'package:flutter/foundation.dart';

/// Logger موحد للتطبيق بالكامل
class AppLogger {
  static void info(String message) {
    _log('ℹ️ INFO', message);
  }

  static void warning(String message) {
    _log('⚠️ WARNING', message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('❌ ERROR', message);
    if (error != null) debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
  }

  static void success(String message) {
    _log('✅ SUCCESS', message);
  }

  static void _log(String level, String message) {
    final time = DateTime.now().toIso8601String();
    debugPrint('[$level - $time] $message');
  }
}
