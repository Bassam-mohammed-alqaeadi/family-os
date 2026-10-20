# العقد: العمود الفقري المشترك للأوامر والقدرات (S0 Spine Commands & Capabilities)

## Scope
ينظم هذا النظام العمود الفقري الموحد للمنصة عبر دفتر قدرات الأجهزة (`family_device_capabilities`)، ودورة حياة الأوامر الموجهة للأجهزة مع الإيصالات المؤكدة (`family_commands`, `family_command_receipts`)، ومظروف الأحداث الأمني S-SEV-1 في جدول `ai_events`، لمنع التكرار وضمان عدم إصدار أي أمر لجهاز لا يدعم القدرة رسمياً.

## Invariants
1. لا يصدر أمر `lock_now` أو أي أمر تنفيذي لجهاز إلا إذا كانت قدرته المطلوبة مسجلة رسمياً كـ `confirmed` في دفتر القدرات.
2. لكل أمر وقت انتهاء إلزامي (`expires_at`)، وأي إيصال متأخر بعد انتهاء الوقت يُرفض بكود `410 Gone`.
3. الإيصال الفاشل يفرض وجود سبب الفشل (`failureReason` إلزامي).
4. نبض القلب الدوري المتطابق في الحالة لا يولد أحداثاً جديدة في `ai_events` تفادياً لإغراق قاعدة البيانات.
5. لا يمكن إصدار أمر لجهاز مقطوع أو ملغى اعتماده (`revoked`).

## Owned Files
- `backend/migrations/117_family_device_capabilities.sql`
- `backend/migrations/118_family_commands.sql`
- `backend/migrations/119_ai_events_spine.sql`
- `backend/src/device-capabilities.js`
- `backend/src/command-lifecycle.js`

## Enforcing Tests
- `backend/test/postgres-spine-s0-migrations.test.js`
- `backend/test/spine-command-lifecycle.test.js`:
  - `S0 only enables lock_now / release_lock / refresh_policy`
  - `lock_now requires confirmed instant_lock capability`
  - `a late receipt on an expired command is refused (410)`
  - `an applied receipt advances state to applied and records the receipt`
- `backend/test/spine-device-capabilities.test.js`:
  - `heartbeat replay (same state) returns no changes and emits no events`
  - `a revoked device credential is refused`

## Phone Evidence
- لا يلزمه فحص أجهزة منفصل في هذه الشريحة (none).

## Change Rule
أي إضافة لأنواع الأوامر أو القدرات تتطلب تعديل ENUM في هجرة SQL معتمدة وتحديث العقد وحارس الانحراف.
