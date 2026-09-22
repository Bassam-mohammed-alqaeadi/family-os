# BACKLOG — Family OS Harness

**NEXT** marker = Orchestrator picks this card first among `ready`.
Statuses: `ready` | `blocked_until_stage1` | `blocked` | `done` | `deferred`

Priority lanes (top → bottom): Foundation → GapClose-SET → GapClose-UI → GlobalGap → Screen waves → Later.

**Owner directive (2026-09-21) — sequence lock:**

1. **Now:** ScreenBuild every remaining SCR (mock-first). One card per logical tick. No Stage 3 backend.
2. **Cadence (same day):** ≥**3 Ships per wake**; chain next card immediately; arm `/loop` **15m** only when leaving. Quality bar unchanged.
3. **Then Phase 1.5:** Service UX completeness — father/child user lens ([`docs/project-plan/10-service-ux-completeness-rubric.md`](../docs/project-plan/10-service-ux-completeness-rubric.md)); Education first vertical. Gate: [`11_PHASE_15_UX_COMPLETENESS_GATE.md`](11_PHASE_15_UX_COMPLETENESS_GATE.md).
4. **Only after 1.5:** Stage 3 real APIs (Lane 6).

SET-001…024 + UI-001…018 stay **CLOSED** (safety spine). Do not reopen unless Phase 1.5 finds a real UX hole. Competitive lens: [`10_COMPETITIVE_LENS.md`](10_COMPETITIVE_LENS.md). Prior SET pivot (2026-09-20) completed.

Template: [`05_TASK_CARD_TEMPLATE.md`](05_TASK_CARD_TEMPLATE.md)

---

## Lane 1 — Foundation

| id | workflow | status | goal | sources |
|---|---|---|---|---|
| F0-0 | ScreenBuild | **done** | Flutter create + SDK pin + CI + IBM Plex + l10n | shipped 2026-09-20 |
| F0-A | ScreenBuild | **done** | Design tokens → `tokens.dart` + gallery swatches | shipped 2026-09-20 |
| F0-B | ScreenBuild | **done** | Ten core components + widget tests | shipped 2026-09-20 |
| F1-A | ScreenBuild | **done** | gen_routes from screens.csv + RoleGuard (go_router) | shipped 2026-09-20 |
| F2-POLICY | ScreenBuild | **done** | PolicyEngine §1–§3 + unit tests per clause | shipped 2026-09-20 |

> SET lane CLOSED 2026-09-21 (SET-001…024). UI lane CLOSED 2026-09-21 (UI-001…018). Owner sequence: Screens → Phase 1.5 UX → Stage 3. Cadence: ≥3 ships/wake · `/loop` 15m. ScreenBuild wave — **NEXT = SCR-FAT-062** (ready). Skills: `harness/08_SKILLS_MAP.md` + competitive lens + [`docs/project-plan/10-service-ux-completeness-rubric.md`](../docs/project-plan/10-service-ux-completeness-rubric.md).

---

## Lane 2 — GapClose SET-001…024

| id | screen | workflow | status | summary | spec |
|---|---|---|---|---|---|
| SET-001 | SCR-FAT-032 | GapClose | **done** | Sleep/prayer/study → real schedule windows (Qustodio/Family Link ControlFit) | shipped 2026-09-20 |
| SET-002 | SCR-FAT-032 | GapClose | **done** | Persist daily policy / per-app wallets (Prefs Rule 25 → TimeEngine) | shipped 2026-09-20 |
| SET-003 | SCR-FAT-032 | GapClose | **done** | Child reflects parent schedule/cap edits same session after sync (P12) | shipped 2026-09-20 |
| SET-004 | SCR-FAT-036 | GapClose | **done** | Category filter rows → real WebFilterPolicy (Qustodio/Net Nanny persist+block) | shipped 2026-09-20 |
| SET-005 | SCR-FAT-036 | GapClose | **done** | Polite block page + father preview | shipped 2026-09-20 |
| SET-006 | SCR-FAT-036 | GapClose | **done** | Child→parent web unlock request loop (Family Link approve/deny) | shipped 2026-09-20 |
| SET-007 | SCR-FAT-037 | GapClose | **done** | Anti-tamper must not appear for mother (ADR-035-b omit) | shipped 2026-09-20 |
| SET-008 | SCR-FAT-037 | GapClose | **done** | Anti-tamper enable effects (whenEnabled + bypass alert mock) | shipped 2026-09-20 |
| SET-009 | SCR-FAT-037 | GapClose | **done** | Mother lock vs father unlock conflict (ADR-035 father wins) | shipped 2026-09-20 |
| SET-010 | SCR-FAT-058 | GapClose | **done** | Quiet hours must never silence SOS | shipped 2026-09-20 |
| SET-011 | SCR-FAT-058 | GapClose | **done** | Mother notification identity | shipped 2026-09-20 |
| SET-012 | SCR-FAT-059 | GapClose | **done** | Child transparency mirrors collection | shipped 2026-09-20 |
| SET-013 | SCR-FAT-059 | GapClose | **done** | Forget vs wipe separate confirmations | shipped 2026-09-21 |
| SET-014 | SCR-FAT-029 | GapClose | **done** | AI stages are server flags | shipped 2026-09-21 |
| SET-015 | SCR-FAT-029 | GapClose | **done** | Mother must not open brain control | shipped 2026-09-21 |
| SET-016 | SCR-FAT-067 | GapClose | **done** | Platform toggles read capability table | shipped 2026-09-21 |
| SET-017 | SCR-FAT-068 | GapClose | **done** | Disabled iOS claims must not look enabled | shipped 2026-09-21 |
| SET-018 | SCR-FAT-085 | GapClose | **done** | School services must not route FAT-039 (ADR-034 → FAT-085) | shipped 2026-09-21 |
| SET-019 | SCR-CHD-004 | GapClose | **done** | Child status card follows active mode stream | shipped 2026-09-21 |
| SET-020 | SCR-FAT-028 | GapClose | **done** | Parents cannot be removed from SOS rung 1 | shipped 2026-09-21 |
| SET-021 | SCR-FAT-028 | GapClose | **done** | No SOS mute for mother/guardian | shipped 2026-09-21 |
| SET-022 | SCR-FAT-079 | GapClose | **done** | Separate AI suggestions from My rules | shipped 2026-09-21 |
| SET-023 | SCR-FAT-079 | GapClose | **done** | Rule editor blocks owner-only consequents | shipped 2026-09-21 |
| SET-024 | SCR-FAT-032 | GapClose | **done** | Wallet overflow father switch (Ruling B) | shipped 2026-09-21 |

> Lane 2 SET-001…024 **CLOSED** 2026-09-21.

---

## Lane 3 — GapClose UI-001…018

| id | workflow | status | title | spec |
|---|---|---|---|---|
| UI-001 | GapClose | **done** | **Host:** `SCR-FAT-001` create family   | shipped 2026-09-21 |
| UI-002 | GapClose | **done** | **Host:** `SCR-FAT-002` completeness wizard   | shipped 2026-09-21 |
| UI-003 | GapClose | **done** | **Host:** `SCR-CHD-002` QR scan   | shipped 2026-09-21 |
| UI-004 | GapClose | **done** | **Host:** `SCR-FAT-010` morning board   | shipped 2026-09-21 |
| UI-005 | GapClose | **done** | **Host:** `SCR-CHD-004`   | shipped 2026-09-21 |
| UI-006 | GapClose | **done** | **Host:** Request inbox / FAT-033   | shipped 2026-09-21 |
| UI-007 | GapClose | **done** | **Host:** `SCR-FAT-056/057` billing   | shipped 2026-09-21 |
| UI-008 | GapClose | **done** | **Host:** Settings spine toggles   | shipped 2026-09-21 |
| UI-009 | GapClose | **done** | **Host:** FAT-036 + child block page   | shipped 2026-09-21 |
| UI-010 | GapClose | **done** | **Host:** `SCR-FAT-058` quiet hours   | shipped 2026-09-21 |
| UI-011 | GapClose | **done** | **Host:** `SCR-CHD-021` time expiry   | shipped 2026-09-21 |
| UI-012 | GapClose | **done** | **Host:** `SCR-FAT-025/026` device health   | shipped 2026-09-21 |
| UI-013 | GapClose | **done** | **Host:** `SCR-FAT-075` coming soon   | shipped 2026-09-21 |
| UI-014 | GapClose | **done** | **Host:** Spine interactive CTAs   | shipped 2026-09-21 |
| UI-015 | GapClose | **done** | **Host:** SOS, lock, approve, grant controls   | shipped 2026-09-21 |
| UI-016 | GapClose | **done** | **Host:** All FAT/CHD/SHR   | shipped 2026-09-21 |
| UI-017 | GapClose | **done** | **Host:** Day boards   | shipped 2026-09-21 |
| UI-018 | GapClose | **done** | **Host:** Platform monitoring (FAT-067/068)   | shipped 2026-09-21 · UI lane CLOSED |

---

## Lane 4 — Global gaps G1–G8

| id | workflow | status | summary | phase hint |
|---|---|---|---|---|
| G1 | ScreenBuild | blocked_until_stage1 | iOS reality honesty badges | F4 · core/platform/ios_reality.dart |
| G2 | ScreenBuild | blocked_until_stage1 | ARB i18n from day one | F0 · ARB skeleton |
| G3 | ScreenBuild | blocked_until_stage1 | guardianship table reserved | schema · owner session later |
| G4 | ScreenBuild | blocked_until_stage1 | SovereigntyRepository contract | contract · owner session later |
| G5 | ScreenBuild | blocked_until_stage1 | Consent/age/region columns | F2 · Drift schema |
| G6 | ScreenBuild | blocked_until_stage1 | Semantics + a11y pass | F0+F7 · Rule 16 |
| G7 | ScreenBuild | blocked_until_stage1 | Store-driven currency abstraction | F6 · plans screen |
| G8 | ScreenBuild | blocked_until_stage1 | Parametric ChildId contract | F1+ · CI ban names outside mock/ |

---

## Lane 5 — Screen waves (from prototype/_REGISTRY/screens.csv)

Each card imports linked SET ids when screen matches. Cannot Ship while linked SETs open (unless deferred in QUESTIONS).

### Wave 1

| id | app | name | workflow | status | linked_gaps |
|---|---|---|---|---|---|
| SCR-SHR-001 | مشترك | شاشة الترحيب | ScreenBuild | **done** | — |
| SCR-SHR-002 | مشترك | إنشاء حساب | ScreenBuild | **done** | — |
| SCR-SHR-003 | مشترك | تسجيل الدخول | ScreenBuild | **done** | — |
| SCR-FAT-001 | الوالدان | إنشاء العائلة | ScreenBuild | **done** | — |
| SCR-FAT-002 | الوالدان | معالج الإعداد | ScreenBuild | **done** | — |
| SCR-FAT-003 | الوالدان | إضافة ابن | ScreenBuild | **done** | — |
| SCR-FAT-004 | الوالدان | رمز الربط QR | ScreenBuild | **done** | — |
| SCR-FAT-005 | الوالدان | شرح الصلاحيات | ScreenBuild | **done** | — |
| SCR-FAT-006 | الوالدان | نجاح الربط | ScreenBuild | **done** | — |
| SCR-FAT-007 | الوالدان | وضع التجربة | ScreenBuild | **done** | — |
| SCR-FAT-008 | الوالدان | دعوة الأم (من لوحة الأب) | ScreenBuild | **done** | — |
| SCR-FAT-009 | الوالدان | قبول دعوة الأم | ScreenBuild | **done** | — |
| SCR-FAT-010 | الوالدان | لوحة اليوم | ScreenBuild | **done** | — |
| SCR-FAT-011 | الوالدان | اقتراحات العقل | ScreenBuild | **done** | ADR-038 suggest-only · Bark · approve→confirm→My rules |
| SCR-FAT-012 | الوالدان | قائمة الأبناء | ScreenBuild | **done** | ChildrenListScreen · Rule 23 empty default · shared policies Family Link/Qustodio override honesty |
| SCR-FAT-013 | الوالدان | ملف الابن | ScreenBuild | **done** | ChildProfileScreen · parametric childId · tools→032/033/036/037/067/026 · Rule 23 missing/not-found |
| SCR-FAT-014 | الوالدان | خريطة الموقع | ScreenBuild | **done** | LocationMapScreen · pins+zones+thread · Life360 honesty · P-4 SOS ungated · Rule 23 empty |
| SCR-FAT-015 | الوالدان | سجل المواقع | ScreenBuild | **done** | LocationHistoryScreen · day-thread+S-SEC-023 frequent · Life360 honesty · P-4 SOS · Rule 23 |
| SCR-FAT-016 | الوالدان | المناطق الآمنة | ScreenBuild | **done** | SafeZonesScreen · list+alert toggles · mother full edit · Life360 honesty · P-4 SOS · FAT-014 CTA |
| SCR-FAT-017 | الوالدان | إنشاء منطقة آمنة | ScreenBuild | **done** | CreateSafeZoneScreen · tap/drag+radius · save→016 repo · mother full · Life360 · P-4 SOS |
| SCR-FAT-018 | الوالدان | بلاغ استغاثة | ScreenBuild | **done** | SosAlertScreen · coral board+siren+live map · auto-call 5s · mother observer OK · P-4 · SET-020/021 |
| SCR-FAT-028 | الوالدان | إعداد الطوارئ | ScreenBuild | **done** | SET-020+021 CLOSED |
| SCR-FAT-019 | الوالدان | مركز التنبيهات | ScreenBuild | **done** | AlertsHubScreen · 🔴🟡🟢 tiers+counters · FAT-020/033/035 · P-4 SOS · Rule 23 |
| SCR-FAT-020 | الوالدان | تفصيل التنبيه | ScreenBuild | **done** | AlertDetailScreen · kind templates · alertId+kind · Bark honesty · P-4 · Rule 23 |
| SCR-FAT-021 | الوالدان | قائمة المحادثات | ScreenBuild | **done** | ConversationsListScreen · pinned family+DMs · UI-007 ungated · FAT-022 · P-4 · Rule 23 |
| SCR-FAT-022 | الوالدان | المحادثة | ScreenBuild | **done** | ConversationScreen · chatWith thread · send mock · UI-007 · P-4 · Rule 23 |
| SCR-FAT-023 | الوالدان | مكالمة جارية | ScreenBuild | **done** | ActiveCallScreen · callId · mute/speaker/video/end mock · play-together · P-4 · Rule 23 |
| SCR-FAT-024 | الوالدان | سجل المكالمات | ScreenBuild | **done** | CallHistoryScreen · redial→023 · dial seam · mother OK/child lean · P-4 · Rule 23 |
| SCR-FAT-025 | الوالدان | الإعدادات | ScreenBuild | **done** | SettingsHubScreen F-08 hub; device health section→026; mother OK/child lean; P-4; UI-012 kept |
| SCR-FAT-026 | الوالدان | تفصيل الجهاز | ScreenBuild | **done** | DeviceHealthDetailScreen OEM guide+permissions; deny→repair→grant; mother OK/child lean; P-4; UI-012 kept |
| SCR-FAT-027 | الوالدان | أعضاء العائلة | ScreenBuild | **done** | FamilyMembersScreen roster · invite→008 owner-only · mother→031 · guardian locked · P-4 · Rule 23 |
| SCR-FAT-029 | الوالدان | لوحة تحكم العقل | ScreenBuild | **done** | SET-014, SET-015 |
| SCR-CHD-001 | الابن | ترحيب الابن | ScreenBuild | **done** | ChildWelcomeScreen · RoleGuard child · CTA→002 · Rule 12/23 |
| SCR-CHD-002 | الابن | مسح رمز الربط | ScreenBuild | **done** | Host: UI-003 ChildQrScanScreen (shipped 2026-09-21) |
| SCR-CHD-003 | الابن | إقرار الشفافية | ScreenBuild | **done** | TransparencyConsentScreen · shared/never/advisor · RoleGuard · CTA→004 · Rule 12/23 |
| SCR-CHD-004 | الابن | لوحة يومي | ScreenBuild | **done** | SET-019 · UI-005 |
| SCR-CHD-005 | الابن | زر الاستغاثة | ScreenBuild | **done** | ChildSosButtonScreen · hold ٣ ثوانٍ · P-4 always-on · fire→CHD-006 · Rule 12/23 |
| SCR-CHD-006 | الابن | الاستغاثة جارية | ScreenBuild | **done** | ChildSosInProgressScreen · P-4 never gated · cancel/resolve · handoff from 005 · Rule 12/23 |
| SCR-CHD-007 | الابن | محادثاتي | ScreenBuild | **done** | ChildChatsScreen · closed circle · UI-007 · →008 chatWith · call CTA · P-4 · Rule 12/23 |
| SCR-CHD-008 | الابن | المحادثة | ScreenBuild | **done** | ChildConversationScreen · incoming call · never-lock · send mock · parent lean · Rule 12/23 |
| SCR-CHD-009 | الابن | مكالمة | ScreenBuild | **done** | ChildActiveCallScreen · mute/speaker/end→007 · P-4 SOS · Rule 12/23 |
| SCR-CHD-010 | الابن | ماذا يُجمع عني | ScreenBuild | **done** | SET-012 shipped 2026-09-20 |
| SCR-SHR-005 | مشترك | خطأ الشبكة | ScreenBuild | **done** | UI-001 AppErrorState |
| SCR-SHR-006 | مشترك | حالة فارغة | ScreenBuild | **done** | UI-005 AppEmptyState |
| SCR-SHR-007 | مشترك | اختيار الوضع (شاشة عمر محايدة) | ScreenBuild | **done** | — |
| SCR-SHR-008 | مشترك | تبديل المستخدم على الجهاز | ScreenBuild | **done** | DeviceUserSwitchScreen · mock local profiles · password confirm · Rule 12/23 |
| SCR-CHD-011 | الابن | قفل وضع الابن + المدخل السري | ScreenBuild | **done** | ChildModeLockScreen · ADR-017 triple-lock · P-4 SOS · entertainment locked · Rule 12/23 |
| SCR-FAT-030 | الوالدان | طلب فتح وضع الوالد (المفتاح الثاني) | ScreenBuild | **done** | ParentSecondKeyScreen · CHD-011 second key allow/deny · attempt log · father decide · mother view · P-4 · Rule 12/23 |
| SCR-FAT-031 | الوالدان | مستوى صلاحية الأم | ScreenBuild | **done** | MotherPermissionLevelScreen · observer/partner/full · owner-only · downgrade confirm · P-4 fixed rights · Rule 12/23 |
| SCR-FAT-085 | الوالدان | الأوضاع الذكية | ScreenBuild | **done** | SET-018 shipped 2026-09-21 |
| SCR-FAT-086 | الوالدان | لحظات عائلتنا | ScreenBuild | blocked_until_stage1 | — |

### Wave 2

| id | app | name | workflow | status | linked_gaps |
|---|---|---|---|---|---|
| SCR-FAT-032 | الوالدان | وقت الشاشة لابن | ScreenBuild | **done** | Host MVP SET-001+002+003+024 |
| SCR-FAT-033 | الوالدان | طلبات الوقت الإضافي | ScreenBuild | **done** | UI-006 RequestInboxScreen |
| SCR-FAT-034 | الوالدان | تطبيقات الابن | ScreenBuild | **done** | ChildAppsScreen · empty/one/many · allow/block · pending→FAT-035 · Rule 12/23 |
| SCR-FAT-035 | الوالدان | موافقة تطبيق جديد | ScreenBuild | **done** | NewAppApprovalScreen · approve/deny · empty · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-036 | الوالدان | فلترة الإنترنت | ScreenBuild | **done** | Host MVP SET-004…006 closed |
| SCR-FAT-037 | الوالدان | القفل الفوري | ScreenBuild | **done** | Host MVP SET-007…009 closed |
| SCR-FAT-038 | الوالدان | تنبيهات التحايل | ScreenBuild | **done** | TamperAlertsScreen · empty/one/many · link→FAT-037 · Bark honesty · P-4 · Rule 12/23 |
| SCR-FAT-039 | الوالدان | وضع المدرسة [محذوفة نهائيًا بقرار أد-١٢ + ق-١٢ في 37] | ScreenBuild | **deferred** | ADR-034 tombstone — never route; school on FAT-085 (SET-018) |
| SCR-FAT-040 | الوالدان | لوحة الاستوديو | ScreenBuild | **done** | StudioBoardScreen · empty/loading/one/many · create→FAT-041 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-041 | الوالدان | أضف من أي مصدر | ScreenBuild | **done** | AddFromSourceScreen · PDF+6 sources · CTAs→042/046/049/043 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-042 | الوالدان | التقاط من الكاميرا | ScreenBuild | **done** | StudioCameraCaptureScreen · mock camera seam · deny→repair · capture→043 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-043 | الوالدان | مخرجات التوليد | ScreenBuild | **done** | GenerationOutputsScreen · 6 mock outputs+toggles · religious lock · generate→FAT-044 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-044 | الوالدان | معاينة واعتماد | ScreenBuild | **done** | PreviewApproveScreen · quiz+lesson · approve/reject · swap/edit/delete · →FAT-045 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-045 | الوالدان | الإسناد والمكافأة | ScreenBuild | **done** | AttributionRewardScreen · child+minutes reward · schedule · →FAT-046 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-046 | الوالدان | مكتبة المجتمع | ScreenBuild | **done** | CommunityLibraryScreen · empty/one/many · import/publish · →FAT-047 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-047 | الوالدان | المسار التعليمي | ScreenBuild | **done** | LearningPathScreen · empty/one/many · progress+thread · →FAT-048 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-048 | الوالدان | المواد والدروس | ScreenBuild | **done** | MaterialsLessonsScreen · empty/one/many · subjects+add · →FAT-049 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-049 | الوالدان | إنشاء واجب واختبار | ScreenBuild | **done** | CreateAssignmentScreen · 3 paths · homework/skill/family · →FAT-050 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-050 | الوالدان | متابعة النتائج | ScreenBuild | **done** | ResultsFollowupScreen · mastery+gap+activity · →FAT-049/051 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-051 | الوالدان | تقرير التركيز | ScreenBuild | **done** | FocusReportScreen · weekly+praise+reward(+15m) · schedules · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-052 | الوالدان | التقويم العائلي | ScreenBuild | **done** | FamilyCalendarScreen · Hijri/Greg · prayer · grid+filters · →FAT-053 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-053 | الوالدان | إضافة حدث | ScreenBuild | **done** | AddEventScreen · cat/date/who · save→FAT-052 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-054 | الوالدان | المهام العائلية | ScreenBuild | **done** | FamilyTasksScreen · empty/one/many · approve+mother help · →FAT-055 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-055 | الوالدان | إنشاء مهمة بمكافأة | ScreenBuild | **done** | CreateTaskScreen · minutes-only · mother help · save→FAT-054 · mother levels · P-4 · Rule 12/23 |
| SCR-FAT-056 | الوالدان | الباقات والاشتراك | ScreenBuild | **done** (UI-007) | PlansScreen · father-owner · entitlement-free SOS |
| SCR-FAT-057 | الوالدان | إدارة الاشتراك | ScreenBuild | **done** (UI-007) | ManageSubscriptionScreen · father-owner |
| SCR-FAT-058 | الوالدان | الإشعارات | ScreenBuild | **done** | SET-010+011 shipped 2026-09-20 |
| SCR-FAT-059 | الوالدان | الخصوصية والبيانات | ScreenBuild | **done** | SET-012/013 closed 2026-09-21 |
| SCR-FAT-060 | الوالدان | سجل التدقيق | ScreenBuild | **done** | AuditLogScreen · append-only R10 · mother view · P-4 · Rule 12/23 |
| SCR-FAT-061 | الوالدان | اللغة والمساعدة | ScreenBuild | **done** | LanguageHelpScreen · AR/EN+help→026/030 · mother levels · P-4 · Rule 12/23 |
| **NEXT → SCR-FAT-062** | الوالدان | أنماط العائلة | ScreenBuild | **ready** | Flipped after SCR-FAT-061 |
| SCR-FAT-063 | الوالدان | الخط الزمني للفرد | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-064 | الوالدان | خرائط المعرفة | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-012 | الابن | تعلّمي — الرئيسة | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-013 | الابن | الدرس | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-014 | الابن | واجبي | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-015 | الابن | الاختبار | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-016 | الابن | نتيجتي | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-017 | الابن | معلمي الذكي | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-018 | الابن | وضع التركيز | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-019 | الابن | نقاطي وشاراتي | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-020 | الابن | طلب وقت إضافي | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-021 | الابن | انتهى الوقت — بلطف | ScreenBuild | **done** (UI-011) | — |
| SCR-CHD-022 | الابن | مهامي | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-023 | الابن | مشاركة وسائط | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-024 | الابن | أنا وصلت + موقعي | ScreenBuild | blocked_until_stage1 | — |

### Wave 3

| id | app | name | workflow | status | linked_gaps |
|---|---|---|---|---|---|
| SCR-FAT-065 | الوالدان | التنبيهات الذكية | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-066 | الوالدان | تفصيل التنبيه وخطوة الحوار | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-067 | الوالدان | إعدادات الرقابة الذكية | ScreenBuild | **done** | SET-016 |
| SCR-FAT-068 | الوالدان | مراقبة المنصات | ScreenBuild | **done** | SET-017 |
| SCR-FAT-069 | الوالدان | تقرير استخدام الابن | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-070 | الوالدان | الدائرة الخارجية | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-071 | الوالدان | موافقة طلب صديق | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-072 | الوالدان | متابعة حفظ القرآن | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-073 | الوالدان | التقرير الأسبوعي بتوصية | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-074 | الوالدان | عقل عائلتي (المساعد الذكي) | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-076 | الوالدان | إخطارات الذكاء للأم | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-075 | الوالدان | ميزات قادمة ✨ | ScreenBuild | **done** (UI-013) | — |
| SCR-CHD-025 | الابن | وردي — حفظ وتلاوة | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-026 | الابن | حفظي وتقدمي | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-027 | الابن | أذكاري اليومية | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-028 | الابن | خطتي الذكية | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-029 | الابن | مراجعة اليوم | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-030 | الابن | أصدقائي | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-031 | الابن | قادم لك 🎁 | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-077 | الوالدان | السلامة على الطريق | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-078 | الوالدان | فلترة الراوتر المنزلي | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-079 | الوالدان | مساعدي الذكي — ماذا يفعل عني | ScreenBuild | **done** | SET-022+023 shipped 2026-09-21 |
| SCR-FAT-080 | الوالدان | ماذا فعل المساعد | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-081 | الوالدان | مقارنة الأقران | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-082 | الوالدان | موزع المهام الذكي | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-083 | الوالدان | المحادثة الصوتية مع العقل | ScreenBuild | blocked_until_stage1 | — |
| SCR-FAT-084 | الوالدان | مشروع بمراحل | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-032 | الابن | تلاوتي الذكية | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-033 | الابن | قصصي التفاعلية | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-034 | الابن | التحديات العائلية | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-035 | الابن | أصوات التركيز | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-036 | الابن | مرح المكالمة | ScreenBuild | blocked_until_stage1 | — |
| SCR-CHD-037 | الابن | ملصقاتي وخلفياتي | ScreenBuild | blocked_until_stage1 | — |

---

## Lane 6 — Later (not active)

| id | status | note |
|---|---|---|
| STAGE3-API | deferred | Repository API swap · Rule 25 |
| STAGE3-AI | deferred | Advisor/Insights/Tutor gateways · Rule 26 |
| STAGE3-BILLING | deferred | Subscription; SOS never gated |
| STAGE4-GROWTH | deferred | GTM / revenue loops after real services |

---

## Orchestrator tip

Until Stage 1 unlock, the only productive ticks are: improve harness docs, answer QUESTIONS, or prepare evidence templates. Do **not** invent Flutter code.
