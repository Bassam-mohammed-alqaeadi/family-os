# العقد: ناقل الإشعارات وصندوق الإرسال (S1 Notification Delivery & Outbox)

## Scope
ينظم هذا النظام ناقل الإشعارات الموحد (Outbox Dispatcher) الذي يعمل بعد إتمام معاملات قاعدة البيانات (`post-commit hook`)، ومحاولات الإرسال المحدودة لـ FCM، وتجاوز أحداث السلامة الأربعة (SOS والمناطق) لساعات الهدوء، مع تقليل حمولة الإشعارات تفادياً لتسريب أسماء الأبناء أو إحداثياتهم.

## Invariants
1. أحداث السلامة الأربعة (وعلى رأسها SOS) تتجاوز جميع ساعات الهدوء والتفضيلات المسجلة (`never_silence_safety`).
2. لا تُعاد محاولة الإرسال إذا كانت نتيجة المزود غامضة (`ambiguous`) لمنع إرسال إشعارات مكررة مربكة للوالد.
3. تفشل محاولات الإرسال بحد أقصى 5 محاولات مع تراجع متزايد (`exponential backoff`).
4. لا تسجل إشعارات المناطق أو الطوارئ أي إحداثيات خطوط طول وعرض أو أسماء أطفال في حمولة الدفع لحماية الخصوصية.
5. حذف تسجيل الدفع (`push registration`) ينهي فوراً أي محاولة إرسال مجدولة معلقة له.

## Owned Files
- `backend/migrations/120_family_push_registrations.sql`
- `backend/migrations/121_notification_delivery_proof.sql`
- `backend/migrations/122_notification_preferences.sql`
- `backend/migrations/123_notification_attempts.sql`
- `backend/migrations/124_notification_geofence_privacy.sql`
- `backend/src/notification-dispatcher.js`
- `app/lib/core/runtime/family_notification_router.dart`

## Enforcing Tests
- `backend/test/postgres-notification-delivery.integration.test.js`:
  - `real PostgreSQL delivers an SOS despite quiet/history preferences and records FCM evidence`
  - `real PostgreSQL never retries an ambiguous provider outcome`
  - `real PostgreSQL reports SOS delivered only after every guardian registration succeeds`
- `backend/test/postgres-push-registrations.test.js`
- `app/test/family_notification_router_test.dart`

## Phone Evidence
- `docs/safety_phase/PHONE_CHECKS.md` ف٤ بنود 0–5 (حالتها معلقة `⬜`؛ بيئة Render الحالية لا تملك مفاتيح FCM الحية، ولم يجرِ فحص الوصول الحي على هاتف).

## Change Rule
أي تغيير في جدول التفضيلات أو محاولات الإرسال يتطلب هجرة إلحاقية فوق 126 وفحص محاكاة FCM في CI وموافقة المالك.
