# إصلاح الفعاليات — `events_search_error` (500)

## التشخيص

التطبيق يستدعي:

```http
GET https://seasonksa.com/api/gemini/events
Accept-Language: ar|en
Accept-Country: SAU|EGY|...
```

الاستجابة الحالية (من السيرفر):

```json
{
  "success": false,
  "status": 500,
  "message": "events_search_error",
  "data": []
}
```

هذا **خطأ من Laravel / خدمة Gemini** وليس من Flutter. التطبيق يرسل الطلب بشكل صحيح.

## المطلوب من Backend

1. مراجعة **Laravel logs** (`storage/logs/laravel.log`) عند طلب `/api/gemini/events` — السبب الحقيقي يكون هناك (Exception stack).
2. التحقق من إعدادات **Google Gemini API** على السيرفر:
   - `GEMINI_API_KEY` (أو الاسم المستخدم في `.env`) صحيح وغير منتهي
   - تفعيل الفوترة / الحصة (quota) في Google AI Studio
   - عدم تجاوز rate limit
3. التأكد أن كود `events_search` / `GeminiEventsController` لا يرمي exception بدون معالجة.
4. بعد الإصلاح، اختبار:
   ```bash
   curl -H "Accept-Language: ar" -H "Accept-Country: SAU" \
     https://seasonksa.com/api/gemini/events
   ```
   المتوقع: `HTTP 200` و `success: true` مع قائمة `events`.

## التطبيق

- يعرض رسالة واضحة للمستخدم + زر **إعادة المحاولة** عند فشل التحميل.
- عند إصلاح السيرفر، الفعاليات تظهر تلقائياً بدون تحديث التطبيق.
