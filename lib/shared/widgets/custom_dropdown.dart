import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/shared/providers/locale_provider.dart';

class CustomDropdown extends ConsumerWidget {
  final String hintText;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;

  const CustomDropdown({
    super.key,
    required this.hintText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((e) => DropdownMenuItem<String>(
                value: e.value,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  child: e.child,
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
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
      isExpanded: true,
      borderRadius: BorderRadius.circular(14),
      dropdownColor: Colors.white,
      menuMaxHeight: 320,
      icon: Icon(
         Icons.arrow_forward_ios,
        size: 16,
      ),
    );
  }
}

