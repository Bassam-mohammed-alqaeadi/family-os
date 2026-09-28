# BACKLOG — Family OS Harness

**NEXT** marker = Orchestrator picks this card first among `ready`.
Statuses: `ready` | `blocked_until_stage1` | `blocked` | `done` | `deferred`

Priority lanes (top → bottom): Foundation → GapClose-SET → GapClose-UI → GlobalGap → Screen waves → Later.

**Current authority (2026-09-28) — supersedes 2026-09-21 ScreenBuild sequence lock:**

1. **Phase markers:** 1.5 · 1.75 · 2 · 3 · 4 · Frontend Closure · CE · VX · LDR — **COMPLETE** (see `AGENTS.md` / `PROJECT_EXECUTION_PLAN.md`).
2. **Now:** Local Cover / Visual Polish when Owner orients — Location 1/1B · Emergency · Notifications shipped (`e2eb4a4`). Native/Backend **NOT AUTHORIZED**.
3. **Screen catalog:** Full Frontend Closure **128/130** — ScreenBuild wave statuses below reconciled to matrix (no more `blocked_until_stage1` for completed SCRs). Authority: [`docs/experience_discovery/FRONTEND_COMPLETION_MATRIX.md`](../docs/experience_discovery/FRONTEND_COMPLETION_MATRIX.md).
4. **Still closed:** SET-001…024 + UI-001…018 (safety spine). P15-QUR-004…007 remain `deferred_campaign`. Lane 6 Stage3 deferred.

Competitive lens: [`10_COMPETITIVE_LENS.md`](10_COMPETITIVE_LENS.md).

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

> SET/UI CLOSED. Lane 5 ScreenBuild catalog **FRONTEND COMPLETE** (2026-09-25; 128/130; OOS=2). PRT-2/2.1 done. Phase 1.5 Education done · Quran `deferred_campaign`. FS-001…007 + PHASE-1.5-HARDEN done. Post-harden Local Cover (Notifications · Emergency · Location 1/1B) shipped 2026-09-27…28. **NEXT:** Visual Polish when Owner orients. Native/Backend NOT AUTHORIZED.

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

`blocked_until_stage1` retired — Stage 1 unlocked. Statuses reconciled 2026-09-28.

| id | workflow | status | summary | phase hint |
|---|---|---|---|---|
| G1 | ScreenBuild | **done** | Capability honesty badges / iOS reality vocabulary | FS-A-FOUND · CapabilityHonestyBadge |
| G2 | ScreenBuild | **done** | ARB i18n from day one | F0 · ARB skeleton |
| G3 | ScreenBuild | **deferred** | guardianship table reserved | schema · owner session later |
| G4 | ScreenBuild | **deferred** | SovereigntyRepository contract | contract · owner session later |
| G5 | ScreenBuild | **deferred** | Consent/age/region columns | Drift/schema deepen later |
| G6 | ScreenBuild | **done** | Semantics + a11y pass (Rule 16 baseline) | ongoing polish allowed under Visual Polish |
| G7 | ScreenBuild | **deferred** | Store-driven currency abstraction | billing / Stage3 |
| G8 | ScreenBuild | **done** | Parametric ChildId contract | F1+ · no child names outside mock/ |

---

## Lane 5 — Screen waves (from prototype/_REGISTRY/screens.csv)

Each card imports linked SET ids when screen matches. Cannot Ship while linked SETs open (unless deferred in QUESTIONS).

### Wave 1

| id | app | name | workflow | status | linked_gaps |
|---|---|---|---|---|---|
| SCR-SHR-001 | مشترك | شاشة الترحيب | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-SHR-002 | مشترك | إنشاء حساب | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-SHR-003 | مشترك | تسجيل الدخول | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-001 | الوالدان | إنشاء العائلة | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-002 | الوالدان | معالج الإعداد | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-003 | الوالدان | إضافة ابن | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-004 | الوالدان | رمز الربط QR | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-005 | الوالدان | شرح الصلاحيات | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-006 | الوالدان | نجاح الربط | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-007 | الوالدان | وضع التجربة | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-008 | الوالدان | دعوة الأم (من لوحة الأب) | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-009 | الوالدان | قبول دعوة الأم | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-010 | الوالدان | لوحة اليوم | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
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
| SCR-SHR-007 | مشترك | اختيار الوضع (شاشة عمر محايدة) | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-SHR-008 | مشترك | تبديل المستخدم على الجهاز | ScreenBuild | **done** | DeviceUserSwitchScreen · mock local profiles · password confirm · Rule 12/23 |
| SCR-CHD-011 | الابن | قفل وضع الابن + المدخل السري | ScreenBuild | **done** | ChildModeLockScreen · ADR-017 triple-lock · P-4 SOS · entertainment locked · Rule 12/23 |
| SCR-FAT-030 | الوالدان | طلب فتح وضع الوالد (المفتاح الثاني) | ScreenBuild | **done** | ParentSecondKeyScreen · CHD-011 second key allow/deny · attempt log · father decide · mother view · P-4 · Rule 12/23 |
| SCR-FAT-031 | الوالدان | مستوى صلاحية الأم | ScreenBuild | **done** | MotherPermissionLevelScreen · observer/partner/full · owner-only · downgrade confirm · P-4 fixed rights · Rule 12/23 |
| SCR-FAT-085 | الوالدان | الأوضاع الذكية | ScreenBuild | **done** | SET-018 shipped 2026-09-21 |
| SCR-FAT-086 | الوالدان | لحظات عائلتنا | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |

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
| SCR-FAT-062 | الوالدان | أنماط العائلة | ScreenBuild | **done** | FRONTEND COMPLETE · FE-W2-FAT-062 · 2026-09-25 |
| SCR-FAT-063 | الوالدان | الخط الزمني للفرد | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-064 | الوالدان | خرائط المعرفة | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-012 | الابن | تعلّمي — الرئيسة | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-013 | الابن | الدرس | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-014 | الابن | واجبي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-015 | الابن | الاختبار | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-016 | الابن | نتيجتي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-017 | الابن | معلمي الذكي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-018 | الابن | وضع التركيز | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-019 | الابن | نقاطي وشاراتي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-020 | الابن | طلب وقت إضافي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-021 | الابن | انتهى الوقت — بلطف | ScreenBuild | **done** (UI-011) | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-022 | الابن | مهامي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-023 | الابن | مشاركة وسائط | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-024 | الابن | أنا وصلت + موقعي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |

### Wave 3

| id | app | name | workflow | status | linked_gaps |
|---|---|---|---|---|---|
| SCR-FAT-065 | الوالدان | التنبيهات الذكية | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-066 | الوالدان | تفصيل التنبيه وخطوة الحوار | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-067 | الوالدان | إعدادات الرقابة الذكية | ScreenBuild | **done** | SET-016 |
| SCR-FAT-068 | الوالدان | مراقبة المنصات | ScreenBuild | **done** | SET-017 |
| SCR-FAT-069 | الوالدان | تقرير استخدام الابن | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-070 | الوالدان | الدائرة الخارجية | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-071 | الوالدان | موافقة طلب صديق | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-072 | الوالدان | متابعة حفظ القرآن | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-073 | الوالدان | التقرير الأسبوعي بتوصية | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-074 | الوالدان | عقل عائلتي (المساعد الذكي) | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-076 | الوالدان | إخطارات الذكاء للأم | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-075 | الوالدان | ميزات قادمة ✨ | ScreenBuild | **done** (UI-013) | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-025 | الابن | وردي — حفظ وتلاوة | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-026 | الابن | حفظي وتقدمي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-027 | الابن | أذكاري اليومية | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-028 | الابن | خطتي الذكية | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-029 | الابن | مراجعة اليوم | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-030 | الابن | أصدقائي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-031 | الابن | قادم لك 🎁 | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-077 | الوالدان | السلامة على الطريق | ScreenBuild | **deferred** | OUT OF SCOPE (matrix) |
| SCR-FAT-078 | الوالدان | فلترة الراوتر المنزلي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-079 | الوالدان | مساعدي الذكي — ماذا يفعل عني | ScreenBuild | **done** | SET-022+023 shipped 2026-09-21 |
| SCR-FAT-080 | الوالدان | ماذا فعل المساعد | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-081 | الوالدان | مقارنة الأقران | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-082 | الوالدان | موزع المهام الذكي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-083 | الوالدان | المحادثة الصوتية مع العقل | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-FAT-084 | الوالدان | مشروع بمراحل | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-032 | الابن | تلاوتي الذكية | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-033 | الابن | قصصي التفاعلية | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-034 | الابن | التحديات العائلية | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-035 | الابن | أصوات التركيز | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-036 | الابن | مرح المكالمة | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |
| SCR-CHD-037 | الابن | ملصقاتي وخلفياتي | ScreenBuild | **done** | FRONTEND COMPLETE (matrix 2026-09-25) |

---

## Lane 5.5 — Phase 1.5 Service UX Completeness

| id | domain | workflow | status | note |
|---|---|---|---|---|
| P15-EDU-001 | Education + Studio | GapClose | **done** | Scored Shell · `PHASE15_EDU_SCORE.md` · 2026-09-22 |
| P15-EDU-002 | Education | GapClose | **done** | LearningAssignment FAT-045/049→CHD-012 · P12 · 2026-09-22 |
| P15-EDU-003 | Studio sources | GapClose / ControlFit | **done** | FAT-041 SourceRef attach · P11 · 2026-09-22 |
| P15-EDU-004 | Studio approve | GapClose | **done** | FAT-044 ApprovedLearningPack → CHD-015 · 2026-09-22 |
| P15-EDU-005 | Studio reward | GapClose | **done** | FAT-045 Assign → WalletLedger/PolicyEngine.earn · 2026-09-22 |
| P15-EDU-006 | Results loop | LoopClose | **done** | CHD-015 quiz submit → LearningResult → FAT-050 activity · P12 · 2026-09-23 |
| P15-EDU-007 | Materials | GapClose | **done** | FAT-048 add subject/lesson persists rows · P11 · 2026-09-23 |
| P15-EDU-008 | Day board | LoopClose | **done** | LearningResult → FAT-010 priority → FAT-050 · P12 · 2026-09-23 |
| P15-QUR-001 | Quran + Athkar | GapClose | **done** | Scored Shell · `PHASE15_QUR_SCORE.md` · 2026-09-23 |
| P15-QUR-002 | Ward plan | GapClose | **done** | QuranWardPlan seam FAT-072 publish → CHD-025 binds · P12 · 2026-09-23 |
| P15-QUR-003 | Recitation loop | LoopClose | **done** | Child submit → FAT-072 pending; approve → WalletLedger.earn · P12 · 2026-09-23 |
| P15-QUR-004 | Offline pack | GapClose | **deferred_campaign** | Parked — do not auto-resume after Phase 1.5; Owner re-order required |
| P15-QUR-005 | Athkar board | LoopClose | **deferred_campaign** | Parked — Owner re-order required |
| P15-QUR-006 | Memorization | GapClose | **deferred_campaign** | Parked — Owner re-order required |
| P15-QUR-007 | Whisper | GapClose | **deferred_campaign** | Parked — Owner re-order required |

---

## Lane FS — Master Implementation Commission FS-001…FS-007

**Plan:** [`docs/experience_discovery/FS_001_007_IMPLEMENTATION_MASTER_PLAN.md`](../docs/experience_discovery/FS_001_007_IMPLEMENTATION_MASTER_PLAN.md)  
**Authority:** Owner commission 2026-09-24 · L2/L3 freezes · no backend.

| id | phase | workflow | status | goal |
|---|---|---|---|---|
| **FS-A-FOUND** | A | GapClose | **done** | Capability registry + SQLite/Memory + MockRemote + delivery vocabulary · 2026-09-24 |
| **FS-001-DOM** | B | GapClose | **done** | Location domain + SQLite trail/zones · 2026-09-24 |
| **FS-001-UX** | B | GapClose | **done** | ADAPT FAT-014…017 + silent/check-in/SLR · 2026-09-24 |
| **FS-001-XSYS** | B | GapClose | **done** | SOS handoff + Modes fact feed + schema v3 · 2026-09-24 |
| **FS-002-OWN** | C | GapClose | **done** | Authoritative WF store + lists honesty · 2026-09-24 |
| **FS-002-ENF** | C | GapClose | **done** | Delivery plane + timed unlock + interstitial · 2026-09-24 |
| **FS-003-OWN** | D | GapClose | **done** | AC dispositions + protected apps + exception · 2026-09-24 |
| **FS-003-UX** | D | GapClose | **done** | Hub/inventory/deny/disclosure ADAPT · 2026-09-24 |
| **FS-004-OWN** | E | GapClose | **done** | Prevent/Monitor/Protect policy store · schema v7 · 2026-09-24 |
| **FS-004-UX** | E | GapClose | **done** | Parent FAT-065 + child CHD-010 transparency · 2026-09-24 |
| **FS-005-OWN** | F | GapClose | **done** | Lifestyle schedule + stack + tighten-only · schema v8 · 2026-09-24 |
| **FS-005-UX** | F | GapClose | **done** | FAT-085 ADAPT + CHD-004 disclosure · 2026-09-24 |
| **FS-006-LIFE** | G | GapClose | **done** | sos_final lifecycle/evidence/readiness · 2026-09-24 |
| **FS-006-XSYS** | G | GapClose | **done** | exemptions + location honesty · 2026-09-24 |
| **FS-007-SIG** | H | GapClose | **done** | Classifier signal + ticket + suggest-only · 2026-09-24 |
| **FS-007-UX** | H | GapClose | **done** | Parent review + child transparency · 2026-09-24 |
| **FS-I-RECON** | I | GapClose | **done** | Cross-system reconcile + closure report · 2026-09-24 |

### Phase 1.5 Platform Hardening (post-FS)

| id | workflow | status | note |
|---|---|---|---|
| **PHASE-1.5-HARDEN** | GapClose | **done** | Shared FsSessionKernel + honesty/RBAC/FAT-034/migration proof · 2026-09-24 · superseded by Local Cover / Frontend Closure waves |

---


## Lane Local Cover — System Polish (2026-09-27…28)

Authority: Owner Father-control Cover · platform cohesion · UI-complete now / Backend wire later.

| id | workflow | status | note |
|---|---|---|---|
| SYS-SEC-NOTIF-CORE | GapClose | **done** | Notifications core CLOSED · Owner EXIT:0 · 2026-09-27 |
| SYS-SEC-EMERGENCY-0 | GapClose | **done** | Emergency inventory · FAT-028 · 2026-09-27 |
| SYS-SEC-EMERGENCY-1 | GapClose | **done** | FAT-028 Father-control cover · 2026-09-27 |
| SYS-SEC-LOCATION-0 | GapClose | **done** | Location inventory · 2026-09-27 |
| SYS-SEC-LOCATION-1B | GapClose | **done** | No-show deadline + FAT-013 desk · 2026-09-28 |
| UX-LOCAL-SEED | GapClose | **done** | Debug projecting producers seed · 2026-09-27 |
| UX-SHELL-TABS-FIX | GapClose | **done** | TabsBar restored · 2026-09-27 |
| HUB-FAT-010-STRUCTURE | GapClose | **done** | Hub chrome + importance ladder · 2026-09-27 |
| **NEXT → VISUAL-POLISH** | GapClose | **ready** | Awaits Owner orientation · Native/Backend closed |

---
## Lane 6 — Later (not active)

| id | status | note |
|---|---|---|
| STAGE3-API | deferred | Repository API swap · Rule 25 |
| STAGE3-AI | deferred | Advisor/Insights/Tutor gateways · Rule 26 |
| STAGE3-BILLING | deferred | Subscription; SOS never gated |
| STAGE4-GROWTH | deferred | GTM / revenue loops after real services |

---

## Lane Parity — Prototype-shape (precedes Phase 1.5 shell wiring)

| id | workflow | status | goal | notes |
|---|---|---|---|---|
| PRT-1 | ScreenBuild | **done** | Generator groundwork: shell_config.dart + hubIndex from screens.csv | shipped 2026-09-22 |
| PRT-2 | ScreenBuild | **done** | FamilyShellHost TabsBar+hub+FABs · Q-PRT-2 | shipped 2026-09-22 |
| PRT-2.1 | ScreenBuild | **done** | Shell harden + Register §10 day-board seed; StatefulShellRoute deferred | shipped 2026-09-23 |

---

## Orchestrator tip

Flutter Stage 1 is long unlocked. Prefer Owner orientation for Visual Polish / next Cover packs. Native/Backend stay gated. Hard stop = unanswered QUESTIONS only.
