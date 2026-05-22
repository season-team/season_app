import 'dart:convert';

/// Parses Google ID token JWT payload (no signature verification).
class GoogleIdToken {
  GoogleIdToken._(this.audience, this.email, this.subject);

  final String? audience;
  final String? email;
  final String? subject;

  static GoogleIdToken? parse(String? idToken) {
    if (idToken == null || idToken.isEmpty) return null;
    try {
      final parts = idToken.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final json =
          jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
      return GoogleIdToken._(
        json['aud']?.toString(),
        json['email']?.toString(),
        json['sub']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
