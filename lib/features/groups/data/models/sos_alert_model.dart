import 'common_models.dart';

class SosAlertModel {
  final int id;
  final int groupId;
  final UserInfoModel user;
  final String message;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  SosAlertModel({
    required this.id,
    required this.groupId,
    required this.user,
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    return SosAlertModel(
      id: _parseInt(json['id']),
      groupId: _parseInt(json['group_id']),
      user: UserInfoModel.fromJson(json['user'] ?? {}),
      message: json['message'] ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

