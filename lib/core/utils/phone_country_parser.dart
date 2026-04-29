import 'package:country_code_picker/country_code_picker.dart' show CountryCode, codes;

/// Splits API phone strings into a [CountryCode] and national number for the picker + field.
class ParsedPhoneForEdit {
  final CountryCode country;
  final String nationalNumber;

  const ParsedPhoneForEdit({
    required this.country,
    required this.nationalNumber,
  });
}

/// Normalizes [phone] from profile API (E.164, digits-only, or local 0-prefixed) for edit UI.
ParsedPhoneForEdit parseProfilePhoneForEdit(String phone) {
  final defaultCountry = CountryCode.fromCountryCode('SA');
  var raw = phone.trim().replaceAll(RegExp(r'[\s-]'), '');
  if (raw.isEmpty) {
    return ParsedPhoneForEdit(country: defaultCountry, nationalNumber: '');
  }

  // Local Saudi-style mobile without country code (05xxxxxxxx)
  if (raw.startsWith('0') &&
      raw.length >= 9 &&
      !raw.startsWith('00') &&
      RegExp(r'^0\d+$').hasMatch(raw)) {
    final national = raw.startsWith('0') ? raw.substring(1) : raw;
    return ParsedPhoneForEdit(country: defaultCountry, nationalNumber: national);
  }

  if (!raw.startsWith('+')) {
    if (raw.startsWith('00')) {
      raw = '+${raw.substring(2)}';
    } else if (RegExp(r'^\d+$').hasMatch(raw)) {
      raw = '+$raw';
    } else {
      return ParsedPhoneForEdit(country: defaultCountry, nationalNumber: raw);
    }
  }

  final allDigits = raw.substring(1).replaceAll(RegExp(r'\D'), '');
  if (allDigits.isEmpty) {
    return ParsedPhoneForEdit(country: defaultCountry, nationalNumber: '');
  }

  final variants = <({String dialDigits, String iso})>[];
  for (final m in codes) {
    final dc = m['dial_code'] ?? '';
    if (!dc.startsWith('+')) continue;
    final d = dc.substring(1);
    final iso = m['code'] ?? '';
    if (d.isEmpty) continue;
    variants.add((dialDigits: d, iso: iso));
  }
  variants.sort((a, b) => b.dialDigits.length.compareTo(a.dialDigits.length));

  for (final v in variants) {
    if (allDigits.startsWith(v.dialDigits)) {
      var national = allDigits.substring(v.dialDigits.length);
      if (national.startsWith('0')) {
        national = national.substring(1);
      }
      final cc = CountryCode.tryFromCountryCode(v.iso);
      if (cc != null) {
        return ParsedPhoneForEdit(country: cc, nationalNumber: national);
      }
    }
  }

  return ParsedPhoneForEdit(country: defaultCountry, nationalNumber: allDigits);
}

/// International number as digits only (country + national), for comparing API vs form.
/// Example: `966501234567` whether API sent `+966 501...`, `966...`, or `050...`.
String canonicalInternationalPhoneDigits(String phone) {
  if (phone.trim().isEmpty) return '';
  final p = parseProfilePhoneForEdit(phone);
  final dial = (p.country.dialCode ?? '').replaceAll(RegExp(r'\D'), '');
  final nat = p.nationalNumber.replaceAll(RegExp(r'\D'), '');
  return '$dial$nat';
}

/// Same canonical form as [canonicalInternationalPhoneDigits] for the edit-profile fields.
String canonicalInternationalPhoneDigitsFromForm({
  required CountryCode country,
  required String nationalInput,
}) {
  var nat = nationalInput.trim().replaceAll(RegExp(r'\D'), '');
  final dial = (country.dialCode ?? '').replaceAll(RegExp(r'\D'), '');
  if (dial == '966' && nat.startsWith('0')) {
    nat = nat.substring(1);
  }
  return '$dial$nat';
}
