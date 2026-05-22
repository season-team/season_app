import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/core/router/routes.dart';

/// Routes the user when they tap a push/local notification.
class NotificationNavigationService {
  NotificationNavigationService._();

  static GoRouter? _router;
  static Map<String, dynamic>? _pendingData;

  static void register(GoRouter router) {
    _router = router;
    if (_pendingData != null) {
      handle(_pendingData!);
      _pendingData = null;
    }
  }

  /// Navigate from notification [data] payload (FCM or local).
  static void handle(Map<String, dynamic> data) {
    final path = _resolvePath(data);
    if (path == null) return;

    final router = _router;
    if (router == null) {
      _pendingData = data;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (router.state.uri.path == path) return;
      router.go(path);
    });
  }

  /// Call after app shell is ready (e.g. [MainScreen]).
  static void consumePending() {
    if (_pendingData == null) return;
    final data = _pendingData!;
    _pendingData = null;
    handle(data);
  }

  static String? _resolvePath(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['notification_type'] ?? '')
        .toString()
        .toLowerCase();
    final groupId = data['group_id']?.toString();

    switch (type) {
      case 'safety_radius_alert':
      case 'safety_radius':
        if (groupId != null && groupId.isNotEmpty) {
          return '/groups/$groupId';
        }
        return '${Routes.home}?tab=groups';
      case 'sos':
      case 'sos_alert':
        if (groupId != null && groupId.isNotEmpty) {
          return '/groups/$groupId/sos';
        }
        return '${Routes.home}?tab=groups';
      case 'group':
      case 'group_invite':
      case 'group_update':
        if (groupId != null && groupId.isNotEmpty) {
          return '/groups/$groupId';
        }
        return '${Routes.home}?tab=groups';
      case 'message':
      case 'new_message':
      case 'chat':
        return '${Routes.home}?tab=reminders';
      case 'emergency':
        return Routes.emergency;
      case 'announcement':
      case 'broadcast':
        return Routes.home;
      default:
        if (groupId != null && groupId.isNotEmpty) {
          return '/groups/$groupId';
        }
        return Routes.home;
    }
  }
}
