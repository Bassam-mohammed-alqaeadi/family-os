# العقد: الاحتفاظ بموقع الطفل ومحو البيانات (W3 Location Retention & Data Erasure)

## Scope
ينظم هذا النظام نافذة الاحتفاظ الصارمة بموقع الطفل المحددة بـ 90 يوماً بقرار المالك، ومحو سجلات التتبع الجغرافي عند طلب الولي الصريح (`POST .../data-erasure`)، أو عند قطع الجهاز، أو عند حذف ملف الطفل (أرشفة الطفل وتجميد دفتر الموافقات وقطع أجهزته وحذف نقاط مواقعه)، مع الحفاظ على الحوادث الأمنية بفك ارتباط عينة الموقع (`fix_id = NULL`).

## Invariants
1. تقتصر نافذة الاحتفاظ بسجل المواقع على 90 يوماً كحد أقصى (`LOCATION_RETENTION_DAYS = 90`) وتُقلم تلقائياً داخل كل عملية كتابة بواسطة ساعة محقونة.
2. النقاط المرتبطة بحادث أمني SOS أو حدث منطقة آمنة لا تُحذف تلقائياً بمرور النافذة، وتنجو لضمان الدليل الجنائي.
3. طلب محو البيانات (`data-erasure`) يمحو نقاط الطفل ويفك ارتباطات SOS (`fix_id = NULL`) ويسجل تدقيقاً خالياً من أي محتوى جغرافي.
4. قطع الجهاز يمحو سجل نقاطه الجغرافية الخاصة به فوراً ولا يمس سجل أجهزة إخوته في نفس العائلة.
5. حذف الطفل يؤرشف سجله ببيانات المؤلف وتاريخ الأرشفة، ويجمد موافقاته، ويقطع أجهزته، ويمحو كافة نقاطه المكانية.

## Owned Files
- `backend/migrations/116_location_retention_erasure.sql`
- `backend/src/data-erasure.js`
- `backend/src/location-telemetry.js`

## Enforcing Tests
- `backend/test/postgres-data-erasure.test.js`:
  - `the trail is bounded at the owner's ninety days, and the samples the safety record points at outlive the window`
  - `the erasure demand really deletes, keeps the incident, audits without content, and never touches consent`
  - `cutting a device off deletes its trail and empties its snapshot — and leaves a sibling child alone`
  - `removal archives with provenance, freezes consent, cuts the handset off, really deletes, and closes every read`
- `backend/test/data-erasure.test.js`

## Phone Evidence
- `docs/safety_phase/PHONE_CHECKS.md` ف٣ بنود 0–6 (معلقة بانتظار قرار المالك لفتح بوابة الفحص بموقع حقيقي).

## Change Rule
أي تعديل على نافذة الـ 90 يوماً أو خوارزمية المحو يتطلب موافقة خطية صريحة من المالك وهجرة SQL معتمدة.
