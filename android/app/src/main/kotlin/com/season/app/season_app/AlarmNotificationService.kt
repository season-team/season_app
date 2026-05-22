package com.season.app.season_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Handles all FCM messages on Android (alarms + regular notifications).
 */
class AlarmNotificationService : FirebaseMessagingService() {
    private val TAG = "AlarmNotificationService"
    private val ALARM_CHANNEL_ID = "safety_radius_alarm_channel"
    private val REGULAR_CHANNEL_ID = "season_app_channel"
    private val ALARM_NOTIFICATION_ID = 9999

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AlarmNotificationService created")
        createAlarmNotificationChannel()
        createRegularNotificationChannel()
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        Log.d(TAG, "📩 FCM Message received")
        Log.d(TAG, "   From: ${remoteMessage.from}")
        Log.d(TAG, "   Message ID: ${remoteMessage.messageId}")
        Log.d(TAG, "   Data: ${remoteMessage.data}")

        val isSafetyRadiusAlarm = remoteMessage.data["type"] == "safety_radius_alert" ||
                remoteMessage.data["notification_type"] == "safety_radius_alert"

        val isAdmin = remoteMessage.data["is_admin"] == "true" ||
                remoteMessage.data["is_owner"] == "true" ||
                remoteMessage.data["for_admin"] == "true"

        if (isSafetyRadiusAlarm && isAdmin) {
            Log.d(TAG, "🚨 Safety radius alarm - showing native alarm notification")
            showAlarmNotification(remoteMessage)
        } else {
            Log.d(TAG, "ℹ️ Regular notification - showing native notification")
            showRegularNotification(remoteMessage)
        }
    }

    private fun createRegularNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                REGULAR_CHANNEL_ID,
                "Season App Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications from Season App"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "✅ Regular notification channel created")
        }
    }

    private fun createAlarmNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = ALARM_CHANNEL_ID
            val channelName = "Safety Radius Alarms"
            val channelDescription =
                "High-priority alarms when group members go out of safety radius"
            val importance = NotificationManager.IMPORTANCE_HIGH

            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            try {
                notificationManager.deleteNotificationChannel(channelId)
                Log.d(TAG, "Deleted existing alarm channel to reset sound")
            } catch (e: Exception) {
                Log.d(TAG, "Channel doesn't exist or couldn't be deleted: ${e.message}")
            }

            val alarmSoundUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            Log.d(TAG, "Alarm sound URI: $alarmSoundUri")

            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()

            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableVibration(true)
                enableLights(true)
                setSound(alarmSoundUri, audioAttributes)
                setShowBadge(true)
            }

            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "✅ Alarm notification channel created with alarm sound: $alarmSoundUri")
        }
    }

    private fun buildContentIntent(remoteMessage: RemoteMessage): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            remoteMessage.data.forEach { (key, value) ->
                putExtra(key, value)
            }
        }
        return PendingIntent.getActivity(
            this,
            remoteMessage.messageId?.hashCode() ?: 0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun showRegularNotification(remoteMessage: RemoteMessage) {
        try {
            val title = remoteMessage.notification?.title
                ?: remoteMessage.data["title"]
                ?: "Season App"

            val body = remoteMessage.notification?.body
                ?: remoteMessage.data["body"]
                ?: remoteMessage.data["message"]
                ?: ""

            val notificationId = remoteMessage.messageId?.hashCode()
                ?: remoteMessage.data.hashCode()

            val notification = NotificationCompat.Builder(this, REGULAR_CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(buildContentIntent(remoteMessage))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .build()

            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(notificationId, notification)

            Log.d(TAG, "✅ Regular notification shown: $title")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing regular notification: ${e.message}", e)
        }
    }

    private fun showAlarmNotification(remoteMessage: RemoteMessage) {
        try {
            val title = remoteMessage.notification?.title
                ?: remoteMessage.data["title"]
                ?: "🚨 Safety Alert"

            val body = remoteMessage.notification?.body
                ?: remoteMessage.data["body"]
                ?: "A group member is outside the safety radius!"

            val groupId = remoteMessage.data["group_id"]
            val memberId = remoteMessage.data["member_id"]
            val notificationId = if (groupId != null && memberId != null) {
                (groupId.hashCode() * 1000 + memberId.hashCode()).and(0x7FFFFFFF)
            } else {
                ALARM_NOTIFICATION_ID
            }

            val alarmSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)

            val notification = NotificationCompat.Builder(this, ALARM_CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentIntent(buildContentIntent(remoteMessage))
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setOngoing(false)
                .setVibrate(longArrayOf(0, 500, 250, 500, 250, 500))
                .setLights(0xFF0000, 1000, 1000)
                .setSound(alarmSoundUri)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .build()

            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(notificationId, notification)

            Log.d(TAG, "✅ Alarm notification shown: $title")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing alarm notification: ${e.message}", e)
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token: $token")
    }
}
