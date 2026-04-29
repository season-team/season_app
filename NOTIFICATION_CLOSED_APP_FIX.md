# Notification Fix for Closed App

## Problem
Notifications were not being received when the app was closed or terminated.

## Root Causes Identified

1. **Missing WidgetsFlutterBinding initialization** - Background handler runs in a separate isolate and needs Flutter bindings initialized
2. **Notification channels not created** - Channels must exist before showing notifications, especially when app is terminated
3. **Missing data-only notification handling** - If backend sends data-only messages (no `notification` field), they weren't being displayed
4. **Missing Android permissions** - POST_NOTIFICATIONS permission needed for Android 13+

## Fixes Applied

### 1. Background Handler Initialization (`lib/core/services/notification_service.dart`)
- ✅ Added `WidgetsFlutterBinding.ensureInitialized()` at the start of background handler
- ✅ Added function to create notification channels in background handler
- ✅ Added fallback to show notifications from data payload if `notification` field is missing
- ✅ Improved error handling with try-catch blocks

### 2. Android Manifest (`android/app/src/main/AndroidManifest.xml`)
- ✅ Added `POST_NOTIFICATIONS` permission for Android 13+
- ✅ Added `WAKE_LOCK` permission for notifications when device is sleeping
- ✅ Added `FOREGROUND_SERVICE_LOCATION` permission (already had FOREGROUND_SERVICE)

### 3. Notification Channel Creation
- ✅ Created `_createNotificationChannelsForBackground()` function
- ✅ Ensures channels exist before showing any notification
- ✅ Handles both regular and alarm notification channels

## How It Works Now

### When App is Closed/Terminated:

1. **FCM receives message** → Firebase Cloud Messaging receives the push notification
2. **Background handler triggered** → `firebaseMessagingBackgroundHandler()` runs in separate isolate
3. **Flutter bindings initialized** → `WidgetsFlutterBinding.ensureInitialized()` called
4. **Local notifications initialized** → FlutterLocalNotificationsPlugin initialized
5. **Channels created** → Notification channels created if they don't exist
6. **Notification displayed** → Local notification shown with proper sound/vibration

### Message Types Supported:

1. **Notification messages** (with `notification` field):
   - Title and body from `notification.title` and `notification.body`
   - Displayed automatically

2. **Data-only messages** (no `notification` field):
   - Title from `data.title` or defaults to "Season App"
   - Body from `data.body` or `data.message` or defaults to "New notification"
   - Now properly displayed

3. **Safety radius alarms**:
   - Special handling with alarm sound
   - High priority notification
   - Alarm category for maximum visibility

## Testing Steps

### 1. Test Regular Notification (App Closed)

**Backend should send:**
```json
{
  "message": {
    "token": "USER_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test message"
    },
    "data": {
      "type": "test"
    }
  }
}
```

**Expected Result:**
- ✅ Notification appears in notification tray
- ✅ Sound plays (if enabled)
- ✅ Vibration occurs (if enabled)

### 2. Test Data-Only Notification (App Closed)

**Backend should send:**
```json
{
  "message": {
    "token": "USER_FCM_TOKEN",
    "data": {
      "title": "Data Only Test",
      "body": "This notification has no notification field"
    }
  }
}
```

**Expected Result:**
- ✅ Notification appears with title "Data Only Test"
- ✅ Body shows "This notification has no notification field"
- ✅ Sound and vibration work

### 3. Test Safety Radius Alarm (App Closed)

**Backend should send:**
```json
{
  "message": {
    "token": "ADMIN_FCM_TOKEN",
    "data": {
      "type": "safety_radius_alert",
      "is_admin": "true",
      "title": "🚨 Safety Alert",
      "body": "Member is outside safety radius",
      "group_id": "123",
      "member_id": "456"
    }
  }
}
```

**Expected Result:**
- ✅ Alarm notification appears
- ✅ System alarm sound plays (not regular notification sound)
- ✅ High priority notification
- ✅ Vibration and lights enabled

### 4. Check Logs

```bash
# Android
adb logcat | grep -E "Background Message|firebaseMessagingBackgroundHandler|Notification"

# Look for:
# - "📩 Background Message Received (App Closed/Terminated)"
# - "✅ Regular notification channel created in background handler"
# - "✅ Local notification shown in background"
# - "🚨 Safety radius alarm notification shown in background/terminated state"
```

## Important Notes

### Android 13+ (API 33+)
- User must grant notification permission manually
- App will request permission on first launch
- Go to: Settings → Apps → Season → Notifications → Allow

### Battery Optimization
- App should be excluded from battery optimization
- Go to: Settings → Apps → Season → Battery → Unrestricted
- This ensures notifications work even when device is in doze mode

### Notification Channels
- Channels are created automatically when app first runs
- Channels are also created in background handler if app is terminated
- Users can modify channel settings in Android Settings → Apps → Season → Notifications

### Backend Requirements

**For notifications to work when app is closed:**

1. **Use FCM v1 API** (recommended):
   ```json
   {
     "message": {
       "token": "FCM_TOKEN",
       "notification": {
         "title": "Title",
         "body": "Body"
       },
       "data": {
         "custom": "data"
       }
     }
   }
   ```

2. **Or use data-only messages**:
   ```json
   {
     "message": {
       "token": "FCM_TOKEN",
       "data": {
         "title": "Title",
         "body": "Body",
         "type": "notification_type"
       }
     }
   }
   ```

3. **For alarm notifications**:
   - Must include `"type": "safety_radius_alert"` in data
   - Must include `"is_admin": "true"` or `"for_admin": "true"` in data
   - Should include `group_id` and `member_id` in data

## Troubleshooting

### Issue: Still not receiving notifications when app is closed

**Check:**
1. ✅ Notification permission granted (Android 13+)
2. ✅ Battery optimization disabled for app
3. ✅ FCM token is valid and registered
4. ✅ Backend is sending to correct FCM token
5. ✅ Check logs for background handler execution
6. ✅ Verify notification channels exist

### Issue: Notifications work in foreground but not when closed

**Solution:**
- This usually means background handler isn't being called
- Check if `FirebaseMessaging.onBackgroundMessage()` is registered in `main.dart`
- Verify FCM token is correct
- Check backend is sending proper FCM payload

### Issue: Notifications appear but no sound

**Solution:**
- Check device volume settings
- Check notification channel sound settings
- For alarms, verify alarm channel is created natively (MainActivity.kt)
- Check Do Not Disturb mode is not enabled

## Files Modified

1. `lib/core/services/notification_service.dart`
   - Added WidgetsFlutterBinding initialization
   - Added notification channel creation in background handler
   - Added data-only message handling
   - Improved error handling

2. `android/app/src/main/AndroidManifest.xml`
   - Added POST_NOTIFICATIONS permission
   - Added WAKE_LOCK permission
   - Added FOREGROUND_SERVICE_LOCATION permission

## Next Steps

1. **Rebuild the app** to include these fixes
2. **Test with app closed** - Force stop app, send notification, verify it appears
3. **Check logs** - Verify background handler is being called
4. **Test all notification types** - Regular, data-only, and alarm notifications
5. **Verify permissions** - Ensure user grants notification permission

## Summary

Notifications should now work reliably when the app is closed or terminated. The key fixes were:
- Initializing Flutter bindings in background handler
- Creating notification channels before showing notifications
- Handling data-only messages
- Adding required Android permissions

