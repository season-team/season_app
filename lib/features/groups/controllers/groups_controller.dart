import 'package:riverpod/riverpod.dart';
import 'package:season_app/features/groups/data/models/group_model.dart';
import 'package:season_app/features/groups/data/models/group_member_model.dart';
import 'package:season_app/features/groups/data/models/sos_alert_model.dart';
import 'package:season_app/features/groups/data/models/common_models.dart';
import 'package:season_app/features/groups/data/repositories/groups_repository.dart';
import 'package:season_app/features/groups/providers.dart';
import 'package:season_app/core/services/background_location_service.dart';

class GroupsState {
  final List<GroupModel> groups;
  final GroupModel? selectedGroup;
  final List<GroupMemberModel> members;
  final List<SosAlertModel> sosAlerts;
  final bool isLoading;
  final bool isCreating;
  final bool isJoining;
  final String? error;
  final String? message;

  GroupsState({
    this.groups = const [],
    this.selectedGroup,
    this.members = const [],
    this.sosAlerts = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isJoining = false,
    this.error,
    this.message,
  });

  GroupsState copyWith({
    List<GroupModel>? groups,
    GroupModel? selectedGroup,
    List<GroupMemberModel>? members,
    List<SosAlertModel>? sosAlerts,
    bool? isLoading,
    bool? isCreating,
    bool? isJoining,
    String? error,
    String? message,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      members: members ?? this.members,
      sosAlerts: sosAlerts ?? this.sosAlerts,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isJoining: isJoining ?? this.isJoining,
      error: error,
      message: message,
    );
  }
}

class GroupsController extends Notifier<GroupsState> {
  late GroupsRepository repository;

  @override
  GroupsState build() {
    repository = ref.read(groupsRepositoryProvider);
    return GroupsState();
  }

  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final groups = await repository.getAllGroups();
      state = state.copyWith(
        groups: groups,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createGroup({
    required String name,
    String? description,
    int? safetyRadius,
    bool? notificationsEnabled,
  }) async {
    state = state.copyWith(isCreating: true, error: null);
    
    try {
      final newGroup = await repository.createGroup(
        name: name,
        description: description,
        safetyRadius: safetyRadius,
        notificationsEnabled: notificationsEnabled,
      );
      
      final updatedGroups = List<GroupModel>.from(state.groups)..add(newGroup);
      state = state.copyWith(
        groups: updatedGroups,
        isCreating: false,
        message: 'تم إنشاء المجموعة بنجاح',
      );
      
      // Refresh group IDs for background location tracking
      await refreshGroupIds();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> loadGroupDetails(int groupId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final details = await repository.getGroupDetails(groupId);
      final group = GroupModel.fromJson(details);
      
      final List<GroupMemberModel> members = [];
      
      // Process members from members array (this includes the owner)
      if (details['members'] != null) {
        for (var memberJson in details['members']) {
          members.add(GroupMemberModel.fromJson(memberJson));
        }
      }
      
      // If no members array but owner exists, add owner as first member
      if (members.isEmpty && details['owner'] != null) {
        final ownerData = details['owner'];
        final ownerMember = GroupMemberModel(
          id: ownerData['id'] ?? 0,
          user: UserInfoModel.fromJson(ownerData),
          role: 'owner',
          status: 'active',
          isWithinRadius: true, // Owner is always within radius
          outOfRangeCount: 0,
          latestLocation: null,
          joinedAt: null,
          isOnline: ownerData['is_online'] ?? false,
          userStatus: ownerData['status'] ?? 'offline',
          lastSeen: ownerData['last_seen'] ?? '',
        );
        members.add(ownerMember);
      }
      
      final List<SosAlertModel> sosAlerts = [];
      if (details['active_sos_alerts'] != null) {
        for (var alertJson in details['active_sos_alerts']) {
          sosAlerts.add(SosAlertModel.fromJson(alertJson));
        }
      }
      
      state = state.copyWith(
        selectedGroup: group,
        members: members,
        sosAlerts: sosAlerts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> joinGroup(String inviteCode) async {
    state = state.copyWith(isJoining: true, error: null);
    
    try {
      final group = await repository.joinGroup(inviteCode);
      final updatedGroups = List<GroupModel>.from(state.groups)..add(group);
      
      state = state.copyWith(
        groups: updatedGroups,
        isJoining: false,
        message: 'تم الانضمام للمجموعة بنجاح',
      );
      
      // Refresh group IDs for background location tracking
      await refreshGroupIds();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isJoining: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> leaveGroup(int groupId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await repository.leaveGroup(groupId);
      final updatedGroups = state.groups.where((g) => g.id != groupId).toList();
      
      state = state.copyWith(
        groups: updatedGroups,
        isLoading: false,
        message: 'تم مغادرة المجموعة بنجاح',
      );
      
      // Refresh group IDs for background location tracking
      await refreshGroupIds();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateGroup({
    required int groupId,
    String? name,
    String? description,
    int? safetyRadius,
    bool? notificationsEnabled,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedGroup = await repository.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        safetyRadius: safetyRadius,
        notificationsEnabled: notificationsEnabled,
      );
      
      final updatedGroups = state.groups.map((g) {
        return g.id == groupId ? updatedGroup : g;
      }).toList();
      
      state = state.copyWith(
        groups: updatedGroups,
        selectedGroup: updatedGroup,
        isLoading: false,
        message: 'تم تحديث المجموعة بنجاح',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteGroup(int groupId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await repository.deleteGroup(groupId);
      final updatedGroups = state.groups.where((g) => g.id != groupId).toList();
      
      state = state.copyWith(
        groups: updatedGroups,
        isLoading: false,
        message: 'تم حذف المجموعة بنجاح',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> sendSOS({
    required int groupId,
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    try {
      final alert = await repository.sendSOS(
        groupId: groupId,
        latitude: latitude,
        longitude: longitude,
        message: message,
      );
      
      final updatedAlerts = List<SosAlertModel>.from(state.sosAlerts)..add(alert);
      state = state.copyWith(
        sosAlerts: updatedAlerts,
        message: 'تم إرسال إشارة SOS بنجاح',
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> resolveSOS({
    required int groupId,
    required int alertId,
  }) async {
    try {
      await repository.resolveSOS(groupId: groupId, alertId: alertId);
      final updatedAlerts = state.sosAlerts.where((a) => a.id != alertId).toList();
      
      state = state.copyWith(
        sosAlerts: updatedAlerts,
        message: 'تم إغلاق إشارة SOS',
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeMember({
    required int groupId,
    required int userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await repository.removeMember(groupId: groupId, userId: userId);
      
      // Update members list
      final updatedMembers = state.members.where((m) => m.user.id != userId).toList();
      
      state = state.copyWith(
        members: updatedMembers,
        isLoading: false,
        message: 'تم إزالة العضو بنجاح',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateLocation({
    required int groupId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await repository.updateLocation(
        groupId: groupId,
        latitude: latitude,
        longitude: longitude,
      );
      return true;
    } catch (e) {
      // Silent fail for location updates
      print('Location update error: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearMessage() {
    state = state.copyWith(message: null);
  }

  // Clear all groups data (for logout)
  void clearAllData() {
    state = GroupsState();
  }
}

