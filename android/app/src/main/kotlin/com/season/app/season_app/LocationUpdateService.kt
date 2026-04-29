package com.season.app.season_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

class LocationUpdateService : Service() {
    private val TAG = "LocationUpdateService"
    private val CHANNEL_ID = "location_update_channel"
    private val NOTIFICATION_ID = 999
    
    private var locationManager: LocationManager? = null
    private var locationListener: LocationListener? = null
    private var handler: Handler? = null
    private var updateRunnable: Runnable? = null
    private var serviceScope: CoroutineScope? = null
    
    private val UPDATE_INTERVAL_SECONDS = 10L
    private val BASE_URL = "https://seasonksa.com/api"
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        
        try {
            createNotificationChannel()
            startForeground(NOTIFICATION_ID, createNotification())
            
            handler = Handler(Looper.getMainLooper())
            serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
            
            // Log current group IDs status on service creation
            logGroupIdsStatus()
            
            startLocationUpdates()
        } catch (e: Exception) {
            Log.e(TAG, "Error in onCreate: ${e.message}", e)
            // Don't crash - try to continue
        }
    }
    
    private fun logGroupIdsStatus() {
        // Removed verbose logging
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started with flags: $flags")
        
        // Check if permissions were granted (service restarted after permission grant)
        if (intent?.getBooleanExtra("permissions_granted", false) == true) {
            Log.d(TAG, "Permissions granted - restarting location updates")
            startLocationUpdates()
        } else {
            // Restart location updates if they're not running
            if (locationListener == null) {
                Log.d(TAG, "Restarting location updates in onStartCommand")
                startLocationUpdates()
            }
        }
        
        return START_STICKY // Restart if killed
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location Updates",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background location tracking for groups"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Season")
            .setContentText("Location tracking active")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(Notification.PRIORITY_LOW)
            .build()
    }
    
    private fun startLocationUpdates() {
        // Check permissions first - request if not granted
        if (!hasLocationPermission()) {
            Log.w(TAG, "Location permission not granted - requesting permissions...")
            requestLocationPermissions()
            return
        }
        
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        
        if (locationManager == null) {
            Log.e(TAG, "LocationManager is null")
            return
        }
        
        locationListener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                // Always try to send location, even if group IDs might not be available yet
                // The sendLocationToAllGroups function will handle empty group IDs gracefully
                sendLocationToAllGroups(location.latitude, location.longitude)
            }
            
            override fun onStatusChanged(provider: String, status: Int, extras: Bundle?) {}
            override fun onProviderEnabled(provider: String) {}
            override fun onProviderDisabled(provider: String) {}
        }
        
        try {
            // Check if GPS provider is enabled
            val isGpsEnabled = locationManager?.isProviderEnabled(LocationManager.GPS_PROVIDER) ?: false
            val isNetworkEnabled = locationManager?.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ?: false
            
            if (!isGpsEnabled && !isNetworkEnabled) {
                Log.w(TAG, "No location providers enabled")
            }
            
            // Request location updates every 10 seconds
            if (isGpsEnabled) {
                locationManager?.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    TimeUnit.SECONDS.toMillis(UPDATE_INTERVAL_SECONDS),
                    0f,
                    locationListener!!
                )
                Log.d(TAG, "GPS location updates started")
            }
            
            // Also request from network provider as fallback
            if (isNetworkEnabled) {
                locationManager?.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    TimeUnit.SECONDS.toMillis(UPDATE_INTERVAL_SECONDS),
                    0f,
                    locationListener!!
                )
                Log.d(TAG, "Network location updates started")
            }
            
            Log.d(TAG, "Location updates started successfully")
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission not granted: ${e.message}", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting location updates: ${e.message}", e)
        }
        
        // Fallback: Periodic timer to ensure updates every 10 seconds
        updateRunnable = object : Runnable {
            override fun run() {
                val location = getLastKnownLocation()
                if (location != null) {
                    sendLocationToAllGroups(location.latitude, location.longitude)
                }
                handler?.postDelayed(this, TimeUnit.SECONDS.toMillis(UPDATE_INTERVAL_SECONDS))
            }
        }
        handler?.post(updateRunnable!!)
    }
    
    private fun hasLocationPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val fineLocation = checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED
            val coarseLocation = checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED
            
            // For Android 10+ (API 29+), also check for background location permission
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val backgroundLocation = checkSelfPermission(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED
                
                // Background location is required for location updates when app is terminated
                return (fineLocation || coarseLocation) && backgroundLocation
            }
            
            return fineLocation || coarseLocation
        }
        return true
    }
    
    private fun requestLocationPermissions() {
        // Create an intent to open MainActivity to request permissions
        // We need an Activity context to request permissions
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("request_location_permission", true)
        }
        startActivity(intent)
        Log.d(TAG, "Opened MainActivity to request location permissions")
    }
    
    private fun getLastKnownLocation(): Location? {
        if (!hasLocationPermission()) {
            return null
        }
        return try {
            locationManager?.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                ?: locationManager?.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException getting last known location: ${e.message}")
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error getting last known location: ${e.message}")
            null
        }
    }
    
    private fun sendLocationToAllGroups(latitude: Double, longitude: Double) {
        serviceScope?.launch {
            try {
                // Flutter stores SharedPreferences with "flutter." prefix
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                
                // Try different key formats that Flutter might use
                val token = prefs.getString("flutter.auth_token", null)
                    ?: prefs.getString("auth_token", null)
                
                if (token == null) {
                    Log.w(TAG, "No auth token found")
                    return@launch
                }
                
                // Try multiple ways to read group IDs
                val groupIds = mutableListOf<Int>()
                
                // Method 1: Try JSON format (flutter.tracked_group_ids)
                val groupIdsJson = prefs.getString("flutter.tracked_group_ids", null)
                
                if (groupIdsJson != null && groupIdsJson.isNotEmpty() && groupIdsJson != "null" && groupIdsJson != "[]") {
                    val parsed = parseGroupIds(groupIdsJson)
                    if (parsed.isNotEmpty()) {
                        groupIds.addAll(parsed)
                    }
                }
                
                // Method 2: Try StringList format (tracked_group_ids) - Flutter stores as StringList
                if (groupIds.isEmpty()) {
                    // Flutter stores StringList, but SharedPreferences doesn't have direct StringList support
                    // We need to read it differently - Flutter stores it as a serialized format
                    // Let's try reading all keys and find the one that matches
                    val allKeys = prefs.all.keys
                    for (key in allKeys) {
                        if (key.contains("tracked_group_ids") && !key.contains("flutter.tracked_group_ids")) {
                            try {
                                // Try as StringSet first
                                val stringSet = prefs.getStringSet(key, null)
                                if (stringSet != null && stringSet.isNotEmpty()) {
                                    val parsed = stringSet.mapNotNull { it.toIntOrNull() }.filter { it > 0 }
                                    if (parsed.isNotEmpty()) {
                                        groupIds.addAll(parsed)
                                        break
                                    }
                                }
                                // Try as String (comma-separated)
                                val stringValue = prefs.getString(key, null)
                                if (stringValue != null && stringValue.isNotEmpty()) {
                                    val parsed = parseGroupIds(stringValue)
                                    if (parsed.isNotEmpty()) {
                                        groupIds.addAll(parsed)
                                        break
                                    }
                                }
                            } catch (e: Exception) {
                                Log.w(TAG, "Error reading key $key: ${e.message}")
                            }
                        }
                    }
                }
                
                // Method 3: Try comma-separated string format directly
                if (groupIds.isEmpty()) {
                    val commaSeparated = prefs.getString("tracked_group_ids", null)
                    if (commaSeparated != null && commaSeparated.isNotEmpty()) {
                        val parsed = parseGroupIds(commaSeparated)
                        if (parsed.isNotEmpty()) {
                            groupIds.addAll(parsed)
                        }
                    }
                }
                
                // Method 4: Try duplicate key flutter.flutter.tracked_group_ids (if exists)
                if (groupIds.isEmpty()) {
                    val duplicateKey = prefs.getString("flutter.flutter.tracked_group_ids", null)
                    if (duplicateKey != null && duplicateKey.isNotEmpty() && duplicateKey != "null" && duplicateKey != "[]") {
                        val parsed = parseGroupIds(duplicateKey)
                        if (parsed.isNotEmpty()) {
                            groupIds.addAll(parsed)
                        }
                    }
                }
                
                if (groupIds.isEmpty()) {
                    return@launch
                }
                
                // Send to all groups in parallel
                groupIds.forEach { groupId ->
                    sendLocationToGroup(groupId, latitude, longitude, token)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error sending location: ${e.message}", e)
            }
        }
    }
    
    private suspend fun sendLocationToGroup(
        groupId: Int,
        latitude: Double,
        longitude: Double,
        token: String
    ) {
        withContext(Dispatchers.IO) {
            try {
                val url = URL("$BASE_URL/groups/$groupId/location")
                val connection = url.openConnection() as HttpURLConnection
                
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Authorization", "Bearer $token")
                connection.setRequestProperty("Accept", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 10000
                connection.readTimeout = 10000
                
                val jsonBody = JSONObject().apply {
                    put("latitude", latitude)
                    put("longitude", longitude)
                }
                
                OutputStreamWriter(connection.outputStream).use { writer ->
                    writer.write(jsonBody.toString())
                    writer.flush()
                }
                
                val responseCode = connection.responseCode
                if (responseCode in 200..299) {
                    Log.d(TAG, "✅ Location sent to group $groupId: lat=$latitude, lng=$longitude")
                }
                
                connection.disconnect()
            } catch (e: Exception) {
                // Silent error handling
            }
        }
    }
    
    private fun parseGroupIds(jsonString: String): List<Int> {
        return try {
            // Check if empty or null string
            if (jsonString.isEmpty() || jsonString == "null" || jsonString == "[]") {
                return emptyList()
            }
            
            // Handle Flutter's SharedPreferences list encoding format
            // Flutter stores lists with prefix: "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!["40"]"
            // We need to extract the JSON array part after the "!" character
            var stringToParse = jsonString
            if (jsonString.contains("!")) {
                val parts = jsonString.split("!", limit = 2)
                if (parts.size == 2) {
                    stringToParse = parts[1]
                }
            }
            
            // Try parsing as JSON array first
            if (stringToParse.startsWith("[")) {
                val jsonArray = org.json.JSONArray(stringToParse)
                val parsed = (0 until jsonArray.length()).mapNotNull { index ->
                    val value = jsonArray.optInt(index, -1)
                    value.takeIf { it > 0 }
                }
                parsed
            } else {
                // Try parsing as comma-separated string
                val parts = stringToParse.split(",")
                val parsed = parts.mapNotNull { idStr ->
                    val trimmed = idStr.trim()
                    val value = trimmed.toIntOrNull()
                    value?.takeIf { it > 0 }
                }
                parsed
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
        
        locationListener?.let {
            locationManager?.removeUpdates(it)
        }
        
        updateRunnable?.let {
            handler?.removeCallbacks(it)
        }
        
        serviceScope?.cancel()
    }
}

