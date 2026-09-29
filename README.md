# WolFox Repo

مستودع WolFox Repo لعرض وتوزيع تطبيقات **Android فقط**.

## Source

سيتم نشر ملف المصدر في `app-repo.json` وربطه بتطبيق WolFox Repo. لا يقبل الكتالوج ملفات IPA أو تطبيقات iOS.

## Server API

توجد طبقة PHP/SQLite مستقلة في `server/` لتسجيل UDID والتحقق منه، مع عميل جاهز للدمج داخل `bot.php`. راجع [server/README.md](server/README.md) قبل النشر، ولا تضع قاعدة البيانات أو مفاتيح API داخل Git.
