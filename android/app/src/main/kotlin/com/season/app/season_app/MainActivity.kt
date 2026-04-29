package com.season.app.season_app

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "season_app/maps"
    private val LOCATION_SERVICE_CHANNEL = "season_app/location_service"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if we need to request location permissions (called from service)
        if (intent.getBooleanExtra("request_location_permission", false)) {
            android.util.Log.d("MainActivity", "Requesting location permissions from service...")
            // Request permissions immediately
            checkAndRequestLocationPermissions()
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Create alarm notification channel with system alarm sound
        createAlarmNotificationChannel()
        
        // Location service method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startLocationService" -> {
                    // Always try to start service - it will request permissions if needed
                    // Check and request permissions before starting service
                    if (checkAndRequestLocationPermissions()) {
                        startLocationService()
                        result.success("Location service started")
                    } else {
                        // Permissions will be requested, service will start after permission granted
                        startLocationService()
                        result.success("Location service starting - permissions requested")
                    }
                }
                "stopLocationService" -> {
                    stopLocationService()
                    result.success("Location service stopped")
                }
                "requestLocationPermissions" -> {
                    val granted = checkAndRequestLocationPermissions()
                    result.success(granted)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchGoogleMaps" -> {
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")
                    if (latitude != null && longitude != null) {
                        launchGoogleMaps(latitude, longitude, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Latitude and longitude are required", null)
                    }
                }
                "launchMapsIntent" -> {
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")
                    if (latitude != null && longitude != null) {
                        launchMapsIntent(latitude, longitude, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Latitude and longitude are required", null)
                    }
                }
                "launchUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        launchUrl(url, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "URL is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun launchGoogleMaps(latitude: Double, longitude: Double, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude")
            val intent = Intent(Intent.ACTION_VIEW, uri)
            intent.setPackage("com.google.android.apps.maps")
            
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success("Google Maps launched successfully")
            } else {
                result.error("APP_NOT_FOUND", "Google Maps app not found", null)
            }
        } catch (e: Exception) {
            result.error("LAUNCH_ERROR", "Failed to launch Google Maps: ${e.message}", null)
        }
    }

    private fun launchMapsIntent(latitude: Double, longitude: Double, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude")
            val intent = Intent(Intent.ACTION_VIEW, uri)
            
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success("Maps intent launched successfully")
            } else {
                result.error("NO_MAPS_APP", "No maps app found", null)
            }
        } catch (e: Exception) {
            result.error("LAUNCH_ERROR", "Failed to launch maps: ${e.message}", null)
        }
    }

    private fun launchUrl(url: String, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse(url)
            val intent = Intent(Intent.ACTION_VIEW, uri)
            
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success("URL launched successfully")
            } else {
                result.error("NO_BROWSER", "No browser found", null)
            }
        } catch (e: Exception) {
            result.error("LAUNCH_ERROR", "Failed to launch URL: ${e.message}", null)
        }
    }
    
    private fun createAlarmNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "safety_radius_alarm_channel"
            val channelName = "Safety Radius Alarms"
            val channelDescription = "High-priority alarms when group members go out of safety radius"
            val importance = NotificationManager.IMPORTANCE_HIGH // Use HIGH instead of MAX for better compatibility
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Delete existing channel if it exists (to reset sound settings)
            try {
                notificationManager.deleteNotificationChannel(channelId)
                android.util.Log.d("MainActivity", "Deleted existing alarm channel to reset sound")
            } catch (e: Exception) {
                android.util.Log.d("MainActivity", "Channel doesn't exist or couldn't be deleted: ${e.message}")
            }
            
            // Get system default alarm sound
            val alarmSoundUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            android.util.Log.d("MainActivity", "Alarm sound URI: $alarmSoundUri")
            
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
            android.util.Log.d("MainActivity", "✅ Alarm notification channel created with alarm sound: $alarmSoundUri")
        }
    }
    
    private fun startLocationService() {
        try {
            // Check if service is already running
            val serviceIntent = Intent(this, LocationUpdateService::class.java)
            val isRunning = isServiceRunning(LocationUpdateService::class.java)
            
            if (!isRunning) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
                android.util.Log.d("MainActivity", "✅ Native location service started")
            } else {
                android.util.Log.d("MainActivity", "ℹ️ Native location service already running")
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "❌ Error starting location service: ${e.message}", e)
        }
    }
    
    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningServices = activityManager.getRunningServices(Integer.MAX_VALUE)
            
            for (service in runningServices) {
                if (serviceClass.name == service.service.className) {
                    return true
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error checking if service is running: ${e.message}")
        }
        return false
    }
    
    private fun stopLocationService() {
        val intent = Intent(this, LocationUpdateService::class.java)
        stopService(intent)
        android.util.Log.d("MainActivity", "🛑 Native location service stopped")
    }
    
    private fun checkAndRequestLocationPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val fineLocation = checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED
            val coarseLocation = checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED
            
            // Request basic location permission first if not granted
            if (!fineLocation && !coarseLocation) {
                android.util.Log.d("MainActivity", "Requesting basic location permission...")
                requestPermissions(arrayOf(
                    android.Manifest.permission.ACCESS_FINE_LOCATION,
                    android.Manifest.permission.ACCESS_COARSE_LOCATION
                ), 1001)
                return false
            }
            
            // For Android 10+ (API 29+), request background location permission
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val backgroundLocation = checkSelfPermission(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED
                
                if (!backgroundLocation) {
                    android.util.Log.d("MainActivity", "Requesting background location permission (all the time)...")
                    requestPermissions(arrayOf(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION), 1002)
                    return false
                }
                
                android.util.Log.d("MainActivity", "✅ All location permissions granted (including background)")
                return true
            }
            
            android.util.Log.d("MainActivity", "✅ Location permissions granted")
            return true
        }
        return true
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            1001 -> {
                // Basic location permission result
                if (grantResults.isNotEmpty() && grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    android.util.Log.d("MainActivity", "✅ Basic location permission granted")
                    
                    // Now request background location permission (Android 10+)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        if (checkSelfPermission(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                            android.util.Log.d("MainActivity", "Requesting background location permission...")
                            requestPermissions(arrayOf(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION), 1002)
                        }
                    }
                } else {
                    android.util.Log.w("MainActivity", "❌ Basic location permission denied")
                }
            }
            1002 -> {
                // Background location permission result
                if (grantResults.isNotEmpty() && grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    android.util.Log.d("MainActivity", "✅ Background location permission granted (all the time)")
                    // Restart location service with permissions granted flag
                    val serviceIntent = Intent(this, LocationUpdateService::class.java).apply {
                        putExtra("permissions_granted", true)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                } else {
                    android.util.Log.w("MainActivity", "❌ Background location permission denied - location updates may not work when app is terminated")
                    // Still try to start service - it will work with while-in-use permission
                    startLocationService()
                }
            }
        }
    }
}
