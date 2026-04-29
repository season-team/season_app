import 'package:season_app/core/services/dio_client.dart';
import 'package:season_app/features/groups/data/datasources/groups_datasource.dart';
import 'package:season_app/features/groups/data/models/group_model.dart';
import 'package:season_app/features/groups/data/models/group_member_model.dart';
import 'package:season_app/features/groups/data/models/sos_alert_model.dart';

class GroupsRepository {
  final GroupsRemoteDataSource remoteDataSource;

  GroupsRepository(this.remoteDataSource);

  Future<List<GroupModel>> getAllGroups() async {
    try {
      final response = await remoteDataSource.getAllGroups();
      
      if (response.data['status'] == 200) {
        final List<dynamic> groupsJson = response.data['data'] ?? [];
        return groupsJson.map((json) => GroupModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load groups');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<GroupModel> createGroup({
    required String name,
    String? description,
    int? safetyRadius,
    bool? notificationsEnabled,
  }) async {
    try {
      final response = await remoteDataSource.createGroup(
        name: name,
        description: description,
        safetyRadius: safetyRadius,
        notificationsEnabled: notificationsEnabled,
      );

      if (response.data['status'] == 201 || response.data['status'] == 200) {
        return GroupModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create group');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<Map<String, dynamic>> getGroupDetails(int groupId) async {
    try {
      final response = await remoteDataSource.getGroupDetails(groupId);
      
      if (response.data['status'] == 200) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load group details');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<GroupModel> updateGroup({
    required int groupId,
    String? name,
    String? description,
    int? safetyRadius,
    bool? notificationsEnabled,
  }) async {
    try {
      final response = await remoteDataSource.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        safetyRadius: safetyRadius,
        notificationsEnabled: notificationsEnabled,
      );

      if (response.data['status'] == 200) {
        return GroupModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update group');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<void> deleteGroup(int groupId) async {
    try {
      final response = await remoteDataSource.deleteGroup(groupId);
      
      if (response.data['status'] != 200) {
        throw Exception(response.data['message'] ?? 'Failed to delete group');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<GroupModel> joinGroup(String inviteCode) async {
    try {
      final response = await remoteDataSource.joinGroup(inviteCode);
      
      if (response.data['status'] == 200) {
        return GroupModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to join group');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<Map<String, dynamic>> getInviteDetails(String inviteCode) async {
    try {
      final response = await remoteDataSource.getInviteDetails(inviteCode);
      
      if (response.data['status'] == 200) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load invite details');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<void> leaveGroup(int groupId) async {
    try {
      final response = await remoteDataSource.leaveGroup(groupId);
      
      if (response.data['status'] != 200) {
        throw Exception(response.data['message'] ?? 'Failed to leave group');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<void> removeMember({
    required int groupId,
    required int userId,
  }) async {
    try {
      final response = await remoteDataSource.removeMember(
        groupId: groupId,
        userId: userId,
      );
      
      if (response.data['status'] != 200) {
        throw Exception(response.data['message'] ?? 'Failed to remove member');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<List<GroupMemberModel>> getGroupMembers(int groupId) async {
    try {
      final response = await remoteDataSource.getGroupMembers(groupId);
      
      if (response.data['status'] == 200) {
        final List<dynamic> membersJson = response.data['data'] ?? [];
        return membersJson.map((json) => GroupMemberModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load members');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateLocation({
    required int groupId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await remoteDataSource.updateLocation(
        groupId: groupId,
        latitude: latitude,
        longitude: longitude,
      );
      
      if (response.data['status'] == 200) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update location');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<SosAlertModel> sendSOS({
    required int groupId,
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    try {
      final response = await remoteDataSource.sendSOS(
        groupId: groupId,
        latitude: latitude,
        longitude: longitude,
        message: message,
      );
      
      if (response.data['status'] == 200) {
        return SosAlertModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send SOS');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }

  Future<void> resolveSOS({
    required int groupId,
    required int alertId,
  }) async {
    try {
      final response = await remoteDataSource.resolveSOS(
        groupId: groupId,
        alertId: alertId,
      );
      
      if (response.data['status'] != 200) {
        throw Exception(response.data['message'] ?? 'Failed to resolve SOS');
      }
    } catch (e) {
      throw DioHelper.handleError(e);
    }
  }
}

