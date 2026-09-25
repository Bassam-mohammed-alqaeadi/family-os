# خطة ربط الشاشات الباقية — Zero Mocks (واقعية وتنفيذية)

> خطة عمل بطاقة-ببطاقة لربط **كل** شاشة متبقّية بصفوف **ADR-054 v6** الحقيقية، بإدارة
> الـOrchestrator (المساعد) وتنفيذ الـworker، بلا مِهادات وبلا أخطاء وبلا تدخّل المالك.
> الأساس: `harness/13_SCREEN_WIRING_QUEUE.md` + `harness/LOOP_STATE.md` في المستودع.
> تاريخ الإعداد: **٢٠٢٦-٠٩-٢٥** · الفرع `feat/real-flutter-build` · [PR #6](https://github.com/Bassam-mohammed-alqaeadi/family-os/pull/6).

## ١. الخلاصة التنفيذية

- **الباقي: ٦١ ملف شاشة** من ١٣١ (المربوط بالمقياس الحالي: **٧٠**).
- منها **٤ فراغات عقدية معلنة** لا تُربط بصفوف (`child_focus_sounds` · `notification_prefs` · `emergency_setup` · `coming_soon`) و٣ قوالب بلا مسار بيانات ⇒ **٥٤–٥٦ شاشة عمل حقيقي**، مقسّمة على **١٢ بطاقة** (WIR-03b → WIR-13) في نحو **١٤ نقلة**.
- أكبر اكتشاف هذه الجلسة: **«مربوطة بـRuntime» لا تعني «تقرأ Drift»** — كل شاشات `n02_day` الباقية افتراضها `InMemoryXRepository`، و`Stage1ChatRuntime` فيه محوّلا Drift جاهزان **ولا شاشة تستعملهما**. لذلك تُضاف للخطة **بوابة عدّ ثانية** تقيس الافتراضي الحقيقي لا وجود الاسم.
- الترتيب: يوم العائلة (٣بطاقات) ← المحادثات (الأرخص لأن محوّلاته جاهزة) ← الاتصال/الوصول ← الربط ← الأونبوردنج ← الوقت ← القفل ← المنصّة/الأجهزة/الخصوصية ← الفرادى والتوابع.

## ٢. الأساس المقيس (تحقّق هذه الجلسة من المستودع)

المقياس: `rg -l 'Stage1[A-Za-z]*Runtime' -g '*_screen.dart' lib/features | wc -l` مقابل
`rg --files -g '*_screen.dart' lib/features`.

| البند | العدد |
|---|---|
| ملفات الشاشات كلها | **١٣١** |
| مربوطة بـ`Stage1…Runtime` | **٧٠** |
| **غير مربوطة** | **٦١** |

**توزيع الباقي على المجالات:**

| المجال | الباقي | الجسر/الوقت الموجود | محوّلات Drift جاهزة؟ |
|---|---|---|---|
| `n02_day` | **٢٠** | `Stage1DayRuntime` · `Stage1ChatRuntime` · `Stage1LocationRuntime` | جزئيًا: `chat_ux_bridge` (محوّلان) · `day_followup_bridge` (واحد) · `location_ux_bridge` |
| `n01_linking` | **١٢** | لا Runtime | **لا** |
| `shared_onboarding` | **٥** | `Stage1DevicesRuntime` | نعم للعائلة/الأجهزة (`devices_ux_bridge` · `family_members_drift_repository`) |
| `n03_screen_time` | **٥** | `Stage1AppControlRuntime` (+ `Stage1ReportsRuntime` لاستخدام اليوم) | **لا** |
| `n05_lock` | **٤** | `Stage1ModesRuntime` | **لا** |
| `n12_devices` | **٣** | `Stage1DevicesRuntime` | نعم للأجهزة/الأعضاء |
| `n08_platform` | **٣** | لا Runtime لهذا المجال | **لا** |
| `n07_privacy` | **٢** | لا Runtime | **لا** (وجدول `audit_log` موجود في العقد!) |
| `shared_templates` | **٢** | — | لا حاجة (قوالب) |
| `n17_child_learn` | **١** | `Stage1LearnRuntime` (١٧ شاشة) | لا (`child_focus_sounds`) |
| `n04_web_filter` · `n06_notifications` · `n10_emergency` · `n13_coming_soon` | **١ لكلٍّ** | `Stage1WebFilterRuntime` للـwebfilter | لا |

**بوابات التشغيل (Runtimes) القائمة أصلاً — تُوسَّع لا يُنشأ لها نظير:** `Learn` (١٧ شاشة) · `Reports` (١٥) · `Studio` (١٣) · `Location` (٤) · `Tasks` (٤) · `Devices` (٣) · `SosFinal` (٣) · `Billing` · `Calendar` · `Modes` · `OfflineAiSafety` · `ScreenCamera` · `AppControl` · `Day` · `WebFilter` · **`Chat` (صفر شاشة!)**.

**معنى ذلك:** `Stage1ChatRuntime` فيه `DriftConversationsListRepository` و`DriftConversationRepository` مكتوبان ومختبَران في مكان آخر، ومع ذلك شاشتا `conversations_list` و`conversation` ما زالتا تربطان `stage1ConversationsListRepository` الـ**InMemory**. أي أن بطاقة المحادثات = **وصل أسلاك + اختبارات**، لا كتابة محوّلات جديدة.

## ٣. التصحيح الجوهري: ما معنى «مربوطة»؟

المقياس الحالي (وجود اسم `Stage1…Runtime` في ملف الشاشة) **لازم لكنه غير كافٍ**. الدليل المقيس:
المخازن الافتراضية العامّة في `n02_day` كلها `InMemoryXRepository`، وكذلك `n01_linking` و`n03_screen_time`
و`n05_lock` و`n08_platform` و`n07_privacy` — أي أن الشاشة «تعمل» على بيانات غير مخزَّنة، وهذا هو المِهاد
بلباس آخر. لذلك تُضاف من البطاقة الأولى:

### المعيار المزدوج للإنجاز
1. **م١ — وجود الافتراضي عبر بوابة:** `widget.<seam> ?? Stage1XRuntime.<getter>` (Rule 25 — الاختبارات تُحقن).
2. **م٢ — أن يكون ذلك الافتراضي محوّل Drift فعلًا:** `Stage1XRuntime.<getter>` يعيد `Drift…Repository` (أو `Local…Store` فوق `family_database`)، ولا يعيد `InMemory…` في مسار الإنتاج.

### أداة العدّ (تُبنى في البطاقة الأولى)
سكربت `app/tool/check_screen_wiring.dart` يطبع لكل شاشة: الشاشة → البوابة/المحوّل المُستخدَم → هل هو Drift أم InMemory؟،
ويُدرج ناتجه المُختصر في `CONVERSION_LOG.md`، فلا يعتمد الإنجاز على عدّ نصّي هش. البوابات الأربع تبقى كما هي، وتُضاف هذه السادسة.

## ٤. العقد التشغيلي لكل بطاقة (غير قابل للتفاوض)

1. **نقلة واحدة = بطاقة واحدة**، والـworker يقرأ `*_models.dart` + `*_repository.dart` + `*_screen.dart` + اختبارها القائم **قبل** كتابة أي كود.
2. **بوابة واحدة للبوابات محفوظة** (`lib/core/data/stage1_row_vocabulary.dart`) — لا نصوص ولا أرقام مزروعة، و`// rule12-allow` للاستثناء المعلَّم فقط.
3. **الجسر في مجاله:** ملف `<domain>_followup_bridge.dart` + توسيع بوابة المجال القائمة (لا بوابة ثانية لمجال واحد).
4. **Rule 23**: الأسماء والأرقام من الصفوف — والطفل `childKeyFor(ordinal)` — واللقطات الفارغة تُعيد أعدادًا مُصفَّرة لا أرقام النموذج الجاهزة.
5. **ADR-042**: كل كتابة صفّ تُختبَر بإغلاق القاعدة وإعادة فتحها.
6. **fail-closed**: نطاق فارغ أو عائلة أخرى ⇒ لا قراءة ولا كتابة.
7. **ع-١**: الدقائق تُمرّ عبر `wallet_ledger` فقط، بلا استثناء.
8. **العمود الغائب = فراغ معلن** (`''` أو `null` أو قائمة فارغة) يُسجَّل في تقرير البطاقة — ولا يُخترع صفّ.
9. **البوابات قبل الإعلان:** `flutter analyze --fatal-infos` (صفر) · `dart run tool/check_hardcoded_strings.dart` · اختبارات البطاقة · **السويت الكامل** بـ`TMPDIR=/var/tmp/flutter-tmp flutter test` (درس: `/tmp` ممتلئ ⇒ `No space left on device`) · `tool/check_screen_wiring.dart`.
10. **الـworker لا يلتزم ولا يدفع** ولا يلمس `CONVERSION_LOG.md` / `LOOP_STATE.md` / المرآة — الـOrchestrator يفعل ذلك بعد إعادة البوابات بنفسه. **لا دفع أحمر**، وفشل ⇒ إصلاح أو إعادة إرسال البطاقة نفسها.
11. **غموض حقيقي فقط** ⇒ `QUESTIONS.md` + `LOOP_STATE: BLOCKED` (لا تخمين). حاليًا لا سؤال مفتوح ⇒ اللووب لا يتوقّف.
12. **لا تشغيل `flutter test` بالتوازي** بين الـworker والمدير (تنافس على الكاش/الذاكرة — سبّب تعليقًا سابقًا).

## ٥. البطاقات المتبقية — بالتفصيل

> الجداول المذكورة **مرشَّحة من عقد v6** وتُثبَّت عند بدء البطاقة بقراءة الـmodels؛ وإن ثبت أن لا صفّ يخدم
> الشاشة ⇒ **فراغ معلن** + قرار عقدي، لا صفّ مُخترع.

### WIR-03b — يوم العائلة A2 (٣ شاشات) · الحجم: نقلة
- **الشاشات:** `day_board` · `alerts_hub` · `alert_detail`.
- **البوابة:** توسيع `Stage1DayRuntime` (فيه `childrenList` وحده الآن) — محوّلا `DriftDayBoardProjectionRepository` + `DriftAlertsRepository`.
- **صفوف v6:** `task` + `task_submission` (مهام اليوم وحالاتها) · `learn_session` (الجلسات) · `calendar_event` · `sos_alert` · `geofence_event` (خروج/عدم حضور) · `ai_event` (التنبيه الذكي) · `child` + `device`/`device_health` (من يحتاج انتباهًا).
- **فراغات معلنة:** أي «درجة خطر» أو ترتيب أولويات بلا صفّ يقرؤه؛ بطاقة تنبيه بلا صفّ تُقرأ فارغة.
- **اختبارات:** لوحة اليوم (ترتيب + إخفاء ما لا صفّ له) · التنبيهات (نوع العتبة من الصفّ) · ADR-042 على أي وسم «قُرِئ».

### WIR-03c — يوم العائلة A3 (٣ شاشات) · الحجم: نقلة
- **الشاشات:** `request_inbox` · `friend_approval` · `outer_circle`.
- **صفوف v6:** `task_submission` بحالة انتظار المراجعة (صندوق الطلبات + قرار الموافقة/الرفض بكتابة الحالة و`reviewed_at`) · `invite` + `member` + `account` (طلبات الانضمام) · `child`.
- **فراغات معلنة:** `outer_circle` يحتاج **جهات اتصال** ولا جدول لها في v6 ⇒ يُعلَن ما يثبته `member` فقط، وبقية القائمة فراغ.
- **اختبارات:** قبول الطلب يكتب الحالة فعلًا وتنجو من إعادة الفتح (ADR-042) · رفض الطلب لا يكتب صفًّا وهميًّا · النطاق الفارغ فاشل-مغلق.

### WIR-04 — المحادثات (٧ شاشات) · الحجم: نقلة (**الأرخص — المحوّلات جاهزة**)
- **الشاشات:** `conversations_list` · `conversation` · `child_conversation` · `child_chats` · `child_friends` · `child_media_share` · `child_stickers_backgrounds`.
- **البوابة:** `Stage1ChatRuntime` (فيه `comms` و`prefs` ومحوّلان Drift جاهزان ولا شاشة تستعملهما) + getters جديدة للشاشات الطفلية.
- **صفوف v6:** `conversation` · `message` · `message_read` · `chat_preference` · `child`.
- **فراغات معلنة:** جدول مرفقات/ملصقات غير موجود ⇒ الوسائط والملصقات تُعلَن؛ الخلفيات تُقرأ من تفضيل المحادثة إن حملها.
- **اختبارات:** الرسائل مرتّبة زمنيًا · «قُرِئ» يكتب `message_read` ولا يتكرّر · تفضيل المحادثة ينجو من إعادة الفتح · شاشات الطفل لا ترى محادثات طفل آخر.

### WIR-05 — الاتصال والوصول والسلامة (٧ شاشات) · الحجم: نقلتان
- **الشاشات:** `active_call` · `child_active_call` · `child_call_play` · `call_history` · `child_arrival` · `road_safety` · `child_profile`.
- **البوابة:** توسيع `Stage1LocationRuntime` + `Stage1DayRuntime`.
- **صفوف v6:** `call_log` (المكالمات) · `location_ping` (الموقع اللحظي) · `geofence_event` + `geofence` (الوصول) · `child` + `device`/`device_health` (الملف) · `sos_alert` · `device_permission`.
- **فراغات معلنة:** «درجة أمان الطريق» بلا صفّ ⇒ تُقرأ من صفوف الموقع/السياج فقط؛ وسائط المكالمة عمل جهاز.
- **اختبارات:** سجل المكالمات من صفوفه · الوصول = آخر `geofence_event` فعلي · ملف الطفل لا يزرع عمرًا (سنة غائبة ٠ = مجهول).

### WIR-06 — الربط A (٦ شاشات) · الحجم: نقلتان (بوابة جديدة)
- **الشاشات:** `setup_wizard` · `add_child` · `invite_mother` · `accept_mother_invite` · `link_qr` · `child_qr_scan`.
- **البوابة:** جسر جديد `linking_followup_bridge.dart` + `Stage1LinkingRuntime` (المجال بلا بوابة حتى الآن).
- **صفوف v6:** `invite` (دعوة الأم وحالتها) · `pairing_token` (رمز QR) · `member` · `account` · `child` · `device`.
- **فراغات معلنة:** عرض QR وتصويره عمل جهاز؛ الرمز نفسه يُكتب صفًّا حقيقيًا ولا يُختلق.
- **اختبارات:** الدعوة تُنشأ بحالة معلومة وتُقبل مرّة واحدة · الرمز صالح/منتهٍ من صفّه · إضافة الطفل تكتب `child` + `device` مرة واحدة.

### WIR-07 — الربط B (٦ شاشات) · الحجم: نقلة (نفس الجسر)
- **الشاشات:** `link_success` · `child_welcome` · `create_family` · `permissions_explainer` · `transparency_consent` · `trial_mode`.
- **صفوف v6:** `family` (إنشاء العائلة) · `member` · `device_permission` (الموافقات) · `subscription_state` + `billing_event` (التجربة/الاشتراك).
- **فراغات معلنة:** نصوص الشرح والتوضيح تحريرية بلا صفّ (تُسجَّل)؛ حالة الموافقة تُقرأ من `device_permission` لا من نصّ.
- **اختبارات:** إنشاء العائلة يكتب صفًّا لواحد فقط · الموافقة تُكتب وتُقرأ بعد إعادة الفتح · التجربة من `subscription_state` لا من عدّاد مزروع.

### WIR-08 — الأونبوردنج (٥ شاشات) · الحجم: نقلة
- **الشاشات:** `welcome` · `login` · `create_account` · `device_mode` · `device_user_switch`.
- **البوابة:** توسيع `Stage1DevicesRuntime` (فيه `devices` و`permissions` و`seam` جاهزة).
- **صفوف v6:** `account` · `member` · `device` · `device_permission` · `family`.
- **فراغات معلنة:** `welcome` شاشة تعريفية بلا صفّ (قرار معلن)؛ شاشة الدخول لا تكتب صفًّا وهميًّا — الجلسة عمل جهاز.
- **اختبارات:** إنشاء الحساب + العضو يكتبان صفّين حقيقيين · تبديل وضع الجهاز/المستخدم يغيّر صفّ `device` · لا كتابة على نطاق فارغ.

### WIR-09 — وقت الشاشة (٥ شاشات) · الحجم: نقلتان (**تبدأ بفحص عقد**)
- **الشاشات:** `child_screen_time` · `child_time_mirror` · `child_time_request` · `new_app_approval` · `time_expiry`.
- **الخطوة صفر (إلزامية):** تثبيت **مصدر دقائق الوقت** في v6 — هل هو `learn_assignment` أم `focus_schedule`/`focus_schedule_app` أم `mode_unlock_attempt`؟ ومن يكتب الاستهلاك؟ النتيجة تُسجَّل في تقرير البطاقة (وقرار عقدي إن نقص جدول) — **إن ثبت النقص ⇒ فراغ معلن لا صفّ مُخترع**.
- **البوابة:** `Stage1AppControlRuntime` (`service` · `store` · `accessRules` · `capabilities`) + `Stage1ReportsRuntime` (تقرير الاستخدام القائم).
- **صفوف v6 (مرشَّحة):** `device_permission` · `focus_schedule` + `focus_schedule_app` · `mode_unlock_attempt` · `subscription_state` (حدود الخطة) · `child`.
- **اختبارات:** طلب وقت الطفل يُكتب ويُقرأ بعد إعادة الفتح · موافقة تطبيق جديد تنقل الصفّ فعلًا · انتهاء الوقت يُحسب من الصفّ لا من مؤقّت مزروع.

### WIR-10 — القفل (٤ شاشات) · الحجم: نقلة
- **الشاشات:** `child_mode_lock` · `instant_lock` · `parent_second_key` · `tamper_alerts`.
- **البوابة:** توسيع `Stage1ModesRuntime` (`service` · `store` · `locationFacts` · `capabilities`).
- **صفوف v6:** `mode_unlock_attempt` (محاولات الفتح والتلاعب) · `device`/`device_permission` · `focus_schedule` · `sos_alert` (تنبيه التلاعب).
- **فراغات معلنة:** «المفتاح الثاني» سرّي بلا صفّ ⇒ يُعلَن، ويُقرأ ما يثبته `device_permission`.
- **اختبارات:** محاولة فتح خاطئة تُكتب صفًّا وتظهر في التنبيهات · القفل الفوري لا يكتب صفّ بيانات وهميًّا · ADR-042 على المحاولات.

### WIR-11 — المنصّة والأجهزة والخصوصية (٨ شاشات) · الحجم: نقلتان (`11a` ثم `11b`)
- **`11a` (٤):** `platform_monitoring` · `smart_supervision` · `smart_alert_detail` · `settings_hub` — الصفوف: `device_permission` (ما رُخِّص فعلًا) · `ai_event`/`ai_suggestion` (التنبيه الذكي) · `account`/`member`/`device` (الإعدادات) · `subscription_state` (الترخيص).
- **`11b` (٤):** `mother_permission_level` · `language_help` · `audit_log` · `privacy_data` — الصفوف: `audit_log` (**جدول موجود في العقد — أول استخدام حقيقي له**) · `member`/`device_permission` (مستوى صلاحية الأم) · حزمة اللغة بلا صفّ ⇒ فراغ معلن · تصدير/حذف البيانات يُقرأ من `audit_log` ويُسجَّل فيه.
- **اختبارات:** التنبيه الذكي من صفّه · `audit_log` يُقرأ مرتّبًا ويُكتب عند إجراء حقيقي · طلب حذف البيانات لا يدّعي حذفًا بلا صفّ.

### WIR-12 — الفرادى (٣ شاشات) · الحجم: نقلة قصيرة
- **الشاشات:** `home_router_filter` (`Stage1WebFilterRuntime.policyRepository` — موجود) · `notification_prefs` · `emergency_setup`.
- **صفوف v6:** `device_permission` (ترخيص الفلترة) · `sos_alert` + `geofence` (إعداد الطوارئ) · `audit_log` (تغيير سياسة).
- **فراغات معلنة (مرشَّحة، تُثبَت):** لا جدول لتفضيلات الإشعارات في v6 ⇒ تُعلَن فارغة بدل زرع قيم؛ ومخزن إعدادات SOS بلا جدول ⇒ ما لا يثبته `sos_alert`/`geofence` يُعلَن.
- **اختبارات:** فلترة المسار من الصفّ المحفوظ · تفضيلات الإشعارات لا تكتب صفًّا وهميًّا · الطوارئ تعرض ما في الصفوف فقط.

### WIR-13 — التوابع والفراغات المعلنة (٤ ملفات) · الحجم: نقلة قصيرة
- **الملفات:** `empty_state_template` · `network_error_template` · `coming_soon` · `child_focus_sounds`.
- **القرار المعلن:** الثلاثة الأولى **قوالب بلا مسار بيانات** (تُوثَّق «لا حاجة لصفّ» مع دليل من الشاشة)، والرابعة **فراغ عقدي** (لا جدول أصوات/تفضيلات في v6).
- **المخرج:** سطر صريح في `CONVERSION_LOG.md` + محوّلاتها تبقى للاختبارات، بلا ادّعاء ربط.

## ٦. الترتيب والتبعيات والحجم

| # | البطاقة | الشاشات | الحجم | تعتمد على |
|---|---|---|---|---|
| ١ | تحضير: `tool/check_screen_wiring.dart` + تثبيت المعيار المزدوج | — | نقلة قصيرة | — |
| ٢ | **WIR-03b** لوحة اليوم والتنبيهات | ٣ | نقلة | التحضير |
| ٣ | **WIR-03c** الطلبات والدائرة | ٣ | نقلة | WIR-03b (نفس الجسر) |
| ٤ | **WIR-04** المحادثات | ٧ | نقلة | — (محوّلات جاهزة) |
| ٥ | **WIR-05** الاتصال والوصول والملف | ٧ | نقلتان | WIR-03b (جسر اليوم) |
| ٦ | **WIR-06** الربط A | ٦ | نقلتان | — (بوابة جديدة) |
| ٧ | **WIR-07** الربط B | ٦ | نقلة | WIR-06 |
| ٨ | **WIR-08** الأونبوردنج | ٥ | نقلة | WIR-07 (صفوف العائلة) |
| ٩ | **WIR-09** وقت الشاشة | ٥ | نقلتان | فحص العقد أولًا |
| ١٠ | **WIR-10** القفل | ٤ | نقلة | `Stage1ModesRuntime` |
| ١١ | **WIR-11a/11b** المنصّة والأجهزة والخصوصية | ٨ | نقلتان | WIR-08 (الأجهزة) |
| ١٢ | **WIR-12** الفرادى | ٣ | نقلة قصيرة | `Stage1WebFilterRuntime` |
| ١٣ | **WIR-13** التوابع والفراغات | ٤ | نقلة قصيرة | — |
| — | **المجموع** | **٦١ ملفًا (٥٦–٥٤ عمل حقيقي)** | **~١٦ نقلة** | — |

## ٧. تعريف الإنجاز (DoD) لكل بطاقة

البطاقة **لا تُعتبر منجزة** إلا بتحقّق كل بند:

1. الافتراضي لكل شاشة في البطاقة **Drift** عبر بوابة المجال (المعيار المزدوج م١ + م٢)، والـ`InMemory` باقٍ للاختبارات فقط.
2. اختبار Drift لكل شاشة (قاعدة ملفية مؤقتة + ساعة ثابتة) — ومعه ADR-042 حيث تُكتب صفوف.
3. لا نص عربي مكتوب في Dart، والمفردات الجديدة في `stage1_row_vocabulary.dart`.
4. كل فراغ معلن مُدرَج حرفيًّا في تقرير البطاقة وفي `CONVERSION_LOG.md`.
5. البوابات: `analyze --fatal-infos` صفر · النصوص · اختبارات البطاقة · **السويت الكامل** · `tool/check_screen_wiring.dart`.
6. دفع أخضر مع مقابلة `ls-remote` لـ`git rev-parse HEAD`، وتحديث `LOOP_STATE.md` + `CONVERSION_LOG.md` + صفّ الخطة + بند الذاكرة + المرآة.

**العدّاد المُعلَن بعد كل بطاقة:** (شاشات Drift-مربوطة / ١٣١) + (فراغات معلنة مُوثَّقة) — لا رقم واحد مضلِّل.

## ٨. المخاطر ومعالجتها

| الخطر | الأثر | المعالجة |
|---|---|---|
| `/tmp` ممتلئ (3.9G) | فشل السويت بـ`No space left on device` | `TMPDIR=/var/tmp/flutter-tmp flutter test` دائمًا، والسجل في `/var/tmp/suite.log` |
| تغيير الافتراضي يكسر اختبار شاشة قائم | دفع أحمر | كل بطاقة تُحقن مخازنها في اختباراتها (Rule 25)، ومراجعة الاختبار القائم قبل التعديل |
| جدول ناقص في v6 (وقت الشاشة · الإشعارات · الطوارئ · الأصوات · جهات الاتصال) | إغراء زرع صفّ | **فراغ معلن** + قرار عقدي مكتوب، وممنوع كتابة صفّ لا يقابله عقد |
| `*.g.dart` متجاهَل | CI يفشل | `dart run build_runner build` قبل السويت في CI |
| تعليق بسبب تشغيل متوازٍ | إهدار نقلة | لا `flutter test` بالتوازي بين الـworker والمدير (قُتِلت عمليات سابقة لهذا السبب) |
| تضخّم بطاقة | تأخير وضغط مراجعة | كل بطاقة > ٧ شاشات تُقسَم (WIR-05 · WIR-09 · WIR-11 مُقسَّمة أصلًا) |

## ٩. القرارات المعلنة الآن (بلا وقف للووب)

هذه ليست أسئلة معلَّقة — هي قرارات مسجَّلة تُنفَّذ ما لم يعترض المالك:

1. **القوالب و«قريبًا»** (`empty_state_template` · `network_error_template` · `coming_soon`): لا مسار بيانات — تُوثَّق كذلك.
2. **`child_focus_sounds`**: فراغ عقدي (لا جدول أصوات/تفضيلات) — تبقى غير مربوطة ومُوثَّقة.
3. **`notification_prefs`** و**`emergency_setup`**: إن لم يوجد جدول مطابق ⇒ فراغ معلن جزئي، وما يثبته `sos_alert`/`geofence` يُربط.
4. **`outer_circle`**: لا جدول جهات اتصال ⇒ يُعلَن ما يثبته `member` فقط.
5. **واجهة الحساب/الدخول**: الجلسة عمل جهاز؛ لا تُكتب صفوف وهمية عند «تسجيل الدخول».

**الحالة:** `LOOP_STATE = RUNNING` · البطاقة التالية فورًا: **تحضير المعيار + WIR-03b**.




