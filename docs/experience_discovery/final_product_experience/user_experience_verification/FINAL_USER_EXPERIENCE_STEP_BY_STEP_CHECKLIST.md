# FINAL USER EXPERIENCE STEP-BY-STEP CHECKLIST

**Executor:** Owner (Bassam) · **PLAN companion** · Exact order · Do not skip Fail logging.
**Result codes:** P | F | BN | BR | OD | NA
**Devices:** A ≤360 dp · B normal · AR + EN · font 1.0 (+1.3 on system homes)

## Phase 0 — Prep
- [ ] Install current frontend build on Device A and Device B
- [ ] Fill Evidence Template session header
- [ ] Start in Arabic (RTL)

## Phase 1 — Lifecycle (`UXV-LC-*`)
- [ ] `UXV-LC-01` — First / cold launch → expect: SHR-001 or session restore · Result: __
- [ ] `UXV-LC-02` — Fresh install empty local DB → expect: empty family / empty chat seed rules · Result: __
- [ ] `UXV-LC-03` — Existing local data relaunch → expect: roster/chat/tasks persist · Result: __
- [ ] `UXV-LC-04` — Authenticated session active → expect: FAT-010 / CHD-004 · Result: __
- [ ] `UXV-LC-05` — Session expired / recovery → expect: sys3 session-expired / recovery · Result: __
- [ ] `UXV-LC-06` — Role resolution father → expect: Today FAT-010 · Result: __
- [ ] `UXV-LC-07` — Role resolution mother → expect: Today + level-limited controls · Result: __
- [ ] `UXV-LC-08` — Role resolution child → expect: My Day CHD-004 · Result: __
- [ ] `UXV-LC-09` — Family select / switch → expect: sys3 family-select if multi · Result: __
- [ ] `UXV-LC-10` — Child select / switch → expect: profile / SHR-008 / active child · Result: __
- [ ] `UXV-LC-11` — Language AR→EN → expect: FAT-061 + shell labels · Result: __
- [ ] `UXV-LC-12` — Language EN→AR → expect: FAT-061 + RTL · Result: __
- [ ] `UXV-LC-13` — RTL→LTR transition → expect: shell FABs/chevrons · Result: __
- [ ] `UXV-LC-14` — LTR→RTL transition → expect: shell FABs/chevrons · Result: __
- [ ] `UXV-LC-15` — Offline start → expect: honest offline / local · Result: __
- [ ] `UXV-LC-16` — Online→offline during use → expect: no fake sync success · Result: __
- [ ] `UXV-LC-17` — Offline→online → expect: no false delivered claims · Result: __
- [ ] `UXV-LC-18` — Kill→relaunch persistence → expect: VX-B6 D6 + Program §13.5 · Result: __
- [ ] `UXV-LC-19` — Back chain drill-down → expect: push not go (G-17) · Result: __
- [ ] `UXV-LC-20` — Repeated open/close sheets → expect: dialogs dismiss clean · Result: __
- [ ] `UXV-LC-21` — Empty family/data states → expect: empty components · Result: __
- [ ] `UXV-LC-22` — Populated states → expect: lists render · Result: __
- [ ] `UXV-LC-23` — Loading states → expect: AppLoadingState · Result: __
- [ ] `UXV-LC-24` — Error states → expect: AppErrorState + retry · Result: __
- [ ] `UXV-LC-25` — Native-closed honesty → expect: BN classification · Result: __
- [ ] `UXV-LC-26` — Remote-closed honesty → expect: BR classification · Result: __
- [ ] `UXV-LC-27` — Local-only honesty → expect: glossary OD-02 · Result: __

## Phase 2 — Device §13 (`UXV-DEV-*`)
- [ ] All `UXV-DEV-A-01…09` on Device A
- [ ] All `UXV-DEV-B-01…09` on Device B (or font/display stress if one phone)
- [ ] `UXV-DEV-AR` / `UXV-DEV-EN` / `UXV-DEV-F10` / `UXV-DEV-F13`

## Phase 3 — Journeys (all 73)
For each journey: set role from `user` → open first screen → complete S01…Sn → exit + persistence checkpoint.

### JRN-CHD-01 — ربط جهازي وفهم القواعد (الابن)
- Goal: فهم ماذا يُراقب ووافق
- Trigger: والده طلب الربط
- [ ] `UXV-JRN-JRN-CHD-01-S01` `SCR-CHD-001` — Child welcome (entry: SHR-007) · Result: __
- [ ] `UXV-JRN-JRN-CHD-01-S02` `SCR-CHD-002` — Scan link QR (entry: CHD-001) · Result: __
- [ ] `UXV-JRN-JRN-CHD-01-S03` `SCR-CHD-003` — Transparency consent (entry: CHD-002) · Result: __
- [ ] `UXV-JRN-JRN-CHD-01-S04` `SCR-CHD-011` — Child-mode lock + secret entry (entry: Hub:me) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-02 — يومي في لمحة (الابن)
- Goal: عرف مهامه ووقته
- Trigger: فتح التطبيق
- [ ] `UXV-JRN-JRN-CHD-02-S01` `SCR-CHD-004` — My day (entry: Tab myday) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-03 — طلب النجدة (الابن)
- Goal: وصل البلاغ لوالديه
- Trigger: شعر بالخطر
- [ ] `UXV-JRN-JRN-CHD-03-S01` `SCR-CHD-005` — SOS button (entry: Child SOS FAB) · Result: __
- [ ] `UXV-JRN-JRN-CHD-03-S02` `SCR-CHD-006` — SOS in progress (entry: CHD-005) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-04 — التواصل مع عائلتي (الابن)
- Goal: رسالة أو مكالمة
- Trigger: أراد التحدث
- [ ] `UXV-JRN-JRN-CHD-04-S01` `SCR-CHD-007` — My chats (entry: Tab cfam) · Result: __
- [ ] `UXV-JRN-JRN-CHD-04-S02` `SCR-CHD-008` — Conversation (never locks) (entry: CHD-007/CHD-021) · Result: __
- [ ] `UXV-JRN-JRN-CHD-04-S03` `SCR-CHD-009` — Call parents (entry: CHD-008) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-05 — معرفة ما يُجمع عني (الابن)
- Goal: رأى فئات البيانات المجموعة
- Trigger: أراد الاطمئنان
- [ ] `UXV-JRN-JRN-CHD-05-S01` `SCR-CHD-003` — Transparency consent (entry: CHD-002) · Result: __
- [ ] `UXV-JRN-JRN-CHD-05-S02` `SCR-CHD-010` — What is collected about me (entry: Tab me) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-06 — طلب وقت إضافي (الابن)
- Goal: طلب مهذب وصل والديه
- Trigger: انتهى وقته وأراد المزيد
- [ ] `UXV-JRN-JRN-CHD-06-S01` `SCR-CHD-020` — Request extra time (entry: CHD-004/CHD-021) · Result: __
- [ ] `UXV-JRN-JRN-CHD-06-S02` `SCR-CHD-021` — Time is up — gently (entry: ST expiry event) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-07 — يوم دراسي كامل (الابن)
- Goal: أنجز وتعلم وكسب نقاطًا
- Trigger: لديه درس وواجب واختبار
- [ ] `UXV-JRN-JRN-CHD-07-S01` `SCR-CHD-012` — Learn home (entry: Tab learn) · Result: __
- [ ] `UXV-JRN-JRN-CHD-07-S02` `SCR-CHD-013` — Lesson (entry: CHD-012) · Result: __
- [ ] `UXV-JRN-JRN-CHD-07-S03` `SCR-CHD-014` — My assignment / flashcards (entry: CHD-012) · Result: __
- [ ] `UXV-JRN-JRN-CHD-07-S04` `SCR-CHD-015` — Quiz (entry: CHD-012) · Result: __
- [ ] `UXV-JRN-JRN-CHD-07-S05` `SCR-CHD-016` — My result (entry: CHD-015) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-08 — سؤال المعلم الذكي (الابن)
- Goal: فهم بالتدرج لا بالجواب الجاهز
- Trigger: علِق في مسألة
- [ ] `UXV-JRN-JRN-CHD-08-S01` `SCR-CHD-017` — Smart tutor (Socratic) (entry: CHD-012) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-09 — جلسة تركيز للمذاكرة (الابن)
- Goal: جلسة بلا مشتتات ووقتها مجاني
- Trigger: وقت الواجب
- [ ] `UXV-JRN-JRN-CHD-09-S01` `SCR-CHD-018` — Focus mode (entry: Hub:learn) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-10 — نقاطي ومكافآتي (الابن)
- Goal: استبدل نقاطًا بوقت لعب
- Trigger: أنجز وأراد الثمرة
- [ ] `UXV-JRN-JRN-CHD-10-S01` `SCR-CHD-019` — My minutes & badges (entry: Hub:me) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-11 — مشاركة لحظة مع العائلة (الابن)
- Goal: شارك بأمان داخل الدائرة
- Trigger: صورة أو وصول أو موقع
- [ ] `UXV-JRN-JRN-CHD-11-S01` `SCR-CHD-023` — Share media (entry: Hub:cfam) · Result: __
- [ ] `UXV-JRN-JRN-CHD-11-S02` `SCR-CHD-024` — I arrived + my location (entry: Hub:cfam) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-12 — مهامي المنزلية (الابن)
- Goal: أنجز وأكد وكسب المكافأة
- Trigger: أسندت له مهمة
- [ ] `UXV-JRN-JRN-CHD-12-S01` `SCR-CHD-022` — My tasks (entry: Hub:myday) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-13 — طلب إضافة صديق (الابن)
- Goal: صديق معتمد يتواصل معه بأمان
- Trigger: تعرّف على صديق في المدرسة
- [ ] `UXV-JRN-JRN-CHD-13-S01` `SCR-CHD-030` — My friends (entry: CHD-007 (noHub)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-14 — وردي اليومي — قرآن وأذكار (الابن)
- Goal: حفظ وتلاوة وأذكار بتشجيع لا إثقال
- Trigger: حان وقت الورد اليومي
- [ ] `UXV-JRN-JRN-CHD-14-S01` `SCR-CHD-025` — My ward (licensed) (entry: Hub:learn) · Result: __
- [ ] `UXV-JRN-JRN-CHD-14-S02` `SCR-CHD-026` — Memorization progress (entry: CHD-025) · Result: __
- [ ] `UXV-JRN-JRN-CHD-14-S03` `SCR-CHD-027` — Daily athkar (entry: Hub:myday; father via FAT-010 pending (wrong)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-15 — خطتي الذكية ومراجعة اليوم (الابن)
- Goal: تعلم يتكيف معه ويعالج فجواته
- Trigger: فتح تعلّمي أو وصلته مراجعة
- [ ] `UXV-JRN-JRN-CHD-15-S01` `SCR-CHD-028` — My smart plan (entry: Hub:learn) · Result: __
- [ ] `UXV-JRN-JRN-CHD-15-S02` `SCR-CHD-029` — Daily review (entry: CHD-028/Hub:learn) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-16 — استكشاف المرح القادم (الابن)
- Goal: يعرف القادم له من مرح وإبداع
- Trigger: فضول داخل التطبيق
- [ ] `UXV-JRN-JRN-CHD-16-S01` `SCR-CHD-031` — Coming for you (catalog) (entry: Hub:me) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-17 — مرح وإبداع متقدم (الابن)
- Goal: مرح آمن وغني داخل عائلته
- Trigger: وقت اللعب والإبداع
- [ ] `UXV-JRN-JRN-CHD-17-S01` `SCR-CHD-033` — Interactive stories (entry: Hub:learn) · Result: __
- [ ] `UXV-JRN-JRN-CHD-17-S02` `SCR-CHD-034` — Family challenges (entry: Hub:me) · Result: __
- [ ] `UXV-JRN-JRN-CHD-17-S03` `SCR-CHD-035` — Focus sounds (entry: Hub:learn/CHD-018) · Result: __
- [ ] `UXV-JRN-JRN-CHD-17-S04` `SCR-CHD-036` — Call play (entry: CHD-031/CHD-009) · Result: __
- [ ] `UXV-JRN-JRN-CHD-17-S05` `SCR-CHD-037` — Stickers & backgrounds (entry: Hub:cfam) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-CHD-18 — تلاوتي الذكية (الابن)
- Goal: تلاوة مصححة بلطف وعلم
- Trigger: أراد تحسين تلاوته بنفسه
- [ ] `UXV-JRN-JRN-CHD-18-S01` `SCR-CHD-032` — Smart tilawah (entry: Hub:learn) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-01 — التسجيل وإنشاء العائلة (الأب)
- Goal: حساب جاهز وعائلة منشأة
- Trigger: حمّل التطبيق أول مرة
- [ ] `UXV-JRN-JRN-FAT-01-S01` `SCR-SHR-001` — Welcome slides + start (entry: initial route) · Result: __
- [ ] `UXV-JRN-JRN-FAT-01-S02` `SCR-SHR-002` — Create account (entry: SHR-001) · Result: __
- [ ] `UXV-JRN-JRN-FAT-01-S03` `SCR-SHR-003` — Login + recovery (entry: SHR-001/SHR-007) · Result: __
- [ ] `UXV-JRN-JRN-FAT-01-S04` `SCR-FAT-001` — Create family (entry: SHR-002) · Result: __
- [ ] `UXV-JRN-JRN-FAT-01-S05` `SCR-SHR-007` — Neutral device mode (entry: SHR-001) · Result: __
- [ ] `UXV-JRN-JRN-FAT-01-S06` `SCR-SHR-008` — Switch user on device (entry: Settings other shortcut) · Result: __
- [ ] `UXV-JRN-JRN-FAT-01-S07` `SCR-FAT-030` — Parent second key (entry: CHD-011 request) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-02 — ربط جهاز الابن الأول (الأب)
- Goal: جهاز متصل وقيمة أولى ظاهرة
- Trigger: أراد بدء المراقبة
- [ ] `UXV-JRN-JRN-FAT-02-S01` `SCR-FAT-002` — Setup wizard (entry: FAT-001) · Result: __
- [ ] `UXV-JRN-JRN-FAT-02-S02` `SCR-FAT-003` — Add child (entry: FAT-002/FAT-012) · Result: __
- [ ] `UXV-JRN-JRN-FAT-02-S03` `SCR-FAT-004` — Link QR (entry: FAT-003) · Result: __
- [ ] `UXV-JRN-JRN-FAT-02-S04` `SCR-FAT-005` — Permissions explainer (entry: FAT-004) · Result: __
- [ ] `UXV-JRN-JRN-FAT-02-S05` `SCR-FAT-006` — Link success (entry: FAT-005) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-03 — تجربة التطبيق قبل الربط (الأب)
- Goal: رأى القيمة ببيانات تجريبية
- Trigger: ابنه غير موجود الآن
- [ ] `UXV-JRN-JRN-FAT-03-S01` `SCR-FAT-002` — Setup wizard (entry: FAT-001) · Result: __
- [ ] `UXV-JRN-JRN-FAT-03-S02` `SCR-FAT-007` — Trial mode (labelled demo) (entry: FAT-002) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-04 — دعوة الأم وتحديد صلاحيتها (الأب)
- Goal: الأم عضو بمستوى صلاحية يحدده الأب
- Trigger: أراد إشراك زوجته
- [ ] `UXV-JRN-JRN-FAT-04-S01` `SCR-FAT-008` — Invite mother + level (entry: Hub:settings/FAT-027) · Result: __
- [ ] `UXV-JRN-JRN-FAT-04-S02` `SCR-FAT-027` — Family members & roles (entry: Hub:settings) · Result: __
- [ ] `UXV-JRN-JRN-FAT-04-S03` `SCR-FAT-031` — Mother permission level (entry: FAT-027) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-05 — نظرة الصباح على العائلة (الأب)
- Goal: فهم حال الجميع في 5 ثوانٍ
- Trigger: فتح التطبيق صباحًا
- [ ] `UXV-JRN-JRN-FAT-05-S01` `SCR-FAT-010` — Today board (entry: Tab today) · Result: __
- [ ] `UXV-JRN-JRN-FAT-05-S02` `SCR-FAT-011` — Advisor suggestions (entry: Hub:today) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-06 — متابعة ابن بعينه (الأب)
- Goal: صورة كاملة عن ابن واحد
- Trigger: أراد تفاصيل خالد
- [ ] `UXV-JRN-JRN-FAT-06-S01` `SCR-FAT-012` — Children list (entry: Tab kids) · Result: __
- [ ] `UXV-JRN-JRN-FAT-06-S02` `SCR-FAT-013` — Child profile (entry: FAT-010/FAT-012) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-07 — معرفة موقع ابنه الآن (الأب)
- Goal: موقع لحظي على الخريطة
- Trigger: سأل أين هو
- [ ] `UXV-JRN-JRN-FAT-07-S01` `SCR-FAT-014` — Location map (entry: FAT-013; Hub:kids (no child); FAT-010 quick action (no child)) · Result: __
- [ ] `UXV-JRN-JRN-FAT-07-S02` `SCR-FAT-015` — Location history (entry: FAT-014) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-08 — ضبط منطقة آمنة (الأب)
- Goal: منطقة محفوظة بتنبيهات
- Trigger: أراد تنبيهًا عند المدرسة
- [ ] `UXV-JRN-JRN-FAT-08-S01` `SCR-FAT-016` — Safe zones list (entry: FAT-013/Hub:kids) · Result: __
- [ ] `UXV-JRN-JRN-FAT-08-S02` `SCR-FAT-017` — Create safe zone (entry: FAT-016/Hub:kids) · Result: __
- [ ] `UXV-JRN-JRN-FAT-08-S03` `SCR-FAT-028` — Emergency setup (entry: Hub:settings) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-09 — استقبال بلاغ استغاثة (الأب)
- Goal: وصل للابن أو طمأن عليه
- Trigger: ابنه ضغط زر الاستغاثة
- [ ] `UXV-JRN-JRN-FAT-09-S01` `SCR-FAT-018` — SOS alert (entry: SOS fire events; Settings shortcut (no alert)) · Result: __
- [ ] `UXV-JRN-JRN-FAT-09-S02` `SCR-FAT-028` — Emergency setup (entry: Hub:settings) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-10 — استقبال تنبيه أمني (الأب)
- Goal: فهم التنبيه وقرر
- Trigger: العقل رصد خطرًا
- [ ] `UXV-JRN-JRN-FAT-10-S01` `SCR-FAT-019` — Alerts hub (entry: Hub:today) · Result: __
- [ ] `UXV-JRN-JRN-FAT-10-S02` `SCR-FAT-020` — Alert detail (entry: FAT-019 (noHub)) · Result: __
- [ ] `UXV-JRN-JRN-FAT-10-S03` `SCR-FAT-029` — Brain control (entry: Hub:settings) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-11 — محادثة العائلة (الأب)
- Goal: رسالة وصلت وقُرئت
- Trigger: أراد التواصل
- [ ] `UXV-JRN-JRN-FAT-11-S01` `SCR-FAT-021` — Conversations list (entry: Tab family) · Result: __
- [ ] `UXV-JRN-JRN-FAT-11-S02` `SCR-FAT-022` — Conversation (entry: FAT-021) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-12 — مكالمة بابنه (الأب)
- Goal: مكالمة ناجحة
- Trigger: أراد سماع صوته
- [ ] `UXV-JRN-JRN-FAT-12-S01` `SCR-FAT-023` — Active call (entry: FAT-022/FAT-018) · Result: __
- [ ] `UXV-JRN-JRN-FAT-12-S02` `SCR-FAT-024` — Call history (entry: Hub:family) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-13 — إدارة أجهزة العائلة (الأب)
- Goal: أجهزة سليمة ومعروفة الحالة
- Trigger: أراد مراجعة الأجهزة
- [ ] `UXV-JRN-JRN-FAT-13-S01` `SCR-FAT-025` — Settings home + device health (entry: Tab settings) · Result: __
- [ ] `UXV-JRN-JRN-FAT-13-S02` `SCR-FAT-026` — Device detail + fix permissions (entry: FAT-025 list; FAT-013 (wrong id); Hub:settings (no id)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-14 — معالجة انقطاع جهاز (الأب)
- Goal: عاد الاتصال أو عرف السبب
- Trigger: جهاز ابنه توقف
- [ ] `UXV-JRN-JRN-FAT-14-S01` `SCR-FAT-025` — Settings home + device health (entry: Tab settings) · Result: __
- [ ] `UXV-JRN-JRN-FAT-14-S02` `SCR-FAT-026` — Device detail + fix permissions (entry: FAT-025 list; FAT-013 (wrong id); Hub:settings (no id)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-15 — ضبط وقت الشاشة لابن (الأب)
- Goal: حدود وجداول نافذة على الجهاز
- Trigger: لاحظ إفراطًا أو بدأ التنظيم
- [ ] `UXV-JRN-JRN-FAT-15-S01` `SCR-FAT-032` — Child screen time (entry: FAT-013 tools) · Result: __
- [ ] `UXV-JRN-JRN-FAT-15-S02` `SCR-FAT-033` — Extra-time requests inbox (entry: FAT-013 tools; FAT-010 pending fallback) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-16 — إدارة تطبيقات الابن (الأب)
- Goal: قواعد تطبيقات واضحة ونافذة
- Trigger: تطبيق جديد أو مراجعة دورية
- [ ] `UXV-JRN-JRN-FAT-16-S01` `SCR-FAT-034` — Child apps (entry: FAT-013 tools) · Result: __
- [ ] `UXV-JRN-JRN-FAT-16-S02` `SCR-FAT-035` — New app approval (entry: FAT-034) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-17 — ضبط فلترة الإنترنت (الأب)
- Goal: فلترة ٢٩ فئة نشطة مع استثناءات
- Trigger: أراد حماية التصفح
- [ ] `UXV-JRN-JRN-FAT-17-S01` `SCR-FAT-036` — Web filter (entry: FAT-013 tools) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-18 — قفل فوري لحظة العشاء (الأب)
- Goal: الجهاز مقفول بلطف ومؤقت
- Trigger: أراد إيقافًا مؤقتًا الآن
- [ ] `UXV-JRN-JRN-FAT-18-S01` `SCR-FAT-037` — Instant lock (entry: FAT-013 tools; FAT-010 quick action) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-19 — معالجة محاولة تحايل (الأب)
- Goal: فهم المحاولة وتصرف
- Trigger: وصله تنبيه تحايل
- [ ] `UXV-JRN-JRN-FAT-19-S01` `SCR-FAT-038` — Tamper alerts (entry: FAT-013 tools) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-20 — ضبط وضع المدرسة (الأب)
- Goal: جدول مدرسة نافذ تلقائيًا
- Trigger: بداية الفصل الدراسي
- [ ] `UXV-JRN-JRN-FAT-20-S01` `SCR-FAT-039` — School mode — deleted (ADR-034) (entry: tombstone redirect) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-21 — صناعة محتوى في الاستوديو (الأب)
- Goal: محتوى مولّد ومعتمد في ≤٩٠ ثانية
- Trigger: أراد درسًا أو اختبارًا لابنه
- [ ] `UXV-JRN-JRN-FAT-21-S01` `SCR-FAT-040` — Studio board (entry: Tab studio) · Result: __
- [ ] `UXV-JRN-JRN-FAT-21-S02` `SCR-FAT-041` — Add from any source (entry: FAT-040/Hub:studio) · Result: __
- [ ] `UXV-JRN-JRN-FAT-21-S03` `SCR-FAT-042` — Camera capture (entry: FAT-041/Hub:studio) · Result: __
- [ ] `UXV-JRN-JRN-FAT-21-S04` `SCR-FAT-043` — Generation outputs (entry: FAT-041/FAT-042) · Result: __
- [ ] `UXV-JRN-JRN-FAT-21-S05` `SCR-FAT-044` — Preview & approve (entry: FAT-043) · Result: __
- [ ] `UXV-JRN-JRN-FAT-21-S06` `SCR-FAT-045` — Assign + reward (entry: FAT-044) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-22 — الاستفادة من مكتبة المجتمع (الأب)
- Goal: استورد أو نشر محتوى موثوقًا
- Trigger: بحث عن محتوى جاهز
- [ ] `UXV-JRN-JRN-FAT-22-S01` `SCR-FAT-046` — Community library (entry: Hub:studio) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-23 — إدارة تعليم ابنه (الأب)
- Goal: صورة تعليمية كاملة وإجراء
- Trigger: تابع المواد والواجبات والنتائج
- [ ] `UXV-JRN-JRN-FAT-23-S01` `SCR-FAT-047` — Learning path (entry: Hub:studio) · Result: __
- [ ] `UXV-JRN-JRN-FAT-23-S02` `SCR-FAT-048` — Materials & lessons (entry: Hub:studio) · Result: __
- [ ] `UXV-JRN-JRN-FAT-23-S03` `SCR-FAT-049` — Create assignment / quiz (entry: FAT-048/Hub:studio) · Result: __
- [ ] `UXV-JRN-JRN-FAT-23-S04` `SCR-FAT-050` — Results follow-up (entry: Hub:studio/FAT-010 pending) · Result: __
- [ ] `UXV-JRN-JRN-FAT-23-S05` `SCR-FAT-051` — Focus report (entry: FAT-013 tools) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-24 — تنظيم التقويم العائلي (الأب)
- Goal: تقويم هجري/ميلادي حي للجميع
- Trigger: حدث عائلي أو موعد
- [ ] `UXV-JRN-JRN-FAT-24-S01` `SCR-FAT-052` — Family calendar (entry: Hub:family) · Result: __
- [ ] `UXV-JRN-JRN-FAT-24-S02` `SCR-FAT-053` — Add event (entry: FAT-052/Hub:family) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-25 — إسناد مهمة بمكافأة (الأب)
- Goal: مهمة مسندة ومكافأة مرتبطة
- Trigger: أراد تعويد ابنه المسؤولية
- [ ] `UXV-JRN-JRN-FAT-25-S01` `SCR-FAT-054` — Family tasks (entry: Hub:family/FAT-010 quick action) · Result: __
- [ ] `UXV-JRN-JRN-FAT-25-S02` `SCR-FAT-055` — Create task with reward (entry: FAT-054/Hub:family) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-26 — إدارة الاشتراك (الأب)
- Goal: باقة مناسبة بلا مفاجآت
- Trigger: انتهاء التجربة أو ترقية
- [ ] `UXV-JRN-JRN-FAT-26-S01` `SCR-FAT-056` — Plans (entry: Hub:settings) · Result: __
- [ ] `UXV-JRN-JRN-FAT-26-S02` `SCR-FAT-057` — Manage subscription (entry: FAT-056) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-27 — ضبط الإشعارات (الأب)
- Goal: إشعارات مجدولة بدرجات إلحاح
- Trigger: إشعارات كثيرة أو مفقودة
- [ ] `UXV-JRN-JRN-FAT-27-S01` `SCR-FAT-058` — Notification prefs (entry: Hub:settings) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-28 — الخصوصية والبيانات (الأب)
- Goal: تحكم كامل بالبيانات وسجل تدقيق
- Trigger: أراد مراجعة أو تصديرًا أو نسيانًا
- [ ] `UXV-JRN-JRN-FAT-28-S01` `SCR-FAT-059` — Privacy & data (entry: Hub:settings) · Result: __
- [ ] `UXV-JRN-JRN-FAT-28-S02` `SCR-FAT-060` — Audit log (append-only) (entry: FAT-059/Hub:settings) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-29 — مراجعة أنماط العقل (الأب)
- Goal: فهم خط الأساس والشذوذ والروابط
- Trigger: ملخص أسبوعي أو فضول
- [ ] `UXV-JRN-JRN-FAT-29-S01` `SCR-FAT-062` — Family patterns (entry: Hub:today) · Result: __
- [ ] `UXV-JRN-JRN-FAT-29-S02` `SCR-FAT-063` — Individual timeline (entry: FAT-062 (noHub)) · Result: __
- [ ] `UXV-JRN-JRN-FAT-29-S03` `SCR-FAT-064` — Knowledge maps (entry: FAT-062 (noHub)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-30 — اللغة والمساعدة (الأب)
- Goal: حل ذاتي سريع بالعربية
- Trigger: احتاج دعمًا أو تغيير لغة
- [ ] `UXV-JRN-JRN-FAT-30-S01` `SCR-FAT-061` — Language + help + support (entry: Hub:settings) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-31 — استقبال تنبيه ذكي والتصرف بحوار (الأب)
- Goal: فهم الموقف وفتح حوار لا عقاب
- Trigger: رصد العقل كلمة مريبة أو مشاعر متدهورة
- [ ] `UXV-JRN-JRN-FAT-31-S01` `SCR-FAT-065` — Smart alerts (entry: FAT-013 tools) · Result: __
- [ ] `UXV-JRN-JRN-FAT-31-S02` `SCR-FAT-066` — Alert detail + dialogue step (entry: FAT-065) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-32 — ضبط الرقابة الذكية والمنصات (الأب)
- Goal: قائمة مراقبة ومنصات مضبوطة بشفافية
- Trigger: أراد تفعيل المراقبة الذكية
- [ ] `UXV-JRN-JRN-FAT-32-S01` `SCR-FAT-067` — Smart supervision settings (entry: FAT-013 tools) · Result: __
- [ ] `UXV-JRN-JRN-FAT-32-S02` `SCR-FAT-068` — Platform monitoring (entry: FAT-067/FAT-013 (noHub)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-33 — مراجعة تقرير الاستخدام (الأب)
- Goal: صورة كاملة عن استخدام كل ابن
- Trigger: وصله التقرير أو فتح اللوحة
- [ ] `UXV-JRN-JRN-FAT-33-S01` `SCR-FAT-069` — Child usage report (entry: FAT-013 tools) · Result: __
- [ ] `UXV-JRN-JRN-FAT-33-S02` `SCR-FAT-081` — Anonymous peer comparison (entry: FAT-069 (noHub)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-34 — إدارة الدائرة الخارجية (الأب)
- Goal: دائرة خارجية آمنة بموافقته وحده
- Trigger: طلب صديق جديد أو إضافة قريب
- [ ] `UXV-JRN-JRN-FAT-34-S01` `SCR-FAT-070` — Outer circle (entry: FAT-013/Hub:family (noHub)) · Result: __
- [ ] `UXV-JRN-JRN-FAT-34-S02` `SCR-FAT-071` — Friend request approval (entry: FAT-070/child request) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-35 — متابعة حفظ القرآن (الأب)
- Goal: خطة حفظ ومتابعة تقدم دقيقة
- Trigger: أسند وردًا أو أراد الاطمئنان
- [ ] `UXV-JRN-JRN-FAT-35-S01` `SCR-FAT-072` — Quran follow-up (entry: FAT-013 tools/FAT-010 quick action) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-36 — قراءة التقرير الأسبوعي بتوصية (الأب)
- Goal: قرار تربوي واحد قابل للتنفيذ
- Trigger: وصل التقرير صباح الجمعة
- [ ] `UXV-JRN-JRN-FAT-36-S01` `SCR-FAT-073` — Weekly report + recommendation (entry: Hub:today) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-37 — سؤال العقل بلغة طبيعية (الأب)
- Goal: إجابة صادقة من بيانات عائلته أو «لا أعلم»
- Trigger: خطر له سؤال عن أبنائه
- [ ] `UXV-JRN-JRN-FAT-37-S01` `SCR-FAT-074` — Family advisor hub (entry: AI FAB) · Result: __
- [ ] `UXV-JRN-JRN-FAT-37-S02` `SCR-FAT-083` — Advisor voice (entry: FAT-074 (noHub)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-38 — استكشاف الميزات القادمة (الأب)
- Goal: يعرف القادم ويحجز اهتمامه
- Trigger: فضول أو حاجة لميزة مؤجلة
- [ ] `UXV-JRN-JRN-FAT-38-S01` `SCR-FAT-075` — Coming features catalog (entry: Hub:settings) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-39 — متابعة السلامة على الطريق (الأب)
- Goal: اطمئنان على تنقلات آمنة
- Trigger: ابنه بدأ يتنقل أو يقود
- [ ] `UXV-JRN-JRN-FAT-39-S01` `SCR-FAT-077` — Road safety (OOS) (entry: deep link only) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-40 — حماية شبكة المنزل (الأب)
- Goal: كل أجهزة البيت محمية بإعداد واحد
- Trigger: أراد فلترة على مستوى الراوتر
- [ ] `UXV-JRN-JRN-FAT-40-S01` `SCR-FAT-078` — Home router filter guide (entry: Hub:settings) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-41 — تفويض الوكيل الذكي (الأب)
- Goal: وكيل ينفذ ضمن حدوده بشفافية كاملة
- Trigger: أراد أتمتة قرارات روتينية
- [ ] `UXV-JRN-JRN-FAT-41-S01` `SCR-FAT-079` — My advisor — delegation rules (entry: Hub:today) · Result: __
- [ ] `UXV-JRN-JRN-FAT-41-S02` `SCR-FAT-080` — What the assistant did (entry: FAT-079 (noHub)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-42 — توزيع المهام بذكاء (الأب)
- Goal: مهام موزعة تلقائيًا بعدالة
- Trigger: أراد عدالة وتنويعًا في مهام الأبناء
- [ ] `UXV-JRN-JRN-FAT-42-S01` `SCR-FAT-082` — Smart chore distributor (entry: Hub:family) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-43 — إطلاق مشروع تعليمي بمراحل (الأب)
- Goal: مشروع بمعالم ومكافآت مرحلية
- Trigger: أراد مشروعًا عمليًا ممتدًا لأبنائه
- [ ] `UXV-JRN-JRN-FAT-43-S01` `SCR-FAT-084` — Staged project (entry: Hub:studio) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-44 — ضبط وضع ذكي بلمسة (الأب)
- Goal: كل قواعد الابن مضبوطة بلمسة واحدة مع معاينة
- Trigger: موسم جديد (رمضان/امتحانات) أو إعداد ابن
- [ ] `UXV-JRN-JRN-FAT-44-S01` `SCR-FAT-085` — Smart modes (entry: Hub:kids (no child)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-FAT-45 — لحظة الفخر الأسبوعية (الأب)
- Goal: فرح ومشاركة بطاقة فخر مع العائلة
- Trigger: صباح الجمعة وصله الملخص الاحتفالي
- [ ] `UXV-JRN-JRN-FAT-45-S01` `SCR-FAT-086` — Family moments (entry: Hub:today) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-MOT-01 — الانضمام بدعوة الأب (الأم)
- Goal: صارت عضوًا بالمستوى الذي حدده الأب
- Trigger: وصلتها دعوة من الأب بمستوى صلاحية محدد
- [ ] `UXV-JRN-JRN-MOT-01-S01` `SCR-SHR-003` — Login + recovery (entry: SHR-001/SHR-007) · Result: __
- [ ] `UXV-JRN-JRN-MOT-01-S02` `SCR-FAT-009` — Accept mother invite (entry: Login invite link; Settings shortcut (wrong)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-MOT-02 — نظرة الصباح (الأم)
- Goal: عرفت حال أبنائها
- Trigger: فتحت التطبيق
- [ ] `UXV-JRN-JRN-MOT-02-S01` `SCR-FAT-010` — Today board (entry: Tab today) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-MOT-03 — متابعة ابن بعينه (الأم)
- Goal: صورة كاملة عن ابن
- Trigger: أرادت تفاصيل
- [ ] `UXV-JRN-JRN-MOT-03-S01` `SCR-FAT-012` — Children list (entry: Tab kids) · Result: __
- [ ] `UXV-JRN-JRN-MOT-03-S02` `SCR-FAT-013` — Child profile (entry: FAT-010/FAT-012) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-MOT-04 — التواصل مع الأبناء (الأم)
- Goal: رسالة أو مكالمة
- Trigger: أرادت الاطمئنان
- [ ] `UXV-JRN-JRN-MOT-04-S01` `SCR-FAT-021` — Conversations list (entry: Tab family) · Result: __
- [ ] `UXV-JRN-JRN-MOT-04-S02` `SCR-FAT-022` — Conversation (entry: FAT-021) · Result: __
- [ ] `UXV-JRN-JRN-MOT-04-S03` `SCR-FAT-023` — Active call (entry: FAT-022/FAT-018) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-MOT-05 — استقبال بلاغ استغاثة (الأم)
- Goal: وصلت له
- Trigger: ابنها في خطر
- [ ] `UXV-JRN-JRN-MOT-05-S01` `SCR-FAT-018` — SOS alert (entry: SOS fire events; Settings shortcut (no alert)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-MOT-06 — متابعة موقع ابنها (الأم)
- Goal: عرفت موقعه
- Trigger: أرادت التأكد
- [ ] `UXV-JRN-JRN-MOT-06-S01` `SCR-FAT-014` — Location map (entry: FAT-013; Hub:kids (no child); FAT-010 quick action (no child)) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-MOT-07 — الموافقة على طلب وقت إضافي (الأم)
- Goal: قرار خلال دقيقة (مشاركة+)
- Trigger: وصلها طلب من ابن
- [ ] `UXV-JRN-JRN-MOT-07-S01` `SCR-FAT-033` — Extra-time requests inbox (entry: FAT-013 tools; FAT-010 pending fallback) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-MOT-08 — متابعة التقويم والمهام (الأم)
- Goal: أحداث ومهام محدثة
- Trigger: تدير تفاصيل اليوم
- [ ] `UXV-JRN-JRN-MOT-08-S01` `SCR-FAT-052` — Family calendar (entry: Hub:family) · Result: __
- [ ] `UXV-JRN-JRN-MOT-08-S02` `SCR-FAT-054` — Family tasks (entry: Hub:family/FAT-010 quick action) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-MOT-09 — استقبال إخطارات التحليلات (الأم)
- Goal: اطلاع حسب مستواها دون إغراق
- Trigger: رصد العقل ما يستحق إخطارها
- [ ] `UXV-JRN-JRN-MOT-09-S01` `SCR-FAT-076` — Mother AI feed (entry: Hub:today) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

### JRN-SHR-01 — معالجة خطأ أو انقطاع شبكة (مشترك)
- Goal: فهم المشكلة وأعاد المحاولة
- Trigger: فشل الاتصال
- [ ] `UXV-JRN-JRN-SHR-01-S01` `SCR-SHR-005` — Network error template (entry: error event) · Result: __
- [ ] `UXV-JRN-JRN-SHR-01-S02` `SCR-SHR-006` — Empty state template (entry: empty event) · Result: __
- [ ] Journey exit / loop partner · Result: __
- [ ] Persistence checkpoint if data mutated · Result: __

## Phase 4 — Per-screen SIP (145 surfaces)
- [ ] `UXV-SCR-SCR-SHR-001-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-SHR-002-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-SHR-003-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-SHR-007-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-SHR-008-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-001-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-002-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-003-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-004-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-005-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-006-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-007-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-030-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-001-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-002-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-003-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-011-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-008-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-009-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-027-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-031-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-025-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-026-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-061-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-010-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-011-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-056-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-057-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-058-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-059-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-060-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-012-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-013-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-014-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-015-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-016-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-017-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-018-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-028-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-005-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-006-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-024-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-077-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-032-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-033-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-034-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-035-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-036-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-037-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-038-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-085-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-004-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-020-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-021-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-065-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-066-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-067-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-068-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-069-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-081-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-073-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-021-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-022-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-023-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-024-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-007-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-008-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-009-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-036-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-023-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-037-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-070-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-071-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-030-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-052-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-053-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-054-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-055-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-082-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-022-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-040-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-041-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-042-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-043-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-044-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-045-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-046-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-047-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-048-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-049-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-050-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-051-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-084-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-012-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-013-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-014-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-015-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-016-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-017-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-018-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-035-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-072-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-025-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-026-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-027-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-032-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-028-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-029-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-019-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-033-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-034-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-031-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-019-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-020-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-029-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-062-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-063-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-064-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-074-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-083-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-076-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-079-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-080-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-075-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-078-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-086-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-CHD-010-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-SHR-005-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-SHR-006-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-SCR-FAT-039-SIP` + VIS + states · Result: __
- [ ] `UXV-SCR-sys3:session-restore-SIP` · Result: __
- [ ] `UXV-SCR-sys3:session-expired-SIP` · Result: __
- [ ] `UXV-SCR-sys3:logout-SIP` · Result: __
- [ ] `UXV-SCR-sys3:recovery-SIP` · Result: __
- [ ] `UXV-SCR-sys3:deactivate-SIP` · Result: __
- [ ] `UXV-SCR-sys3:family-select-SIP` · Result: __
- [ ] `UXV-SCR-sys3:remove-adult-SIP` · Result: __
- [ ] `UXV-SCR-sys3:ownership-transfer-SIP` · Result: __
- [ ] `UXV-SCR-sys3:leave-family-SIP` · Result: __
- [ ] `UXV-SCR-sys3:invite-status-SIP` · Result: __
- [ ] `UXV-SCR-sys3:adult-sessions-SIP` · Result: __
- [ ] `UXV-SCR-sys3:child-sessions-SIP` · Result: __
- [ ] `UXV-SCR-sys3:remote-end-SIP` · Result: __
- [ ] `UXV-SCR-sys3:revoke-confirm-SIP` · Result: __
- [ ] `UXV-SCR-dev:/gallery-SIP` · Result: __

## Phase 5 — Cross-screen + honesty + findings
- [ ] `UXV-X-01` — Active child same on profile tools vs child My Day · Result: __
- [ ] `UXV-X-02` — Family scope same on Today vs Kids vs Chat · Result: __
- [ ] `UXV-X-03` — Child display name after Add Child on Kids/Today/profile · Result: __
- [ ] `UXV-X-04` — Family chat message father→child after relaunch · Result: __
- [ ] `UXV-X-05` — Time request approve reflects on child minutes · Result: __
- [ ] `UXV-X-06` — Language setting reflected on hub labels AR/EN · Result: __
- [ ] `UXV-X-07` — SOS subject child matches alert screen · Result: __
- [ ] `UXV-X-08` — Safe zone saved appears on zones list · Result: __
- [ ] `UXV-X-09` — Alerts hub reflects SOS/tamper/time/app/friend local producers · Result: __
- [ ] `UXV-X-10` — Device health from profile uses linked device id · Result: __
- [ ] `UXV-HON-01` — Fingerprint never fake-success (C-01) · Result: __
- [ ] `UXV-HON-02` — Login local-account honesty line (C-02) · Result: __
- [ ] `UXV-HON-03` — Chat multi-device delivery not claimed (S-01/OD-09) · Result: __
- [ ] `UXV-HON-04` — GPS/battery demo bannered LOCAL_DEMO · Result: __
- [ ] `UXV-HON-05` — Native OS lock/filter closed honest · Result: __
- [ ] `UXV-HON-06` — AI suggests never auto-executes · Result: __
- [ ] `UXV-HON-07` — No MOCK/Native/Remote jargon in AR user strings (G-02) · Result: __
- [ ] `UXV-HON-08` — Billing never gates SOS/chat/location · Result: __
- [ ] `UXV-HON-09` — Empty SOS screen designed empty not crash (C-08) · Result: __
- [ ] `UXV-HON-10` — Settings no dead invite/SOS shortcuts (S-09/OD-10) · Result: __
- [ ] All `UXV-FD-*` from Matrix §8 · Result: __

## Phase 6 — Closeout
- [ ] Fail log complete in Evidence Template
- [ ] Coverage Report questions reviewed
- [ ] Deliver session pack to Cursor when D-FINAL authorized
