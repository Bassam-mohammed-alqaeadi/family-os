# العقد: العمود الفقري المشترك للأوامر والقدرات (S0 Spine Commands & Capabilities)

## Scope
ينظم هذا النظام العمود الفقري الموحد للمنصة عبر دفتر قدرات الأجهزة (`family_device_capabilities`)، ودورة حياة الأوامر الموجهة للأجهزة مع الإيصالات المؤكدة (`family_commands`, `family_command_receipts`)، ومظروف الأحداث الأمني S-SEV-1 في جدول `ai_events`، لمنع التكرار وضمان عدم إصدار أي أمر لجهاز لا يدعم القدرة رسمياً.

## Invariants
1. لا يصدر أمر `lock_now` أو أي أمر تنفيذي لجهاز إلا إذا كانت قدرته المطلوبة مسجلة رسمياً كـ `confirmed` في دفتر القدرات.
2. لكل أمر وقت انتهاء إلزامي (`expires_at`)، وأي إيصال متأخر بعد انتهاء الوقت يُرفض بكود `410 Gone`.
3. الإيصال الفاشل يفرض وجود سبب الفشل (`failureReason` إلزامي).
4. نبض القلب الدوري المتطابق في الحالة لا يولد أحداثاً جديدة في `ai_events` تفادياً لإغراق قاعدة البيانات.
5. لا يمكن إصدار أمر لجهاز مقطوع أو ملغى اعتماده (`revoked`).

## App Surface (admitted 2026-10-26)

The guardian screen that reads this spine is `SCR-FAT-026` (device health detail), mounted last in
`app/lib/features/n12_devices/device_health_detail_screen.dart` by
`app/lib/features/n12_devices/device_capability_ledger_panel.dart`, behind
`app/lib/features/n12_devices/device_ledger_server_authority.dart`. Two rules bind that surface:

6. **One capability, one road to the handset.** This screen issues `refresh_policy` only. `lock_now`
   and `release_lock` belong to the screen-time panel until S11 moves that decision onto this bus, and
   the ledger says so instead of offering a second button. A control that would duplicate an existing
   power is a contract violation, not a UI choice.
7. **No identifier that is not the server's.** A child or device id that is not a UUID is answered as
   `notLinked` by the authority and never sent; the server's 404 must not be allowed to become a
   statement about a child it has never met.

## Owned Files
- `backend/migrations/117_family_device_capabilities.sql`
- `backend/migrations/118_family_commands.sql`
- `backend/migrations/119_ai_events_spine.sql`
- `backend/src/device-capabilities.js`
- `backend/src/command-lifecycle.js`
- `app/lib/features/n12_devices/device_ledger_server_authority.dart`
- `app/lib/features/n12_devices/device_capability_ledger_panel.dart`
- `app/lib/core/design/components/device_capability_honesty_badge.dart`

## Enforcing Tests
- `app/test/features/n12_devices/device_ledger_server_authority_test.dart` (13) ·  `device_capability_ledger_panel_test.dart` (7) ·  `device_health_detail_screen_test.dart` (9, two of them the ledger's screen wiring)

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
- العمود الخامس لم يُمنح بعد. الفحص المطلوب محدَّد في  [`docs/harness/cards/SAFETY-S0-app-surface.md`](../harness/cards/SAFETY-S0-app-surface.md) §٦  (٤ بنود على هاتفين)، ولا ✅ إلا بسطر مؤرَّخ في `docs/safety_phase/PHONE_CHECKS.md`.

## Change Rule
أي إضافة لأنواع الأوامر أو القدرات تتطلب تعديل ENUM في هجرة SQL معتمدة وتحديث العقد وحارس الانحراف.
