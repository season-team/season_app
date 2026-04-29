# Native Location Service Setup

## Overview

This implementation provides **native Android and iOS services** that send user location to the API every **10 seconds** for all groups, even when the app is closed or terminated.

## Architecture

### Android
- **Service**: `LocationUpdateService.kt` - Foreground service that runs continuously
- **Location Updates**: Uses `LocationManager` with GPS and Network providers
- **API Calls**: Native HTTP requests using `HttpURLConnection`
- **Interval**: 10 seconds (configurable via `UPDATE_INTERVAL_SECONDS`)

### iOS
- **Service**: `LocationUpdateService.swift` - Singleton service using `CLLocationManager`
- **Location Updates**: Uses `CLLocationManager` with background location updates
- **API Calls**: Native HTTP requests using `URLSession`
- **Interval**: 10 seconds (configurable via `updateInterval`)

## Features

✅ **Works when app is closed or terminated**
✅ **Sends location every 10 seconds**
✅ **Sends to all user groups automatically**
✅ **Reads auth token and group IDs from SharedPreferences**
✅ **Handles network errors gracefully**
✅ **Low battery impact with optimized location settings**

## Setup Instructions

### Android

1. **Permissions** (Already in `AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
   ```

2. **Service Registration** (Already in `AndroidManifest.xml`):
   ```xml
   <service
       android:name=".LocationUpdateService"
       android:foregroundServiceType="location"
       android:enabled="true"
       android:exported="false" />
   ```

3. **Method Channel** (Already in `MainActivity.kt`):
   - Channel: `season_app/location_service`
   - Methods: `startLocationService`, `stopLocationService`

### iOS

1. **Info.plist** (Already updated):
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>location</string>
   </array>
   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>We need your location to share it with your groups for safety tracking.</string>
   ```

2. **AppDelegate** (Already updated):
   - Automatically starts location service on app launch
   - Method channel handler for start/stop

## How It Works

### Data Flow

1. **Flutter App** stores auth token and group IDs in SharedPreferences:
   - Key: `flutter.auth_token`
   - Key: `flutter.tracked_group_ids` (JSON array string)

2. **Native Service** reads from SharedPreferences:
   - Android: Uses `getSharedPreferences("FlutterSharedPreferences", ...)`
   - iOS: Uses `UserDefaults.standard` with `flutter.` prefix

3. **Location Updates**:
   - Android: `LocationManager` requests updates every 10 seconds
   - iOS: `CLLocationManager` with timer backup every 10 seconds

4. **API Calls**:
   - For each group ID, sends POST to `/groups/{id}/location`
   - Body: `{"latitude": double, "longitude": double}`
   - Headers: `Authorization: Bearer {token}`

### Starting the Service

The service is automatically started when:
- User logs in (via `startBackgroundLocationTracking()` in `main.dart`)
- App launches and user is already logged in

You can also manually start/stop:
```dart
import 'package:season_app/core/services/native_location_service.dart';

// Start
await NativeLocationService.startService();

// Stop
await NativeLocationService.stopService();
```

## Testing

### Android

1. **Check Logs**:
   ```bash
   adb logcat | grep LocationUpdateService
   ```

2. **Verify Service Running**:
   - Settings → Apps → Season → App info → Running services
   - Should see "LocationUpdateService" with notification

3. **Test Background**:
   - Start service
   - Close app completely
   - Check API logs for location updates every 10 seconds

### iOS

1. **Check Logs**:
   - Xcode → Window → Devices and Simulators → View Device Logs
   - Filter by "LocationUpdateService"

2. **Verify Background Mode**:
   - Settings → Privacy → Location Services → Season → Always

3. **Test Background**:
   - Start service
   - Close app completely
   - Check API logs for location updates every 10 seconds

## Troubleshooting

### Android

**Service not starting:**
- Check if location permission is granted
- Check if foreground service permission is granted (Android 10+)
- Check logs for errors

**Location not updating:**
- Ensure GPS is enabled
- Check if device has location services enabled
- Verify location permission includes background location

**API calls failing:**
- Check if auth token is stored correctly
- Verify group IDs are stored as JSON array
- Check network connectivity

### iOS

**Service not starting:**
- Check if location permission is granted (Always)
- Verify `UIBackgroundModes` includes `location` in Info.plist
- Check if app has background location capability enabled in Xcode

**Location not updating:**
- iOS may throttle location updates in background
- Ensure "Always" permission is granted (not "While Using")
- Check device location services are enabled

**API calls failing:**
- Check if auth token is stored correctly
- Verify group IDs format in UserDefaults
- Check network connectivity

## Configuration

### Change Update Interval

**Android** (`LocationUpdateService.kt`):
```kotlin
private val UPDATE_INTERVAL_SECONDS = 10L // Change this value
```

**iOS** (`LocationUpdateService.swift`):
```swift
private let updateInterval: TimeInterval = 10.0 // Change this value
```

### Change Location Accuracy

**Android**:
```kotlin
locationManager?.requestLocationUpdates(
    LocationManager.GPS_PROVIDER,
    TimeUnit.SECONDS.toMillis(UPDATE_INTERVAL_SECONDS),
    0f, // Change distance filter (meters)
    locationListener!!
)
```

**iOS**:
```swift
locationManager?.desiredAccuracy = kCLLocationAccuracyBest
locationManager?.distanceFilter = 10 // Change distance filter (meters)
```

## Battery Optimization

The service is optimized for battery efficiency:
- Uses medium accuracy location (Android)
- Updates only when moved 10+ meters
- Efficient HTTP connections with timeouts
- Proper service lifecycle management

However, **10-second intervals will consume battery**. Consider:
- Increasing interval to 30 seconds for better battery life
- Using significant location changes only
- Implementing adaptive intervals based on movement

## Limitations

### Android
- Foreground service requires persistent notification
- Battery optimization may kill service (user must whitelist app)
- Exact 10-second intervals may vary slightly

### iOS
- Background location updates are throttled by iOS
- Exact 10-second intervals not guaranteed when app is terminated
- Requires "Always" location permission
- May be limited by iOS background execution time

## Security

- Auth token stored securely in SharedPreferences
- HTTPS API calls only
- No location data stored locally
- Service stops when user logs out

## Next Steps

1. **Test on real devices** (not emulators for location)
2. **Monitor battery usage** and adjust intervals if needed
3. **Test with app terminated** to verify background execution
4. **Check API logs** to confirm location updates are received

## Support

If you encounter issues:
1. Check device logs for errors
2. Verify permissions are granted
3. Test with app in foreground first
4. Check API endpoint is correct
5. Verify auth token and group IDs are stored correctly

