/// Prevents duplicate safety-radius (and similar) notifications within a time window.
class NotificationDedup {
  NotificationDedup._();

  static const Duration _window = Duration(seconds: 45);
  static final Map<String, DateTime> _recent = {};

  static String safetyRadiusKey(int groupId, int memberId) =>
      'safety_radius_${groupId}_$memberId';

  static bool shouldShow(String key) {
    final now = DateTime.now();
    _recent.removeWhere(
      (_, time) => now.difference(time) > _window,
    );
    final last = _recent[key];
    if (last != null && now.difference(last) < _window) {
      return false;
    }
    _recent[key] = now;
    return true;
  }
}
