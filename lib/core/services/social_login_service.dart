import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:season_app/core/constants/google_oauth_config.dart';

class SocialLoginService {
  /// [serverClientId] must be the Web client ID so the ID token `aud` matches
  /// what Laravel/backend verifies (same as `GOOGLE_CLIENT_ID` on the server).
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: GoogleOAuthConfig.serverClientId.isEmpty
        ? null
        : GoogleOAuthConfig.serverClientId,
  );

  /// Sign in with Google
  /// Returns a map with user data: {id, email, name, photo, idToken, accessToken}
  ///
  /// Calls [signOut] first so the user always gets the account chooser instead of
  /// silently reusing the last signed-in account.
  static Future<Map<String, String?>> signInWithGoogle() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore; still attempt fresh sign-in so account picker can show.
      }
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (kDebugMode && GoogleOAuthConfig.serverClientId.isEmpty) {
        debugPrint(
          'Google Sign-In: set GOOGLE_SERVER_CLIENT_ID (Web client, same as '
          'backend GOOGLE_CLIENT_ID) or ID token verification may fail.',
        );
      }

      return {
        'id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'photo': googleUser.photoUrl,
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
      };
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign in with Apple
  /// Returns a map with user data: {id, email, name, idToken, authorizationCode}
  /// Note: Apple only provides name on first sign-in
  static Future<Map<String, String?>> signInWithApple() async {
    try {
      // Check if Apple Sign In is available (iOS 13+ or macOS 10.15+)
      if (!Platform.isIOS && !Platform.isMacOS) {
        throw Exception('Apple Sign In is only available on iOS and macOS');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Build full name from given and family name
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

  /// Sign out from Google
  static Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }

  /// Check if Apple Sign In is available
  static bool isAppleSignInAvailable() {
    return Platform.isIOS || Platform.isMacOS;
  }
}

