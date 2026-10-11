# `SAFETY-S0` — العمود الفقري المشترك: دفتر القدرات + ناقل الأوامر + مظروف الأحداث الأمني

> **النوع:** الشريحة صفر في مرحلة السلامة — العمود الفقري الذي س١ (قفل حي) وس٢ (الموقع الحي) يبنيان فوقه.
> **الحالة:** مدموجة في `main` (هذه الشريحة) · **الاختبارات: ٣٦٦ pass / ٠ fail** (ارتفعت من ٣٥١ قبل الشريحة بـ١٥ قانوناً جديداً) · `npm run check` أخضر · `check_dart_imports` أخضر (٠ ميت) · `check_manifest_policy` أخضر · `check_migration_range` ينتظر ١٢٠.

---

## ١) الهوية

| الحقل | القيمة |
|---|---|
| **المعرّف** | `SAFETY-S0` |
| **النظام** | العمود الفقري المشترك (قدرات الجهاز + ناقل الأوامر + مظروف الأحداث) |
| **الموجة** | المرحلة الثانية — السلامة (قبل س١ قفل حي وس٢ موقع حي) |
| **المرحلة** | `REAL_ENGINE` |
| **المالك** | جلسة واحدة (Arena) |
| **الملفات المملوكة** | `backend/db/migrations/117_device_capabilities.sql` · `backend/db/migrations/118_command_lifecycle.sql` · `backend/db/migrations/119_ai_events_security_envelope.sql` · `backend/src/device-capabilities.js` (جديد) · `backend/src/command-lifecycle.js` (جديد) · `backend/src/ai-events.js` (مظروف S-SEV-1: مطلوب `securityContext` + قيود كاتب/قارئ/ttl) · `backend/src/app.js` (٥ مسارات) · `backend/src/validation.js` (مدخلات القدرات/الأوامر/الإيصالات) · `backend/src/schema-manifest.js` (بصمات ١١٧–١١٩) · `backend/openapi/foundation.v1.json` (١٢٠ مساراً و٢١٣ schema) · `backend/test/spine-device-capabilities.test.js` · `backend/test/spine-command-lifecycle.test.js` · `app/lib/foundation_gate/foundation_gate_configuration.dart` (٦ URI builders) · `app/lib/foundation_gate/family_capability_api_client.dart` (جديد) · `app/lib/foundation_gate/family_command_api_client.dart` (جديد) · `app/lib/core/design/components/device_capability_honesty_badge.dart` (جديد) |
| **تاريخ الفتح** | 2026-10-11 |

## ٢) مشكلة المستخدم

**جملة واحدة:** قبل س٠ لم يكن هناك «دفتر» يثبت ماذا يستطيع الجهاز فعلاً (بعيداً عن مزاعم الشاشة)، ولا «ناقل أوامر» يربط بين وصي يأمر وجهاز يطبّع مع إيصالات صادقة وآجال تنتهي؛ وكانت أحداث الذكاء الاصطناعي تكتب بلا مظروف أمني (لا `securityContext`، لا `requiredCapabilities`، لا TTL)، فينكسر مبدأ الصدق (R4) قبل أن نبدأ بالقفل الحي أو الموقع.

**الأدوار:** الجهاز (يبلّغ حقائقه، يسحب الأوامر، يردّ بإيصالات)، الوصي (يقرأ القدرات، يطلق أوامر lock_now/release_lock/refresh_policy)، الخادم (يملك الحقائق، لا يكذب على الشاشة).

**القيمة:**
- *الصدق قبل القفل*: شارة «غير مدعوم على هذا الجهاز» أو «إذن مطلوب» تظهر قبل أي زر قفل، فلا زر يعِد بما لا يقدر عليه الجهاز (R4).
- *الأوامر آجلة لا سرمدية*: `expires_at` (ttl) + ٤١٠ على الإيصال المتأخر، و`failureReason` إلزامي عند الفشل، و`effectiveState` يُحفظ مع الإيصال.
- *الحدث الأمني لا يسافر عارياً*: مظروف S-SEV-1 من `02_PLATFORM_COHERENCE_MAP.md` يفرض `securityContext` و`requiredCapabilities` على الكاتب و`ttl` على الأحداث الأمنية؛ لا `console.log` لأحداث الذكاء (T2).

**ما لا تهدف إليه:** قفل حي فعلي (س١)، موقع حي فعلي (س٢)، أوامر تتجاوز الثلاثة (`block_app`, `grant_extra_minutes`, … تنتظر س١+)، لقطة Kotlin للقدرات في `MainActivity` (بنية القناة موجودة في المكوّن الجديد وتُكمل في جولة تثبيت قادمة عند توفر Flutter SDK).

## ٣) ما تغيّر

| البند | التغيير | الدليل |
|---|---|---|
| هجرة ١١٧ `family_device_capabilities` | دفتر القدرات (`(device_id, capability_key)` مفتاح طبيعي) · CHECK يربط `state='confirmed'` بـ`confirmed_at` غير فارغ · فهرس `(family_id, child_id)` لقراءات الوصي · نوع `capability_key` ENUM بقيم س٠ (`instant_lock`, `background_location`, `push_delivery`, …) ونوع `capability_state` ENUM (`confirmed`, `awaiting_setup`, `permission_needed`, `unsupported`, `revoked`, `unknown`) | بصمة sha256 في المانيفست |
| هجرة ١١٨ `family_commands` + `family_command_receipts` | ناقل الأوامر مع `idempotency_key` فريد داخل العائلة + `expires_at` · CHECK على حالات الحياة (`accepted→dispatched→received→applied` أو `limited` أو `failed` أو `expired`) + حقل `failure_reason` إلزامي عند `failed`/`limited` · جدول الإيصالات مع PK على `command_id` (إيصال واحد للأمر) · نوع `command_type` ENUM س٠ (`lock_now`, `release_lock`, `refresh_policy`) | بصمة sha256 |
| هجرة ١١٩ مظروف `ai_events` | أعمدة `security_context` JSONB، `required_capabilities` text[]، `ttl_minutes` int، `expires_at` timestamptz، `confidence` smallint CHECK 0..100، `reject_path` text، `trace_id` text | بصمة sha256 |
| مسار `POST /v1/devices/{deviceId}/capabilities` | الجهاز يرسل لقطة قدرات (Idempotency-Key)؛ نفس الحالة لا تُحدث صفاً ولا تُطلق حدثاً (R6: صف outbox واحد عند التغير فقط)؛ ٤٠١ عند اعتماد مرفوض/مقطوع | `spine-device-capabilities.test.js` (٦ قوانين) |
| مسار `GET /v1/families/{fid}/children/{cid}/device-capabilities` | الوصي الأساسي يقرأ القدرات مجمّعة بالأجهزة مع `confirmedAt` و`evidence` — العقد يطابق schema `CapabilityLedgerKey`/`CapabilityLedgerState`/`DeviceCapabilityRecord` | openapi-contract |
| مسار `POST /v1/families/{fid}/children/{cid}/devices/{did}/commands` | الوصي يطلق أمراً؛ يرفض ٤٠٩ `capability_not_confirmed` إن كانت القدرة المقابلة (مثل `instant_lock` لـ`lock_now`) غير مؤكدة؛ أمر مقبول مع `expires_at = now + ttl` وحدث `command.dispatched` في نفس المعاملة | `spine-command-lifecycle.test.js` (٦ قوانين) |
| مسار `GET /v1/devices/{deviceId}/commands/pending` · `POST /v1/devices/{deviceId}/command-receipts` | السحب الدوري والردّ بإيصال؛ إيصال متأخر بعد `expires_at` → ٤١٠ `command_expired`؛ `applied` → حدث `command.applied` مع `effectiveState`؛ `failed` يتطلب `failureReason` | `spine-command-lifecycle.test.js` |
| مسار `GET /v1/families/{fid}/commands` | الوصي يقرأ آخر أوامر العائلة (للاستكشاف في الشاشات القادمة) | openapi-contract |
| عملاء Dart | عميلان في `app/lib/foundation_gate/` بنفس نمط `FamilyDeviceApiClient` (bearer + Device)، مع enums و`FoundationGateApiException` وتغطية أرقام الحالة (201/400/401/403/404/409/410/429/503) + ٦ URI builders في `foundation_gate_configuration.dart` (تحقق UUID وquery params) | `check_dart_imports` ٠ ميت |
| مكوّن الصدق | `DeviceCapabilityHonestyBadge` يعرض شارة عربية (مؤكَّد/ينتظر الإعداد/إذن مطلوب/غير مدعوم/تم سحب الإذن/غير معروف) بألوان `TagVariant` (g/a/p) — يستعمل عند رسم أي زر يتكلّم عن قدرة | يعيد استعمال `Tag` الموجود |

## ٤) إثباتات الاختبار

| النوع | النتيجة |
|---|---|
| `npm test` (كامل) | **٣٦٦ pass / ٠ fail** من ٤١٠ (٤٤ skip لبنية Postgres الحية في CI)؛ قبل الشريحة ٣٥١ pass |
| `npm run check` | أخضر |
| `spine-device-capabilities.test.js` | ٦ قوانين (مفردات س٠، لقطة أولية تبعث أحداثاً، نبض القلب لا يبعث شيئاً، رفض confirmedAt مع unsupported، رفض الاعتماد الخاطئ، قراءة الوصي) |
| `spine-command-lifecycle.test.js` | ٦ قوانين (أنواع س٠ فقط، رفض lock_now بلا قدرة مؤكدة، قبول lock_now وبعث حدث واحد، إيصال متأخر ٤١٠، إيصال applied يقدّم الحالة، failed يتطلب failureReason) |
| `openapi-contract.test.js` | ١٢٠ مساراً و٢١٣ schema في `foundation.v1.json` |
| `check_dart_imports.mjs` | ٦٢٩٠ استيراداً، ٠ ميت |
| `check_manifest_policy.mjs` | أخضر |
| `check_migration_range.sh` | الترقيم آمن، الهجرة التالية ١٢٠ |

## ٥) ما يُؤجَّل

- **لقطة Kotlin للقدرات في `MainActivity`**: استدعاءات الأجهزة لقنوات MethodChannel (`capabilitiesSnapshot`, `pullPendingCommands`, `submitReceipt`) تُكمل في جولة تثبيت قادمة (Flutter SDK غير متاح الآن في الصندوق؛ الكود Dart موجود والبوابات الخلفية جاهزة).
- **تكامل حقيقي مع PostgreSQL على CI**: مسارات العمود الفقري مضمونة بقوانين الوحدة على fake port؛ تكامل Postgres الحي يضاف في جولة لاحقة عند تمديد الاختبارات التكاملية الموجودة.
- **شاشات الوصي الفعلية**: س١ (قفل حي) هي من يرسم الأزرار فوق هذه المسارات؛ المكوّن `DeviceCapabilityHonestyBadge` والعميلان جاهزان للاستيراد.

## ٦) البوابات التي فتحتها

- **ف١ (عمود القفل الحي — س١):** القدرات `instant_lock`/`push_delivery` مدعومة بدفتر صادق؛ `lock_now` و`release_lock` و`refresh_policy` جاهزة؛ `CapabilityHonestyBadge` يُستعمل في شاشة القفل لقول الحقيقة قبل الضغط.
- **ف٢ (موقع حي — س٢):** القدرة `background_location` موجودة في الدفتر ومسار قراءتها جاهز لدمج لقطات التليمتري الحالية مع حالة الإذن (الموقع كان موجوداً لكن لم يكن يبلّغ عن إذنه بصدق في واجهة الوصي).

## ٧) قرارات مُلزِمة

- **ثلاثة أنواع أوامر فقط لس٠:** `lock_now`, `release_lock`, `refresh_policy`. أي نوع آخر (مثل `block_app` أو `grant_extra_minutes`) يُرفض ٤٠٠ إلى أن تفتح شريحته.
- **الصدق قبل التحكم:** زرّ يُعرض قبل أن يكون `state=confirmed` لا يرسل أمراً؛ وإن أُرسل من مهاجم يرفضه الخادم ٤٠٩ `capability_not_confirmed`.
- **الأوامر تموت:** TTL إلزامي، وإيصال بعد الموت = ٤١٠، والعميل يعيد طلب السياسة.
- **لا بيانات وهمية ولا mock على المسارات المنشورة:** الدفتر يعكس ما يبلّغه الجهاز فقط؛ لا حالات افتراضية من الخادم.
