# `SAFETY-S2` — الموافقة والإفصاح بقدر السوق: سجل موافقات على الخادم، وجمع مشروط بها، وإفصاح في موضعه الصحيح

> **النوع:** الشريحة الثانية في مرحلة السلامة — [`../../safety_phase/01_SAFETY_PHASE_PLAN.md`](../../safety_phase/01_SAFETY_PHASE_PLAN.md) §٦ (معدّلة وفق §٥).
> **الحالة:** مدموجة في `main` (PR #35، 2026-10-10) · CI أخضر بكل بواباته · **لم تُفحص على هاتف حقيقي بعد** (ف٢ في [`PHONE_CHECKS.md`](../../safety_phase/PHONE_CHECKS.md)).

---

## ١) الهوية

| الحقل | القيمة |
|---|---|
| **المعرّف** | `SAFETY-S2` |
| **النظام** | الموقع الحي (عمود الجمع المشروع) + أدوات الصدق المشتركة |
| **الموجة** | المرحلة الثانية — السلامة (إكمال على الهاتف) |
| **المرحلة** | `REAL_ENGINE` |
| **المالك** | جلسة واحدة (Arena) |
| **الملفات المملوكة** | `backend/db/migrations/114_child_consents.sql` · `backend/src/child-consents.js` · `backend/src/location-telemetry.js` (فرض الموافقة) · `backend/src/validation.js` (مدخلات الموافقة) · `backend/src/app.js` (٣ مسارات) · `backend/openapi/foundation.v1.json` · `backend/test/{child-consents,postgres-child-consents,openapi-contract,postgres-integration}.test.js` · `app/android/.../MainActivity.kt` (وكيل `consentRequest` + `startConfigured`) · `LocationFixProtocolTest.kt` · `app/lib/foundation_gate/native_child_telemetry_bridge.dart` · `app/lib/features/n01_linking/{transparency_consent_screen,native_device_pairing_screens}.dart` · `app/lib/features/n07_privacy/what_is_collected_screen.dart` · `app/lib/features/n02_day/location_map_screen.dart` · ARB والمولَّدات · `app/test/support/native_telemetry_channel.dart` والاختبارات المقابلة |
| **تاريخ الفتح** | 2026-10-10 |
| **تاريخ الدمج** | 2026-10-10 (PR #35) |

## ٢) مشكلة المستخدم

**جملة واحدة:** التطبيق كان يطلب أذونات الموقع **قبل** أي إفصاح، ويجمع الموقع بلا سجل موافقة على الخادم، وزر «تحديد صامت» يوحي بمراقبة خفية — ثلاثة مخالفات لسياسات Play (User Data، Background Location، Stalkerware) وثلاث كذبات في تجربة المستخدم.

**الأدوار:** الطفل (يُفصح له ويوافق)، الولي (يسحب ويقرأ)، الخادم (يرفض جمعاً بلا موافقة).

**القيمة:** جمع الموقع صار **مشروطاً بموافقة مسجّلة** (من، متى، أي نص)، والإفصاح البارز يقع قبل طلب الأذونات بفعل موافقة صريح، وهاتف الطفل يقرأ حالة مشاركته من دفتر الخادم لا من تخمين محلي.

**ما لا تهدف إليه:** واجهة «ما أشاركه» الدائمة (أُزيلت من الشريحة بقرار المالك)؛ إشعار الطفل عند كل اطلاع (أُزيل)؛ موافقات `usage_stats` و`web_filtering` تُسجَّل في القاموس لكن فرضها يأتي في ش١١/ش١٤؛ زر «تحديث الموقع الآن» يعود في ش٤/ش٥ حين يصير الطلب حقيقة (دفع من الخادم للهاتف).

## ٣) ما تغيّر

| البند | التغيير | الدليل |
|---|---|---|
| سجل الموافقات | هجرة ١١٤ `family_child_consents`: capability/text_version/granted_at/withdrawn_at · مانح واحد حصراً (عضوية ولي **XOR** جهاز الطفل) بـCHECK · موافقة نشطة واحدة لكل (طفل، قدرة) بفهرس جزئي فريد · السحب يجمّد الصف ولا يمحوه · `UNIQUE (family_id, id)` للأجهزة (يلزم FK المركّب) | sha256 في المانيفست · رحلة PostgreSQL ترفض إدراج موافقتين نشطتين (23505) |
| فرض الموافقة | `POST /v1/devices/{id}/location-fixes` يرفض **403 `consent_required` قبل التخزين** بلا موافقة نشطة؛ الإقران يبقى (الجهاز يصنّفها `ACCESS_REFUSED` ولا يمسح) | رحلة PG: رفض ← منح ← قبول ← سحب ← رفض ← إعادة منح ← قبول · `LocationFixProtocolTest` صف 403 الجديد |
| المسارات | `POST …/consents` (جهاز **أو** ولي أول، Idempotency-Key، 409 `consent_already_granted`) · `POST …/consents/withdrawal` (ولي فقط، آمن التكرار) · `GET …/location-sharing` (قراءة مزدوجة: جهاز/ولي) — العقد ٩٣ مساراً، ومجموعتا الاختبار المسمّيات محدَّثتان | `openapi-contract.test.js` أخضر · `child-consents.test.js` ٨ قوانين |
| ترتيب Play | CHD-002 (الإقران) لم يعد يطلب الأذونات: يطالب ويخزّن الاعتماد فقط · CHD-003 (الإفصاح البارز) يقود الآن: موافقة ← **تسجيل على الخادم** ← طلب الأذونات ← بدء الخدمة (`startConfigured`) | `native_device_pairing_screens.dart` · `transparency_consent_screen.dart` · وكيل Kotlin `consentRequest` بقاموس مغلق (الاعتماد لا يعود لـDart أبداً) |
| صدق الرفض | تسجيل رُفض ⇒ الرحلة **تقف** بلافتة صادقة والزر هو إعادة المحاولة — لا «تم» بلا سجل | اختبارا CHD-003 الجديدان |
| CHD-010 | نطاق الموقع مدعوم بقراءة دفتر الخادم (`granted/withdrawn/none`)؛ بلا جلسة مقترنة يبقى المحلي كما هو بلا ادعاء | `_applyServerLocationConsent` · اختبارات fs004/fs007/privacy خضراء |
| «تحديد صامت» | إعادة تسمية كل المفاتيح إلى «تحديث الموقع الآن» (بلا كلمة «صامت») + **إخفاء الزر** حتى ش٤/ش٥ (لا طلب حي حقيقياً بعد) | ARB + المولَّدات byte-for-byte · `fs001_ux_adapt_test` يتوقع `findsNothing` |
| اختبارات الويدجت | قناة `native_child_telemetry` غير المربوطة لا تجيب أبداً ⇒ `pumpAndSettle` يعلق؛ مساعد مشترك يربط جواب «غير متاح» الصادق في ٦ مجموعات | `app/test/support/native_telemetry_channel.dart` |

## ٤) بوابة البيئة (PostgreSQL حقيقي)

- `postgres-child-consents.test.js` (٣ رحلات) مسجّل في `backend_ci.yml` وشغّال أخضر في CI.
- رحلات `location-fixes` الثلاث القائمة (w3 zones · w4 SOS · nl native) تمنح الموافقة أولاً — القانون الجديد يُطبق على الاختبارات كما على الإنتاج.
- محلياً: `npm test` = **٠ فشل** (بلا DATABASE_URL تتخطى رحلات PG؛ CI يشغّلها).

## ٥) ما بقي لف٢ (هاتف حقيقي)

1. إعداد هاتف طفل من الصفر: الشاشة تطلب الأذونات **بعد** الإفصاح لا قبله.
2. `location-sharing` على الهاتف يقول `granted` بعد الموافقة — و`location-fixes` يُقبل.
3. السحب من جانب الوالد ⇒ التقرير التالي من هاتف الطفل مرفوض `consent_required` والإقران باقٍ (الخدمة تشتكي، لا تموت).
4. إعادة المنح ⇒ القبول يعود. **الشرط:** كل خطوة بصف «نجح» في `PHONE_CHECKS.md` قبل ✅ في العمود الخامس.
