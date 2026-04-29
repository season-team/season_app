import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider =
StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('locale') ?? 'ar';
      state = Locale(langCode);
    } catch (e) {
      // If there's an error loading, default to Arabic
      state = const Locale('ar');
    }
  }

  Future<void> setLocale(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', languageCode);
      state = Locale(languageCode);
    } catch (e) {
      // If there's an error saving, still update the state
      state = Locale(languageCode);
    }
  }

  bool get isArabic => state.languageCode == 'ar';
  bool get isEnglish => state.languageCode == 'en';
  
  /// Get current language code
  String get currentLanguageCode => state.languageCode;
  
  /// Get current language name
  String get currentLanguageName => isArabic ? 'Arabic' : 'English';
}
