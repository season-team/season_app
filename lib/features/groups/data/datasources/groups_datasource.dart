import 'package:dio/dio.dart';

class GroupsRemoteDataSource {
  final Dio dio;

  GroupsRemoteDataSource(this.dio);

  // Get all user's groups
  Future<Response> getAllGroups() async {
    final response = await dio.get('/groups');
    return response;
  }

  // Create new group
  Future<Response> createGroup({
    required String name,
    String? description,
    int? safetyRadius,
    bool? notificationsEnabled,
  }) async {
    final data = {
      'name': name,
      if (description != null) 'description': description,
      if (safetyRadius != null) 'safety_radius': safetyRadius,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
    };

    final response = await dio.post('/groups', data: data);
    return response;
  }

  // Get group details
  Future<Response> getGroupDetails(int groupId) async {
    final response = await dio.get('/groups/$groupId');
    return response;
  }

  // Update group
  Future<Response> updateGroup({
    required int groupId,
    String? name,
    String? description,
    int? safetyRadius,
    bool? notificationsEnabled,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (safetyRadius != null) data['safety_radius'] = safetyRadius;
    if (notificationsEnabled != null) {
      data['notifications_enabled'] = notificationsEnabled;
    }

    final response = await dio.put('/groups/$groupId', data: data);
    return response;
  }

  // Delete group
  Future<Response> deleteGroup(int groupId) async {
    final response = await dio.delete('/groups/$groupId');
    return response;
  }

  // Join group by invite code
  Future<Response> joinGroup(String inviteCode) async {
    final data = {'invite_code': inviteCode};
    final response = await dio.post('/groups/join', data: data);
    return response;
  }

  // Get invite details (no auth required)
  Future<Response> getInviteDetails(String inviteCode) async {
    final response = await dio.get('/groups/invite/$inviteCode');
    return response;
  }

  // Leave group
  Future<Response> leaveGroup(int groupId) async {
    final response = await dio.post('/groups/$groupId/leave');
    return response;
  }

  // Remove member (owner only)
  Future<Response> removeMember({
    required int groupId,
    required int userId,
  }) async {
    final response = await dio.delete('/groups/$groupId/members/$userId');
    return response;
  }

  // Get group members
  Future<Response> getGroupMembers(int groupId) async {
    final response = await dio.get('/groups/$groupId/members');
    return response;
  }

  // Update location
  Future<Response> updateLocation({
    required int groupId,
    required double latitude,
    required double longitude,
  }) async {
    final data = {
      'latitude': latitude,
      'longitude': longitude,
    };
    final response = await dio.post('/groups/$groupId/location', data: data);
    return response;
  }

  // Send SOS alert
  Future<Response> sendSOS({
    required int groupId,
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    final data = {
      'latitude': latitude,
      'longitude': longitude,
      if (message != null) 'message': message,
    };
    final response = await dio.post('/groups/$groupId/sos', data: data);
    return response;
  }

  // Resolve SOS alert
  Future<Response> resolveSOS({
    required int groupId,
    required int alertId,
  }) async {
    final response =
        await dio.post('/groups/$groupId/sos/$alertId/resolve');
    return response;
  }
}

