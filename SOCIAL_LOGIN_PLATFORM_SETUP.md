# Social Login Platform Setup Guide

This document provides step-by-step instructions for configuring Google Sign-In and Apple Sign-In on Android and iOS platforms.

## Prerequisites

- Google Cloud Console account
- Apple Developer account (for Apple Sign-In)
- Firebase project (for Google Sign-In)
- Xcode installed (for iOS configuration)

---

## Android Configuration

### 1. Google Sign-In Setup

#### Step 1: Configure Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select or create your project
3. Enable **Google Sign-In API**:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Google Sign-In API"
   - Click "Enable"

#### Step 2: Create OAuth 2.0 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Android" as application type
4. Configure:
   - **Name:** Season App Android
   - **Package name:** `com.season.app.season_app`
   - **SHA-1 certificate fingerprint:** (See below how to get this)

#### Step 3: Get SHA-1 Fingerprint

**For Debug Build:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**For Release Build:**
```bash
keytool -list -v -keystore <path-to-your-keystore> -alias <your-key-alias>
```

Copy the SHA-1 fingerprint and add it to the OAuth client configuration.

#### Step 4: Update google-services.json

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings > General
4. Scroll to "Your apps" section
5. Click on Android app or "Add app" if not exists
6. Package name: `com.season.app.season_app`
7. Download `google-services.json`
8. Replace the file at `android/app/google-services.json`
9. **Important:** Ensure the `oauth_client` array in `google-services.json` contains your OAuth client configuration

#### Step 5: Verify Configuration

Check that `android/app/google-services.json` contains:
- Correct `package_name`: `com.season.app.season_app`
- `oauth_client` array with your Android OAuth client ID
- Valid `project_number` and `project_id`

**Current Status:** ✅ `google-services.json` exists, but `oauth_client` array is empty - needs to be configured with OAuth credentials.

---

## iOS Configuration

### 1. Google Sign-In Setup for iOS

#### Step 1: Create iOS App in Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings > General
4. Click "Add app" > iOS (if not already added)
5. Bundle ID: `com.season.app.season_app`
6. Download `GoogleService-Info.plist`

#### Step 2: Add GoogleService-Info.plist to iOS Project

1. Place `GoogleService-Info.plist` in `ios/Runner/` directory
2. Open Xcode: `ios/Runner.xcworkspace`
3. Drag and drop `GoogleService-Info.plist` into the Runner target in Xcode
4. Ensure it's added to the target (check "Copy items if needed")

#### Step 3: Extract REVERSED_CLIENT_ID

1. Open `GoogleService-Info.plist` in a text editor
2. Find the `REVERSED_CLIENT_ID` value
3. It will look like: `com.googleusercontent.apps.123456789-abcdefghijklmnop`
4. Copy this value

#### Step 4: Update Info.plist

1. Open `ios/Runner/Info.plist`
2. Find the `CFBundleURLSchemes` array
3. Replace `YOUR_REVERSED_CLIENT_ID` with the actual REVERSED_CLIENT_ID from step 3

**Example:**
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.123456789-abcdefghijklmnop</string>
    <string>com.season.app.season_app</string>
</array>
```

#### Step 5: Create OAuth Client for iOS in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "APIs & Services" > "Credentials"
3. Click "Create Credentials" > "OAuth client ID"
4. Select "iOS" as application type
5. Configure:
   - **Name:** Season App iOS
   - **Bundle ID:** `com.season.app.season_app`
6. Save the Client ID

### 2. Apple Sign-In Setup

#### Step 1: Configure Apple Developer Account

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to "Certificates, Identifiers & Profiles"
3. Select "Identifiers" > "App IDs"
4. Find or create your app ID: `com.season.app.season_app`
5. Enable "Sign in with Apple" capability
6. Save changes

#### Step 2: Configure in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the "Runner" target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Search for and add "Sign in with Apple"
6. Ensure your Team is selected
7. Verify Bundle Identifier: `com.season.app.season_app`

**Note:** The `Runner.entitlements` file has already been created with the Apple Sign-In capability. Xcode will automatically update it when you add the capability.

#### Step 3: Verify Entitlements File

The file `ios/Runner/Runner.entitlements` should contain:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>
</dict>
</plist>
```

✅ This file has been created.

#### Step 4: Update Info.plist (Already Done)

The `Info.plist` has been updated with:
- `CFBundleURLSchemes` for Google Sign-In
- Bundle identifier for Apple Sign-In

**Important:** Don't forget to replace `YOUR_REVERSED_CLIENT_ID` with the actual value from `GoogleService-Info.plist`!

---

## Testing

### Android Testing

1. Build the app: `flutter build apk --debug`
2. Install on an Android device or emulator
3. Click "Login with Google" button
4. Verify Google Sign-In popup appears
5. Test with a Google account

### iOS Testing

**Prerequisites:**
- iOS 13.0 or later (required for Apple Sign-In)
- Physical iOS device (Apple Sign-In doesn't work on simulator)
- Valid Apple Developer account

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select a physical iOS device (not simulator)
3. Ensure your Team is selected in "Signing & Capabilities"
4. Build and run: `flutter run`
5. Test Google Sign-In
6. Test Apple Sign-In (only works on physical device)

---

## Common Issues and Solutions

### Android Issues

**Issue 1: "Developer Error" or "10:" error code**
- **Solution:** Ensure SHA-1 fingerprint is added to Google Cloud Console OAuth credentials
- **Solution:** Verify `google-services.json` has the correct `package_name`

**Issue 2: Google Sign-In popup doesn't appear**
- **Solution:** Check internet connection
- **Solution:** Verify Google Sign-In API is enabled in Google Cloud Console
- **Solution:** Ensure `oauth_client` array in `google-services.json` is populated

**Issue 3: "Sign in with Google temporarily disabled"**
- **Solution:** Wait a few minutes and try again (rate limiting)
- **Solution:** Check OAuth consent screen is configured in Google Cloud Console

### iOS Issues

**Issue 1: "Sign in with Apple" button doesn't appear**
- **Solution:** Ensure you're testing on iOS 13.0 or later
- **Solution:** Verify "Sign in with Apple" capability is added in Xcode
- **Solution:** Check `Runner.entitlements` file exists and is correct

**Issue 2: Apple Sign-In fails with "Invalid client"**
- **Solution:** Verify Bundle ID matches Apple Developer account
- **Solution:** Ensure Apple Sign-In is enabled in App ID configuration

**Issue 3: Google Sign-In redirect fails**
- **Solution:** Verify `REVERSED_CLIENT_ID` in `Info.plist` matches `GoogleService-Info.plist`
- **Solution:** Ensure `GoogleService-Info.plist` is added to Xcode target
- **Solution:** Check `CFBundleURLSchemes` in `Info.plist` is correct

**Issue 4: "No app installed" error**
- **Solution:** Ensure `GoogleService-Info.plist` is in the correct location
- **Solution:** Verify URL scheme is correctly configured in `Info.plist`

---

## Configuration Checklist

### Android ✅
- [x] `google-services.json` exists in `android/app/`
- [x] Google Services plugin added to `build.gradle.kts`
- [x] Package name configured: `com.season.app.season_app`
- [ ] **TODO:** OAuth client created in Google Cloud Console
- [ ] **TODO:** SHA-1 fingerprint added to OAuth credentials
- [ ] **TODO:** `oauth_client` array populated in `google-services.json`

### iOS ✅
- [x] `Runner.entitlements` created with Apple Sign-In capability
- [x] `CFBundleURLSchemes` added to `Info.plist`
- [ ] **TODO:** `GoogleService-Info.plist` downloaded and added to project
- [ ] **TODO:** `REVERSED_CLIENT_ID` updated in `Info.plist`
- [ ] **TODO:** Apple Sign-In capability added in Xcode
- [ ] **TODO:** OAuth client created for iOS in Google Cloud Console

---

## Next Steps

1. **For Backend Developer:**
   - Implement the endpoints as documented in `BACKEND_SOCIAL_LOGIN_IMPLEMENTATION.md`
   - Test token verification
   - Set up Google and Apple credentials in `.env`

2. **For Frontend Developer:**
   - Complete the platform configuration steps above
   - Download and configure `GoogleService-Info.plist` for iOS
   - Update `REVERSED_CLIENT_ID` in `Info.plist`
   - Test on physical devices (especially for Apple Sign-In)

3. **Testing:**
   - Test Google Sign-In on both Android and iOS
   - Test Apple Sign-In on iOS (physical device only)
   - Verify backend endpoints are working
   - Test error scenarios (invalid tokens, network errors)

---

## Support

If you encounter issues:
1. Check the "Common Issues and Solutions" section above
2. Review Google Sign-In and Apple Sign-In official documentation
3. Verify all configuration files are correct
4. Check backend logs for authentication errors

