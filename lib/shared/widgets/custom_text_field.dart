import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/shared/providers/locale_provider.dart';

class CustomTextField extends ConsumerWidget {
  final TextEditingController? controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final bool showCountryPicker;
  final void Function(CountryCode)? onCountryChanged;
  final CountryCode? initialCountry;
  final TextDirection? textDirection;
  final int maxLines;

  const CustomTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.showCountryPicker = false,
    this.onCountryChanged,
    this.textDirection,
    this.initialCountry,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: textDirection ?? (isArabic ? TextDirection.rtl : TextDirection.ltr),
      obscureText: obscureText,
      maxLines: maxLines,
      obscuringCharacter: '●',
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: showCountryPicker
            ? CountryCodePicker(
          key: ValueKey(
            '${initialCountry?.code ?? ''}_${initialCountry?.dialCode ?? ''}',
          ),
          onChanged: onCountryChanged,
          initialSelection: initialCountry?.code ?? 'SA',
          favorite: const ['+966', 'SA', '+20', 'EG'],
          showCountryOnly: false,
          alignLeft: false,
          showOnlyCountryWhenClosed: false,
        )
            : prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6ECF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C8EF5), width: 1.5),
        ),
      ),
    );
  }
}
