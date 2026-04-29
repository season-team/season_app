# Native Location Service - Quick Start

## ✅ What's Implemented

Native Android and iOS services that send location updates to the API **every 10 seconds** for all groups, even when the app is closed or terminated.

## 🚀 How It Works

1. **Flutter stores data** in SharedPreferences:
   - Auth token: `flutter.auth_token`
   - Group IDs: `flutter.tracked_group_ids` (JSON format: `"[1,2,3]"`)

2. **Native services read** this data and:
   - Get location every 10 seconds
   - Send to API for each group: `POST /groups/{id}/location`

3. **Service starts automatically** when:
   - User logs in
   - App launches (if user already logged in)

## 📱 Testing

### Android
```bash
# Check logs
adb logcat | grep LocationUpdateService

# Verify service is running
# Settings → Apps → Season → Running services
```

### iOS
```bash
# Check logs in Xcode
# Window → Devices → View Device Logs
# Filter: LocationUpdateService
```

## ⚙️ Configuration

### Change Update Interval

**Android** (`LocationUpdateService.kt`):
```kotlin
private val UPDATE_INTERVAL_SECONDS = 10L // Change here
```

**iOS** (`LocationUpdateService.swift`):
```swift
private let updateInterval: TimeInterval = 10.0 // Change here
```

## 🔧 Manual Control

```dart
import 'package:season_app/core/services/native_location_service.dart';

// Start service
await NativeLocationService.startService();

// Stop service
await NativeLocationService.stopService();
```

## ⚠️ Important Notes

1. **Permissions Required**:
   - Android: Location (Always), Foreground Service
   - iOS: Location (Always)

2. **Battery Impact**:
   - 10-second intervals will consume battery
   - Consider increasing to 30 seconds for better battery life

3. **iOS Limitations**:
   - Background location updates may be throttled
   - Exact 10-second intervals not guaranteed when terminated

4. **Android Limitations**:
   - Requires persistent notification
   - Battery optimization may kill service (whitelist app)

## 📋 Files Created

- **Android**: `android/app/src/main/kotlin/com/season/app/season_app/LocationUpdateService.kt`
- **iOS**: `ios/Runner/LocationUpdateService.swift`
- **Flutter**: `lib/core/services/native_location_service.dart`
- **Documentation**: `NATIVE_LOCATION_SERVICE_SETUP.md`

## 🎯 Next Steps

1. Build and test on real devices
2. Monitor battery usage
3. Test with app terminated
4. Check API logs for location updates

