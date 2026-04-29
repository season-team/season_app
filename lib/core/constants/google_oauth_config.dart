/// Web OAuth 2.0 client ID — must match the backend `GOOGLE_CLIENT_ID` used to
/// verify ID tokens (the "Web application" client in Google Cloud Console).
///
/// Run / build with:
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_ID.apps.googleusercontent.com`
class GoogleOAuthConfig {
  GoogleOAuthConfig._();

  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
