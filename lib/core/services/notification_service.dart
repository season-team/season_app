import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:season_app/core/services/auth_service.dart';
import 'package:season_app/core/services/dio_client.dart';
import 'package:season_app/core/services/notification_dedup.dart';
import 'package:season_app/core/services/notification_navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel _androidNotificationChannel =
    MethodChannel('season_app/notifications');

/// Background message handler - must be a top-level function
/// This runs in a separate isolate when app is terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Android: AlarmNotificationService handles all FCM in native code.
  if (Platform.isAndroid) return;

  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('📩 Background Message Received (App Closed/Terminated)');
  debugPrint('📩 Message ID: ${message.messageId}');
  debugPrint('📩 Title: ${message.notification?.title}');
  debugPrint('📩 Body: ${message.notification?.body}');
  debugPrint('📩 Data: ${message.data}');
  
  try {
    final flutterLocalNotifications = FlutterLocalNotificationsPlugin();
    
    // Initialize local notifications plugin
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await flutterLocalNotifications.initialize(initSettings);
    
    // CRITICAL: Create notification channels BEFORE showing notifications
    // This ensures channels exist even when app is terminated
    if (Platform.isAndroid) {
      await _createNotificationChannelsForBackground(flutterLocalNotifications);
    }
  
    // Check if this is a safety radius alarm
  final isSafetyRadiusAlarm = message.data['type'] == 'safety_radius_alert' ||
      message.data['notification_type'] == 'safety_radius_alert';
  
  final isAdmin = message.data['is_admin'] == 'true' ||
      message.data['is_owner'] == 'true' ||
      message.data['for_admin'] == 'true';

  if (isSafetyRadiusAlarm && isAdmin) {
    final groupId = int.tryParse(message.data['group_id']?.toString() ?? '');
    final memberId = int.tryParse(message.data['member_id']?.toString() ?? '');
    if (groupId != null && memberId != null) {
      final key = NotificationDedup.safetyRadiusKey(groupId, memberId);
      if (!NotificationDedup.shouldShow(key)) return;
    }
    await _showBackgroundSafetyAlarm(flutterLocalNotifications, message);
    return;
  }

  // Regular notifications (iOS background / data-only)
  if (message.notification != null) {
    // Regular notification
    const androidDetails = AndroidNotificationDetails(
      'season_app_channel',
      'Season App Notifications',
      channelDescription: 'Notifications from Season App',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Season App',
      message.notification?.body ?? '',
      notificationDetails,
    );
    debugPrint('✅ Local notification shown in background');
  } else {
    // If no notification object, show from data payload
    if (message.data.isNotEmpty) {
      final title = message.data['title'] ?? 'Season App';
      final body = message.data['body'] ?? message.data['message'] ?? 'New notification';
      
      const androidDetails = AndroidNotificationDetails(
        'season_app_channel',
        'Season App Notifications',
        channelDescription: 'Notifications from Season App',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);
      await flutterLocalNotifications.show(
        message.hashCode,
        title.toString(),
        body.toString(),
        notificationDetails,
      );
      debugPrint('✅ Local notification shown from data payload');
    } else {
      debugPrint('⚠️ No notification data to display');
    }
  }
  } catch (e, stackTrace) {
    debugPrint('❌ Error in background message handler: $e');
    debugPrint('❌ Stack trace: $stackTrace');
  }
}

/// Create notification channels for background handler
/// This ensures channels exist when app is terminated
Future<void> _createNotificationChannelsForBackground(
  FlutterLocalNotificationsPlugin flutterLocalNotifications,
) async {
  try {
    // Create regular notification channel
    const AndroidNotificationChannel regularChannel = AndroidNotificationChannel(
      'season_app_channel',
      'Season App Notifications',
      description: 'Notifications from Season App',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await flutterLocalNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(regularChannel);

    debugPrint('✅ Regular notification channel created in background handler');
    
    // NOTE: Alarm channel is created by native AlarmNotificationService
    // We don't create it here to avoid overwriting the native channel with alarm sound
    // The native service creates the channel with proper alarm sound URI
    debugPrint('ℹ️ Alarm channel is created by native AlarmNotificationService with alarm sound');
  } catch (e) {
    debugPrint('❌ Error creating notification channels in background: $e');
  }
}

Future<void> _showBackgroundSafetyAlarm(
  FlutterLocalNotificationsPlugin plugin,
  RemoteMessage message,
) async {
  const alarmChannel = AndroidNotificationChannel(
    'safety_radius_alarm_channel',
    'Safety Radius Alarms',
    description: 'High-priority alarms when group members go out of safety radius',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alarmChannel);

  final title = message.data['title']?.toString() ?? '🚨 Safety Alert';
  final body = message.data['body']?.toString() ??
      'A group member is outside the safety radius!';
  final groupId = int.tryParse(message.data['group_id']?.toString() ?? '');
  final notificationId = groupId ?? message.hashCode;

  const androidDetails = AndroidNotificationDetails(
    'safety_radius_alarm_channel',
    'Safety Radius Alarms',
    channelDescription: 'Safety radius alarms',
    importance: Importance.high,
    priority: Priority.max,
    playSound: true,
    category: AndroidNotificationCategory.alarm,
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.critical,
  );
  await plugin.show(
    notificationId,
    title,
    body,
    const NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: jsonEncode(message.data),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static bool get _pushSupported => !kIsWeb;

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  FirebaseMessaging get _messaging =>
      _firebaseMessaging ??= FirebaseMessaging.instance;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// FCM token for auth APIs; null on web (Firebase push is not configured).
  Future<String?> getTokenForAuth() async {
    if (!_pushSupported) return null;
    await ensureInitialized();
    if (_fcmToken == null) {
      await _getFCMToken();
    }
    return await getSavedFCMToken() ?? fcmToken;
  }

  /// Ensures permissions, channels, and FCM token are ready.
  Future<void> ensureInitialized() async {
    if (!_pushSupported || _isInitialized) return;
    try {
      await initialize();
    } catch (e) {
      debugPrint('⚠️ Notification init failed in ensureInitialized: $e');
    }
  }

  /// After login: topics + sync token to backend.
  Future<void> onUserLoggedIn({String? userId}) async {
    if (!_pushSupported) return;
    await ensureInitialized();
    await subscribeToAllUsers();
    if (userId != null && userId.isNotEmpty) {
      await subscribeToUserTopic(userId);
    }
    final token = fcmToken ?? await getSavedFCMToken();
    if (token != null && token.isNotEmpty) {
      await syncTokenToBackend(token);
    }
  }

  /// On logout: unsubscribe topics, clear server token, delete local FCM token.
  Future<void> clearPushRegistration() async {
    if (!_pushSupported) return;
    final userId = AuthService.getUserId();
    try {
      if (userId != null && userId.isNotEmpty) {
        await unsubscribeFromUserTopic(userId);
      }
      await unsubscribeFromTopic('all_users');
      if (AuthService.isLoggedIn()) {
        await syncTokenToBackend('');
      }
    } catch (e) {
      debugPrint('⚠️ Error clearing push registration: $e');
    }
    await deleteToken();
  }

  /// Sends FCM token to backend (empty string clears it on logout).
  Future<void> syncTokenToBackend(String token) async {
    if (!_pushSupported || !AuthService.isLoggedIn()) return;
    try {
      await DioHelper.instance.dio.post(
        ApiEndpoints.authProfile,
        data: {'fcm_token': token, '_method': 'PUT'},
      );
      debugPrint('✅ FCM token synced to backend');
    } on DioException catch (e) {
      debugPrint('⚠️ FCM token sync failed: ${e.response?.statusCode} ${e.message}');
    } catch (e) {
      debugPrint('⚠️ FCM token sync failed: $e');
    }
  }

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initialize() async {
    if (!_pushSupported) {
      _isInitialized = true;
      debugPrint('🔔 Notification Service skipped on web');
      return;
    }

    if (_isInitialized) {
      debugPrint('🔔 Notification Service already initialized');
      return;
    }

    try {
      debugPrint('🔔 Initializing Notification Service...');

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      // Listen to token refresh
      _setupTokenRefreshListener();

      _isInitialized = true;
      debugPrint('✅ Notification Service initialized successfully');
      debugPrint('🔑 FCM Token: $_fcmToken');

      await _handleAndroidLaunchNotification();
      await _handleTerminatedMessageTap();
    } catch (e) {
      debugPrint('❌ Error initializing Notification Service: $e');
      rethrow;
    }
  }

  /// Request notification permissions (iOS & Android 13+)
  Future<NotificationSettings> _requestPermissions() async {
    debugPrint('🔔 Requesting notification permissions...');

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔔 Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('⚠️ User granted provisional notification permission');
    } else {
      debugPrint('❌ User declined or has not accepted notification permission');
    }

    return settings;
  }

  /// Initialize Flutter Local Notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    debugPrint('🔔 Initializing local notifications...');

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with callback for when notification is tapped
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    debugPrint('✅ Local notifications initialized');
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'season_app_channel', // id
      'Season App Notifications', // name
      description: 'Notifications from Season App',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // NOTE: Alarm channel is created natively in MainActivity.kt with system alarm sound
    // We don't create it here to avoid overriding the native channel configuration
    // The native channel has the alarm sound properly configured

    debugPrint('✅ Android notification channels created');
    debugPrint('✅ Alarm channel created natively in MainActivity.kt with alarm sound');
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      debugPrint('🔔 Getting FCM token...');
      
      if (Platform.isIOS) {
        // For iOS, get APNs token first
        String? apnsToken = await _messaging.getAPNSToken();
        debugPrint('📱 APNs Token: $apnsToken');
        
        if (apnsToken == null) {
          debugPrint('⚠️ APNs token not available yet, will retry...');
          // Wait a bit and retry
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _messaging.getAPNSToken();
        }
      }

      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null) {
        debugPrint('✅ FCM Token: $_fcmToken');
        await _saveFCMToken(_fcmToken!);
      } else {
        debugPrint('⚠️ FCM Token is null');
      }

      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to local storage
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      debugPrint('💾 FCM Token saved to local storage');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Get saved FCM token from local storage
  Future<String?> getSavedFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      debugPrint('📖 Retrieved FCM Token from storage: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Error retrieving FCM token: $e');
      return null;
    }
  }

  /// Setup message handlers for foreground, background, and terminated states
  void _setupMessageHandlers() {
    debugPrint('🔔 Setting up message handlers...');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    debugPrint('✅ Message handlers configured');
  }

  Future<void> _handleAndroidLaunchNotification() async {
    if (!Platform.isAndroid) return;
    try {
      final data = await _androidNotificationChannel
          .invokeMapMethod<String, dynamic>('getLaunchNotificationData');
      if (data != null && data.isNotEmpty) {
        NotificationNavigationService.handle(
          Map<String, dynamic>.from(data),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Could not read Android launch notification: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📩 Foreground Message Received');
    debugPrint('📩 Message ID: ${message.messageId}');
    debugPrint('📩 Title: ${message.notification?.title}');
    debugPrint('📩 Body: ${message.notification?.body}');
    debugPrint('📩 Data: ${message.data}');

    // Check if this is a safety radius alarm
    final isSafetyRadiusAlarm = message.data['type'] == 'safety_radius_alert' ||
        message.data['notification_type'] == 'safety_radius_alert';
    
    // Check if user is group admin (owner) - handle both string and bool values
    final isAdmin = message.data['is_admin'] == true || 
                    message.data['is_admin'] == 'true' ||
                    message.data['is_owner'] == true ||
                    message.data['is_owner'] == 'true' ||
                    message.data['for_admin'] == true ||
                    message.data['for_admin'] == 'true';
    
    // Additional validation: Verify required fields exist
    final hasRequiredFields = message.data['group_id'] != null && 
                               message.data['member_id'] != null;
    
    if (isSafetyRadiusAlarm && isAdmin && hasRequiredFields) {
      final groupId = int.tryParse(message.data['group_id'].toString());
      final memberId = int.tryParse(message.data['member_id'].toString());
      if (groupId != null && memberId != null) {
        final key = NotificationDedup.safetyRadiusKey(groupId, memberId);
        if (!NotificationDedup.shouldShow(key)) return;
      }

      if (Platform.isAndroid) {
        // Native AlarmNotificationService shows the alarm on Android.
        return;
      }

      await _showSafetyRadiusAlarm(
        title: message.notification?.title ?? message.data['title'] ?? '🚨 Safety Alert',
        body: message.notification?.body ?? message.data['body'] ?? 'A group member is outside the safety radius!',
        payload: jsonEncode(message.data),
        notificationId: message.data['group_id'] != null 
            ? int.tryParse(message.data['group_id'].toString()) ?? message.hashCode
            : message.hashCode,
      );
    } else if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    } else if (message.data.isNotEmpty) {
      await _showLocalNotification(
        title: message.data['title']?.toString() ?? 'Season App',
        body: message.data['body']?.toString() ??
            message.data['message']?.toString() ??
            '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle background message tap (when app is in background and user taps notification)
  void _handleBackgroundMessageTap(RemoteMessage message) {
    debugPrint('📩 Background Message Tapped');
    debugPrint('📩 Message ID: ${message.messageId}');
    debugPrint('📩 Data: ${message.data}');

    // Navigate or perform action based on notification data
    _handleNotificationAction(message.data);
  }

  /// Handle terminated message tap (when app was closed and user taps notification)
  Future<void> _handleTerminatedMessageTap() async {
    // Get initial message if app was opened from terminated state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('📩 App opened from terminated state via notification');
      debugPrint('📩 Message ID: ${initialMessage.messageId}');
      debugPrint('📩 Data: ${initialMessage.data}');

      // Handle the notification action
      _handleNotificationAction(initialMessage.data);
    }
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    debugPrint('🎯 Handling notification action with data: $data');
    NotificationNavigationService.handle(data);
  }

  /// Show local notification (for foreground messages)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'season_app_channel',
        'Season App Notifications',
        channelDescription: 'Notifications from Season App',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecond, // notification id
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('✅ Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Show safety radius alarm notification (for admins only)
  Future<void> _showSafetyRadiusAlarm({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    try {
      // NOTE: Alarm channel is created natively in MainActivity.kt with system alarm sound
      // We don't delete/recreate it here to preserve the native alarm sound configuration
      // The channel is created once when the app starts with proper alarm sound settings

      // Alarm notification with SYSTEM ALARM SOUND (not default notification sound)
      // Use system alarm sound URI directly in notification details
      final alarmSoundUri = UriAndroidNotificationSound(
        'content://settings/system/alarm_alert'
      );
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'safety_radius_alarm_channel',
        'Safety Radius Alarms',
        channelDescription: 'High-priority alarms when group members go out of safety radius',
        importance: Importance.high, // Match channel importance
        priority: Priority.max,
        playSound: true, // Explicitly enable sound
        sound: alarmSoundUri, // Use alarm sound URI directly
        enableVibration: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        ongoing: false,
        autoCancel: true,
        category: AndroidNotificationCategory.alarm, // Alarm category for maximum priority
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

      // Use a unique notification ID to ensure it always shows
      final uniqueNotificationId = ((notificationId ?? DateTime.now().millisecond).abs() % 2147483647).toInt();
      
      await _localNotifications.show(
        uniqueNotificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('🚨 Safety radius alarm notification shown: $title');
      debugPrint('   Notification ID: $uniqueNotificationId');
      debugPrint('   Channel: safety_radius_alarm_channel');
      debugPrint('   Play Sound: true, Category: alarm');
    } catch (e) {
      debugPrint('❌ Error showing safety radius alarm: $e');
    }
  }

  /// Callback when local notification is tapped
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🎯 Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationAction(data);
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Setup token refresh listener
  void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      _fcmToken = newToken;
      _saveFCMToken(newToken);
      syncTokenToBackend(newToken);
    });
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    if (!_pushSupported) return;
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      
      debugPrint('✅ FCM Token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    if (!_pushSupported) return;
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_pushSupported) return;
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Get notification permission status
  Future<bool> isNotificationEnabled() async {
    if (!_pushSupported) return false;
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Request permission again (useful for settings screen)
  Future<bool> requestPermissionAgain() async {
    if (!_pushSupported) return false;
    final settings = await _requestPermissions();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Subscribe to "all_users" topic for broadcast messages
  Future<void> subscribeToAllUsers() async {
    await subscribeToTopic('all_users');
    debugPrint('📢 Subscribed to broadcast notifications');
  }

  /// Subscribe to user-specific topic (e.g., for personal notifications)
  Future<void> subscribeToUserTopic(String userId) async {
    await subscribeToTopic('user_$userId');
    debugPrint('👤 Subscribed to user notifications: $userId');
  }

  /// Unsubscribe from user-specific topic (useful on logout)
  Future<void> unsubscribeFromUserTopic(String userId) async {
    await unsubscribeFromTopic('user_$userId');
    debugPrint('👤 Unsubscribed from user notifications: $userId');
  }
}

