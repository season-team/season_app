import 'common_models.dart';

class GroupMemberModel {
  final int id;
  final UserInfoModel user;
  final String role;
  final String status;
  final bool isWithinRadius;
  final int outOfRangeCount;
  final LocationModel? latestLocation;
  final DateTime? joinedAt;
  // Online/Offline status fields
  final bool isOnline;
  final String userStatus;
  final String lastSeen;

  GroupMemberModel({
    required this.id,
    required this.user,
    required this.role,
    required this.status,
    required this.isWithinRadius,
    required this.outOfRangeCount,
    this.latestLocation,
    this.joinedAt,
    this.isOnline = false,
    this.userStatus = 'offline',
    this.lastSeen = '',
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    // Some APIs return member fields flat (id, name, ...), others nest them under 'user'.
    final bool hasNestedUser = json['user'] is Map<String, dynamic>;
    final Map<String, dynamic> userData = hasNestedUser
        ? (json['user'] as Map<String, dynamic>)
        : {
            'id': json['id'],
            'name': json['name'],
            'avatar': json['avatar'],
            'photo_url': json['photo_url'],
            'is_online': json['is_online'],
            // API may send either 'user_status' or 'status' for user presence
            'user_status': json['user_status'] ?? json['status'],
            'last_seen': json['last_seen'],
          };
    return GroupMemberModel(
      id: json['id'] ?? (userData['id'] ?? 0),
      user: UserInfoModel.fromJson(userData),
      role: json['role'] ?? 'member',
      status: json['status'] ?? 'active',
      isWithinRadius: json['is_within_radius'] ?? true,
      outOfRangeCount: json['out_of_range_count'] ?? 0,
      latestLocation: json['latest_location'] != null
          ? LocationModel.fromJson(json['latest_location'])
          : null,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : null,
      // Online/Offline status from user object within member
      isOnline: userData['is_online'] ?? false,
      userStatus: userData['user_status'] ?? userData['status'] ?? 'offline',
      lastSeen: userData['last_seen'] ?? '',
    );
  }
}

class LocationModel {
  final double latitude;
  final double longitude;
  final double distanceFromCenter;
  final bool isWithinRadius;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.distanceFromCenter,
    required this.isWithinRadius,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      distanceFromCenter: _parseDouble(json['distance_from_center']),
      isWithinRadius: json['is_within_radius'] ?? true,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

