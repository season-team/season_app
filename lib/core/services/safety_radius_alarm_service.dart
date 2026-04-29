import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:season_app/features/groups/data/models/group_member_model.dart';
import 'package:season_app/features/groups/data/models/group_model.dart';
import 'package:season_app/core/services/auth_service.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafetyRadiusAlarmService {
  static final SafetyRadiusAlarmService _instance = SafetyRadiusAlarmService._internal();
  factory SafetyRadiusAlarmService() => _instance;
  SafetyRadiusAlarmService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  Timer? _monitoringTimer;
  Map<int, Map<int, bool>> _previousMemberStatus = {}; // groupId -> {memberId -> isWithinRadius}
  Map<int, int> _groupOwnerIds = {}; // groupId -> ownerId
  bool _isMonitoring = false;
  
  // Track active alarms to prevent duplicates
  final Set<String> _activeAlarms = {}; // Format: "groupId_memberId"
  
  // Dio instance for API calls
  Dio? _dio;

  /// Start continuous monitoring for all groups where user is admin
  Future<void> startContinuousMonitoring() async {
    if (_isMonitoring) {
      debugPrint('⚠️ Safety radius monitoring already active');
      return;
    }

    final currentUserId = AuthService.getUserId();
    if (currentUserId == null) {
      debugPrint('⚠️ User not logged in, monitoring not started');
      return;
    }

    // Initialize Dio for API calls
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      debugPrint('❌ No auth token found');
      return;
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {'Authorization': 'Bearer $token'},
        receiveTimeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    _isMonitoring = true;
    debugPrint('🚨 Starting continuous safety radius monitoring for all admin groups');

    // Create alarm notification channel
    await _createAlarmChannel();

    // Start periodic monitoring (every 10 seconds)
    _monitoringTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _checkAllGroups();
    });

    // Initial check
    await _checkAllGroups();

    debugPrint('✅ Continuous safety radius monitoring started');
  }

  /// Check all groups where user is admin
  Future<void> _checkAllGroups() async {
    if (!_isMonitoring || _dio == null) return;

    final currentUserId = AuthService.getUserId();
    if (currentUserId == null) {
      stopMonitoring();
      return;
    }

    try {
      final response = await _dio!.get(
        ApiEndpoints.groups,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      final data = response.data['data'] as List<dynamic>?;
      
      if (data == null || data.isEmpty) {
        return;
      }

      // Process each group
      for (var groupJson in data) {
        final group = GroupModel.fromJson(groupJson);
        final ownerId = group.ownerId;
        
        // Only monitor groups where current user is admin
        if (currentUserId == ownerId.toString()) {
          await _checkGroupMembers(group.id, ownerId);
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking groups: $e');
      // Continue monitoring even if one check fails
    }
  }

  /// Check members of a specific group
  Future<void> _checkGroupMembers(int groupId, int ownerId) async {
    if (!_isMonitoring || _dio == null) return;

    try {
      final response = await _dio!.get(
        ApiEndpoints.groupById.replaceFirst('{id}', groupId.toString()),
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      final details = response.data['data'] ?? response.data;
      
      if (details == null) return;

      // Store owner ID for this group
      _groupOwnerIds[groupId] = ownerId;

      // Parse members
      final List<GroupMemberModel> members = [];
      if (details['members'] != null) {
        for (var memberJson in details['members']) {
          members.add(GroupMemberModel.fromJson(memberJson));
        }
      }

      // Update member statuses and check for alarms
      await updateMemberStatuses(groupId, members);
    } catch (e) {
      debugPrint('❌ Error checking group $groupId members: $e');
      // Continue monitoring other groups even if one fails
    }
  }

  /// Start monitoring safety radius for a specific group (legacy method, kept for compatibility)
  Future<void> startMonitoring(int groupId, List<GroupMemberModel> members, int ownerId) async {
    // This method is kept for backward compatibility but doesn't start monitoring
    // Use startContinuousMonitoring() instead for continuous monitoring
    debugPrint('⚠️ startMonitoring() called but continuous monitoring should be used');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _previousMemberStatus.clear();
    _groupOwnerIds.clear();
    _activeAlarms.clear();
    _dio = null;
    debugPrint('🛑 Safety radius monitoring stopped');
  }

  /// Update member statuses and check for out-of-range transitions
  Future<void> updateMemberStatuses(int groupId, List<GroupMemberModel> members) async {
    if (!_isMonitoring) return;

    // Verify user is still admin
    final ownerId = _groupOwnerIds[groupId];
    final currentUserId = AuthService.getUserId();
    if (ownerId == null || currentUserId == null || currentUserId != ownerId.toString()) {
      debugPrint('⚠️ User is not group admin, skipping alarm check');
      return;
    }

    // Initialize previous statuses if not exists
    if (_previousMemberStatus[groupId] == null) {
      _previousMemberStatus[groupId] = {};
    }

    final previousStatuses = _previousMemberStatus[groupId]!;
    
    for (var member in members) {
      // Skip checking the owner/admin themselves
      if (member.id == ownerId) continue;

      // Skip if member data is invalid
      if (member.user.name.isEmpty) continue;

      final previousStatus = previousStatuses[member.id] ?? true;
      final currentStatus = member.isWithinRadius;

      // Detect transition from "in range" to "out of range"
      if (previousStatus && !currentStatus) {
        debugPrint('🚨 ALERT: Member ${member.user.name} (ID: ${member.id}) went OUT OF RANGE!');
        await _triggerAlarm(groupId, member);
      }
      // Detect transition from "out of range" to "in range" - cancel any active alarms
      else if (!previousStatus && currentStatus) {
        debugPrint('✅ Member ${member.user.name} (ID: ${member.id}) is back IN RANGE');
        await cancelAlarm(groupId, member.id);
      }

      // Update stored status
      _previousMemberStatus[groupId]![member.id] = currentStatus;
    }
  }

  /// Create alarm notification channel
  /// NOTE: Channel is created natively in MainActivity.kt with system alarm sound
  /// This method is kept for compatibility but the channel is already created natively
  Future<void> _createAlarmChannel() async {
    // Channel is created natively in MainActivity.kt with system alarm sound
    // No need to create it here - it's already configured with alarm sound
    debugPrint('✅ Alarm channel already exists (created natively with alarm sound)');
  }

  /// Trigger alarm notification with system default sound
  Future<void> _triggerAlarm(int groupId, GroupMemberModel member) async {
    try {
      // Prevent duplicate alarms for the same member
      final alarmKey = '${groupId}_${member.id}';
      if (_activeAlarms.contains(alarmKey)) {
        debugPrint('⚠️ Alarm already active for member ${member.user.name}, skipping');
        return;
      }

      // Ensure alarm channel exists
      await _createAlarmChannel();

      // Prepare alarm notification details with SYSTEM ALARM SOUND
      // Use UriAndroidNotificationSound to specify the system alarm sound
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'safety_radius_alarm_channel',
        'Safety Radius Alarms',
        channelDescription: 'High-priority alarms when group members go out of safety radius',
        importance: Importance.high, // Match native channel importance
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        ongoing: false,
        autoCancel: true,
        category: AndroidNotificationCategory.alarm,
        // Sound is set on the channel via native Android code (MainActivity.kt)
        // This ensures the system alarm sound is used
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'alarm.caf', // Custom alarm sound file (add alarm.caf to ios/Runner/)
        interruptionLevel: InterruptionLevel.critical,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the alarm notification with unique ID
      final notificationId = groupId * 1000 + member.id; // Unique ID for each member alarm
      final uniqueNotificationId = (notificationId.abs() % 2147483647).toInt();
      
      await _localNotifications.show(
        uniqueNotificationId,
        '🚨 Safety Alert',
        '${member.user.name} is outside the safety radius!',
        notificationDetails,
      );

      // Mark alarm as active
      _activeAlarms.add(alarmKey);

      debugPrint('🚨 Alarm triggered for ${member.user.name} (Group: $groupId)');
      debugPrint('   Notification ID: $uniqueNotificationId');
      debugPrint('   Channel: safety_radius_alarm_channel');
      debugPrint('   Play Sound: true, Category: alarm');
    } catch (e) {
      debugPrint('❌ Error triggering alarm: $e');
    }
  }

  /// Cancel alarm for a specific member
  Future<void> cancelAlarm(int groupId, int memberId) async {
    try {
      final notificationId = groupId * 1000 + memberId;
      await _localNotifications.cancel(notificationId);
      
      // Remove from active alarms set
      final alarmKey = '${groupId}_${memberId}';
      _activeAlarms.remove(alarmKey);
      
      debugPrint('✅ Alarm cancelled for member $memberId (Group: $groupId)');
    } catch (e) {
      debugPrint('❌ Error cancelling alarm: $e');
    }
  }

  /// Cancel all alarms for a group
  Future<void> cancelAllAlarms(int groupId) async {
    final previousStatuses = _previousMemberStatus[groupId] ?? {};
    for (var memberId in previousStatuses.keys) {
      await cancelAlarm(groupId, memberId);
    }
  }
}

