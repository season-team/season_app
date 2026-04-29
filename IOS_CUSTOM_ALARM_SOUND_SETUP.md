# iOS Custom Alarm Sound Setup - No Apple Approval Required

## ✅ Good News!

**Option 2 (Custom Alarm Sound File) does NOT require Apple approval!**

You can add a custom alarm sound file to your iOS app without requesting any entitlements from Apple.

## Implementation Steps

### Step 1: Get an Alarm Sound File

You need an alarm sound file in one of these formats:
- `.caf` (recommended for iOS)
- `.aiff` 
- `.wav`

**Requirements:**
- Max duration: 30 seconds
- Format: Linear PCM, MA4 (IMA/ADPCM), µLaw, or aLaw
- File size: Keep it reasonable (under 500KB recommended)

**Where to get alarm sounds:**
- Download from free sound libraries (freesound.org, zapsplat.com)
- Convert existing alarm sounds using online converters
- Use audio editing software to create your own

### Step 2: Add Sound File to iOS Project

1. **Open Xcode:**
   ```
   open ios/Runner.xcworkspace
   ```

2. **Add Sound File:**
   - Right-click on `Runner` folder in Xcode
   - Select "Add Files to Runner..."
   - Select your alarm sound file (e.g., `alarm.caf`)
   - ✅ Check "Copy items if needed"
   - ✅ Check "Add to targets: Runner"
   - Click "Add"

3. **Verify:**
   - The file should appear in `ios/Runner/` directory
   - The file should be listed in Xcode's project navigator

### Step 3: Update Info.plist (Optional but Recommended)

Open `ios/Runner/Info.plist` and ensure `UIBackgroundModes` includes notifications:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### Step 4: Code is Already Updated! ✅

The code has been updated to use `sound: 'alarm.caf'`. Just make sure:
- The file is named `alarm.caf` (or update the code to match your filename)
- The file is in the `ios/Runner/` directory
- The file is added to the Xcode project

### Step 5: Test

1. Build and run the iOS app
2. Send a test alarm notification
3. You should hear your custom alarm sound!

## File Naming

The code currently references `alarm.caf`. If you use a different filename, update the code:

```dart
sound: 'your_alarm_sound.caf', // Change to match your filename
```

## Converting Audio Files to .caf Format

If you have a sound file in another format (mp3, wav, etc.), convert it to .caf:

**Using macOS Terminal:**
```bash
afconvert input.wav output.caf -d ima4 -f caff -v
```

**Using Online Converter:**
- Use online tools like cloudconvert.com
- Upload your sound file
- Convert to CAF format
- Download and add to Xcode

## Limitations

⚠️ **Important Notes:**
- Custom sounds work, but they're still regular notifications
- They may be silenced if device is in Do Not Disturb mode (unless using Critical Alerts)
- The `interruptionLevel.critical` helps but doesn't guarantee bypass of DND
- For true alarm behavior that bypasses DND, you still need Critical Alert entitlement

## Current Implementation

The code is now configured to use:
```dart
sound: 'alarm.caf', // Custom alarm sound
interruptionLevel: InterruptionLevel.critical, // High priority
```

## Summary

✅ **No Apple approval needed** for custom sound files
✅ **Code is already updated** to use `alarm.caf`
✅ **Just add the sound file** to `ios/Runner/` in Xcode
✅ **Works immediately** after adding the file

## Next Steps

1. Get or create an alarm sound file
2. Convert to `.caf` format if needed
3. Add to Xcode project (`ios/Runner/`)
4. Build and test!

The alarm sound will work on iOS devices once you add the sound file! 🎉

