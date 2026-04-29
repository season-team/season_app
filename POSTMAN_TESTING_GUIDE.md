# Postman Testing Guide for FCM Safety Radius Alarms

## Prerequisites

1. **Firebase Project Setup**
   - Create a Firebase project at https://console.firebase.google.com
   - Enable Cloud Messaging API
   - Download service account JSON key

2. **Get OAuth2 Access Token**
   - You need an access token to authenticate with FCM v1 API
   - Use the service account JSON to generate a JWT and exchange it for an access token

## Step 1: Get OAuth2 Access Token

### Request
```
POST https://oauth2.googleapis.com/token
Content-Type: application/x-www-form-urlencoded
```

### Body (x-www-form-urlencoded)
```
grant_type: urn:ietf:params:oauth:grant-type:jwt-bearer
assertion: {JWT_TOKEN}
```

**Note:** You need to generate a JWT token using your service account credentials. This is typically handled by the Firebase Admin SDK in Laravel.

## Step 2: Send Test Notification

### Request
```
POST https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send
Authorization: Bearer {ACCESS_TOKEN}
Content-Type: application/json
```

### Replace:
- `{PROJECT_ID}` - Your Firebase project ID
- `{ACCESS_TOKEN}` - OAuth2 access token from Step 1
- `{USER_FCM_TOKEN}` - The FCM token from the mobile app

### Body (JSON)
```json
{
  "message": {
    "token": "{USER_FCM_TOKEN}",
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
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "default",
          "interruption-level": "critical",
          "alert": {
            "title": "🚨 Safety Alert",
            "body": "Test User is outside the safety radius!"
          },
          "badge": 1
        }
      }
    }
  }
}
```

## Step 3: Expected Response

### Success Response (200 OK)
```json
{
  "name": "projects/{PROJECT_ID}/messages/{MESSAGE_ID}"
}
```

### Error Response (400 Bad Request)
```json
{
  "error": {
    "code": 400,
    "message": "Invalid argument",
    "status": "INVALID_ARGUMENT"
  }
}
```

## Quick Test Payload

Copy this JSON directly into Postman:

```json
{
  "message": {
    "token": "YOUR_DEVICE_FCM_TOKEN",
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

## How to Get FCM Token from Mobile App

1. Open the app
2. Check the logs for: `🔑 FCM Token: ...`
3. Copy the token
4. Use it in the Postman request

## Testing Scenarios

### Test 1: App in Foreground
1. Keep app open
2. Send notification
3. Verify notification appears with sound

### Test 2: App in Background
1. Minimize app (don't close)
2. Send notification
3. Verify notification appears with sound

### Test 3: App Terminated
1. Force close the app
2. Send notification
3. Verify notification appears with sound

## Troubleshooting

### Error: "Invalid argument"
- Check all data values are strings (not numbers or booleans)
- Verify FCM token is valid
- Ensure project ID is correct

### Error: "Unauthorized"
- Access token expired (get a new one)
- Check service account permissions

### Notification appears but no sound
- Verify it's a data-only message (no `notification` object)
- Check device notification settings
- Ensure app is using latest version with sound fixes

### No notification received
- Verify FCM token is correct
- Check device has internet connection
- Verify app has notification permissions

## Notes

- **All data values must be strings** - Convert numbers and booleans
- **No `notification` object** - Use data-only for alarms
- **Priority must be "high"** - For immediate delivery
- **Test with real device** - Emulators may not work correctly

