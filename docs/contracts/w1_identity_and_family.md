# العقد: العائلة والهوية ورموز الدعوة (W1 Identity & Family)

## Scope
يدير هذا النظام إنشاء العائلات وعضويات الأولياء (الأب والأم) ونظام رموز الدعوة المكونة من 10 أحرف (SHA-256) التي تتيح للأم الانضمام إلى العائلة بحسابها الموثق عبر Firebase Auth دون كشف معرفات الحسابات أو البريد مسبقاً، مع ضبط انتهاء الصلاحية والتراجع والأمان ضد التكرار والتنافس.

## Invariants
1. لا يُخزن رمز الدعوة بصيغة نصية مجردة في قاعدة البيانات بل بصمة SHA-256 فقط (`CHECK` constraint).
2. الرمز صالح لمرة واحدة فقط ولمدة 24 ساعة كحد أقصى، ولا يُقبل أكثر من 5 رموز مفتوحة في العائلة في نفس الوقت.
3. التراجع عن الرمز أو انتهاء صلاحيته يُرجع نفس الاستجابة الموحدة التي يرجعها الرمز المجهول لمنع استكشاف الحالات.
4. عند تنافس حسابين على استرداد نفس الرمز، ينضم حساب واحد فقط بنجاح ويُرفض الآخر بقطعية.
5. الولي الأساسي (الأب) وحده يملك صلاحية إصدار رموز الدعوة وإلغائها.

## Owned Files
- `backend/src/family-invite-codes.js`
- `backend/migrations/115_family_invite_codes.sql`
- `app/lib/core/identity/identity_runtime.dart`
- `app/lib/features/n01_linking/invite_mother_screen.dart`
- `app/lib/features/n01_linking/accept_mother_invite_screen.dart`
- `app/lib/foundation_gate/family_invite_code_api_client.dart`

## Enforcing Tests
- `backend/test/postgres-invite-codes.test.js`:
  - `a guardian issues a code once, and the invitee joins with it - no account id needed`
  - `expired and revoked codes are refused with the same answer as an unknown one`
  - `only the primary guardian issues; members cannot spend a code twice; five open codes at most`
  - `two accounts racing for one code: exactly one joins`
- `app/test/foundation_gate/family_invite_code_api_client_test.dart`

## Phone Evidence
- `docs/safety_phase/PHONE_CHECKS.md` ف١ بنود 2، 3 (تم الفحص على **محاكي أندرويد emulator** وليس هاتفاً حقيقياً).

## Change Rule
أي تعديل على جداول الدعوات أو شروط الصلاحية يتطلب هجرة SQL إلحاقية مرقمة جديدة فوق 126 مع حارس انحراف العقد (`npm run check`) وموافقة المالك.
