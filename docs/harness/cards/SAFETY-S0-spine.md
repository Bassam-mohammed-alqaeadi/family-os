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
| **الملفات المملوكة** | `backend/db/migrations/117_device_capabilities.sql` · `backend/db/migrations/118_command_lifecycle.sql` · `backend/db/migrations/119_ai_events_security_envelope.sql` · `backend/src/device-capabilities.js` (جديد) · `backend/src/command-lifecycle.js` (جديد) · `backend/src/ai-events.js` (مظروف S-SEV-1: أعمدة `security_context`/`required_capabilities`/`ttl_minutes`/`expires_at`/`trace_id` + قيود) · `backend/src/app.js` (٦ مسارات) · `backend/src/validation.js` (مدخلات القدرات/الأوامر/الإيصالات) · `backend/src/schema-manifest.js` (بصمات ١١٧–١١٩) · `backend/openapi/foundation.v1.json` (١٢٠ مساراً و٢١٣ schema) · `backend/test/spine-device-capabilities.test.js` · `backend/test/spine-command-lifecycle.test.js` · `backend/test/postgres-spine-s0-migrations.test.js` (PGlite يطبّق ٢٨ هجرة كاملة) · `app/lib/foundation_gate/foundation_gate_configuration.dart` (٦ URI builders) · `app/lib/foundation_gate/family_capability_api_client.dart` (جديد) · `app/lib/foundation_gate/family_command_api_client.dart` (جديد) · `app/lib/core/design/components/device_capability_honesty_badge.dart` (جديد) · `app/android/app/src/main/kotlin/com/familyos/family_os/NativeCapabilitySnapshot.kt` (جديد) + `MainActivity.kt` (قناة `capabilitySnapshot`) |
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

- **سحب الأوامر وتقديم الإيصالات على Kotlin** (`pullPendingCommands` / `submitReceipt`) تُكمل في س١ (الإشعارات) لأنها تحتاج ربطًا بخدمة الإقلاع والطابور المشفّر الذي يأتي في س٢؛ لقطة القدرات نفسها صارت Native والقناة `capabilitySnapshot` موصولة في `MainActivity`.
- **رحلات Postgres الحية لمسارات القدرات/الأوامر HTTP** تُضاف في جولة لاحقة. بوابة CI الحقيقية (`backend_ci.yml` الهجرة) تُطبّق ٠٠١–١١٩ فعلاً فانكسار FK/CHECK/ENUM سيظهر فوراً؛ رحلات HTTP السطحية تغطيها قوانين الوحدة (١٢) + اختبار PGlite (٢٨ هجرة كاملة).
- **شاشات الوصي الفعلية**: س١١ (القفل الفوري، بعد ١٠ شرائح) هي من يرسم الأزرار فوق هذه المسارات — س١ (الإشعارات) يكتفي باستعمال ناقل الأوامر لتبليغات التسليم، والمكوّن `DeviceCapabilityHonestyBadge` والعميلان جاهزان للاستيراد من أي شاشة.

## ٥ب) الصدق في المصدر (Kotlin) — أُنجز في التصحيح

لقطة القدرات تُبنى في `app/android/app/src/main/kotlin/com/familyos/family_os/NativeCapabilitySnapshot.kt` من إشارات أندرويد الأصلية فقط: أذونات Runtime (`ACCESS_FINE_LOCATION`/`ACCESS_BACKGROUND_LOCATION`)، `SYSTEM_ALERT_WINDOW` (canDrawOverlays)، `PACKAGE_USAGE_STATS` (AppOpsManager)، `AccessibilityService` (مكشوف في الخدمات المفعّلة)، مستقبل `BOOT_COMPLETED` (استعلام PackageManager)، `DevicePolicyManager` (isAdminActive)، وإشارات العبث (خيارات المطور وADB). القدرات التي لا يعرفها Dart بصدق **لا يُبلَّغ عنها من Dart أبدًا** كقيمة مخترعة؛ القناة `capabilitySnapshot` في `TELEMETRY_CHANNEL` تعيد JSON جاهزاً يمزجه Dart مع القدرات التي هو وحده يملكها (وجود رمز FCM، ربط خدمة التليمتري) قبل إرسال `reportSnapshot`. القدرات غير المبنية في س٠ (مثل `web_filter_vpn`) تُرجَع صراحةً `unsupported` مع دليل نصي.

## ٦) البوابات التي فتحتها

- **عمود س١ الإشعارات (= ش٤):** القدرة `push_delivery` صارت ذات مصداقية من Kotlin (خدمات اللعب + رمز FCM)، وناقل الأوامر يحمل `command.dispatched/applied/expired/failed` التي س١ تُحوّلها إلى تنبيهات تسليم؛ مسار `GET …/commands` يُستعمل في قائمة «آخر الأوامر» للوصي.
- **عمود س٢ متانة الهاتف (= ش٥):** لقطة القدرات تُبلغ من البداية عن حقيقة `boot_persistence` و`accessibility_enforcement` و`battery_reporting` قبل أن تُبنى هذه الخدمات — فالوصي يرى «ينتظر الإعداد» لا «جاهز».
- **عمود س١١ القفل الفوري (= ش١٢):** دفتر `instant_lock` ومسار `lock_now` جاهزان؛ القفل الحقيقي على الهاتف يأتي في شريحته لكن الشارة الصادقة موجودة من الآن.
- **سجل الموقع الحالي (س٨/س٤):** القدرة `background_location` موجودة في الدفتر ومسار قراءتها جاهز لدمج لقطات التليمتري الحالية مع حالة الإذن (الموقع كان موجوداً لكن لم يكن يبلّغ عن إذنه بصدق في واجهة الوصي).

## ٧) قرارات مُلزِمة

- **ثلاثة أنواع أوامر فقط لس٠:** `lock_now`, `release_lock`, `refresh_policy`. أي نوع آخر (مثل `block_app` أو `grant_extra_minutes`) يُرفض ٤٠٠ إلى أن تفتح شريحته.
- **الصدق قبل التحكم:** زرّ يُعرض قبل أن يكون `state=confirmed` لا يرسل أمراً؛ وإن أُرسل من مهاجم يرفضه الخادم ٤٠٩ `capability_not_confirmed`.
- **الأوامر تموت:** TTL إلزامي، وإيصال بعد الموت = ٤١٠، والعميل يعيد طلب السياسة.
- **لا بيانات وهمية ولا mock على المسارات المنشورة:** الدفتر يعكس ما يبلّغه الجهاز فقط؛ لا حالات افتراضية من الخادم.
