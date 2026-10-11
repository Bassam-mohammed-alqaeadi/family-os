# استئناف العمل — مرحلة السلامة (اقرأ هذا أولاً)

> **الغرض:** أن تستأنف أي جلسة — إنسان أو وكيل — العمل بلا فقد، حتى لو انتهى رصيد الجلسة السابقة.
> **يُحدَّث في نهاية كل شريحة**، في طلب الدمج نفسه.
> **آخر تحديث:** 2026-10-11 — ش٠ (العمود الفقري) مكتملة على الفرع (دفع القدرات + ناقل الأوامر + مظروف الأحداث، ٣٦٦/٠ اختبار)؛ ش٣ مدموجة (PR #37)؛ التالية ش١ القفل الحي، يليها ش٢ الموقع الحي فوق العمود الفقري، ثم ش٤ الإشعارات. بوابة ف٣ (أول فحص بموقع حقيقي) بانتظار قرار المالك.

---

## ١) أين نحن

| الحقل | القيمة |
|---|---|
| المرحلة | السلامة — [`01_SAFETY_PHASE_PLAN.md`](01_SAFETY_PHASE_PLAN.md) |
| الشريحة الحالية | **ش٤ — الإشعارات** — بطاقتها تُفتح مع أول إيداع (تحتاج `FAMILY_PUSH_FCM_*` على Render قبل أي فحص حي) |
| الفرع | `main` وحده (توحيد التطوير) — كل شريحة بفرع قصير العمر ← PR ← CI أخضر ← merge |
| حالة ش٠ | **مدموجة** (PR #34، 2026-10-10): الإنشاء الحقيقي للعائلة، القطع server-first، محاذاة التوثيق — بطاقة التماسك في خريطة التماسك «Slice 0 resolutions» |
| حالة ش١ | **مدموجة**: APK release من CI + إعلان Play + إزالة بقايا التجربة — بطاقة [`SAFETY-S1`](../harness/cards/SAFETY-S1-honest-build.md) |
| حالة ش٢ | **مدموجة** (PR #35، 2026-10-10، CI أخضر بكل بواباته): هجرة ١١٤ سجل الموافقات، `location-fixes` يرفض `consent_required` بلا موافقة نشطة، ٣ مسارات موافقات، ترتيب Play (الإفصاح قبل الأذونات)، CHD-010 من دفتر الخادم، «تحديث الموقع الآن» مسمّى ومُخفى حتى ش٤/ش٥ — بطاقة [`SAFETY-S2`](../harness/cards/SAFETY-S2-consent-disclosure.md) |
| حالة ش٣ | **مدموجة** (PR #37، 2026-10-11، خادم فقط — لم تمسّ الهاتف): هجرة ١١٦ (فهرس الاحتفاظ + أرشفة الأطفال + قانون لقطة التليمتري المُعاد تعريفه)، `LOCATION_RETENTION_DAYS = 90` مُثبت بساعة محقونة على PostgreSQL، محو بطلب الوالد (`data-erasure`)، إزالة الطفل (أرشفة + تجميد الدفتر + قطع الأجهزة + محو كامل)، والمحو الفعلي عند قطع الجهاز، وسجل تدقيق «حُذف» بلا محتوى ولا outbox — بطاقة [`SAFETY-S3`](../harness/cards/SAFETY-S3-retention-erasure.md) |
| حالة ش٠ (العمود الفقري) | **مكتملة على الفرع (هذا الطلب)**: هجرات ١١٧ (دفتر القدرات) · ١١٨ (ناقل الأوامر + الإيصالات) · ١١٩ (مظروف الأحداث الأمني S-SEV-1: security_context/required_capabilities/ttl_minutes/expires_at/trace_id + قيود) · وحدتا `device-capabilities.js` و`command-lifecycle.js` · ٦ مسارات منشورة في العقد · عقد OpenAPI صار ١٢٠ مساراً و٢١٣ schema (من ١١٤/١٩٥ عند إيداع الخطة) · عملاء Dart و٦ URI builders · مكوّن `DeviceCapabilityHonestyBadge` · لقطة Kotlin أصلية (`NativeCapabilitySnapshot.kt` + قناة `capabilitySnapshot` في `MainActivity`) مصدر صادق للأذونات التي لا يعرفها Dart (PACKAGE_USAGE_STATS/SYSTEM_ALERT_WINDOW/Accessibility/BOOT_COMPLETED/DeviceAdmin) · ١٢ قانون وحدة + اختبار PGlite يطبّق ٢٨ هجرة (إجمالي ٣٦٦/٠) — بطاقة [`SAFETY-S0`](../harness/cards/SAFETY-S0-spine.md) |
| التالي | **س١ الإشعارات** (هجرات ١٢٠/١٢١/١٢٢ وفق §٦٫١ من الخطة الرئيسية — تسجيل الدفع بهوية الجهاز، delivered/failed في delivery_state، تفضيلات الإشعارات). يليها س٢ متانة الهاتف، فس٤ الخريطة الحية، فس٥ الأماكن وتنبيهاتها، وصولاً إلى س١١ القفل الفوري وس١٦ الاختبار الشامل. **بوابة ف٣ (أول فحص بموقع حقيقي على هاتفين) شرطها التقني س٤ (الخريطة) + ش٣، ولا تُفتح إلا بقرار المالك** — [`PHONE_CHECKS.md`](PHONE_CHECKS.md) ف٣ |
| الهجرة التالية | `120` (لس١ الإشعارات) |
| اختبار على هاتف حقيقي | **لم يجرِ أي اختبار بعد** |

## ٢) ما أُنجز في ش٣ (مدموجة — PR #37، 2026-10-11)

- **هجرة ١١٦** `116_location_retention_erasure.sql`: فهرس الاحتفاظ `(family_id, recorded_at)` الذي وعدت به ١٠٣ ولم يوجد · `family_children.archived_at` + `archived_by_membership_id` بقيد إسناد (لا أرشفة بلا مؤلف) وفهرس جزئي للنشطين · **إعادة تعريف `family_child_devices_latest_telemetry_complete`** (٠٠٧): قانون «الكل أو لا شيء» جعل تفريغ `location_*` وحده مستحيلاً بلا كذب عن البطارية وآخر رؤية — صار «لا تليمتري قبل أول تقرير»، والموقع المُفرَّغ حالة شرعية يقرؤها `device-lifecycle` بصدق. الـsha256 مسجّل في المانيفست.
- **الاحتفاظ ٩٠ يوماً** (قرار المالك): `LOCATION_RETENTION_DAYS = 90` في `location-telemetry.js`، وجواب السجل يقول `retentionDays: 90`، والتنظيف يجري داخل كل كتابة — **مُثبت على PostgreSQL بساعة محقونة** (مرساة ٢٠٠ يوم في الماضي؛ المخطط يرفض تثبيتات المستقبل): العادي يُقلم، والمشار إليه من حدث منطقة أو من SOS ينجو، وداخل النافذة ينجو.
- **محو بطلب الوالد**: `POST /v1/families/{fid}/children/{cid}/data-erasure` (ولي أساسي **أو** مشارك، Idempotency-Key إلزامي) — الترتيب الواحد في كل المحو: أحداث المناطق ← فصل مراجع SOS (`fix_id = NULL`؛ الحادث يبقى وعيّنته تُحذف) ← التثبيتات ← تفريغ لقطات الأجهزة (`last_seen_at` يبقى — الزمن ليس موقعاً). الجواب أعداد صادقة، وإعادة التشغيل أصفار صادقة، وتدقيق `family.child_location_erased` **بلا محتوى وبلا outbox**.
- **إزالة الطفل**: `DELETE /v1/families/{fid}/children/{cid}` — أرشفة بإسناد (لا حذف صف: التاريخ القانوني يبقى)، سحب كل الموافقات النشطة (الدفتر **يتجمد** — قانون ش٢)، قطع كل جهاز غير مقطوع، ومحو كامل؛ `family.child_archived` في التدقيق **وoutbox**. القراءات كلها تستبعد المؤرشف (٨ وحدات)، والابتلاع من أجهزته ٤٠١، وإعادة الإزالة بمفتاح جديد ٤٠٩ `child_already_archived`.
- **المحو عند القطع**: `revocation` تفرّغ `location_*` **وتحذف الأثر فعلياً** (+ تدقيق `family.child_device_location_erased`) — الجواب `{device, erased}`، والمحو معلّق على الجهاز فلا يمسّ أثر أخيه. رحلة LOC-001 المحدّثة تؤكد: بعد القطع `countFixes() === 0`.
- **العقد**: مساران + مخططات المحو/الأرشفة + `erased` — **٩٨ مساراً و١٩٥ مخططاً**.
- **الاختبارات**: `data-erasure.test.js` ١٥ قانوناً + قانون محو في `device-revocation.test.js` + ٤ قوانين SQL + **`postgres-data-erasure.test.js` ٤ رحلات** مضافة إلى `backend_ci.yml`. محلياً على PostgreSQL ١٨٫٤ حقيقي: قائمة CI الكاملة **٤٢/٤٢** و`npm test` كاملاً **٣٩٦/٠**؛ وبلا قاعدة: **٣٥٤/٠/٤٤ تخطياً**.
- **شريحة خادم فقط**: Dart لم تتغير (العميل يقرأ `retentionDays` من الخادم أصلاً) — لا فحص هاتف لش٣، والبوابة التي فتحتها هي **ف٣ بقرار المالك**. التفصيل في بطاقة [`SAFETY-S3`](../harness/cards/SAFETY-S3-retention-erasure.md).

## ٢ب) ما أُنجز في ش٢ (مدموجة — PR #35، 2026-10-10)

- **هجرة ١١٤** `family_child_consents`: سجل الموافقات (capability · text_version · granted_by · granted_at · withdrawn_at) — مانح واحد حصراً (عضوية ولي **XOR** جهاز الطفل) بـCHECK، وموافقة نشطة واحدة لكل (طفل، قدرة) بفهرس جزئي فريد، والسحب يجمّد الصف ولا يمحوه (التاريخ يبقى). + `UNIQUE (family_id, id)` للأجهزة (يلزم الـFK المركّب).
- **الجمع مشروط**: `POST /v1/devices/{id}/location-fixes` يرفض **403 `consent_required` قبل التخزين** بلا موافقة نشطة؛ الإقران باقٍ — الجهاز يصنّفها `ACCESS_REFUSED` (صفّ اختبار في `LocationFixProtocolTest`).
- **٣ مسارات**: منح (جهاز أو ولي أول، Idempotency-Key، 409 `consent_already_granted`) · سحب (ولي فقط، آمن التكرار) · `GET …/location-sharing` (قراءة مزدوجة) — العقد ٩٣ مساراً و٥ مخططات.
- **ترتيب Play أُصلح**: CHD-002 (الإقران) يطالب ويخزّن الاعتماد فقط؛ CHD-003 (الإفصاح البارز) يقود: موافقة ← تسجيل على الخادم ← طلب الأذونات ← بدء الخدمة (`startConfigured`). رفض التسجيل يوقف الرحلة بلافتة صادقة (لا «تم» بلا سجل). وكيل Kotlin `consentRequest` بقاموس مغلق — الاعتماد لا يعود لـDart.
- **CHD-010** يقرأ نطاق الموقع من دفتر الخادم؛ **«تحديد صامت» → «تحديث الموقع الآن»** (بلا كلمة «صامت») والزر **مُخفى** حتى ش٤/ش٥ حين يصير الطلب حقيقة.
- **الاختبارات**: ٨ قوانين وحدة + رحلتا PostgreSQL (رفض←منح←قبول←سحب←رفض←إعادة منح · عائلة أخرى 403 · القاعدة ترفض موافقتين نشطتين) في `backend_ci.yml`؛ رحلات location-fixes القائمة تمنح الموافقة أولاً؛ ٦ مجموعات ويدجت تربط قناة telemetry الصامتة (`app/test/support/native_telemetry_channel.dart`).
- **CI أخضر بكل بواباته** (analyze-test · Real PostgreSQL · Test-signed APK · Native JVM · contract). التفصيل في بطاقة [`SAFETY-S2`](../harness/cards/SAFETY-S2-consent-disclosure.md).

## ٢ج) ما أُنجز في ش١ (مدموجة)

- `.github/workflows/android_build.yml`: APK release موقّع بمفتاح اختبار مؤقّت (لا يُرفع إلى Play أبداً)، يتحقق من APK نفسه (`isMonitoringTool`، غير قابل للتصحيح)، ويفشل باسم واضح عند غياب `GOOGLE_SERVICES_JSON` أو `FAMILY_OS_API_ORIGIN`.
- `scripts/verify-no-service-account-keys.mjs` يرفض `*.jks|*.keystore|*.p12|*.pfx` و`key.properties`، و`scripts/verify-no-service-account-keys.test.mjs` يثبت ذلك سلبياً (يعمل في Credential Guard).
- `AndroidManifest.xml`: `<meta-data android:name="isMonitoringTool" android:value="child_monitoring" />` + `tools/android/check_manifest_policy.mjs` في Android Native CI.
- `classifyHost` (الخادم) و`WebFilterEngine.classifyHost` (العميل) بلا جدول `*.example`؛ اختباران يثبتان أن التصنيف لم يتغير.
- قفل وضع الطفل: لا كلمة سر في `lib`؛ الإنتاج يجيب `ChildModeUnlockOutcome.unavailable` والشاشة تعرض لافتة صادقة وتُخفي تحذير «إخطار الوالد». سجل الـmock ٢٠ ← ١٩.
- `applyUxLocalSeed(isReleaseMode: true)` لا يزرع شيئاً، واختبار يحرسه.
- عمود «على الهاتف» في `docs/CURRENT_EXECUTION_PLAN.md`، والمؤشر يشير إلى هذه المرحلة.

التفصيل والأدلة في البطاقة.

> **ش٠ (شريحة التماسك) مدموجة قبل ش١** (PR #34): الإنشاء الحقيقي للعائلة، القطع server-first، ومحاذاة التوثيق — انظر «Slice 0 resolutions» في [`02_PLATFORM_COHERENCE_MAP.md`](02_PLATFORM_COHERENCE_MAP.md).

## ٢ب) ما أُنجز في ش٠-العمود الفقري (هذا الطلب)

- **هجرة ١١٧ `family_device_capabilities`**: دفتر قدرات صادق لكل جهاز، مفتاح طبيعي `(device_id, capability_key)`، CHECK يربط `state='confirmed'` بـ`confirmed_at` غير فارغ، نوعا `capability_key` و`capability_state` ENUM بالمفردات الأولى (`instant_lock`, `background_location`, `push_delivery` × `confirmed/awaiting_setup/permission_needed/unsupported/revoked/unknown`).
- **هجرة ١١٨ `family_commands` + `family_command_receipts`**: ناقل أوامر بـ`idempotency_key` فريد في العائلة، و`expires_at` إلزامي، وقيود حالة، و`failure_reason` إلزامي عند `failed`/`limited`، وجدول إيصالات بمفتاح أمر واحد فقط. أنواع س٠: `lock_now`, `release_lock`, `refresh_policy`.
- **هجرة ١١٩ مظروف `ai_events`**: أعمدة S-SEV-1 (`security_context` JSONB object، `required_capabilities` text[] مقيدة بالمفردات المعلنة، `ttl_minutes` int مع CHECK ١–٤٣٢٠٠، `expires_at` timestamptz بقيود ttl_pair، `capability_key`، `command_id` FK إلى family_commands، `causality_id`, `severity`, `policy_id`, `source_trust`, `data_quality`, `visibility_class`, `retention_class`, `trace_id` بفهرس فريد داخل العائلة) + backfill للأحداث التاريخية.
- **الوحدات**: `device-capabilities.js` (جهاز يُبلّغ لقطة + وصي يقرأ، idempotent، نبض القلب لا يُحدث حدثاً) و`command-lifecycle.js` (وصي يُنشئ أمراً بتحقق من القدرة المؤكدة، جهاز يسحب ويردّ بإيصال، إيصال متأخر ٤١٠) مع منافذ Postgres كاملة وتحقق من المدخلات.
- **العقد**: ٦ مسارات منشورة فعلاً (منها مسار قائمة أوامر العائلة)، ٢١٣ schema، ١٢٠ مساراً إجمالاً (بسبب schemas/مسارات سابقة مضافة أثناء العمل).
- **Dart**: عميلان للقدرات وللأوامر بنمط العميل الموجود، ٦ URI builders، مكوّن `DeviceCapabilityHonestyBadge` يعرض شارات عربية صادقة بألوان `Tag` الموجودة.
- **الاختبارات**: ١٢ قانوناً جديداً (٦ للقدرات + ٦ للأوامر); المجموع الكلي ٣٦٦ pass / ٠ fail من ٤١٠. البوابات الخلفية كلها خضراء.

التفصيل والأدلة في البطاقة.

## ٣) قرارات المالك (ملزمة)

1. **أندرويد أولاً**، ثم آيفون بعد الاختبار الشامل.
2. **Render المجاني** حتى قرب الإطلاق.
3. **خرائط Google** الآن (ش٦).
4. **الاحتفاظ بسجل الموقع ٩٠ يوماً** (ش٣).
5. **ثمانية أنظمة في النطاق:** الموقع الحي، الأماكن وتنبيهات الوصول/المغادرة، SOS، تسجيل الوصول وتنبيه البطارية، سجل الموقع، وقت الشاشة وحدود التطبيقات، حجب التطبيقات، فلترة الويب. **سلامة القيادة مؤجّلة.**
6. **لا بيانات اصطناعية في تجربة المستخدم** (مسموحة في الاختبارات فقط).
7. **فحص هاتف صغير بعد كل شريحة تمسّ الهاتف**، ببيانات اختبار موسومة وبلا GPS حقيقي — [`PHONE_CHECKS.md`](PHONE_CHECKS.md).
8. **سياسة الشفافية:** بقدر السوق (Life360 / FamiSafe / Family Link) وما يفرضه أندرويد وPlay فقط — الخطة §٥.
9. **التوثيق داخل المستودع إلزامي** ويُحدَّث كل شريحة.
10. لا إنفاق ولا قرار تخزين جديد؛ مزوّد الوسائط مؤجّل.
11. رحلات عاملة فعلاً عند المالك ولا يجوز كسرها: **تسجيل الدخول، إنشاء عائلة، إضافة طفل للعائلة.**

## ٤) الإعداد المعروف (بلا قيم سرّية)

| ما | أين | الحالة |
|---|---|---|
| سرّ `GOOGLE_SERVICES_JSON` (محتوى `google-services.json` كاملاً) | GitHub Actions secrets | أكّد المالك وجوده واسمه (2026-10-10). مشروع Firebase: `family-os-synthetic-test`، الحزمة `com.familyos.family_os` |
| متغيّر `FAMILY_OS_API_ORIGIN` (https) | GitHub Actions **variables** | كان موجوداً 2026-10-07 (تشغيلات «Android Build» ناجحة على فرع arena قديم). **لم يُتحقق منه اليوم** (لا صلاحية قراءة المتغيّرات) — أول تشغيل لـ`android_build.yml` يكشفه برسالة واضحة |
| رابط قاعدة البيانات | متغيّرات Render فقط | لا يُطلب ولا يُخزَّن |
| مفاتيح FCM للخادم (`FAMILY_PUSH_FCM_*`) | Render | مطلوبة قبل ش٤ |
| مفتاح Maps SDK | Google Cloud | مطلوب قبل ش٦ |

## ٥) مخاطر مؤرّخة

| الخطر | التاريخ | المطلوب |
|---|---|---|
| **قاعدة Render المجانية تُحذف** — أُنشئت 2026-09-29، وRender يحذف القاعدة المجانية بعد ٣٠ يوماً (مع مهلة ١٤ يوماً للترقية، وبلا نسخ احتياطي) | **قرابة 2026-10-29** | قبل ذلك: يرقّي المالك القاعدة، أو يُعيد إنشاءها ويُشغّل الهجرات (`npm run migrate`). البيانات الحالية اصطناعية |
| مفتاح توقيع الاختبار مخزّن في cache الـActions | عند إخلاء الـcache | يُولَّد مفتاح جديد، وعلى الهاتف حذف النسخة السابقة قبل التثبيت (يُفقد الإقران) |
| الخادم المجاني ينام بعد ١٥ دقيقة | دائم حتى الترقية | أول طلب بعد النوم يتأخر نحو دقيقة؛ يُذكر في كل فحص هاتف |

## ٦) قرارات معلّقة على المالك (ومتى تلزم)

| القرار | يلزم قبل |
|---|---|
| **حاضر الآن:** تخزين بيانات موقع حقيقية على خادم التطوير؟ ولمن؟ وأي هاتفان؟ (ش٢+ش٣ اكتملتا — البوابة التقنية لف٣ مفتوحة والقرار للمالك) | ف٣ — أول فحص بموقع حقيقي |
| من يحتفظ بمفتاح توقيع الإصدار | ش٦ |
| طريقة حجب التطبيقات (بعد التجربة) | ش١٢ |
| مصدر تصنيف المواقع | ش١٤ |

## ٧) كيف تتحقق محلياً

```bash
# الخادم
cd backend && npm ci && npm run check && npm test        # اختبارات PostgreSQL تُتخطّى بلا DATABASE_URL
# Flutter 3.35.7
cd app && flutter pub get && flutter gen-l10n && dart run tool/gen_routes.dart
flutter analyze --fatal-infos && flutter test
# حراس المستودع
node scripts/verify-no-service-account-keys.mjs
node --test scripts/verify-no-service-account-keys.test.mjs
node tools/android/check_manifest_policy.mjs
node tools/harness/check_dart_imports.mjs .
tools/harness/harness_check.sh
```

## ٨) قواعد العمل

- فرع قصير العمر لكل شريحة ← طلب دمج ← CI أخضر ← merge commit.
- لا أسرار ولا قيم إعداد ولا معرّفات عائلات في المستودع أو السجلات أو المحادثة.
- لا GPS حقيقي حتى بوابة ش٢+ش٣ وقرار المالك.
- في نهاية كل شريحة: حدّث هذا الملف، و`CURRENT_EXECUTION_PLAN.md`، وكتلة `LOOP_STATE.md`، وبطاقة الشريحة.
