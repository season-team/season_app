import 'package:flutter/material.dart';

class SnackbarHelper {
  static void show(
      BuildContext context, {
        required String message,
        Color? backgroundColor,
        Duration duration = const Duration(seconds: 3),
        SnackBarAction? action,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: backgroundColor ?? Colors.black87,
          duration: duration,
          action: action,
          behavior: SnackBarBehavior.fixed,
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, backgroundColor: Colors.green);

  static void error(BuildContext context, String message) =>
      show(context, message: message, backgroundColor: Colors.redAccent);

  static void info(BuildContext context, String message) =>
      show(context, message: message, backgroundColor: Colors.blueAccent);
}
