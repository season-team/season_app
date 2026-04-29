# iOS Alarm Sound Setup Guide

## Current Status

The iOS notification configuration currently uses:
- ✅ `interruptionLevel: InterruptionLevel.critical` - Makes notification high priority
- ✅ `presentSound: true` - Plays notification sound
- ⚠️ **Uses default notification sound** (not a true alarm sound)

## iOS Alarm Sound Options

### Option 1: Critical Alert (Requires Apple Approval)

For true alarm sounds on iOS, you need **Critical Alert** entitlement:

1. **Request Critical Alert Entitlement from Apple**
   - Go to https://developer.apple.com/contact/request/critical-alerts-entitlement/
   - Explain why you need it (safety/emergency alerts)
   - Wait for approval (can take days/weeks)

2. **Add Entitlement to Xcode**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Add "Push Notifications" capability
   - Add "Critical Alerts" capability (after Apple approval)

3. **Update Code**
   - The code already uses `interruptionLevel: InterruptionLevel.critical`
   - Once entitlement is approved, it will work automatically

### Option 2: Custom Alarm Sound File

Add a custom alarm sound file to the iOS app:

1. **Add Sound File**
   - Add alarm sound file (`.caf`, `.aiff`, `.wav`) to `ios/Runner/` directory
   - Recommended: `alarm.caf` or `alarm.aiff`
   - Max duration: 30 seconds
   - Format: Linear PCM, MA4 (IMA/ADPCM), µLaw, or aLaw

2. **Update Code**
   ```dart
   const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
     presentAlert: true,
     presentBadge: true,
     presentSound: true,
     sound: 'alarm.caf', // Custom alarm sound file
     interruptionLevel: InterruptionLevel.critical,
   );
   ```

3. **Update Info.plist**
   - Add sound file to `UIBackgroundModes` if needed

### Option 3: Use Default Sound with Critical Priority (Current)

**Current Implementation:**
- Uses `interruptionLevel: InterruptionLevel.critical`
- Plays default notification sound
- Works without Apple approval
- **Limitation:** Not a true alarm sound, but high priority

## Current Code Configuration

The code is already configured for Option 3 (default sound with critical priority):

```dart
const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
  interruptionLevel: InterruptionLevel.critical, // High priority
);
```

## Backend FCM Configuration for iOS

The backend should send FCM with:

```json
{
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "interruption-level": "critical",
        "alert": {
          "title": "🚨 Safety Alert",
          "body": "Member is outside the safety radius!"
        },
        "badge": 1
      }
    }
  }
}
```

## Testing on iOS

1. **Test with Critical Level:**
   - Notification should appear even in Do Not Disturb mode
   - Sound should play (default notification sound)
   - Should be more prominent than regular notifications

2. **Test with Custom Sound (if added):**
   - Add alarm sound file to iOS project
   - Update code to use custom sound
   - Test notification playback

3. **Test with Critical Alert Entitlement (if approved):**
   - Request entitlement from Apple
   - Add capability in Xcode
   - Test - should play true alarm sound

## Recommendations

**For Production:**
1. **Short-term:** Current implementation (critical interruption level) works but uses default sound
2. **Long-term:** Request Critical Alert entitlement from Apple for true alarm sounds
3. **Alternative:** Add custom alarm sound file if entitlement is not approved

## Notes

- iOS doesn't have a built-in "system alarm sound" like Android
- Critical Alert entitlement requires justification and Apple approval
- Custom sound files must be in specific formats and locations
- `interruptionLevel.critical` makes notifications more prominent but doesn't guarantee alarm sound

## Summary

**Current Status:**
- ✅ iOS notifications configured with `interruptionLevel.critical`
- ✅ Sound will play (default notification sound)
- ⚠️ Not a true "alarm" sound (requires entitlement or custom file)

**To Get True Alarm Sound:**
- Option A: Request Critical Alert entitlement from Apple (recommended)
- Option B: Add custom alarm sound file to iOS project

