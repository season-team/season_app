# إصلاح Google Sign-In على Android (Api10 / sign_in_failed)

## السبب

الخطأ `PlatformException(sign_in_failed, com.google.android.gms.common.api.Api10: ...)` = **DEVELOPER_ERROR**.

في مشروعك، ملف `android/app/google-services.json` يحتوي على:

```json
"oauth_client": []
```

بدون **Android OAuth client** + **SHA-1**، Google Play Services ترفض تسجيل الدخول.

---

## الحل (Firebase — الأفضل)

1. افتح [Firebase Console](https://console.firebase.google.com/) → مشروع **season-80348** (Project number: `947193806162`)
2. ⚙️ **Project settings** → تطبيق Android `com.season.app.season_app`
3. **Add fingerprint** → الصق SHA-1 للتطوير (Debug):

```
97:D7:3D:13:1D:E0:4E:27:8E:DD:85:F1:85:C9:46:40:BA:85:06:41
```

4. (اختياري) أضف SHA-256:

```
A6:D2:FB:96:7B:07:41:7B:A1:D1:FF:99:DA:AF:85:A1:F4:20:AD:87:76:72:C0:93:79:74:FB:7D:31:27:6F:60
```

5. **حمّل** `google-services.json` جديد
6. استبدل الملف: `android/app/google-services.json`
7. تحقق أن `oauth_client` **ليس فارغاً** (يحتوي Android + Web clients)
8. أعد البناء:

```bash
cd /Users/minatharwat/season_app
flutter clean
flutter run -d emulator-5554
```

---

## بديل (Google Cloud Console)

1. [Credentials](https://console.cloud.google.com/apis/credentials) → نفس مشروع Firebase
2. **Create credentials** → **OAuth client ID** → **Android**
3. Package name: `com.season.app.season_app`
4. SHA-1: (نفس القيمة أعلاه)
5. أنشئ أيضاً **Web application** client (نفس `GOOGLE_CLIENT_ID` على الـ backend)
6. أعد تحميل `google-services.json` من Firebase

---

## Web Client ID (للـ backend / idToken) — مهم جداً

يجب أن يكون **نفس القيمة** في الثلاثة:

| المكان | القيمة |
|--------|--------|
| Laravel `.env` → `GOOGLE_CLIENT_ID` | `947193806162-nua0frbdtn89jipohvfn43bbbc8r86er.apps.googleusercontent.com` |
| `lib/core/constants/google_oauth_local.dart` | نفس الـ ID |
| `android/app/src/main/res/values/strings.xml` → `default_web_client_id` | نفس الـ ID |

إذا ظهر `Invalid Google ID token` فالـ `aud` داخل الـ token لا يطابق `GOOGLE_CLIENT_ID` على السيرفر.

بعد تعديل `.env` على السيرفر: `php artisan config:clear`

---

## التحقق من SHA-1 على جهازك

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

أو:

```bash
cd android && ./gradlew :app:signingReport
```

---

## Release build

عند النشر، أضف SHA-1 **release keystore** أيضاً في Firebase (نفس الخطوات).
