# Safety Radius Alarm - Implementation Summary

## Overview
This document provides a complete summary of the safety radius alarm feature implementation, including what the backend needs to do and how the client-side handles alarms.

## Feature Description
When a group member goes outside the safety radius, an alarm notification with sound should be triggered on the group admin's device. This works in two scenarios:
1. **App Open (Foreground)**: Client-side monitoring detects out-of-range members
2. **App Closed (Terminated)**: Backend sends FCM notification → Client receives and plays alarm

---

## ✅ Client-Side Implementation (COMPLETE)

### 1. Foreground Monitoring (`SafetyRadiusAlarmService`)
- **Location**: `lib/core/services/safety_radius_alarm_service.dart`
- **How it works**:
  - Monitors group members every 10 seconds when Group Details screen is open
  - Detects transitions from "in range" → "out of range"
  - Triggers alarm notification with system default sound
  - **Only works for group admins**
- **Status**: ✅ Fully implemented and working

### 2. Background/Terminated State (`firebaseMessagingBackgroundHandler`)
- **Location**: `lib/core/services/notification_service.dart`
- **How it works**:
  - Receives FCM notifications from backend
  - Detects `type: "safety_radius_alert"` in notification data
  - Shows alarm notification with system default sound
  - Works even when app is completely terminated
- **Status**: ✅ Fully implemented and ready

### 3. Notification Channel Setup
- **Location**: `lib/core/services/notification_service.dart`
- **Channel**: `safety_radius_alarm_channel`
- **Priority**: Maximum (Importance.max, Priority.max)
- **Sound**: System default alarm sound
- **Status**: ✅ Fully configured

---

## ⚠️ Backend Implementation (REQUIRED)

### What the Backend MUST Do

#### 1. Detect Out-of-Range Members
When processing location updates via `POST /api/groups/{id}/location`:

```php
// Pseudo-code example
function processLocationUpdate($groupId, $memberId, $latitude, $longitude) {
    $group = Group::find($groupId);
    $member = GroupMember::where('group_id', $groupId)
                          ->where('user_id', $memberId)
                          ->first();
    
    // Calculate distance from group center
    $distance = calculateDistance(
        $group->center_latitude,
        $group->center_longitude,
        $latitude,
        $longitude
    );
    
    // Check if member is outside safety radius
    $wasInRange = $member->is_within_radius;
    $isNowInRange = $distance <= $group->safety_radius;
    
    // Update member status
    $member->is_within_radius = $isNowInRange;
    $member->distance_from_center = $distance;
    $member->save();
    
    // Detect transition: was in range, now out of range
    if ($wasInRange && !$isNowInRange) {
        // Member just went out of range - send alarm to admin
        sendSafetyRadiusAlarm($group, $member);
    }
}
```

#### 2. Send FCM Notification to Group Admin
When a member goes out of range, send FCM notification **ONLY** to the group owner/admin:

```php
function sendSafetyRadiusAlarm($group, $outOfRangeMember) {
    $owner = $group->owner; // Group owner/admin
    $fcmToken = $owner->fcm_token; // Get owner's FCM token
    
    if (!$fcmToken) {
        // Owner doesn't have FCM token registered
        return;
    }
    
    // Prepare notification payload
    $notification = [
        'title' => '🚨 Safety Alert',
        'body' => "{$outOfRangeMember->user->name} is outside the safety radius!",
    ];
    
    $data = [
        'type' => 'safety_radius_alert',
        'notification_type' => 'safety_radius_alert',
        'group_id' => (string) $group->id,
        'member_id' => (string) $outOfRangeMember->id,
        'member_name' => $outOfRangeMember->user->name,
        'is_admin' => 'true',
        'is_owner' => 'true',
        'for_admin' => 'true',
    ];
    
    // Send FCM notification
    sendFCMNotification($fcmToken, $notification, $data);
}
```

#### 3. FCM Notification Format

**Required Structure:**
```json
{
  "to": "OWNER_FCM_TOKEN_HERE",
  "notification": {
    "title": "🚨 Safety Alert",
    "body": "Member Name is outside the safety radius!"
  },
  "data": {
    "type": "safety_radius_alert",
    "notification_type": "safety_radius_alert",
    "group_id": "32",
    "member_id": "29",
    "member_name": "Fady Malak",
    "is_admin": "true",
    "is_owner": "true",
    "for_admin": "true"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "safety_radius_alarm_channel",
      "sound": "default",
      "priority": "max",
      "importance": "max"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "interruption-level": "critical",
        "alert": {
          "title": "🚨 Safety Alert",
          "body": "Member Name is outside the safety radius!"
        }
      }
    }
  }
}
```

#### 4. Important Rules

✅ **DO:**
- Only send notifications to the group **owner/admin**
- Send notification when member transitions from "in range" → "out of range"
- Include all required data fields (`type`, `group_id`, `member_id`, etc.)
- Use `channel_id: "safety_radius_alarm_channel"` for Android
- Use `interruption-level: "critical"` for iOS
- Use system default sound (`"sound": "default"`)

❌ **DON'T:**
- Send notifications to regular members (only admin)
- Send duplicate notifications (check state transition)
- Send notifications when member is already out of range (only on transition)
- Use custom sound files (use system default)

---

## 📋 Backend Checklist

- [ ] Detect when member goes outside safety radius
- [ ] Track previous state to detect transitions (in range → out of range)
- [ ] Get group owner's FCM token
- [ ] Send FCM notification with correct format
- [ ] Include all required data fields
- [ ] Use correct notification channel (`safety_radius_alarm_channel`)
- [ ] Set maximum priority/importance
- [ ] Use system default sound
- [ ] Test with app in terminated state
- [ ] Test with app in background state
- [ ] Test with app in foreground state

---

## 🧪 Testing Guide

### Test Scenario 1: App Open (Foreground)
1. Open app and navigate to Group Details screen
2. Have a member move outside safety radius
3. **Expected**: Alarm notification appears with sound (client-side detection)

### Test Scenario 2: App Closed (Terminated)
1. Close the app completely
2. Backend detects member goes out of range
3. Backend sends FCM notification to admin
4. **Expected**: Alarm notification appears with sound (FCM handler)

### Test Scenario 3: App in Background
1. Put app in background (home button)
2. Backend detects member goes out of range
3. Backend sends FCM notification to admin
4. **Expected**: Alarm notification appears with sound (FCM handler)

### Test Scenario 4: Only Admin Receives Alarms
1. Login as regular member (not admin)
2. Have another member go out of range
3. **Expected**: No alarm notification (only admin receives)

---

## 🔧 API Endpoints Reference

### Location Update Endpoint
```
POST /api/groups/{id}/location
Body: {
  "latitude": 25.2048,
  "longitude": 55.2708
}
```

**This is where backend should:**
1. Update member's location
2. Calculate distance from group center
3. Check if member is within safety radius
4. Detect state transition
5. Send FCM notification if needed

---

## 📱 Client-Side Files Reference

1. **Safety Radius Alarm Service**: `lib/core/services/safety_radius_alarm_service.dart`
   - Handles foreground monitoring
   - Triggers alarms when app is open

2. **Notification Service**: `lib/core/services/notification_service.dart`
   - Handles FCM notifications
   - `firebaseMessagingBackgroundHandler()` - Processes terminated state notifications
   - `_handleForegroundMessage()` - Processes foreground notifications

3. **Group Details Screen**: `lib/features/groups/presentation/screens/group_details_screen.dart`
   - Starts monitoring when screen opens
   - Refreshes group details every 10 seconds

---

## 🎯 Key Points for Backend Developer

1. **Detection Logic**: Check distance from group center vs safety radius
2. **State Tracking**: Only send notification on transition (in → out), not continuously
3. **Target User**: Only send to group owner/admin, never to regular members
4. **FCM Format**: Follow the exact format specified above
5. **Priority**: Use maximum priority to ensure delivery even when app is terminated
6. **Sound**: Use system default sound (don't specify custom sound file)

---

## 📞 Support

If you have questions about the implementation:
1. Check `SAFETY_RADIUS_ALARM_BACKEND_REQUIREMENTS.md` for detailed FCM format
2. Review client-side code in `lib/core/services/notification_service.dart`
3. Test FCM notifications using Firebase Console or Postman

---

## ✅ Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Client Foreground Monitoring | ✅ Complete | Works when app is open |
| Client FCM Handler | ✅ Complete | Ready to receive notifications |
| Backend Detection Logic | ⚠️ Required | Needs implementation |
| Backend FCM Sending | ⚠️ Required | Needs implementation |
| Notification Channel Setup | ✅ Complete | Configured in client |
| Admin-Only Logic | ✅ Complete | Client checks admin status |

**The client-side is 100% ready. The backend needs to implement the detection and FCM sending logic.**

