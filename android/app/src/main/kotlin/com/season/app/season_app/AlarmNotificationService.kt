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
 * Native Android service to handle FCM messages and show alarm notifications
 * Works even when app is closed or terminated
 */
class AlarmNotificationService : FirebaseMessagingService() {
    private val TAG = "AlarmNotificationService"
    private val ALARM_CHANNEL_ID = "safety_radius_alarm_channel"
    private val ALARM_NOTIFICATION_ID = 9999
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AlarmNotificationService created")
        createAlarmNotificationChannel()
    }
    
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        Log.d(TAG, "📩 FCM Message received")
        Log.d(TAG, "   From: ${remoteMessage.from}")
        Log.d(TAG, "   Message ID: ${remoteMessage.messageId}")
        Log.d(TAG, "   Data: ${remoteMessage.data}")
        Log.d(TAG, "   Notification: ${remoteMessage.notification?.title}")
        
        // Check if this is a safety radius alarm
        val isSafetyRadiusAlarm = remoteMessage.data["type"] == "safety_radius_alert" ||
                remoteMessage.data["notification_type"] == "safety_radius_alert"
        
        // Verify admin status
        val isAdmin = remoteMessage.data["is_admin"] == "true" ||
                remoteMessage.data["is_owner"] == "true" ||
                remoteMessage.data["for_admin"] == "true"
        
        if (isSafetyRadiusAlarm && isAdmin) {
            Log.d(TAG, "🚨 Safety radius alarm detected - showing native notification")
            showAlarmNotification(remoteMessage)
        } else {
            Log.d(TAG, "ℹ️ Regular notification - not handling here")
        }
    }
    
    private fun createAlarmNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = ALARM_CHANNEL_ID
            val channelName = "Safety Radius Alarms"
            val channelDescription = "High-priority alarms when group members go out of safety radius"
            val importance = NotificationManager.IMPORTANCE_HIGH
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Delete existing channel if it exists (to reset sound settings)
            try {
                notificationManager.deleteNotificationChannel(channelId)
                Log.d(TAG, "Deleted existing alarm channel to reset sound")
            } catch (e: Exception) {
                Log.d(TAG, "Channel doesn't exist or couldn't be deleted: ${e.message}")
            }
            
            // Get system default alarm sound
            val alarmSoundUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            Log.d(TAG, "Alarm sound URI: $alarmSoundUri")
            
            // Create audio attributes for alarm
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableVibration(true)
                enableLights(true)
                setSound(alarmSoundUri, audioAttributes) // Set alarm sound
                setShowBadge(true)
            }
            
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "✅ Alarm notification channel created with alarm sound: $alarmSoundUri")
        }
    }
    
    private fun showAlarmNotification(remoteMessage: RemoteMessage) {
        try {
            // Extract title and body from notification or data
            val title = remoteMessage.notification?.title
                ?: remoteMessage.data["title"]
                ?: "🚨 Safety Alert"
            
            val body = remoteMessage.notification?.body
                ?: remoteMessage.data["body"]
                ?: "A group member is outside the safety radius!"
            
            // Create intent to open app when notification is tapped
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                // Add data from notification
                putExtra("type", remoteMessage.data["type"])
                putExtra("group_id", remoteMessage.data["group_id"])
                putExtra("member_id", remoteMessage.data["member_id"])
            }
            
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            
            // Get alarm sound URI
            val alarmSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            Log.d(TAG, "Using alarm sound URI: $alarmSoundUri")
            
            // Build notification with alarm sound
            // The channel already has alarm sound configured with proper audio attributes
            // We just need to set the sound URI on the notification
            val notification = NotificationCompat.Builder(this, ALARM_CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(android.R.drawable.ic_dialog_alert) // Use system alert icon
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setOngoing(false)
                .setVibrate(longArrayOf(0, 500, 250, 500, 250, 500)) // Vibrate pattern
                .setLights(0xFF0000, 1000, 1000) // Red light
                .setSound(alarmSoundUri) // Alarm sound - channel has audio attributes configured
                .setDefaults(NotificationCompat.DEFAULT_ALL) // Include sound in defaults
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .build()
            
            Log.d(TAG, "Notification built with sound URI: $alarmSoundUri")
            
            // Show notification
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(ALARM_NOTIFICATION_ID, notification)
            
            Log.d(TAG, "✅ Alarm notification shown: $title")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing alarm notification: ${e.message}", e)
        }
    }
    
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token: $token")
        // Token refresh is handled by Flutter FirebaseMessaging plugin
    }
}

