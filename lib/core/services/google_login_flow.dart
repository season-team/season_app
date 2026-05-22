import 'package:flutter/foundation.dart';
import 'package:season_app/core/constants/google_oauth_config.dart';
import 'package:season_app/core/services/social_login_service.dart';
import 'package:season_app/core/utils/google_id_token.dart';

/// Obtains Google credentials and calls [apiCall]; retries with alternate Web client if backend rejects token.
class GoogleLoginFlow {
  GoogleLoginFlow._();

  static Future<T> run<T>({
    required Future<T> Function(Map<String, String?> googleData) apiCall,
  }) async {
    Object? lastError;
    String? lastAud;

    for (var i = 0; i < GoogleOAuthConfig.webClientIdsToTry.length; i++) {
      final webClientId = GoogleOAuthConfig.webClientIdsToTry[i];
      try {
        final googleData = await SocialLoginService.signInWithGoogle(
          webClientId: webClientId,
        );
        lastAud = GoogleIdToken.parse(googleData['idToken'])?.audience;
        if (kDebugMode) {
          debugPrint('Google login attempt ${i + 1}: aud=$lastAud client=$webClientId');
        }
        return await apiCall(googleData);
      } catch (e) {
        lastError = e;
        final canRetry = SocialLoginService.isBackendInvalidIdTokenError(e) &&
            i < GoogleOAuthConfig.webClientIdsToTry.length - 1;
        if (!canRetry) break;
        if (kDebugMode) {
          debugPrint('Google login retry with alternate Web client after: $e');
        }
      }
    }

    throw Exception(
      _formatFailureMessage(lastError, lastAud),
    );
  }

  static String _formatFailureMessage(Object? error, String? aud) {
    final base = error?.toString().replaceAll('Exception: ', '') ??
        'Google login failed';
    if (aud != null && aud.isNotEmpty) {
      return 'تسجيل Google فشل لأن السيرفر لا يطابق التوكن.\n'
          'Firebase يعمل — المشكلة في Laravel .env وليس التطبيق.\n\n'
          'على seasonksa.com ضع بالضبط:\n'
          'GOOGLE_CLIENT_ID=$aud\n'
          '(والـ secret لنفس الـ Web client في Google Cloud)\n'
          'ثم: php artisan config:clear';
    }
    return '$base\n\n'
        'حدّث GOOGLE_CLIENT_ID على السيرفر ليطابق aud في التوكن.\n'
        'ثم: php artisan config:clear';
  }
}
