# Laravel FCM Implementation Guide - Safety Radius Alarms

## Overview
This guide explains how to implement Firebase Cloud Messaging (FCM) for safety radius alarms in Laravel. The alarm notifications must play sound reliably, even when the app is in the background or terminated.

## Important: Use Data-Only Messages

**CRITICAL:** For safety radius alarms, use **data-only messages** (no `notification` object). This ensures:
- ✅ Full control over notification display and sound
- ✅ Guaranteed alarm sound playback
- ✅ No timing issues with FCM auto-display

## FCM v1 API Endpoint

```
POST https://fcm.googleapis.com/v1/projects/{project_id}/messages:send
```

**Headers:**
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

## Payload Structure

### For Safety Radius Alarms (Data-Only Message)

```json
{
  "message": {
    "token": "{user_fcm_token}",
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

### Key Points:
- ❌ **NO `notification` object** - This prevents FCM from auto-displaying
- ✅ **All data in `data` object** - Client handles display
- ✅ **`android.priority: "high"`** - Ensures quick delivery
- ✅ **`title` and `body` in `data`** - Client extracts these for display

## Laravel Implementation

### 1. Install Firebase Admin SDK

```bash
composer require kreait/firebase-php
```

### 2. Configure Firebase Credentials

Add to `.env`:
```
FIREBASE_CREDENTIALS_PATH=/path/to/firebase-credentials.json
FIREBASE_PROJECT_ID=your-project-id
```

### 3. Create FCM Service

```php
<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Firebase\Messaging\MessageData;
use Illuminate\Support\Facades\Log;

class FCMService
{
    protected $messaging;

    public function __construct()
    {
        $factory = (new Factory)
            ->withServiceAccount(config('firebase.credentials_path'));

        $this->messaging = $factory->createMessaging();
    }

    /**
     * Send safety radius alarm notification
     * 
     * @param string $fcmToken User's FCM token
     * @param array $data Notification data
     * @return bool
     */
    public function sendSafetyRadiusAlarm(string $fcmToken, array $data): bool
    {
        try {
            // Prepare data payload (all values must be strings)
            $messageData = [
                'type' => 'safety_radius_alert',
                'notification_type' => 'safety_radius_alert',
                'group_id' => (string) $data['group_id'],
                'member_id' => (string) $data['member_id'],
                'member_name' => $data['member_name'],
                'is_admin' => $data['is_admin'] ? 'true' : 'false',
                'is_owner' => $data['is_owner'] ? 'true' : 'false',
                'for_admin' => 'true', // Always true for safety radius alarms
                'distance' => (string) $data['distance'],
                'safety_radius' => (string) $data['safety_radius'],
                'group_name' => $data['group_name'],
                'timestamp' => $data['timestamp'] ?? now()->toIso8601String(),
                'title' => $data['title'] ?? '🚨 Safety Alert',
                'body' => $data['body'] ?? "{$data['member_name']} is outside the safety radius!",
            ];

            // Create message with data-only payload (NO notification object)
            $message = CloudMessage::withTarget('token', $fcmToken)
                ->withData($messageData)
                ->withAndroidConfig([
                    'priority' => 'high',
                ])
                ->withApnsConfig([
                    'payload' => [
                        'aps' => [
                            'sound' => 'default',
                            'interruption-level' => 'critical',
                            'alert' => [
                                'title' => $messageData['title'],
                                'body' => $messageData['body'],
                            ],
                            'badge' => 1,
                        ],
                    ],
                ]);

            // Send message
            $result = $this->messaging->send($message);
            
            Log::info('Safety radius alarm sent', [
                'fcm_token' => substr($fcmToken, 0, 20) . '...',
                'message_id' => $result,
                'group_id' => $data['group_id'],
                'member_id' => $data['member_id'],
            ]);

            return true;
        } catch (\Exception $e) {
            Log::error('Failed to send safety radius alarm', [
                'error' => $e->getMessage(),
                'fcm_token' => substr($fcmToken, 0, 20) . '...',
                'data' => $data,
            ]);

            return false;
        }
    }

    /**
     * Send regular notification (with notification object)
     * Use this for non-alarm notifications
     */
    public function sendNotification(string $fcmToken, string $title, string $body, array $data = []): bool
    {
        try {
            $message = CloudMessage::withTarget('token', $fcmToken)
                ->withNotification(Notification::create($title, $body))
                ->withData($data)
                ->withAndroidConfig([
                    'priority' => 'high',
                    'notification' => [
                        'channel_id' => 'season_app_channel',
                        'sound' => 'default',
                    ],
                ]);

            $this->messaging->send($message);
            return true;
        } catch (\Exception $e) {
            Log::error('Failed to send notification', [
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }
}
```

### 4. Usage in Controller/Service

```php
<?php

namespace App\Http\Controllers;

use App\Services\FCMService;
use App\Models\Group;
use App\Models\User;
use Illuminate\Http\Request;

class SafetyRadiusController extends Controller
{
    protected $fcmService;

    public function __construct(FCMService $fcmService)
    {
        $this->fcmService = $fcmService;
    }

    /**
     * Send safety radius alarm when member goes outside radius
     */
    public function sendSafetyRadiusAlarm(Request $request)
    {
        $group = Group::findOrFail($request->group_id);
        $member = User::findOrFail($request->member_id);
        
        // Only send to group owner/admin
        $owner = $group->owner;
        
        if (!$owner || !$owner->fcm_token) {
            return response()->json(['error' => 'Owner FCM token not found'], 400);
        }

        // Calculate distance (your logic here)
        $distance = $this->calculateDistance($request->latitude, $request->longitude, $group);
        
        // Prepare notification data
        $data = [
            'group_id' => $group->id,
            'member_id' => $member->id,
            'member_name' => $member->name,
            'is_admin' => true,
            'is_owner' => true,
            'distance' => $distance,
            'safety_radius' => $group->safety_radius,
            'group_name' => $group->name,
            'title' => '🚨 Safety Alert',
            'body' => "{$member->name} is outside the safety radius!",
        ];

        // Send alarm notification
        $sent = $this->fcmService->sendSafetyRadiusAlarm($owner->fcm_token, $data);

        return response()->json([
            'success' => $sent,
            'message' => $sent ? 'Alarm sent successfully' : 'Failed to send alarm',
        ]);
    }
}
```

## Testing with Postman

### 1. Get Access Token

First, get an OAuth2 access token:

```
POST https://oauth2.googleapis.com/token
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer
&assertion={JWT_TOKEN}
```

### 2. Send Test Notification

```
POST https://fcm.googleapis.com/v1/projects/{project_id}/messages:send
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "message": {
    "token": "USER_FCM_TOKEN",
    "data": {
      "type": "safety_radius_alert",
      "notification_type": "safety_radius_alert",
      "group_id": "32",
      "member_id": "29",
      "member_name": "Test User",
      "is_admin": "true",
      "is_owner": "true",
      "for_admin": "true",
      "distance": "150",
      "safety_radius": "100",
      "group_name": "Test Group",
      "timestamp": "2024-01-15T10:30:00Z",
      "title": "🚨 Safety Alert",
      "body": "Test User is outside the safety radius!"
    },
    "android": {
      "priority": "high"
    }
  }
}
```

## Important Notes

### 1. Data Values Must Be Strings
All values in the `data` object must be strings. Convert booleans and numbers:
```php
'is_admin' => $isAdmin ? 'true' : 'false',
'group_id' => (string) $group->id,
```

### 2. No Notification Object for Alarms
**DO NOT** include a `notification` object for safety radius alarms. This causes FCM to auto-display the notification, which prevents our client from controlling the sound.

### 3. Priority Setting
Always use `"priority": "high"` for alarm notifications to ensure immediate delivery.

### 4. Error Handling
Handle FCM errors gracefully:
- Invalid FCM token → Remove from database
- Rate limiting → Implement retry logic
- Network errors → Log and retry

## Client-Side Handling

The Flutter client will:
1. Receive the data-only message
2. Extract `title` and `body` from `data`
3. Show local notification with alarm sound
4. Use alarm category for maximum priority

## Testing Checklist

- [ ] FCM credentials configured correctly
- [ ] User FCM tokens stored in database
- [ ] Data-only messages sent (no `notification` object)
- [ ] All data values are strings
- [ ] `android.priority` set to `"high"`
- [ ] Error handling implemented
- [ ] Logging for debugging
- [ ] Test with app in foreground
- [ ] Test with app in background
- [ ] Test with app terminated
- [ ] Verify alarm sound plays in all states

## Support

If you encounter issues:
1. Check FCM token is valid
2. Verify Firebase credentials
3. Check Laravel logs for errors
4. Test with Postman first
5. Verify client receives the message

## References

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FCM v1 API Reference](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
- [Kreait Firebase PHP SDK](https://github.com/kreait/firebase-php)

