# FINAL USER EXPERIENCE EXPECTED RESULTS

**Authority:** Policy Register (supreme) · frozen prototype · Matrix fields · Owner decisions D1–D12 / OD-13/14 · CLOSED VX-B0…B7 finding statuses.
**Rule:** Do not invent behavior. Observable expected results only.

## 1. Classifications
| Result | Use when |
|---|---|
| PASS | UI + state + navigation match; evidence captured |
| FAIL | Observable mismatch |
| BLOCKED-NATIVE | Needs native; honesty of closed UI must still PASS |
| BLOCKED-REMOTE | Needs backend; honesty of closed UI must still PASS |
| OWNER-DECISION | New ambiguity only (D1–D12 already answered) |
| NOT-APPLICABLE | Criterion does not apply |

## 2. Nine-field template (every actionable case)
1. Precondition 2. Exact action 3. UI response 4. Data/state change 5. Navigation 6. Feedback 7. Must NOT happen 8. Persistence 9. Evidence

## 3. Canonical SIP expected results
| Field | Expected |
|---|---|
| Title | ARB string for screen; no Register §10 person names |
| Route | `/scr-…` or sys3 path from router |
| Wrong role | RoleGuard → role home + toast (D4); never gallery |
| Context | Active child/family via resolver; no wrong-child |
| Primary CTA | One clear primary; ≥48dp; Semantics |
| Back | Drill-down push returns to origin (G-17) |
| Empty/Error/Loading | Shared components; no false server blame for local |
| Native/Remote closed | Glossary honesty; no fake success |
| Local mutate | Immediate UI + kill/relaunch if Local-claimed |
| Feedback | AppToast/banner not hidden behind FAB |

## 4. Lifecycle (`UXV-LC-*`)
### `UXV-LC-01` — First / cold launch
- Expected: SHR-001 or session restore
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-02` — Fresh install empty local DB
- Expected: empty family / empty chat seed rules
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-03` — Existing local data relaunch
- Expected: roster/chat/tasks persist
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-04` — Authenticated session active
- Expected: FAT-010 / CHD-004
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-05` — Session expired / recovery
- Expected: sys3 session-expired / recovery
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-06` — Role resolution father
- Expected: Today FAT-010
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-07` — Role resolution mother
- Expected: Today + level-limited controls
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-08` — Role resolution child
- Expected: My Day CHD-004
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-09` — Family select / switch
- Expected: sys3 family-select if multi
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-10` — Child select / switch
- Expected: profile / SHR-008 / active child
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-11` — Language AR→EN
- Expected: FAT-061 + shell labels
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-12` — Language EN→AR
- Expected: FAT-061 + RTL
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-13` — RTL→LTR transition
- Expected: shell FABs/chevrons
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-14` — LTR→RTL transition
- Expected: shell FABs/chevrons
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-15` — Offline start
- Expected: honest offline / local
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-16` — Online→offline during use
- Expected: no fake sync success
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-17` — Offline→online
- Expected: no false delivered claims
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-18` — Kill→relaunch persistence
- Expected: VX-B6 D6 + Program §13.5
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-19` — Back chain drill-down
- Expected: push not go (G-17)
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-20` — Repeated open/close sheets
- Expected: dialogs dismiss clean
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-21` — Empty family/data states
- Expected: empty components
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-22` — Populated states
- Expected: lists render
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-23` — Loading states
- Expected: AppLoadingState
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-24` — Error states
- Expected: AppErrorState + retry
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-25` — Native-closed honesty
- Expected: BN classification
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-26` — Remote-closed honesty
- Expected: BR classification
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

### `UXV-LC-27` — Local-only honesty
- Expected: glossary OD-02
- Must NOT: crash; debug localhost; planted names; remote delivery claims without Backend

## 5. Journeys
Each `UXV-JRN-*-Snn`: Matrix purpose/entry/exit; CLOSED findings show fixed behavior; NC/RC show honest closed.

### JRN-CHD-01 — ربط جهازي وفهم القواعد
- User: الابن · Goal: فهم ماذا يُراقب ووافق
- Screens: SCR-CHD-001, SCR-CHD-002, SCR-CHD-003, SCR-CHD-011
- Re-verify findings: FVX-G-13
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-02 — يومي في لمحة
- User: الابن · Goal: عرف مهامه ووقته
- Screens: SCR-CHD-004
- Re-verify findings: FVX-G-03
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-03 — طلب النجدة
- User: الابن · Goal: وصل البلاغ لوالديه
- Screens: SCR-CHD-005, SCR-CHD-006
- Re-verify findings: FVX-G-06
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-04 — التواصل مع عائلتي
- User: الابن · Goal: رسالة أو مكالمة
- Screens: SCR-CHD-007, SCR-CHD-008, SCR-CHD-009
- Re-verify findings: FVX-S-01
- Matrix freeze result: `OD` — re-evaluate live after VX closures

### JRN-CHD-05 — معرفة ما يُجمع عني
- User: الابن · Goal: رأى فئات البيانات المجموعة
- Screens: SCR-CHD-003, SCR-CHD-010
- Re-verify findings: FVX-G-03
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-06 — طلب وقت إضافي
- User: الابن · Goal: طلب مهذب وصل والديه
- Screens: SCR-CHD-020, SCR-CHD-021
- Re-verify findings: FVX-G-03, FVX-G-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-07 — يوم دراسي كامل
- User: الابن · Goal: أنجز وتعلم وكسب نقاطًا
- Screens: SCR-CHD-012, SCR-CHD-013, SCR-CHD-014, SCR-CHD-015, SCR-CHD-016
- Re-verify findings: FVX-G-03, FVX-C-06
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-08 — سؤال المعلم الذكي
- User: الابن · Goal: فهم بالتدرج لا بالجواب الجاهز
- Screens: SCR-CHD-017
- Re-verify findings: FVX-G-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-09 — جلسة تركيز للمذاكرة
- User: الابن · Goal: جلسة بلا مشتتات ووقتها مجاني
- Screens: SCR-CHD-018
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-10 — نقاطي ومكافآتي
- User: الابن · Goal: استبدل نقاطًا بوقت لعب
- Screens: SCR-CHD-019
- Re-verify findings: FVX-G-11
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-11 — مشاركة لحظة مع العائلة
- User: الابن · Goal: شارك بأمان داخل الدائرة
- Screens: SCR-CHD-023, SCR-CHD-024
- Re-verify findings: FVX-G-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-12 — مهامي المنزلية
- User: الابن · Goal: أنجز وأكد وكسب المكافأة
- Screens: SCR-CHD-022
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-13 — طلب إضافة صديق
- User: الابن · Goal: صديق معتمد يتواصل معه بأمان
- Screens: SCR-CHD-030
- Re-verify findings: FVX-G-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-14 — وردي اليومي — قرآن وأذكار
- User: الابن · Goal: حفظ وتلاوة وأذكار بتشجيع لا إثقال
- Screens: SCR-CHD-025, SCR-CHD-026, SCR-CHD-027
- Re-verify findings: FVX-G-03
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-15 — خطتي الذكية ومراجعة اليوم
- User: الابن · Goal: تعلم يتكيف معه ويعالج فجواته
- Screens: SCR-CHD-028, SCR-CHD-029
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-16 — استكشاف المرح القادم
- User: الابن · Goal: يعرف القادم له من مرح وإبداع
- Screens: SCR-CHD-031
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-17 — مرح وإبداع متقدم
- User: الابن · Goal: مرح آمن وغني داخل عائلته
- Screens: SCR-CHD-033, SCR-CHD-034, SCR-CHD-035, SCR-CHD-036, SCR-CHD-037
- Re-verify findings: FVX-G-12
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-CHD-18 — تلاوتي الذكية
- User: الابن · Goal: تلاوة مصححة بلطف وعلم
- Screens: SCR-CHD-032
- Re-verify findings: FVX-G-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-01 — التسجيل وإنشاء العائلة
- User: الأب · Goal: حساب جاهز وعائلة منشأة
- Screens: SCR-SHR-001, SCR-SHR-002, SCR-SHR-003, SCR-FAT-001, SCR-SHR-007, SCR-SHR-008, SCR-FAT-030
- Re-verify findings: FVX-G-01, FVX-C-01, FVX-C-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-02 — ربط جهاز الابن الأول
- User: الأب · Goal: جهاز متصل وقيمة أولى ظاهرة
- Screens: SCR-FAT-002, SCR-FAT-003, SCR-FAT-004, SCR-FAT-005, SCR-FAT-006
- Re-verify findings: FVX-S-04
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-03 — تجربة التطبيق قبل الربط
- User: الأب · Goal: رأى القيمة ببيانات تجريبية
- Screens: SCR-FAT-002, SCR-FAT-007
- Re-verify findings: FVX-G-11
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-04 — دعوة الأم وتحديد صلاحيتها
- User: الأب · Goal: الأم عضو بمستوى صلاحية يحدده الأب
- Screens: SCR-FAT-008, SCR-FAT-027, SCR-FAT-031
- Re-verify findings: FVX-G-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-05 — نظرة الصباح على العائلة
- User: الأب · Goal: فهم حال الجميع في 5 ثوانٍ
- Screens: SCR-FAT-010, SCR-FAT-011
- Re-verify findings: FVX-S-03, FVX-G-05, FVX-G-17
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-06 — متابعة ابن بعينه
- User: الأب · Goal: صورة كاملة عن ابن واحد
- Screens: SCR-FAT-012, SCR-FAT-013
- Re-verify findings: FVX-S-04
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-07 — معرفة موقع ابنه الآن
- User: الأب · Goal: موقع لحظي على الخريطة
- Screens: SCR-FAT-014, SCR-FAT-015
- Re-verify findings: FVX-G-08, FVX-G-12
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-08 — ضبط منطقة آمنة
- User: الأب · Goal: منطقة محفوظة بتنبيهات
- Screens: SCR-FAT-016, SCR-FAT-017, SCR-FAT-028
- Re-verify findings: FVX-S-05, FVX-G-09
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-09 — استقبال بلاغ استغاثة
- User: الأب · Goal: وصل للابن أو طمأن عليه
- Screens: SCR-FAT-018, SCR-FAT-028
- Re-verify findings: FVX-G-06, FVX-S-09
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-10 — استقبال تنبيه أمني
- User: الأب · Goal: فهم التنبيه وقرر
- Screens: SCR-FAT-019, SCR-FAT-020, SCR-FAT-029
- Re-verify findings: FVX-S-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-11 — محادثة العائلة
- User: الأب · Goal: رسالة وصلت وقُرئت
- Screens: SCR-FAT-021, SCR-FAT-022
- Re-verify findings: FVX-S-01
- Matrix freeze result: `OD` — re-evaluate live after VX closures

### JRN-FAT-12 — مكالمة بابنه
- User: الأب · Goal: مكالمة ناجحة
- Screens: SCR-FAT-023, SCR-FAT-024
- Re-verify findings: FVX-G-06, FVX-G-10
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-13 — إدارة أجهزة العائلة
- User: الأب · Goal: أجهزة سليمة ومعروفة الحالة
- Screens: SCR-FAT-025, SCR-FAT-026
- Re-verify findings: FVX-S-06, FVX-S-09
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-14 — معالجة انقطاع جهاز
- User: الأب · Goal: عاد الاتصال أو عرف السبب
- Screens: SCR-FAT-025, SCR-FAT-026
- Re-verify findings: FVX-S-06
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-15 — ضبط وقت الشاشة لابن
- User: الأب · Goal: حدود وجداول نافذة على الجهاز
- Screens: SCR-FAT-032, SCR-FAT-033
- Re-verify findings: FVX-S-03
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-16 — إدارة تطبيقات الابن
- User: الأب · Goal: قواعد تطبيقات واضحة ونافذة
- Screens: SCR-FAT-034, SCR-FAT-035
- Re-verify findings: FVX-G-02, FVX-G-17
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-17 — ضبط فلترة الإنترنت
- User: الأب · Goal: فلترة ٢٩ فئة نشطة مع استثناءات
- Screens: SCR-FAT-036
- Re-verify findings: FVX-G-04, FVX-G-03
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-18 — قفل فوري لحظة العشاء
- User: الأب · Goal: الجهاز مقفول بلطف ومؤقت
- Screens: SCR-FAT-037
- Re-verify findings: FVX-G-04, FVX-G-03
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-19 — معالجة محاولة تحايل
- User: الأب · Goal: فهم المحاولة وتصرف
- Screens: SCR-FAT-038
- Re-verify findings: FVX-S-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-20 — ضبط وضع المدرسة
- User: الأب · Goal: جدول مدرسة نافذ تلقائيًا
- Screens: SCR-FAT-039
- Re-verify findings: none
- Matrix freeze result: `NA` — re-evaluate live after VX closures

### JRN-FAT-21 — صناعة محتوى في الاستوديو
- User: الأب · Goal: محتوى مولّد ومعتمد في ≤٩٠ ثانية
- Screens: SCR-FAT-040, SCR-FAT-041, SCR-FAT-042, SCR-FAT-043, SCR-FAT-044, SCR-FAT-045
- Re-verify findings: FVX-C-03, FVX-G-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-22 — الاستفادة من مكتبة المجتمع
- User: الأب · Goal: استورد أو نشر محتوى موثوقًا
- Screens: SCR-FAT-046
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-23 — إدارة تعليم ابنه
- User: الأب · Goal: صورة تعليمية كاملة وإجراء
- Screens: SCR-FAT-047, SCR-FAT-048, SCR-FAT-049, SCR-FAT-050, SCR-FAT-051
- Re-verify findings: FVX-G-04
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-24 — تنظيم التقويم العائلي
- User: الأب · Goal: تقويم هجري/ميلادي حي للجميع
- Screens: SCR-FAT-052, SCR-FAT-053
- Re-verify findings: FVX-G-15
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-25 — إسناد مهمة بمكافأة
- User: الأب · Goal: مهمة مسندة ومكافأة مرتبطة
- Screens: SCR-FAT-054, SCR-FAT-055
- Re-verify findings: FVX-G-17
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-26 — إدارة الاشتراك
- User: الأب · Goal: باقة مناسبة بلا مفاجآت
- Screens: SCR-FAT-056, SCR-FAT-057
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-27 — ضبط الإشعارات
- User: الأب · Goal: إشعارات مجدولة بدرجات إلحاح
- Screens: SCR-FAT-058
- Re-verify findings: FVX-G-09
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-28 — الخصوصية والبيانات
- User: الأب · Goal: تحكم كامل بالبيانات وسجل تدقيق
- Screens: SCR-FAT-059, SCR-FAT-060
- Re-verify findings: FVX-G-03, FVX-G-06
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-29 — مراجعة أنماط العقل
- User: الأب · Goal: فهم خط الأساس والشذوذ والروابط
- Screens: SCR-FAT-062, SCR-FAT-063, SCR-FAT-064
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-30 — اللغة والمساعدة
- User: الأب · Goal: حل ذاتي سريع بالعربية
- Screens: SCR-FAT-061
- Re-verify findings: FVX-S-07
- Matrix freeze result: `OD` — re-evaluate live after VX closures

### JRN-FAT-31 — استقبال تنبيه ذكي والتصرف بحوار
- User: الأب · Goal: فهم الموقف وفتح حوار لا عقاب
- Screens: SCR-FAT-065, SCR-FAT-066
- Re-verify findings: FVX-G-04, FVX-G-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-32 — ضبط الرقابة الذكية والمنصات
- User: الأب · Goal: قائمة مراقبة ومنصات مضبوطة بشفافية
- Screens: SCR-FAT-067, SCR-FAT-068
- Re-verify findings: FVX-G-04, FVX-G-03
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-33 — مراجعة تقرير الاستخدام
- User: الأب · Goal: صورة كاملة عن استخدام كل ابن
- Screens: SCR-FAT-069, SCR-FAT-081
- Re-verify findings: FVX-G-04
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-34 — إدارة الدائرة الخارجية
- User: الأب · Goal: دائرة خارجية آمنة بموافقته وحده
- Screens: SCR-FAT-070, SCR-FAT-071
- Re-verify findings: FVX-S-03
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-35 — متابعة حفظ القرآن
- User: الأب · Goal: خطة حفظ ومتابعة تقدم دقيقة
- Screens: SCR-FAT-072
- Re-verify findings: FVX-G-03, FVX-G-04
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-36 — قراءة التقرير الأسبوعي بتوصية
- User: الأب · Goal: قرار تربوي واحد قابل للتنفيذ
- Screens: SCR-FAT-073
- Re-verify findings: FVX-G-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-37 — سؤال العقل بلغة طبيعية
- User: الأب · Goal: إجابة صادقة من بيانات عائلته أو «لا أعلم»
- Screens: SCR-FAT-074, SCR-FAT-083
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-38 — استكشاف الميزات القادمة
- User: الأب · Goal: يعرف القادم ويحجز اهتمامه
- Screens: SCR-FAT-075
- Re-verify findings: FVX-G-08
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-39 — متابعة السلامة على الطريق
- User: الأب · Goal: اطمئنان على تنقلات آمنة
- Screens: SCR-FAT-077
- Re-verify findings: FVX-C-05
- Matrix freeze result: `OD` — re-evaluate live after VX closures

### JRN-FAT-40 — حماية شبكة المنزل
- User: الأب · Goal: كل أجهزة البيت محمية بإعداد واحد
- Screens: SCR-FAT-078
- Re-verify findings: FVX-G-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-41 — تفويض الوكيل الذكي
- User: الأب · Goal: وكيل ينفذ ضمن حدوده بشفافية كاملة
- Screens: SCR-FAT-079, SCR-FAT-080
- Re-verify findings: FVX-C-04
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-42 — توزيع المهام بذكاء
- User: الأب · Goal: مهام موزعة تلقائيًا بعدالة
- Screens: SCR-FAT-082
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-43 — إطلاق مشروع تعليمي بمراحل
- User: الأب · Goal: مشروع بمعالم ومكافآت مرحلية
- Screens: SCR-FAT-084
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-44 — ضبط وضع ذكي بلمسة
- User: الأب · Goal: كل قواعد الابن مضبوطة بلمسة واحدة مع معاينة
- Screens: SCR-FAT-085
- Re-verify findings: FVX-G-04
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-FAT-45 — لحظة الفخر الأسبوعية
- User: الأب · Goal: فرح ومشاركة بطاقة فخر مع العائلة
- Screens: SCR-FAT-086
- Re-verify findings: FVX-G-02
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-MOT-01 — الانضمام بدعوة الأب
- User: الأم · Goal: صارت عضوًا بالمستوى الذي حدده الأب
- Screens: SCR-SHR-003, SCR-FAT-009
- Re-verify findings: FVX-S-09
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-MOT-02 — نظرة الصباح
- User: الأم · Goal: عرفت حال أبنائها
- Screens: SCR-FAT-010
- Re-verify findings: FVX-S-03
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-MOT-03 — متابعة ابن بعينه
- User: الأم · Goal: صورة كاملة عن ابن
- Screens: SCR-FAT-012, SCR-FAT-013
- Re-verify findings: FVX-S-04
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-MOT-04 — التواصل مع الأبناء
- User: الأم · Goal: رسالة أو مكالمة
- Screens: SCR-FAT-021, SCR-FAT-022, SCR-FAT-023
- Re-verify findings: FVX-S-01
- Matrix freeze result: `OD` — re-evaluate live after VX closures

### JRN-MOT-05 — استقبال بلاغ استغاثة
- User: الأم · Goal: وصلت له
- Screens: SCR-FAT-018
- Re-verify findings: FVX-G-06
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-MOT-06 — متابعة موقع ابنها
- User: الأم · Goal: عرفت موقعه
- Screens: SCR-FAT-014
- Re-verify findings: FVX-G-08
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-MOT-07 — الموافقة على طلب وقت إضافي
- User: الأم · Goal: قرار خلال دقيقة (مشاركة+)
- Screens: SCR-FAT-033
- Re-verify findings: FVX-S-03
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-MOT-08 — متابعة التقويم والمهام
- User: الأم · Goal: أحداث ومهام محدثة
- Screens: SCR-FAT-052, SCR-FAT-054
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-MOT-09 — استقبال إخطارات التحليلات
- User: الأم · Goal: اطلاع حسب مستواها دون إغراق
- Screens: SCR-FAT-076
- Re-verify findings: FVX-G-13
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

### JRN-SHR-01 — معالجة خطأ أو انقطاع شبكة
- User: مشترك · Goal: فهم المشكلة وأعاد المحاولة
- Screens: SCR-SHR-005, SCR-SHR-006
- Re-verify findings: none
- Matrix freeze result: `PENDING` — re-evaluate live after VX closures

## 6. Cross-screen & honesty
- `UXV-X-01`: Active child same on profile tools vs child My Day
- `UXV-X-02`: Family scope same on Today vs Kids vs Chat
- `UXV-X-03`: Child display name after Add Child on Kids/Today/profile
- `UXV-X-04`: Family chat message father→child after relaunch
- `UXV-X-05`: Time request approve reflects on child minutes
- `UXV-X-06`: Language setting reflected on hub labels AR/EN
- `UXV-X-07`: SOS subject child matches alert screen
- `UXV-X-08`: Safe zone saved appears on zones list
- `UXV-X-09`: Alerts hub reflects SOS/tamper/time/app/friend local producers
- `UXV-X-10`: Device health from profile uses linked device id
- `UXV-HON-01`: Fingerprint never fake-success (C-01)
- `UXV-HON-02`: Login local-account honesty line (C-02)
- `UXV-HON-03`: Chat multi-device delivery not claimed (S-01/OD-09)
- `UXV-HON-04`: GPS/battery demo bannered LOCAL_DEMO
- `UXV-HON-05`: Native OS lock/filter closed honest
- `UXV-HON-06`: AI suggests never auto-executes
- `UXV-HON-07`: No MOCK/Native/Remote jargon in AR user strings (G-02)
- `UXV-HON-08`: Billing never gates SOS/chat/location
- `UXV-HON-09`: Empty SOS screen designed empty not crash (C-08)
- `UXV-HON-10`: Settings no dead invite/SOS shortcuts (S-09/OD-10)

## 7. Owner decisions (expected law)
| D | Law |
|---|---|
| D1 | Real AR/EN persisted |
| D2 | Glossary honesty + child line |
| D3 | ink2 AA |
| D4 | RoleGuard → role home |
| D5 | Western digits on AR |
| D6 | No core/policy default ID change |
| D7+OD-13 | SOS parent + viewed child |
| D9/OD-09 | Local family chat seed; no mock messages |
| D10 | No Settings FAT-009/018 shortcuts |
| D11 | FAT-077 → FAT-075 |
| OD-14 | Education roster children |
