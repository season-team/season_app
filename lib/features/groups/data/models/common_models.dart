// Common models shared across groups feature

class UserInfoModel {
  final int id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final String userStatus;
  final String lastSeen;

  UserInfoModel({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.userStatus = 'offline',
    this.lastSeen = '',
  });

  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? json['photo_url'],
      isOnline: json['is_online'] ?? false,
      userStatus: json['user_status'] ?? json['status'] ?? 'offline',
      lastSeen: json['last_seen'] ?? '',
    );
  }
}

