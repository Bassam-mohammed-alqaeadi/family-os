# العقد: دورة حياة جهاز الطفل وتلميتري الإبطال (W2 Child Device Lifecycle)

## Scope
يدير هذا النظام إقران هاتف الطفل بالعائلة عبر رمز إقران خادم مؤقت، وإرسال نبض تلميتري دوري (كل 15 ثانية) يتضمن نسبة البطارية وحالة الاتصال، مع كشف فوري لقطع الجهاز أو حذف ملف الطفل ووقف خدمة التتبع الأمامية وإطلاق إشعار نظام وإعادة ضبط التطبيق وخروجه فوراً لشاشة البداية.

## Invariants
1. لا يُعتبر قطع الجهاز ناجحاً على واجهة التطبيق إلا بعد إقرار الخادم الصريح في قاعدة البيانات (`server-first revocation`).
2. الرفض الصريح من الخادم يُبقي الجهاز مقترناً ويعرض رسالة خطأ صادقة دون اصطناع نجاح محلي.
3. عند حدوث سباق بين عمليتي قطع لنفس الجهاز، تنجح عملية واحدة فقط بحارس `WHERE credential_revoked_at IS NULL`.
4. انقطاع الاتصال أو حذف الطفل يُوقف خدمة `ChildTelemetryService` الأصلية فوراً ويبث `ACTION_DEVICE_REVOKED`.
5. تلقي إشارة الإبطال في Flutter يعيد ضبط الدور تلقائياً إلى دور الأب وينتقل إلى `/scr-shr-001`.

## Owned Files
- `app/android/app/src/main/kotlin/com/familyos/family_os/ChildTelemetryService.kt`
- `app/android/app/src/main/kotlin/com/familyos/family_os/MainActivity.kt`
- `app/lib/foundation_gate/native_child_telemetry_bridge.dart`
- `app/lib/features/n02_day/child_profile_screen.dart`
- `backend/src/device-lifecycle.js`
- `backend/src/device-revocation.js`

## Enforcing Tests
- `backend/test/postgres-integration.test.js`:
  - `a real revocation commits, and the device stops being trusted`
  - `the guard in the WHERE clause survives two real concurrent revocations`
- `app/test/features/device_revocation_server_first_test.dart`:
  - `child profile lost cut: server confirms, then the local mirror closes`
  - `child profile lost cut: server refusal leaves the device open and says so`
- `app/test/foundation_gate/family_device_api_client_test.dart`

## Phone Evidence
- `docs/safety_phase/PHONE_CHECKS.md` ف١ بنود 4، 5، 6، 7، 8 (تم الفحص والتحقق على **محاكيي أندرويد emulator-5554 و emulator-5556**، ولم يُجرَ على هاتف حقيقي).

## Change Rule
أي تغيير في مسارات الإبطال أو أعمدة أجهزة الأطفال يتطلب موافقة المالك واختبارات تكامل PostgreSQL وفحص سلوك البث الأصلي على المحاكي.
