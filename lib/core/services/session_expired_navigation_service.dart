import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/core/services/auth_service.dart';

/// Central place to clear session and send the user to [Routes.home] (guest shell / login entry).
/// Registered from [routerProvider] with [clearDioTokens] so this file does not import [DioHelper]
/// (avoids circular imports with [dio_client.dart]).
class SessionExpiredNavigationService {
  SessionExpiredNavigationService._();

  static GoRouter? _router;
  static void Function()? _clearDioTokens;
  static bool _redirectInProgress = false;

  static void register({
    required GoRouter router,
    required void Function() clearDioTokens,
  }) {
    _router = router;
    _clearDioTokens = clearDioTokens;
  }

  /// Call when the API indicates the session is no longer valid (e.g. HTTP 401 Unauthenticated).
  static Future<void> handleSessionExpired() async {
    if (_redirectInProgress || _router == null) return;
    _redirectInProgress = true;
    try {
      await AuthService.logout();
      _clearDioTokens?.call();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final router = _router;
        if (router == null) return;
        if (router.state.uri.path == Routes.home) return;
        router.go(Routes.home);
      });
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        _redirectInProgress = false;
      });
    }
  }
}
