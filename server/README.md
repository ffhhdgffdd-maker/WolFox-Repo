# WolFox UDID API

هذه طبقة خادم صغيرة مستقلة لتسجيل UDID والتحقق من وجوده باستخدام SQLite. لا تخزن ملفات الشهادات أو كلمات مرورها، ولا تعرض UDID في الاستجابات العامة.

## المسارات

بعد نشر مجلد `server` داخل جذر الموقع:

- `POST /server/api/udid.php` — تسجيل أو تحديث UDID.
- `GET /server/api/udid.php?udid=...` — التحقق من التسجيل.

كل الطلبات تتطلب أحد التالي:

```text
X-WolFox-Api-Key: <قيمة سرية>
```

أو:

```text
Authorization: Bearer <قيمة سرية>
```

## إعداد الخادم

1. ارفع مجلد `server` إلى الخادم، مثل:

   ```text
   /home/USER/public_html/Repo/server/
   ```

2. اجعل قاعدة البيانات قابلة للكتابة من PHP فقط، ولا تجعل `server/data` مسارًا عامًا. ملف `.htaccess` مرفق كحاجز إضافي.
3. عرّف متغيرات البيئة في إعدادات Hostinger/Apache أو في إعداد PHP-FPM:

   ```text
   WOLFOX_UDID_API_KEY=<سر طويل عشوائي>
   WOLFOX_UDID_API_URL=https://example.com/Repo/server/api/udid.php
   ```

   لا تضع السر في Git أو داخل `bot.php`.
4. تأكد من تفعيل إضافات PHP: `sqlite3` و`curl`.
5. اختبر من جهاز الإدارة، وليس من متصفح عام:

   ```bash
   curl -sS -X POST \
     -H 'Content-Type: application/json' \
     -H 'X-WolFox-Api-Key: YOUR_SECRET' \
     -d '{"udid":"00008120-001238913C83601E","deviceName":"اختبار","source":"manual"}' \
     https://example.com/Repo/server/api/udid.php
   ```

## دمجه مع bot.php

انسخ `server/bot_client.php` إلى نفس الخادم، ثم في `bot.php`:

```php
require_once __DIR__ . '/server/bot_client.php';

try {
    $result = wolfoxRegisterUdid($udid, $telegramUserName, 'telegram');
    // أرسل للمستخدم: تم التسجيل، والحالة الحالية هي $result['certificateStatus'].
} catch (Throwable $e) {
    // سجّل الخطأ داخليًا فقط، ولا تعرض API key أو UDID كاملًا.
    error_log('UDID registration failed: ' . $e->getMessage());
}
```

للتحقق:

```php
$result = wolfoxCheckUdid($udid);
$isRegistered = (bool) ($result['registered'] ?? false);
```

## الدمج مع المستودع الحالي

المستودع الحالي يحتوي تطبيق Swift وكتالوج Android فقط. لا تضع ملفات الخادم داخل مجلدات `Feather/` أو `WolFoxRepo/`. استخدم هذا التقسيم:

```text
WolFox-Repo/
├── Feather/                 # تطبيق Swift الحالي
├── WolFoxRepo/              # واجهة الكتالوج
├── panel/                   # أدوات بناء المصدر
└── server/                  # API PHP وعميل البوت
    ├── api/udid.php
    ├── bootstrap.php
    ├── bot_client.php
    └── data/.gitignore
```

ملفات `bot.php` و`config.php` و`repo.db` القديمة يمكن دمجها لاحقًا داخل `server/` فقط بعد مراجعتها. لا تستبدل `app-repo.json` بقاعدة SQLite؛ لكل منهما وظيفة مختلفة.

## ملاحظات أمان

- قاعدة البيانات تخزن UDID الأصلي داخل الخادم لاستخدامه إداريًا، إضافة إلى SHA-256 للبحث. احمِ الخادم والنسخ الاحتياطية.
- لا تسجل UDID أو API key في سجلات الوصول أو رسائل Telegram.
- لا تُرجع UDID في JSON.
- لا تستخدم هذا API لتوزيع شهادات أو ملفات `.p12`؛ هذه وظيفة منفصلة تحتاج ضوابط وصلاحيات إضافية.
- استخدم HTTPS فقط، وغيّر المفتاح إذا تسرب.
