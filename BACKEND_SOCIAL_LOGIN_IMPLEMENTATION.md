# Backend Implementation Guide: Social Login (Google & Apple)

## Overview
This document outlines the requirements for implementing Google Sign-In and Apple Sign-In authentication endpoints in the Laravel backend API.

## Endpoints Required

### 1. Google Login
**Endpoint:** `POST /api/auth/login/google`

**Request Body:**
```json
{
  "id_token": "string (required)",
  "access_token": "string (required)",
  "fcm_token": "string (optional)"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Login successful",
  "message_ar": "تم تسجيل الدخول بنجاح",
  "data": {
    "token": "jwt_access_token",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "name": "John Doe",
      "photo": "https://profile_photo_url",
      "phone": null,
      "email_verified_at": "2024-01-01T00:00:00.000000Z"
    }
  }
}
```

**Response (User Not Found - 404):**
```json
{
  "success": false,
  "message": "User not found. Please register first.",
  "message_ar": "المستخدم غير موجود. يرجى التسجيل أولاً",
  "error": "User not registered"
}
```

**Note:** The frontend signup screen will automatically call the register endpoint if it receives a 404 error. On the login screen, it will show this error message to the user.

### 2. Google Register
**Endpoint:** `POST /api/auth/register/google`

**Request Body:**
```json
{
  "id_token": "string (required)",
  "access_token": "string (required)",
  "fcm_token": "string (optional)"
}
```

**Response (Success - 201):**
```json
{
  "success": true,
  "message": "Registration successful",
  "message_ar": "تم التسجيل بنجاح",
  "data": {
    "token": "jwt_access_token",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "name": "John Doe",
      "photo": "https://profile_photo_url",
      "phone": null,
      "email_verified_at": "2024-01-01T00:00:00.000000Z"
    }
  }
}
```

**Response (User Already Exists - 400):**
```json
{
  "success": false,
  "message": "User already exists. Please login instead.",
  "message_ar": "المستخدم موجود بالفعل. يرجى تسجيل الدخول",
  "error": "User already registered"
}
```

**Note:** If user already exists, the frontend will automatically try to login instead. However, this error should rarely occur if the backend automatically handles login/register in a unified endpoint.

### 3. Apple Login
**Endpoint:** `POST /api/auth/login/apple`

**Request Body:**
```json
{
  "id_token": "string (required)",
  "authorization_code": "string (optional)",
  "fcm_token": "string (optional)"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Login successful",
  "message_ar": "تم تسجيل الدخول بنجاح",
  "data": {
    "token": "jwt_access_token",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "name": "John Doe",
      "photo": null,
      "phone": null,
      "email_verified_at": "2024-01-01T00:00:00.000000Z"
    }
  }
}
```

**Response (User Not Found - 404):**
```json
{
  "success": false,
  "message": "User not found. Please register first.",
  "message_ar": "المستخدم غير موجود. يرجى التسجيل أولاً",
  "error": "User not registered"
}
```

**Note:** The frontend signup screen will automatically call the register endpoint if it receives a 404 error. On the login screen, it will show this error message to the user.

### 4. Apple Register
**Endpoint:** `POST /api/auth/register/apple`

**Request Body:**
```json
{
  "id_token": "string (required)",
  "authorization_code": "string (optional)",
  "fcm_token": "string (optional)"
}
```

**Response (Success - 201):**
```json
{
  "success": true,
  "message": "Registration successful",
  "message_ar": "تم التسجيل بنجاح",
  "data": {
    "token": "jwt_access_token",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "name": "John Doe",
      "photo": null,
      "phone": null,
      "email_verified_at": "2024-01-01T00:00:00.000000Z"
    }
  }
}
```

**Response (User Already Exists - 400):**
```json
{
  "success": false,
  "message": "User already exists. Please login instead.",
  "message_ar": "المستخدم موجود بالفعل. يرجى تسجيل الدخول",
  "error": "User already registered"
}
```

**Note:** If user already exists, the frontend will automatically try to login instead. However, this error should rarely occur if the backend automatically handles login/register in a unified endpoint.

## Implementation Steps

### 1. Database Schema Updates

Add columns to the `users` table:

```php
Schema::table('users', function (Blueprint $table) {
    $table->string('provider')->nullable()->after('email'); // 'google', 'apple', 'email'
    $table->string('provider_id')->nullable()->after('provider'); // Google/Apple user ID
    $table->string('provider_token')->nullable()->after('provider_id'); // Store access token for future use
    $table->timestamp('email_verified_at')->nullable()->after('email_verified_at');
});
```

**Migration:**
```php
php artisan make:migration add_social_login_fields_to_users_table
```

### 2. Install Required Packages

```bash
composer require google/apiclient
composer require firebase/php-jwt
composer require lcobucci/jwt
```

For Apple Sign-In, you'll need to use Apple's public keys to verify the JWT token.

### 3. Create Request Validation Classes

**GoogleLoginRequest:**
```php
php artisan make:request GoogleLoginRequest
```

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class GoogleLoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_token' => 'required|string',
            'access_token' => 'required|string',
            'fcm_token' => 'nullable|string',
        ];
    }
}
```

**AppleLoginRequest:**
```php
php artisan make:request AppleLoginRequest
```

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AppleLoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_token' => 'required|string',
            'authorization_code' => 'nullable|string',
            'fcm_token' => 'nullable|string',
        ];
    }
}
```

### 4. Create Service Classes

**GoogleAuthService:**
```php
php artisan make:service GoogleAuthService
```

```php
<?php

namespace App\Services;

use Google\Client as GoogleClient;
use Illuminate\Support\Facades\Http;
use Exception;

class GoogleAuthService
{
    /**
     * Verify Google ID token and get user info
     */
    public function verifyIdToken(string $idToken): array
    {
        try {
            $client = new GoogleClient(['client_id' => config('services.google.client_id')]);
            $payload = $client->verifyIdToken($idToken);
            
            if (!$payload) {
                throw new Exception('Invalid Google ID token');
            }
            
            return [
                'id' => $payload['sub'],
                'email' => $payload['email'] ?? null,
                'email_verified' => $payload['email_verified'] ?? false,
                'name' => $payload['name'] ?? null,
                'given_name' => $payload['given_name'] ?? null,
                'family_name' => $payload['family_name'] ?? null,
                'picture' => $payload['picture'] ?? null,
            ];
        } catch (Exception $e) {
            throw new Exception('Failed to verify Google token: ' . $e->getMessage());
        }
    }
}
```

**AppleAuthService:**
```php
php artisan make:service AppleAuthService
```

```php
<?php

namespace App\Services;

use Lcobucci\JWT\Configuration;
use Lcobucci\JWT\Signer\Rsa\Sha256;
use Lcobucci\JWT\Signer\Key\InMemory;
use Lcobucci\JWT\Validation\Constraint\SignedWith;
use Illuminate\Support\Facades\Http;
use Exception;

class AppleAuthService
{
    /**
     * Verify Apple ID token and get user info
     */
    public function verifyIdToken(string $idToken): array
    {
        try {
            // Decode the JWT token
            $tokenParts = explode('.', $idToken);
            if (count($tokenParts) !== 3) {
                throw new Exception('Invalid token format');
            }
            
            $payload = json_decode(base64_decode(strtr($tokenParts[1], '-_', '+/')), true);
            
            // Verify the token signature using Apple's public keys
            // You need to fetch Apple's public keys from: https://appleid.apple.com/auth/keys
            $this->verifyAppleTokenSignature($idToken);
            
            return [
                'id' => $payload['sub'],
                'email' => $payload['email'] ?? null,
                'email_verified' => $payload['email_verified'] ?? false,
            ];
        } catch (Exception $e) {
            throw new Exception('Failed to verify Apple token: ' . $e->getMessage());
        }
    }
    
    /**
     * Verify Apple token signature using Apple's public keys
     */
    private function verifyAppleTokenSignature(string $idToken): void
    {
        // Implementation: Fetch Apple's public keys and verify signature
        // This is a simplified version - you'll need full implementation
        // Reference: https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/verifying_a_user
    }
}
```

### 5. Create Controller Methods

**AuthController.php:**
```php
public function loginWithGoogle(GoogleLoginRequest $request, GoogleAuthService $googleAuth)
{
    try {
        // Verify Google token
        $googleUser = $googleAuth->verifyIdToken($request->id_token);
        
        // Find or create user
        $user = User::where('provider', 'google')
            ->where('provider_id', $googleUser['id'])
            ->orWhere('email', $googleUser['email'])
            ->first();
        
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found. Please register first.',
                'error' => 'User not registered'
            ], 404);
        }
        
        // Update FCM token if provided
        if ($request->fcm_token) {
            $user->update(['fcm_token' => $request->fcm_token]);
        }
        
        // Generate JWT token
        $token = auth()->login($user);
        
        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'first_name' => $user->first_name,
                    'last_name' => $user->last_name,
                    'name' => $user->name,
                    'photo' => $user->photo,
                    'phone' => $user->phone,
                    'email_verified_at' => $user->email_verified_at,
                ]
            ]
        ], 200);
        
    } catch (Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Google login failed',
            'error' => $e->getMessage()
        ], 400);
    }
}

public function registerWithGoogle(GoogleLoginRequest $request, GoogleAuthService $googleAuth)
{
    try {
        // Verify Google token
        $googleUser = $googleAuth->verifyIdToken($request->id_token);
        
        // Check if user already exists
        $existingUser = User::where('email', $googleUser['email'])->first();
        if ($existingUser) {
            return response()->json([
                'success' => false,
                'message' => 'User already exists. Please login instead.',
                'error' => 'User already registered'
            ], 400);
        }
        
        // Create new user
        $nameParts = explode(' ', $googleUser['name'] ?? 'User', 2);
        $user = User::create([
            'email' => $googleUser['email'],
            'first_name' => $googleUser['given_name'] ?? $nameParts[0] ?? 'User',
            'last_name' => $googleUser['family_name'] ?? ($nameParts[1] ?? ''),
            'name' => $googleUser['name'] ?? 'User',
            'photo' => $googleUser['picture'],
            'provider' => 'google',
            'provider_id' => $googleUser['id'],
            'provider_token' => $request->access_token,
            'email_verified_at' => $googleUser['email_verified'] ? now() : null,
            'fcm_token' => $request->fcm_token,
            'password' => bcrypt(Str::random(32)), // Random password for social login users
        ]);
        
        // Generate JWT token
        $token = auth()->login($user);
        
        return response()->json([
            'success' => true,
            'message' => 'Registration successful',
            'data' => [
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'first_name' => $user->first_name,
                    'last_name' => $user->last_name,
                    'name' => $user->name,
                    'photo' => $user->photo,
                    'phone' => $user->phone,
                    'email_verified_at' => $user->email_verified_at,
                ]
            ]
        ], 201);
        
    } catch (Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Google registration failed',
            'error' => $e->getMessage()
        ], 400);
    }
}

public function loginWithApple(AppleLoginRequest $request, AppleAuthService $appleAuth)
{
    try {
        // Verify Apple token
        $appleUser = $appleAuth->verifyIdToken($request->id_token);
        
        // Find user by provider_id or email
        $user = User::where('provider', 'apple')
            ->where('provider_id', $appleUser['id'])
            ->orWhere('email', $appleUser['email'])
            ->first();
        
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found. Please register first.',
                'error' => 'User not registered'
            ], 404);
        }
        
        // Update FCM token if provided
        if ($request->fcm_token) {
            $user->update(['fcm_token' => $request->fcm_token]);
        }
        
        // Generate JWT token
        $token = auth()->login($user);
        
        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'first_name' => $user->first_name,
                    'last_name' => $user->last_name,
                    'name' => $user->name,
                    'photo' => $user->photo,
                    'phone' => $user->phone,
                    'email_verified_at' => $user->email_verified_at,
                ]
            ]
        ], 200);
        
    } catch (Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Apple login failed',
            'error' => $e->getMessage()
        ], 400);
    }
}

public function registerWithApple(AppleLoginRequest $request, AppleAuthService $appleAuth)
{
    try {
        // Verify Apple token
        $appleUser = $appleAuth->verifyIdToken($request->id_token);
        
        // Check if user already exists
        $existingUser = User::where('email', $appleUser['email'])->first();
        if ($existingUser) {
            return response()->json([
                'success' => false,
                'message' => 'User already exists. Please login instead.',
                'error' => 'User already registered'
            ], 400);
        }
        
        // Note: Apple only provides name on first sign-in
        // Create new user
        $user = User::create([
            'email' => $appleUser['email'],
            'first_name' => 'User', // Apple doesn't provide name in subsequent logins
            'last_name' => '',
            'name' => 'User',
            'provider' => 'apple',
            'provider_id' => $appleUser['id'],
            'provider_token' => $request->authorization_code,
            'email_verified_at' => $appleUser['email_verified'] ? now() : null,
            'fcm_token' => $request->fcm_token,
            'password' => bcrypt(Str::random(32)), // Random password for social login users
        ]);
        
        // Generate JWT token
        $token = auth()->login($user);
        
        return response()->json([
            'success' => true,
            'message' => 'Registration successful',
            'data' => [
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'first_name' => $user->first_name,
                    'last_name' => $user->last_name,
                    'name' => $user->name,
                    'photo' => $user->photo,
                    'phone' => $user->phone,
                    'email_verified_at' => $user->email_verified_at,
                ]
            ]
        ], 201);
        
    } catch (Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Apple registration failed',
            'error' => $e->getMessage()
        ], 400);
    }
}
```

### 6. Add Routes

**routes/api.php:**
```php
Route::prefix('auth')->group(function () {
    // Existing routes...
    Route::post('/login/google', [AuthController::class, 'loginWithGoogle']);
    Route::post('/register/google', [AuthController::class, 'registerWithGoogle']);
    Route::post('/login/apple', [AuthController::class, 'loginWithApple']);
    Route::post('/register/apple', [AuthController::class, 'registerWithApple']);
});
```

### 7. Configuration

**config/services.php:**
```php
'google' => [
    'client_id' => env('GOOGLE_CLIENT_ID'),
    'client_secret' => env('GOOGLE_CLIENT_SECRET'),
    'redirect' => env('GOOGLE_REDIRECT_URI'),
],

'apple' => [
    'client_id' => env('APPLE_CLIENT_ID'),
    'team_id' => env('APPLE_TEAM_ID'),
    'key_id' => env('APPLE_KEY_ID'),
    'private_key' => env('APPLE_PRIVATE_KEY'),
    'redirect' => env('APPLE_REDIRECT_URI'),
],
```

**.env:**
```env
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
APPLE_CLIENT_ID=your_apple_client_id
APPLE_TEAM_ID=your_apple_team_id
APPLE_KEY_ID=your_apple_key_id
APPLE_PRIVATE_KEY=your_apple_private_key
```

## Important Notes

### Google Sign-In
1. **Token Verification:** Always verify the Google ID token on the backend to ensure it's valid and not tampered with.
2. **User Identification:** Use the `sub` field from the verified token as the unique user identifier.
3. **Email Verification:** Google automatically verifies emails, so you can set `email_verified_at` immediately.

### Apple Sign-In
1. **Token Verification:** Apple uses JWT tokens. You need to verify the signature using Apple's public keys.
2. **User Identification:** Use the `sub` field from the token as the unique user identifier.
3. **Email Handling:** Apple may hide the email after the first sign-in. Store it when first provided.
4. **Name Information:** Apple only provides name (given_name, family_name) on the first sign-in. Subsequent logins won't include this.

### Security Considerations
1. **Always verify tokens on the backend** - Never trust client-side tokens.
2. **Use HTTPS only** - All authentication requests must use HTTPS.
3. **Store provider tokens securely** - Encrypt sensitive tokens in the database.
4. **Handle edge cases:**
   - User changes email on Google/Apple account
   - User deletes and recreates account
   - Multiple users with same email from different providers

### Testing
1. Test with valid Google/Apple tokens
2. Test with invalid/expired tokens
3. Test user registration flow
4. Test user login flow
5. Test existing user scenarios
6. Test error handling

## API Response Format Consistency

All responses should follow this format:
- **Success:** `success: true`, `message: string`, `data: object`
- **Error:** `success: false`, `message: string`, `error: string`

The `data` object should always include:
- `token`: JWT access token
- `user`: User object with standard fields

## Frontend Flow Explanation

### Login Screen
- User clicks "Login with Google/Apple"
- Frontend calls `POST /api/auth/login/google` or `POST /api/auth/login/apple`
- If user exists → Returns token and user data → User logged in
- If user doesn't exist → Returns 404 error → Frontend shows error message asking to register

### Signup Screen
- User clicks "Login with Google/Apple"
- Frontend **first tries** `POST /api/auth/login/google` or `POST /api/auth/login/apple`
- If user exists → Returns token and user data → User logged in directly
- If user doesn't exist (404 error) → Frontend **automatically calls** `POST /api/auth/register/google` or `POST /api/auth/register/apple`
- User is registered and logged in

**Recommendation:** For better UX, you can create a unified endpoint that handles both login and register automatically. Example:
- `POST /api/auth/social/{provider}` - Automatically logs in if user exists, registers if not.

## Platform Configuration Requirements

### Android Configuration
1. **Google Sign-In Setup:**
   - The `google-services.json` file is already in `android/app/`
   - However, the `oauth_client` array is empty - you need to:
     - Go to [Google Cloud Console](https://console.cloud.google.com/)
     - Enable Google Sign-In API
     - Create OAuth 2.0 credentials (Android client ID)
     - Download the updated `google-services.json` file
     - Replace the existing file in `android/app/google-services.json`
   
2. **SHA-1 Fingerprint:**
   - Get your app's SHA-1 fingerprint: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
   - Add this SHA-1 to your Google Cloud Console project's OAuth 2.0 credentials

3. **Package Name:**
   - Ensure the package name in `google-services.json` matches: `com.season.app.season_app`

### iOS Configuration
1. **Google Sign-In Setup:**
   - Download `GoogleService-Info.plist` from [Firebase Console](https://console.firebase.google.com/)
   - Place it in `ios/Runner/` directory
   - Extract the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`
   - Update `ios/Runner/Info.plist`:
     - Replace `YOUR_REVERSED_CLIENT_ID` with the actual REVERSED_CLIENT_ID
     - Add URL scheme: `com.googleusercontent.apps.{REVERSED_CLIENT_ID}`
   
2. **Apple Sign-In Setup:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select the Runner target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Sign in with Apple"
   - The `Runner.entitlements` file has been created with the Apple Sign-In capability
   - Bundle ID must match your Apple Developer account
   
3. **Info.plist Configuration:**
   - The `CFBundleURLTypes` has been added to `Info.plist`
   - **Important:** Replace `YOUR_REVERSED_CLIENT_ID` with actual value from `GoogleService-Info.plist`
   - The bundle identifier `com.season.app.season_app` is already configured for Apple Sign-In

## Alternative: Unified Endpoint (Recommended for Better UX)

Instead of separate login/register endpoints, you can implement a unified endpoint:

**Endpoint:** `POST /api/auth/social/{provider}` where `{provider}` is `google` or `apple`

**Request Body (Google):**
```json
{
  "id_token": "string (required)",
  "access_token": "string (required for Google)",
  "fcm_token": "string (optional)"
}
```

**Request Body (Apple):**
```json
{
  "id_token": "string (required)",
  "authorization_code": "string (optional)",
  "fcm_token": "string (optional)"
}
```

**Backend Logic:**
1. Verify the token
2. Check if user exists (by provider_id or email)
3. If user exists → Log them in and return token
4. If user doesn't exist → Create new user, log them in, and return token
5. Always return 200 with token (no need for 404)

**Benefits:**
- Simpler frontend logic (no need to try login then register)
- Better UX (no error messages for new users)
- Single endpoint to maintain

## Additional Resources

- [Google Sign-In for iOS](https://developers.google.com/identity/sign-in/ios)
- [Google Sign-In for Android](https://developers.google.com/identity/sign-in/android/start-integrating)
- [Apple Sign-In Documentation](https://developer.apple.com/documentation/sign_in_with_apple)
- [Laravel Socialite (Alternative)](https://laravel.com/docs/socialite)
- [JWT Token Handling in Laravel](https://laravel.com/docs/sanctum)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)

 
 - - - 
 
 
 
 # #   S u m m a r y 
 
 
 
 # # #   E n d p o i n t s   t o   I m p l e m e n t 
 
 1 .   \ P O S T   / a p i / a u t h / l o g i n / g o o g l e \   -   L o g i n   w i t h   G o o g l e   ( r e t u r n s   4 0 4   i f   u s e r   n o t   f o u n d ) 
 
 2 .   \ P O S T   / a p i / a u t h / r e g i s t e r / g o o g l e \   -   R e g i s t e r   w i t h   G o o g l e   ( r e t u r n s   4 0 0   i f   u s e r   e x i s t s ) 
 
 3 .   \ P O S T   / a p i / a u t h / l o g i n / a p p l e \   -   L o g i n   w i t h   A p p l e   ( r e t u r n s   4 0 4   i f   u s e r   n o t   f o u n d ) 
 
 4 .   \ P O S T   / a p i / a u t h / r e g i s t e r / a p p l e \   -   R e g i s t e r   w i t h   A p p l e   ( r e t u r n s   4 0 0   i f   u s e r   e x i s t s ) 
 
 