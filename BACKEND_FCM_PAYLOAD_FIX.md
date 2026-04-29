# Backend FCM Payload Fix - FCM v1 API Structure

## Problem
The alarm sound is NOT playing. The FCM v1 API has a different structure than the legacy API.

## Important: FCM v1 API Structure

**FCM v1 API does NOT support:**
- ❌ `sound` in `message.notification` (not a valid field)
- ❌ `priority` in `message.android.notification` (not a valid field)
- ❌ `importance` in `message.android.notification` (not a valid field)

## Correct FCM v1 API Payload Structure

```json
{
  "message": {
    "token": "USER_FCM_TOKEN",
    "notification": {
      "title": "🚨 Safety Alert",
      "body": "Fady Malak is outside the safety radius!"
      // Note: NO "sound" field here - FCM v1 doesn't support it
    },
    "data": {
      "type": "safety_radius_alert",
      "notification_type": "safety_radius_alert",
      "group_id": "32",
      "member_id": "29",
      "member_name": "Fady Malak",
      "is_admin": "true",
      "is_owner": "true",
      "for_admin": "true",
      "distance": "150",
      "safety_radius": "100",
      "group_name": "Test Group",
      "timestamp": "2024-01-15T10:30:00Z"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "safety_radius_alarm_channel",
        "sound": "default"
        // Note: Only "sound" and "channel_id" are valid here
        // "priority" and "importance" are NOT valid in android.notification
      }
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "default",
          "interruption-level": "critical",
          "alert": {
            "title": "🚨 Safety Alert",
            "body": "Fady Malak is outside the safety radius!"
          },
          "badge": 1
        }
      }
    }
  }
}
```

## Key Points

1. **`message.notification`** - Only contains `title` and `body` (no `sound` field in FCM v1)
2. **`message.android.priority`** - Must be at `android.priority` (not inside `android.notification`)
3. **`message.android.notification.sound`** - This is where the sound is specified for Android
4. **`message.android.notification.channel_id`** - Must match the channel created in the app

## Why Sound Might Not Play

Even with `android.notification.sound: "default"`, the sound might not play because:
1. FCM auto-displays the notification before our background handler runs
2. The notification channel might not be properly configured on the device
3. Device settings might mute the channel

## Client-Side Solution

The client-side code handles this by:
- Cancelling any FCM auto-displayed notifications
- Showing a local notification with guaranteed sound
- Using alarm category to ensure sound plays
- Configuring the notification channel with `importance: max` and `playSound: true`

## Current Backend Payload (Your Current Structure)

Your current payload structure is mostly correct for FCM v1 API:
```json
{
  "message": {
    "token": "...",
    "notification": {
      "title": "🚨 Safety Alert",
      "body": "Fady Malak is outside the safety radius!"
    },
    "data": { ... },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "safety_radius_alarm_channel",
        "sound": "default"
      }
    }
  }
}
```

**This structure is CORRECT for FCM v1 API!** ✅

## Why Sound Still Might Not Play

Even with the correct structure, sound might not play because:
1. **FCM auto-displays notifications** before our background handler can process them
2. The auto-displayed notification might not respect the sound setting
3. Device notification channel settings might override the sound

## Client-Side Solution (Already Implemented)

The client-side code now:
- ✅ Cancels any FCM auto-displayed notifications
- ✅ Shows a local notification with guaranteed sound
- ✅ Uses alarm category (`AndroidNotificationCategory.alarm`) for maximum priority
- ✅ Configures notification channel with `importance: max` and `playSound: true`

## Testing

1. Send a test FCM notification with the current structure
2. The client will cancel the FCM notification and show its own with sound
3. **Verify the alarm sound plays** (should work now with client-side fix)
4. Check device volume is up and not in silent mode
5. Check device Settings → Apps → Season App → Notifications → "Safety Radius Alarms" channel is enabled

## Summary

**Your FCM payload structure is correct for FCM v1 API!** 

The client-side code now ensures the alarm sound plays by:
- Cancelling FCM auto-displayed notifications
- Showing a local notification with guaranteed sound configuration

The alarm should now work correctly! 🎉

