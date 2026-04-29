# Alarm Sound Troubleshooting Guide

## Issue
Notification appears but alarm sound doesn't play when a user goes outside the safety radius.

## Possible Causes & Solutions

### 1. Backend FCM Payload Missing Sound
**Problem**: The FCM notification payload from backend doesn't include the `sound` field.

**Solution**: Ensure backend sends FCM with sound in the payload:
```json
{
  "notification": {
    "title": "🚨 Safety Alert",
    "body": "Member is outside the safety radius!",
    "sound": "default"  // ← THIS IS CRITICAL
  },
  "android": {
    "notification": {
      "channel_id": "safety_radius_alarm_channel",
      "sound": "default"  // ← ALSO NEEDED
    }
  }
}
```

### 2. Device Notification Settings
**Problem**: User might have muted notifications for the app or the specific channel.

**Solution**: 
- Check device Settings → Apps → Season App → Notifications
- Ensure "Safety Radius Alarms" channel is enabled and sound is on
- Check if device is in Do Not Disturb mode (alarm category should override this)

### 3. Notification Channel Not Created Properly
**Problem**: The alarm notification channel might not be created with correct settings.

**Solution**: 
- The channel is created automatically when the app starts
- Channel ID: `safety_radius_alarm_channel`
- Importance: `max`
- Play Sound: `true`
- Category: `alarm`

### 4. FCM Notification vs Local Notification
**Problem**: When FCM sends notification, Android might use FCM's sound settings instead of local notification settings.

**Solution**: 
- Backend MUST include `sound: "default"` in FCM payload
- Client-side code will also show local notification with alarm sound as fallback

## Testing Steps

1. **Check FCM Payload**:
   - Verify backend sends `notification.sound: "default"`
   - Verify backend sends `android.notification.sound: "default"`
   - Verify backend sends `android.notification.channel_id: "safety_radius_alarm_channel"`

2. **Check Device Settings**:
   - Go to Settings → Apps → Season App → Notifications
   - Find "Safety Radius Alarms" channel
   - Ensure it's enabled and sound is on
   - Check importance level (should be "Urgent" or "High")

3. **Test Notification**:
   - Have a member go outside safety radius
   - Check if notification appears
   - Check if sound plays
   - Check device volume (not muted)

4. **Check Logs**:
   - Look for: `🚨 Safety radius alarm notification shown`
   - Verify channel is created: `✅ Android notification channels created`

## Current Implementation

The client-side code:
- ✅ Creates alarm notification channel with `importance: max` and `playSound: true`
- ✅ Uses `category: AndroidNotificationCategory.alarm` for alarm notifications
- ✅ Sets `priority: Priority.max` and `importance: Importance.max`
- ✅ Handles both FCM notifications (background/terminated) and local notifications (foreground)

## Required Backend Configuration

The backend MUST send FCM notifications with:
```json
{
  "notification": {
    "sound": "default"  // ← REQUIRED
  },
  "android": {
    "notification": {
      "channel_id": "safety_radius_alarm_channel",
      "sound": "default"  // ← REQUIRED
    }
  }
}
```

Without these fields, Android will not play the sound even if the notification appears.

## Next Steps

1. **CRITICAL**: Verify backend is sending `sound: "default"` in FCM payload
   - Check FCM payload includes `notification.sound: "default"`
   - Check FCM payload includes `android.notification.sound: "default"`
   - Without these, Android will NOT play sound even if notification appears

2. Check device notification settings for the app
   - Settings → Apps → Season App → Notifications
   - Ensure "Safety Radius Alarms" channel is enabled
   - Ensure sound is enabled for this channel

3. Test with device volume up and not in silent mode
   - Alarm category should override Do Not Disturb, but verify

4. Check Android logs for notification details:
   - Look for: `🚨 Safety radius alarm notification shown`
   - Verify: `Channel: safety_radius_alarm_channel`
   - Verify: `Play Sound: true, Category: alarm`

## Client-Side Improvements Made

The client-side code has been updated to:
- ✅ Always create alarm notification channel with `importance: max` and `playSound: true`
- ✅ Use `category: AndroidNotificationCategory.alarm` for alarm notifications
- ✅ Set `priority: Priority.max` and `importance: Importance.max`
- ✅ Use unique notification IDs to prevent suppression
- ✅ Add detailed logging for debugging

**However, the sound will still NOT play if the backend FCM payload doesn't include `sound: "default"`**

