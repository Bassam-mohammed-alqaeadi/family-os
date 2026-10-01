# سجل توجّه التحول إلى منصة Family OS حقيقية

> **الحالة:** سجل اتجاه ومنتج — بانتظار اعتماد مالك المشروع لخطة تنفيذ محددة.
>
> **التاريخ:** 2026-10-02 (Asia/Aden)
>
> **الغرض:** حفظ قرار مالك المشروع أن الهدف ليس خادمًا منفصلًا أو Flutter prototype أنيقًا، بل منصة Family OS حقيقية وعالمية. لا يحتوي هذا السجل أسرارًا أو إعدادات أو identities أو tokens أو origins أو بيانات عائلية، ولا يوسّع تلقائيًا تفويضات الخدمات الخارجية أو Native أو Production.

---

## 1. القرار الذي لا يجب أن يُفقد

Family OS يجب أن تصبح منصة عائلية يختارها المستخدم بدل المنصات المشابهة؛ لا لأن لديها شاشات أو APIs أكثر، بل لأن كل رحلة مهمة فيها أوضح وأسرع وأصدق وأكثر مرونة وأمانًا.

النتيجة المقصودة تدريجيًا:

- **الأب/المالك:** لوحة قيادة وتحكم حقيقيان، لا أزرار شكلية أو role محلي.
- **الأم:** تجربة مصممة حسب `observer` و`partner` و`full`، لا مجرد نسخة مخفية من لوحة الأب.
- **الطفل:** تعلم وطلبات وشفافية وسلامة مناسبة للعمر، من دون منحه تحكمًا أبويًا.
- **الأسرة:** وقت وتطبيقات وروتين وسلامة وموقع وتعلم ودقائق واتصال وخصوصية وإدارة تؤدي نتائج حقيقية قابلة للتفسير.
- **المنصة:** Arabic-first/RTL، وإنجليزية سليمة، accessibility، responsive UI، device truth، local/offline truth، ثم multi-device truth.

لا يجوز أن تصبح Foundation Gate الضيقة أو API واحد هدفًا بديلًا لهذا المنتج. إنها دليل محدود مفيد؛ أما العمل الرئيسي فهو التطبيق الحقيقي، وتجربة المستخدم، والقدرات المحلية/Native الحقيقية، والخادم الذي يخدم هذه الرحلات.

---

## 2. تعريف "حقيقي" و"بلا محاكاة"

### محظور في مسار المنتج الطبيعي

لا يجوز أن تشغل نتائج المستخدم الظاهرة أي من الآتي:

- بيانات عائلة أو أطفال أو رسائل أو مواقع أو أجهزة أو أرصدة أو نتائج أو status مزروعة أو ثابتة.
- صلاحيات مستنتجة من role picker أو fallback محلي بدل سياق عائلي مصرح به.
- نجاح مزيف: toast أو checkmark أو delivery/read/apply/verify receipt من غير مصدر حالة حقيقي.
- `stage1*` أو `InMemory*` أو mock repository كـfallback في normal runtime.
- ادعاء تأثير على جهاز آخر من غير lifecycle وreceipt فعليين.
- secrets أو Firebase/Render configuration أو tokens أو origins في Flutter source أو Git أو CI أو evidence.
- إخفاء تعطل خدمة حقيقية خلف fixture تجعل المستخدم يظن أن العملية نجحت.

### المسموح والمنضبط

- fixtures/fakes داخل `test/`، أو demo/development route صريح لا يختلط بمسار المنتج.
- design tokens وi18n keys وroute IDs وschema versions وenums؛ ليست نتائج منتج.
- empty/setup states صادقة ومحتوى مساعدة ثابت.
- local-first functionality حقيقي للجهاز الحالي عندما يوضح التطبيق المصدر والحداثة وحدود التأثير.
- local cache فقط مع freshness/source/pending/recovery truth مرئي.

### متى تعتبر الميزة حقيقية؟

لا تنتقل الميزة من UI-complete إلى feature-complete إلا بوجود:

1. مصدر حقيقة محدد: Render-authoritative service أو Native adapter موثق.
2. authorization حقيقي للأسرة/الدور/الطفل/الجهاز/الغرض.
3. حالة متينة قابلة للاستعادة بعد restart.
4. action/mutation متحقق منه، لا نجاح محلي وهمي.
5. offline/retry/conflict/failure/recovery behavior.
6. activity/audit/notification relation عند الحاجة.
7. unit/widget/repository/API contract/integration/device evidence الملائم.
8. AR/EN، RTL، accessibility، responsiveness وprivacy/support truth.

هذا يطبّق `docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md` ولا يستبدله.

---

## 3. ما تحقق حتى الآن

- أفاد مالك المشروع محليًا أن global `flutter test` نجح بعد الإصلاحات: **1728 tests passed**.
- GitHub Flutter CI نجح على commit `a2b3d4a` في run `36925242945`، بما يشمل `flutter gen-l10n` و`flutter analyze --fatal-infos` وglobal `flutter test` وgenerated-source verification.
- Credential Guard نجح على commit نفسه في run `36925242820`.
- `ENT_DEBUG` الذي ظهر في probe لمسار SYS3 بعد الإصلاح ليس failure أو claim منتج؛ ضمن برنامج التطبيق يجب تحويله إلى assertion نظيف أو حذفه بعد الإبقاء على التغطية المكافئة.
- دليل Foundation Gate السابق يبقى دليلًا محدودًا منفصلًا؛ لا يعني تلقائيًا أن Native أو Production أو provider integrations أو توسع APIs صار مصرحًا به.

المراجع المحدودة: `docs/foundation/14_FLUTTER_CONNECTED_FOUNDATION_GATE_ADMISSION_PACKET.md`، `15_FLUTTER_CONNECTED_FOUNDATION_IMPLEMENTATION_PLAN.md`، `16_LOCAL_ANDROID_EMULATOR_FOUNDATION_VERIFICATION.md`.

---

## 4. التصميم والصقل جزء من الحقيقة وليس مرحلة مؤجلة

التصميم الحالي أصل مهم؛ لا يُرمى ولا يعاد اختراعه عشوائيًا. لكنه ليس الشكل النهائي لمجرد أن الشاشات موجودة، إذ إن جزءًا منه بني حول fixtures وحالات ثابتة بينما المنتج الحقيقي يحتاج pending/offline/stale/denied/unsupported/repair/conflict/recovery.

### عناصر الهوية الثابتة

- Arabic-first وRTL.
- الأب/المالك، الأم بمستوياتها، والطفل صاحب طلب وتعلم وشفافية لا والد مصغر.
- الدقائق فقط كمكافأة، لا coins/points كعملة الأسرة.
- SOS والسلامة لا يحجبهما paywall.
- capability honesty: لا GPS أو enforcement أو delivery أو AI أو subscription claim بلا دليل.
- استثمار screen inventory والـroutes والـdesign assets القائمة بدل نسف غير منضبط.

### عناصر يجب أن تتطور

- Shell والتنقل: hubs أقل ازدحامًا، disclosure متدرج، tabs/panels واضحة، وإزالة positioning السحري غير المتجاوب.
- لوحات الأب/الأم/الطفل كخبرات مختلفة، لا إخفاء عشوائي للأزرار.
- typography/spacing/contrast/iconography/dark mode/responsive system موحد.
- control component موحد يعرض value + effect + eligibility + capability status + explanation + confirmation.
- حالات حقيقية لكل شاشة: skeleton/loading، empty/setup، error، offline، stale، denied، pending، applied، repair.
- semantics وhit targets وfocus order وfont scaling وphone/tablet/landscape وAR/EN.

قاعدة التنفيذ:

```text
Design system
→ screen and user journey
→ real repository/API/Native source
→ truthful states
→ responsive + a11y + AR/EN polish
→ unit/widget/contract/integration/device verification
```

لا يوجد "نربط كل شيء ثم نصقل لاحقًا" ولا "نصقل UI وهمي ثم نبحث عن الحقيقة لاحقًا".

---

## 5. Control Center & Settings Superiority

### الرؤية

الإعدادات ليست قائمة روابط أو مئات toggles. المطلوب هو **Family OS Control Center**: يجد فيه المستخدم القادم من منصة أخرى الوظيفة التي اعتاد عليها، ثم ينجزها أسرع وبثقة أكبر.

كل control يجيب بوضوح:

```text
ما الذي سيتغير؟
على أي طفل وأي جهاز؟
من يحق له تغييره؟
هل الحالة local أم remote؟
هل هي configured أم published أم delivered أم applied أم verified؟
كيف أتراجع أو أصلح مشكلة؟
```

### طبقات التجربة

1. **Quick controls:** أفعال يومية واضحة: وقت طفل، تطبيق، routine، approval، repair، تنبيه، SOS.
2. **Goal-guided flows:** مسارات مثل «أريد تنظيم النوم»، «أريد تقليل تطبيق»، «أريد إضافة ولي بصلاحية محددة»، و«أريد فهم حالة جهاز».
3. **Advanced control centre:** القوة الكاملة للمستخدم الخبير بلا إرباك للمستخدم العادي.

### أقسام مركز التحكم

| القسم | المسؤوليات |
|---|---|
| حسابي وتجربتي | اللغة، المظهر، accessibility، home customization، notifications، security/recovery |
| عائلتي وصلاحياتي | membership، invites، mother levels، child scopes، authority history |
| كل طفل | profile، devices، apps/time، routines، web، location، learning/minutes، transparency |
| السلامة | SOS، escalation، safe zones، health، tamper/repair، capability truth |
| الأتمتة والقواعد | templates، schedules، exceptions، temporary overrides، rollback/versioning |
| الخصوصية والبيانات | source/visibility/retention، requests، audit، support-safe diagnostics |

### Settings Registry / Policy Engine

لا تضاف controls عشوائيًا لكل feature. كل setting/policy يحتاج contract يحمل:

```text
identity + localized title/help
role/scope eligibility
child/device applicability
value schema and validation
capability/dependency requirements
local/remote source and freshness
publish/delivery/application/verification lifecycle
confirmation/undo/versioning/audit behavior
```

Flutter يعرض controls معروفة وآمنة (`toggle`، `choice`، `slider`، `schedule`، `entity picker`، `rule builder`، `status row`، `danger action`) ولا ينفذ code أو UI عشوائيًا قادمًا من الخادم. Render يملك authorization والvalidation والإصدارات والسجل والحالة الفعلية.

---

## 6. المعمارية المستهدفة

```text
Flutter parent / child experiences
  → AppScope + typed ports + repositories
  → encrypted local cache + explicit pending outbox
  → versioned typed API client / OpenAPI contract
  → Render API (modular Express application)
  → PostgreSQL durable state + audit + outbox + workers
  → authorized Android/native capability adapters
```

### المبادئ

- Render هو system of record للحالة متعددة الأجهزة والعائلة والصلاحيات والأحداث المدققة.
- Flutter لا يحمل secret ولا يقرر authority عن بعد.
- API versioned، documented، validated، idempotent وcontract-tested.
- نبدأ modular monolith منظمًا حسب domain، لا microservices مبكرة.
- Android-first للقدرات privileged مع capability truth وdevice proof قبل أي claim.
- Firebase، إن استُخدم، مساعد محدود فقط وفق `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md`، لا source of truth.

---

## 7. برنامج التنفيذ المقترح

> هذا برنامج مقترح، لا تفويض تنفيذ تلقائي. الهدف هو اختيار مسار واعٍ بدل backend-only أو UI-only work.

| المسار | النسبة المقترحة | الدور |
|---|---:|---|
| التطبيق وتجربة المستخدم | 50% | AppScope، Control Center، panels، screens، responsive/a11y/localisation |
| Backend/API/data contracts | 30% | Render authority، APIs، PostgreSQL، audit/outbox، authorization/sync |
| Native/quality/operations | 20% | Android adapters، device tests، CI، observability، security/privacy |

### المرحلة 0 — Real Runtime App Foundation

- `AppScope` وRepository registry.
- ports/interfaces ثابتة، لا screens تعتمد على process globals.
- `PermissionMatrix` و`PanelProfile` و`RoleGate`.
- standard state components.
- migration inventory لكل screen/service: source، authority، persistence، API، native dependency، offline truth، mock exit.
- CI guards تمنع mock/global fallback في normal runtime.
- تحويل root screens تدريجيًا كنموذج، لا rewrite شامل خطير.

### المرحلة 1 — Account / Family / Role / Child truth

- account/session/family/membership/role/child authoritative contracts.
- onboarding وfamily/child creation/join/recovery journeys حقيقية.
- Flutter يتصل بسياق server-authorized حقيقي ويعرض empty/pending/denied/recovery states.

### المرحلة 2 — Device / policy / approval loop

- device registration/pairing/capability/repair.
- policy versioning وdelivery receipts.
- parent control → child/device outcome lifecycle.
- أول loop مقترح: screen time/app policy + request/approval + applied/verified receipt.

### المرحلة 3 — Safety and local Native reality

- GPS/freshness، safe zones، وSOS يفصل local fire وqueue وtransport attempt وreceipt وacknowledgement.
- alarms/background wake/local notifications بحسب platform capability.
- Android enforcement adapters بعد اعتمادها واختبارها على جهاز حقيقي.

### المرحلة 4 — Learning, minutes and family connection

- assignments/results/minutes ledger متين ومدقق.
- tasks/calendar/chat على durable authorized state.
- realtime/sync فقط مع reconnect/order/recovery design ومصدر حقيقة متين.

### المرحلة 5 — platform completion

- privacy/data lifecycle، support، entitlements/billing عند اعتمادها، operations، backup/recovery، device lab، performance/security/accessibility.
- AI فقط بعد حقيقة مصادر البيانات والخصوصية والغرض؛ Render-controlled وsuggestion-only حسب القرارات المعتمدة.

---

## 8. vertical slices المقترحة

أي slice يجب أن يحتوي UI + API + persistence + truthful states + tests؛ لا API وحده ولا screen وحدها.

1. **Family entry:** sign-in → create/join family → authorized membership → add/select child → honest empty Today.
2. **Child/device foundation:** child profile → device registration → capability/repair truth.
3. **Time and app control:** parent policy → child request/approval → device applied/verified receipt → audit.
4. **Safety:** location/safe zone/SOS lifecycle بحسب القدرة الفعلية.
5. **Learning/minutes:** approved action → validated result → durable minutes ledger → parent/child visibility.
6. **Connection:** task/calendar/chat lifecycle مع authorization وdelivery/read distinction وrecovery.
7. **Intelligence/commercial:** فقط بعد أن تكون source data والخصوصية والتكلفة والauthority حقيقية ومعتمدة.

---

## 9. قواعد الجودة غير القابلة للتفاوض

لكل slice:

- unit + widget + repository + API contract + integration tests.
- global `flutter analyze --fatal-infos` و`flutter test` يبقيان green.
- backend/migration tests تبقى green.
- AR/EN، RTL/LTR، phone/tablet، font scale، accessibility semantics.
- no secret/config/identity/token/raw payload في Git/CI/chat/documentation.
- لا production claim بلا device/integration proof مناسب.
- rollback/feature-flag/kill-switch عند وجود capability حساسة أو external dependency.

---

## 10. الحدود التي تبقى قائمة

هذا السجل لا يلغي تلقائيًا القيود القائمة على:

- Production/public release أو real data.
- secrets/configuration وإدارتها خارج Git/chat/CI.
- Firebase products/providers غير المعتمدة.
- Native privileged capabilities وFCM وbilling وAI providers وrealtime وغيرها من integrations التي تحتاج قرارًا خاصًا.
- synthetic staging principals/data: يبقى تاريخ التحكم/التقاعد 2026-10-31 وشروط الإحالة عند withdrawal أو exposure أو expiry.

---

## 11. القرار التالي المطلوب

بعد مراجعة السجل يختار مالك المشروع:

### A — الموصى به: اعتماد برنامج التحول وبدء المرحلة 0

```text
GO — Real Platform Transformation
Android-first
App-first delivery with vertical slices
Render-authoritative backend
No mock/hard-coded product outcomes in normal runtime
Control Center & Settings Superiority is a first-class workstream
```

يبدأ التنفيذ عندها بـReal Runtime App Foundation من دون إدخال secrets أو توسيع provider/native scope قبل المراجعات اللازمة.

### B — اعتماد Blueprint الإعدادات أولًا

تثبيت competitor-parity/user-job matrix وControl Center/Settings Registry contracts قبل implementation.

### C — اعتماد vertical slice واحد فقط

اختيار Family entry أو Child/device foundation وتنفيذه end-to-end قبل التوسع.

### D — مراجعة أو تعديل

يبقى السجل مرجعًا ولا يبدأ تنفيذ واسع حتى يحدد المالك ترتيبًا مختلفًا.

---

## 12. قاعدة العمل المقبلة

لا نعود إلى:

```text
واجهة جميلة → mock دائم → API منفصل → إعادة كتابة لاحقة
```

بل نعمل:

```text
User job
→ refined UX
→ typed contract
→ authorized real source
→ durable state
→ truthful lifecycle
→ tests and device proof
→ measured improvement
```

هذا هو المسار إلى Family OS حقيقية، عالمية ومرنة، تتفوق بالثقة وتجربة المستخدم لا بمجرد كثرة الشاشات أو endpoints.
