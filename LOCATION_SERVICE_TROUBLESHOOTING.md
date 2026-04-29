# Location Service Troubleshooting Guide

## Issues Fixed

### 1. Location Not Updating
**Problem**: Location not updating in foreground, background, or terminated mode.

**Fixes Applied**:
- ✅ Added permission checks before starting location updates
- ✅ Added provider availability checks (GPS/Network)
- ✅ Added better error handling and logging
- ✅ Added fallback timer to ensure periodic updates
- ✅ Fixed SharedPreferences key access for group IDs

### 2. App Crashes on Reopen
**Problem**: App crashes when trying to reopen after being terminated.

**Fixes Applied**:
- ✅ Added service running check to prevent duplicate starts
- ✅ Added try-catch blocks in onCreate and onStartCommand
- ✅ Added proper error handling in MainActivity
- ✅ Added null checks for LocationManager

## Testing Steps

### 1. Check Logs
```bash
# Android
adb logcat | grep -E "LocationUpdateService|MainActivity|NativeLocationService"

# Look for:
# - "Service created"
# - "Location updates started"
# - "Location updated: lat, lng"
# - "Location sent to group X"
```

### 2. Verify Permissions
- Settings → Apps → Season → Permissions → Location
- Must be set to "Allow all the time" (not just "While using app")

### 3. Check Service Status
- Settings → Apps → Season → App info → Running services
- Should see "LocationUpdateService" with notification

### 4. Test Scenarios

#### Foreground Mode
1. Open app
2. Check logs for location updates every 10 seconds
3. Check API logs for POST requests to `/groups/{id}/location`

#### Background Mode
1. Open app
2. Press home button (app goes to background)
3. Check logs - should continue updating
4. Check API logs - should continue receiving updates

#### Terminated Mode
1. Open app
2. Swipe away from recent apps (force stop)
3. Wait 10-20 seconds
4. Check API logs - should still receive updates
5. Try reopening app - should NOT crash

## Common Issues

### Issue: "Location permission not granted"
**Solution**: 
- Go to Settings → Apps → Season → Permissions
- Enable "Location" → Select "Allow all the time"
- Restart app

### Issue: "No location providers enabled"
**Solution**:
- Enable GPS in device settings
- Enable Location Services in device settings
- Restart app

### Issue: "No auth token found"
**Solution**:
- Make sure user is logged in
- Check SharedPreferences key: `flutter.auth_token`
- Restart app after login

### Issue: "No group IDs found"
**Solution**:
- Make sure user has joined at least one group
- Check SharedPreferences key: `flutter.tracked_group_ids`
- Format should be JSON array: `"[1,2,3]"`
- Restart app after joining group

### Issue: Service not starting
**Solution**:
- Check if service is already running
- Check AndroidManifest.xml has service registered
- Check logs for errors
- Restart device if needed

### Issue: App crashes on reopen
**Solution**:
- Check logs for crash stack trace
- Make sure service is properly initialized
- Check if there are null pointer exceptions
- Try clearing app data and reinstalling

## Debug Commands

### Check Service Status
```bash
adb shell dumpsys activity services | grep LocationUpdateService
```

### Check Permissions
```bash
adb shell dumpsys package com.season.app.season_app | grep permission
```

### Monitor Location Updates
```bash
adb logcat -s LocationUpdateService:D MainActivity:D
```

### Check SharedPreferences
```bash
adb shell run-as com.season.app.season_app
cd /data/data/com.season.app.season_app/shared_prefs
cat FlutterSharedPreferences.xml
```

## Expected Behavior

### Logs Should Show:
```
LocationUpdateService: Service created
LocationUpdateService: Service started
LocationUpdateService: GPS location updates started
LocationUpdateService: Network location updates started
LocationUpdateService: Location updated: 24.123, 46.456
LocationUpdateService: Sending location to 2 groups
LocationUpdateService: ✅ Location sent to group 1: lat=24.123, lng=46.456
LocationUpdateService: ✅ Location sent to group 2: lat=24.123, lng=46.456
```

### API Should Receive:
- POST requests to `/groups/{id}/location` every 10 seconds
- Body: `{"latitude": 24.123, "longitude": 46.456}`
- Headers: `Authorization: Bearer {token}`

## Next Steps if Still Not Working

1. **Check device logs** for specific error messages
2. **Verify API endpoint** is correct and accessible
3. **Test with different devices** to rule out device-specific issues
4. **Check battery optimization** - app should be whitelisted
5. **Test with app in foreground first** before testing background/terminated

## Contact Support

If issues persist, provide:
- Device model and Android version
- Full logcat output
- Steps to reproduce
- API response codes (if any)



