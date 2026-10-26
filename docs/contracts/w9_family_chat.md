# العقد: دردشة العائلة والوسائط الحية (W9 Family Chat & Media)

## Scope
ينظم هذا النظام المحادثات العائلية النصية والصوتية، ورفع وتنزيل الوسائط مع تنظيف البيانات الوصفية (Metadata Sanitation) قبل التخزين، وحذف بايتات الوسائط من التخزين عند حذف الرسالة مع بقاء تسلسلها، وإيصالات القراءة المجمعة، وبوابة WebSocket للتلميحات اللحظية الخالية من المحتوى.

## Invariants
1. تنظيف البيانات الوصفية (EXIF/Metadata) يجري إلزامياً على ملفات الصور والصوت (JPEG, PNG, WebP, MP3) قبل حفظها.
2. حذف الرسالة يمسح بايتات الوسائط فعلياً من القرص أو وحدة التخزين فور اكتمال المعاملة.
3. إيصالات الاستلام والقراءة مجمعة فقط (`receipt counts`) ولا تقدم قائمة بأسماء من قرأ الرسالة.
4. تلميحات WebSocket اللحظية تحمل إشارات فقط (`chat.message`, `resync`) دون نقل محتوى الرسالة، وتتطلب توثيقاً صارماً بترويسة `Authorization` عند ترقية الاتصال.
5. لا يرى العضو الجديد أي رسائل أو وسائط سبقت تسلسل انضمامه (`seq < joined_seq`).

## Owned Files
- `backend/migrations/112_family_chat_media.sql`
- `backend/src/family-chat.js`
- `backend/src/chat-media-store.js`
- `app/lib/features/n02_day/family_chat_screen.dart`
- `app/lib/foundation_gate/family_chat_api_client.dart`

## Enforcing Tests
- `backend/test/postgres-chat-realtime-media.test.js`:
  - `media: the bytes are cleaned before they are kept, replay is idempotent, and a lie is refused`
  - `deleting a voice note removes its bytes from disk, and the message keeps its place without them`
  - `receipts are aggregate counts only, never ahead of the newest message, and a read is also a delivery`
  - `realtime: authentication on upgrade, membership on subscribe, hints without content, removal and limits`
- `app/test/foundation_gate/family_chat_api_client_test.dart`

## Phone Evidence
- لا يلزمه فحص أجهزة أصلية منفصل، ولم يُختبر S3 السحابي الفعلي في هذه البيئة (none).

## Change Rule
أي تعديل على جدول الوسائط `family_chat_media` أو مسارات WebSocket يستلزم هجرة جديدة واجتياز اختبارات PostgreSQL في CI وموافقة المالك.
