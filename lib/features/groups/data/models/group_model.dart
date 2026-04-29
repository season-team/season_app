class GroupModel {
  final int id;
  final String name;
  final String? description;
  final int ownerId;
  final String inviteCode;
  final String? qrCode;
  final int safetyRadius;
  final bool notificationsEnabled;
  final bool isActive;
  final int membersCount;
  final int outOfRangeCount;
  final DateTime createdAt;
  final OwnerModel? owner;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.inviteCode,
    this.qrCode,
    required this.safetyRadius,
    required this.notificationsEnabled,
    required this.isActive,
    required this.membersCount,
    required this.outOfRangeCount,
    required this.createdAt,
    this.owner,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      ownerId: json['owner_id'] ?? 0,
      inviteCode: json['invite_code'] ?? '',
      qrCode: json['qr_code'],
      safetyRadius: json['safety_radius'] ?? 100,
      notificationsEnabled: json['notifications_enabled'] ?? true,
      isActive: json['is_active'] ?? true,
      membersCount: json['members_count'] ?? 0,
      outOfRangeCount: json['out_of_range_count'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      owner: json['owner'] != null ? OwnerModel.fromJson(json['owner']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'invite_code': inviteCode,
      'qr_code': qrCode,
      'safety_radius': safetyRadius,
      'notifications_enabled': notificationsEnabled,
      'is_active': isActive,
      'members_count': membersCount,
      'out_of_range_count': outOfRangeCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class OwnerModel {
  final int id;
  final String name;
  final String? avatar;

  OwnerModel({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    return OwnerModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      avatar: json['avatar'],
    );
  }
}

