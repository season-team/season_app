# إصلاح Google Login — السيرفر (Laravel)

## ليست مشكلة Firebase

التطبيق يحصل على **Google ID token** بنجاح. الخطأ:

`Failed to verify Google token: Invalid Google ID token`

يصدر من **Laravel** عندما `GOOGLE_CLIENT_ID` في `.env` **لا يساوي** حقل `aud` داخل التوكن.

من الشاشة الحالية، `aud` في التوكن هو عميل Firebase Web:

```
947193806162-a2brd7oi08orov298knjtn2ntc7o975d.apps.googleusercontent.com
```

## المطلوب على seasonksa.com

في `.env` على السيرفر (الإنتاج):

```env
GOOGLE_CLIENT_ID=947193806162-a2brd7oi08orov298knjtn2ntc7o975d.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=<Client Secret لنفس الـ Web client في Google Cloud Console>
```

ثم:

```bash
php artisan config:clear
php artisan cache:clear
```

## أين تجد الـ Client Secret

1. [Google Cloud Console](https://console.cloud.google.com/) → مشروع **season-80348** (رقم 947193806162)
2. APIs & Services → Credentials
3. افتح **Web client** الذي Client ID ينتهي بـ `a2brd7oi...`
4. انسخ Client secret إلى `GOOGLE_CLIENT_SECRET`

## عميل بديل (إن كان السيرفر مضبوطاً عليه مسبقاً)

```
947193806162-nua0frbdtn89jipohvfn43bbbc8r86er.apps.googleusercontent.com
```

يجب أن يطابق **واحد فقط** قيمة `aud` في التوكن — لا يمكن الجمع بينهما.

## التحقق

بعد التعديل، جرّب Google Sign-In من التطبيق. إن استمر الخطأ، تأكد أن `config('services.google.client_id')` على السيرفر يعرض القيمة الجديدة (ليس cache قديم).
