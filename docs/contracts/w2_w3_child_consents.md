# العقد: موافقات وإفصاح الطفل (W2/W3 Child Consents)

## Scope
ينظم هذا النظام دفتر موافقات الطفل الصريحة ومطابقة متطلبات متجر Google Play (الترتيب: الإفصاح البارز أولاً ثم طلب أذونات الموقع)، واشتراط وجود موافقة نشطة مسجلة في جدول `family_child_consents` على الخادم قبل قبول وتخزين أي نقطة موقع من هاتف الطفل، مع إمكانية سحب الموافقة وتجميد الصف وإعادة المنح.

## Invariants
1. يرفض الخادم أي نقطة موقع (`location-fixes`) بكود `403 consent_required` إذا لم تكن هناك موافقة نشطة مسجلة ومؤرخة على الخادم للقدرة المعنية.
2. لا تُطلب أذونات الموقع من نظام أندرويد في شاشة الإقران (CHD-002)، بل حصراً بعد شاشة الإفصاح البارز (CHD-003) وموافقة الطفل الصريحة.
3. قاعدة البيانات تفرض موافقة نشطة واحدة فقط لكل (طفل، قدرة) عبر فهرس جزئي فريد (`UNIQUE partial index`).
4. سحب الموافقة من قبل الولي يجمد الصف في دفتر الخادم ويوقف قبول نقاط الموقع فوراً، مع بقاء الإقران نشطاً دون مسح اعتماده.
5. لا يملك أي ولي من عائلة أخرى صلاحية تسجيل أو قراءة أو سحب موافقات عائلة ثانية (`403 Forbidden`).

## Owned Files
- `backend/migrations/114_family_child_consents.sql`
- `backend/src/child-consents.js`
- `app/lib/core/policy/child_consents.dart`

## Enforcing Tests
- `backend/test/postgres-child-consents.test.js`:
  - `no consent, no collection: the fix is refused, then granted, withdrawn, and re-granted — exactly the ledger`
  - `a guardian of another family records nothing here and reads nothing here`
  - `the database itself refuses two active consents for one capability`
- `backend/test/child-consents.test.js`

## Phone Evidence
- `docs/safety_phase/PHONE_CHECKS.md` ف٢ بنود 1–7 (حالتها الحالية `⬜` معلقة وغير مفحوصة بعد).

## Change Rule
أي تغيير في أعمدة جدول `family_child_consents` أو منطق التحقق في `child-consents.js` يستوجب هجرة مرقمة جديدة فوق 126 وفحص رحلات PostgreSQL في CI وموافقة المالك.
