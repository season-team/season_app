# FCM Data-Only Solution for Alarm Sound

## Problem
When FCM receives a message with a `notification` payload, it **automatically displays the notification** before our background handler can process it. This means:
1. FCM shows the notification immediately (without guaranteed sound)
2. Our background handler runs AFTER FCM has already displayed it
3. Even if we cancel and show our own, there's a delay and the sound might not play

## Solution: Use Data-Only Messages for Safety Radius Alarms

**Send data-only FCM messages for safety radius alarms** so FCM doesn't auto-display them. Our background handler will handle the display with guaranteed sound.

## Current Payload (Causes Auto-Display)
```json
{
  "message": {
    "token": "...",
    "notification": {  // ← This causes FCM to auto-display
      "title": "🚨 Safety Alert",
      "body": "Fady Malak is outside the safety radius!"
    },
    "data": { ... },
    "android": { ... }
  }
}
```

## Recommended Payload (Data-Only)
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

## Key Changes

1. **Remove `notification` object** - This prevents FCM from auto-displaying
2. **Move `title` and `body` to `data`** - Our handler will extract them
3. **Keep `android.priority: "high"`** - Ensures message is delivered quickly
4. **Remove `android.notification`** - Not needed for data-only messages

## Benefits

✅ **FCM won't auto-display** - Our handler has full control
✅ **Guaranteed sound** - Our handler shows notification with alarm sound
✅ **No timing issues** - No race condition with FCM auto-display
✅ **Consistent behavior** - Same notification display logic for all states

## Client-Side Code

The client-side code already handles data-only messages correctly:
- Background handler extracts `title` and `body` from `data` if `notification` is null
- Shows local notification with alarm sound
- Uses alarm category for maximum priority

## Testing

1. Send a data-only FCM message (no `notification` object)
2. Verify the background handler receives it
3. Verify our local notification appears with sound
4. Check logs for: `🚨 Safety radius alarm notification shown`

## Alternative: Keep Current Structure

If you must keep the `notification` object for other reasons:
- The client-side code will still try to cancel FCM's notification
- But there might be a brief delay where FCM's notification appears without sound
- The alarm sound should still play from our local notification

## Recommendation

**Use data-only messages for safety radius alarms** to ensure reliable alarm sound playback.

