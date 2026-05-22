import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:season_app/core/constants/google_oauth_config.dart';
import 'package:season_app/core/utils/google_id_token.dart';

class SocialLoginService {
  /// Web client ID — must match Laravel `GOOGLE_CLIENT_ID` (token `aud` claim).
  static const List<String> _scopes = ['email', 'profile', 'openid'];

  static GoogleSignIn _createGoogleSignIn(String webClientId) {
    if (kDebugMode) {
      debugPrint('GoogleSignIn serverClientId (must match backend GOOGLE_CLIENT_ID): $webClientId');
    }

    if (kIsWeb) {
      return GoogleSignIn(
        clientId: webClientId.isEmpty ? null : webClientId,
        scopes: _scopes,
      );
    }

    return GoogleSignIn(
      scopes: _scopes,
      serverClientId: webClientId,
      forceCodeForRefreshToken: true,
    );
  }

  /// Sign in with Google using a specific Web client ID ([webClientId]).
  static Future<Map<String, String?>> signInWithGoogle({String? webClientId}) async {
    final clientId = webClientId ?? GoogleOAuthConfig.serverClientId;
    if (!GoogleOAuthConfig.isConfigured && clientId.isEmpty) {
      throw Exception(kIsWeb ? _missingWebClientIdMessage : _missingClientIdMessage);
    }
    if (clientId.isEmpty) {
      throw Exception(_missingClientIdMessage);
    }

    final expectedAud = clientId;
    final googleSignIn = _createGoogleSignIn(clientId);

    try {
      try {
        await googleSignIn.disconnect();
      } catch (_) {}
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(_missingIdTokenMessage);
      }

      final parsed = GoogleIdToken.parse(idToken);
      if (kDebugMode && parsed != null) {
        debugPrint(
          'Google idToken aud=${parsed.audience} (expected $expectedAud) email=${parsed.email}',
        );
      }

      if (parsed?.audience != null && parsed!.audience != expectedAud) {
        throw Exception(
          'Google ID token audience لا يطابق إعداد التطبيق.\n'
          'aud في التوكن: ${parsed.audience}\n'
          'المطلوب (نفس GOOGLE_CLIENT_ID على السيرفر): $expectedAud\n'
          'حدّث Laravel .env أو lib/core/constants/google_oauth_local.dart لنفس القيمة.',
        );
      }

      return {
        'id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'photo': googleUser.photoUrl,
        'idToken': idToken,
        'accessToken': googleAuth.accessToken,
      };
    } on PlatformException catch (e) {
      debugPrint('Error signing in with Google: ${e.code} ${e.message}');
      if (e.code == 'sign_in_failed' &&
          (e.message?.contains('Api10') == true ||
              e.message?.contains('10:') == true ||
              e.message?.toLowerCase().contains('developer_error') == true)) {
        throw Exception(_androidConfigErrorMessage);
      }
      throw Exception(e.message ?? e.code);
    } catch (e, stack) {
      debugPrint('Error signing in with Google: $e\n$stack');
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg.toLowerCase().contains('invalid google id token')) {
        throw Exception(_backendRejectedTokenMessage);
      }
      throw Exception(msg);
    }
  }

  static const String _missingClientIdMessage =
      'مطلوب Google Web Client ID في google_oauth_local.dart '
      '(نفس GOOGLE_CLIENT_ID على السيرفر).';

  static const String _missingIdTokenMessage =
      'لم يُرجع Google ID token. تأكد من serverClientId وإعداد SHA-1 على Android.';

  static const String _backendRejectedTokenMessage =
      'السيرفر رفض Google ID token — GOOGLE_CLIENT_ID على Laravel لا يطابق aud في التوكن.';

  static const String _androidConfigErrorMessage =
      'إعداد Google Sign-In على Android غير مكتمل.\n'
      'أضف SHA-1 في Firebase ثم حمّل google-services.json جديد.';

  static const String _missingWebClientIdMessage =
      'مطلوب Google Web Client ID في google_oauth_local.dart';

  /// Sign in with Apple
  static Future<Map<String, String?>> signInWithApple() async {
    try {
      if (!isAppleSignInAvailable()) {
        throw Exception('Apple Sign In is only available on iOS and macOS');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      String? fullName;
      if (credential.givenName != null || credential.familyName != null) {
        fullName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        if (fullName.isEmpty) fullName = null;
      }

      return {
        'id': credential.userIdentifier,
        'email': credential.email,
        'name': fullName,
        'idToken': credential.identityToken,
        'authorizationCode': credential.authorizationCode,
      };
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      rethrow;
    }
  }

  /// True when Laravel rejected the ID token (audience / GOOGLE_CLIENT_ID mismatch).
  static bool isBackendInvalidIdTokenError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('invalid google id token') ||
        message.contains('failed to verify google token');
  }

  static Future<void> signOutGoogle() async {
    try {
      final googleSignIn = _createGoogleSignIn(GoogleOAuthConfig.serverClientId);
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }

  static bool isAppleSignInAvailable() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}
