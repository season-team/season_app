# Safety Radius Alarm - Backend Requirements

## Overview
This document describes the requirements for the backend to send Firebase Cloud Messaging (FCM) notifications when a group member goes outside the safety radius. These notifications will trigger an alarm sound on the group admin's device, even when the app is terminated.

## When to Send Notification
Send an FCM notification to the group admin (owner) when:
- A group member's location update indicates they are now **outside** the safety radius
- The member was previously **within** the safety radius (to avoid duplicate notifications)
- Only send to the group **owner/admin**, not to regular members

## FCM Notification Format

### Required Data Fields
```json
{
  "type": "safety_radius_alert",
  "notification_type": "safety_radius_alert",
  "group_id": 32,
  "member_id": 29,
  "member_name": "Fady Malak",
  "is_admin": true,
  "is_owner": true,
  "for_admin": true
}
```

### Notification Payload Structure (FCM v1 API)

**⚠️ CRITICAL: For Alarm Sound to Work Reliably**

**RECOMMENDED: Use Data-Only Messages** (No `notification` object)
- Prevents FCM from auto-displaying the notification
- Gives our background handler full control
- Guarantees alarm sound will play

**ALTERNATIVE: Keep `notification` Object** (Current Structure)
- FCM will auto-display the notification
- Our handler will try to cancel it and show our own
- May have brief delay where FCM notification appears without sound

**IMPORTANT: FCM v1 API Structure**
- ❌ `sound` is NOT a valid field in `message.notification`
- ❌ `priority` and `importance` are NOT valid fields in `message.android.notification`
- ✅ `sound` must be in `message.android.notification.sound` (if using notification object)
- ✅ `priority` must be at `message.android.priority` (not inside notification)

### Option 1: Data-Only Message (RECOMMENDED for Alarm Sound)

```json
{
  "message": {
    "token": "USER_FCM_TOKEN",
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
      "timestamp": "2024-01-15T10:30:00Z",
      "title": "🚨 Safety Alert",
      "body": "Fady Malak is outside the safety radius!"
    },
    "android": {
      "priority": "high"
    }
  }
}
```

**Benefits:**
- ✅ FCM won't auto-display (our handler has full control)
- ✅ Guaranteed alarm sound playback
- ✅ No timing issues or race conditions

### Option 2: With Notification Object (Current Structure)

```json
{
  "message": {
    "token": "USER_FCM_TOKEN",
    "notification": {
      "title": "🚨 Safety Alert",
      "body": "Fady Malak is outside the safety radius!"
      // Note: FCM v1 API does NOT support "sound" in notification object
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

**Note:** With this structure, FCM will auto-display the notification. Our client-side code will cancel it and show our own with sound, but there may be a brief delay.

**REQUIRED FIELDS FOR ALARM SOUND:**
1. ✅ `android.notification.sound` MUST be set to `"default"` - You have this ✓
2. ✅ `android.notification.channel_id` MUST be `"safety_radius_alarm_channel"` - You have this ✓
3. ✅ `android.priority` MUST be `"high"` - You have this ✓

**Note:** Even with these fields, FCM might auto-display the notification without sound. The client-side code handles this by cancelling the FCM notification and showing a local notification with guaranteed sound.

## Implementation Details

### 1. Detection Logic
- When processing location updates via `POST /api/groups/{id}/location`
- Check if the member's distance from the group center exceeds `safety_radius`
- Compare with previous status to detect transition from "in range" to "out of range"
- Only trigger notification on state change, not on every update

### 2. Target User
- Send notification **only** to the group owner/admin
- Use the FCM token associated with the group owner's user account
- Do NOT send to regular members

### 3. Notification Priority
- Use **high priority** for Android
- Use **critical interruption level** for iOS
- This ensures the notification is delivered even when the app is terminated

### 4. Sound
- Use system default alarm sound (do not specify custom sound file)
- Android: `"sound": "default"` in notification payload
- iOS: `"sound": "default"` in APNs payload

## Example Backend Code (Laravel)

```php
// When detecting member is out of range
if ($member->is_out_of_range && !$member->was_out_of_range) {
    $group = $member->group;
    $owner = $group->owner;
    
    // Get owner's FCM token
    $fcmToken = $owner->fcm_token; // Store FCM token in users table
    
    if ($fcmToken) {
        // Send FCM notification
        $notification = [
            'title' => '🚨 Safety Alert',
            'body' => "{$member->user->name} is outside the safety radius!",
        ];
        
        $data = [
            'type' => 'safety_radius_alert',
            'notification_type' => 'safety_radius_alert',
            'group_id' => (string) $group->id,
            'member_id' => (string) $member->id,
            'member_name' => $member->user->name,
            'is_admin' => 'true',
            'is_owner' => 'true',
            'for_admin' => 'true',
        ];
        
        // Use Laravel Notification or FCM SDK
        $owner->notify(new SafetyRadiusAlertNotification($notification, $data));
    }
}
```

## Testing
1. Create a test group with admin and member
2. Set a small safety radius (e.g., 50 meters)
3. Move the member outside the radius
4. Verify admin receives alarm notification with sound
5. Test with app in:
   - Foreground
   - Background
   - Terminated state

## Notes
- The client-side code will automatically handle these notifications
- The alarm will play system default sound
- Notifications work even when app is completely terminated
- Only group admins receive these alarms

