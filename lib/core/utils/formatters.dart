import 'package:flutter/services.dart';

class Formatters {
  static TextInputFormatter onlyNumbers() {
    return FilteringTextInputFormatter.digitsOnly;
  }

  static TextInputFormatter onlyLetters() {
    return FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\u0600-\u06FF\s]'));
  }

  static TextInputFormatter noSpaces() {
    return FilteringTextInputFormatter.deny(RegExp(r'\s'));
  }

  static String formatPhone(String phone) {
    // Adds spaces every 3 digits like: 010 123 4567
    return phone.replaceAllMapped(RegExp(r'.{3}'), (match) => '${match.group(0)} ').trim();
  }

  static String formatPrice(num number) {
    return '${number.toStringAsFixed(2)} EGP';
  }
}
