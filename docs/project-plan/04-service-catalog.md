# 04 — Service Catalog
**Mission:** Discovery phase 3 · Branch `discovery/master-plan`  
**Date:** 2026-09-19 · **Authority:** Section A wins · Policy Register = supreme law · Registry `_REGISTRY/services.csv` = canonical service list  
**Counting convention (ADR-034):** 129 active screens + 1 tombstone (`SCR-FAT-039`)

---

## 1. Method & coverage status

**Source of truth:** `family-os/_REGISTRY/services.csv` — **240 services**, 5 domains, 42 subsystems. The registry is authoritative; this catalog **traces and specifies**, it never invents or renumbers services.

**Screen binding:** `services.csv` has an **empty `screens` column** for all 240 rows. Screen↔service linkage therefore had to be **reverse-derived** from `screens.csv.services` and `journeys.csv.services`. That derived mapping is Annex A of this document, and it is the input for phase 12 traceability.

**Coverage in this pass:**

| Depth | Services | Where |
|---|---:|---|
| Full end-to-end specification (UI→…→Test) | **12** (constitutional spine) | §4 |
| Structured domain/subsystem analysis (purpose, actor, governing law, risk) | **240** | §3 |
| Indexed with derived screen + journey binding | **240** | Annex A |
| Blocked pending owner decision | **4** (`S-EDU-030/032/033`, `S-EDU-036`) | ADR-036 / ADR-037 |

**Honest limit:** 240 full specifications is a multi-pass job. This pass specifies the spine that every other service depends on (identity, delegation, time engine, economy, safety, chat, alerts, audit). The remaining services are batched in §6 in dependency order, so each later batch inherits settled semantics instead of re-litigating them.

---

## 2. Domain map

| Domain | Arabic | Services | P0 | Purpose | Primary actor |
|---|---|---:|---:|---|---|
| **SEC** | الأمن والرعاية | 60 | 41 | Time, apps, web, location, emergency, monitoring, anti-tamper, instant lock, reports, driving, school mode | Father configures · Child experiences |
| **EDU** | التعليم | 65 | 46 | Subjects, homework, assessment, tutor, adaptive learning, motivation, Qur'an, focus, father's studio | Father assigns · Child earns |
| **ADM** | الإدارة | 42 | 40 | Onboarding, family/members, devices, subscription, notifications, privacy, day board, settings | Father (owner) |
| **COM** | التواصل | 39 | 30 | Chat, calls, media, safe contact circle, calendar, chores, location-in-chat | All primary actors |
| **AIC** | الذكاء | 34 | 19 | Detection, patterns, family knowledge store, advisor/reports, interactive assistant, delegated agent | Advisor proposes · Father approves |

**By status:** موجودة (exists in prototype) 116 · جديدة (new) 119 · قاعدة حاكمة (governing rule) 5  
**By wave:** W1 55 · W2 127 · W3 58

### 2.1 The 5 "governing rule" services (not features — invariants)

| ID | Name | Invariant it encodes |
|---|---|---|
| `S-EDU-044` | وقت التعليم مجاني دائمًا | Register **S-1**: education/Qur'an/calls never count against the cap |
| `S-AIC-006` | مقتطف التنبيه لا الأرشيف | Alerts show an excerpt, never a surveillance archive |
| `S-AIC-029` | إخطار الأم بالتحليلات | Mother is informed of analyses (R-3 channel) |
| `S-ADM-033` | لوحة تحكم العقل | AI scope per child — **father-only** (doc 20) |
| `S-ADM-035` | شاشة «ماذا يُجمع عني» للابن | P-7 transparency: protection without deception |

**Implementation consequence:** these five must be implemented as **policy predicates in `core/policy/`**, not as screens. A widget-level implementation of any of them is a Rule 24 violation waiting to happen.

---

## 3. Subsystem analysis (all 240)

### 3.1 SEC — الأمن والرعاية (60)

| Ref | Subsystem | # | Governing law | Cross-role obligation |
|---|---|---:|---|---|
| أ | إدارة وقت الشاشة | 7 | §2 rulings A–D, S-1, S-2, S-3 | Cap change → child countdown + T-5 notice |
| ب | التحكم بالتطبيقات | 6 | P-3 (blocked stays blocked) | Block → child grid re-tints, balance cannot open |
| ج | فلترة الإنترنت | 5 | P-8 (3 levels + polite block page) | Child sees block page; unlock-request loop to father |
| د | الموقع والمناطق الآمنة | 7 | P-1, geofence tables | Zone event → parent alert; mother always sees location |
| هـ | الطوارئ والاستغاثة | 6 | **P-4, P-5** | SOS reaches all guardians regardless of level/plan/network |
| و | مراقبة المحتوى الذكية | 6 | **P-7** (with the child's knowledge) | Every monitoring switch must surface on the child's transparency card |
| ز | مراقبة منصات التواصل | 4 | P-7 + platform limits (G1) | Honesty badge per platform capability |
| ح | مقاومة التحايل | 5 | **P-6** (6 switches) · **ADR-035: owner-only** | Bypass attempt → father alert + audit |
| ط | القفل الفوري | 3 | §2 priority ladder (lock above all) · ADR-035 | Mother FULL may lock; father can reverse; audit both |
| ي | التقارير والتحليلات | 5 | G-7 (settings-aware, real data) | Reports must reflect actual settings, not defaults |
| ك | السلامة الحركية والقيادة | 3 | P-10 (Android-first honesty) | iOS limitation stated in UI, not hidden |
| ل | وضع المدرسة | 3 | §3 modes (M-A…M-D) | **Note:** bound screen `SCR-FAT-039` is tombstoned — services must attach to the surviving modes screens (traceability item T-1) |

### 3.2 EDU — التعليم (65)

| Ref | Subsystem | # | Governing law | Cross-role obligation |
|---|---|---:|---|---|
| أ | المواد والدروس | 6 | S-1 (education not counted) | — |
| ب | الواجبات | 6 | A-2 (Socratic tutor) | Homework help never gives direct answers |
| ج | الاختبارات والتقييم | 6 | G-8 (no embarrassing ranking) | Results are private to child+parents |
| د | المعلم الذكي | 6 | **A-2, A-3** | Conversations logged to father; child sees transparency line |
| هـ | التعلّم التكيفي | 5 | A-6 (anonymous comparison) | No named peer comparison |
| و | التحفيز والمكافآت | 7 | **E-1 (minutes only)** | **3 of 7 blocked** — ADR-036 (points/XP naming), ADR-037 (competitive divisions) |
| ز | القرآن والتربية الإسلامية | 5 | **A-4** (licensed Madinah Mushaf only) | AI never generates verses; Qur'an never locked |
| ح | التركيز وبيئة الدراسة | 6 | S-5 (two focus channels) | `rewardSelfDiscipline` untouchable |
| ط | استوديو الأب | 18 | E-2 (father sets reward at creation) | Largest subsystem — father-authored content/tasks |

### 3.3 ADM — الإدارة (42)

| Ref | Subsystem | # | Governing law | Cross-role obligation |
|---|---|---:|---|---|
| أ | الإعداد الأول | 7 | R-4 (role by device linking), ADR-003 (email+password, no OTP) | Pairing decides role — never a picker |
| ب | العائلة والأعضاء | 6 | **R-1, R-2, doc 20, ADR-035** | Level change → mother notified + audit; downgrade double-confirm |
| ج | الأجهزة | 5 | Device health/permission tables | Missing permission → actionable repair path |
| د | الاشتراك والفوترة | 6 | **Rule 9 / owner-only** | Safety surfaces must never read subscription state |
| هـ | الإشعارات | 5 | S-3, C-4, P-4 urgency tiers | Critical-alert channel bypasses DND |
| و | الخصوصية والبيانات | 6 | P-7, wipe amendment, audit append-only | 7-day regret window + audit entry |
| ز | لوحة اليوم | 4 | G-1 offline-first, Rule 23 | Dashboard is fully state-bound; "last synced" always honest |
| ح | الإعدادات والدعم | 3 | G-3 human language | — |

### 3.4 COM — التواصل (39)

| Ref | Subsystem | # | Governing law | Cross-role obligation |
|---|---|---:|---|---|
| أ | المحادثات | 9 | **C-1 (never locked), C-2 (E2EE), C-3 (15-min edit)** | Chat exempt from TimeEngine entirely |
| ب | المكالمات | 6 | C-4, C-5 (LiveKit, no recording) | Check-in rings on silent; father-side mirror of child controls |
| ج | الوسائط والملفات | 5 | C-6 (stays in family circle) | Voice notes auto-transcribed |
| د | دائرة الاتصال الآمنة | 5 | **P-9 (strangers always blocked)** | Whitelist-only; father approves each friend |
| هـ | التقويم العائلي | 6 | — | Shared family events |
| و | المهام والمسؤوليات | 5 | **E-2, E-4, E-5** | Child tasks carry minutes; **mother's tasks carry none** |
| ز | الموقع في التواصل | 3 | P-1 | Location sharing inside chat respects policy layer |

### 3.5 AIC — الذكاء (34)

| Ref | Subsystem | # | Governing law | Cross-role obligation |
|---|---|---:|---|---|
| أ | محرك الرصد | 6 | A-1, `S-AIC-006` excerpt rule | Alerts are event-emitted (Rule 23), never planted |
| ب | محرك الأنماط والشذوذ | 5 | A-6 anonymity | Baselines computed server-side (Rule 26) |
| ج | مخزن المعرفة العائلية | 6 | Wipe/forget amendment | `S-AIC-017` زر النسيان never touches messages or audit log |
| د | المستشار والتقارير | 6 | A-1, A-5, G-7 | Weekly report from real settings + data |
| هـ | المساعد التفاعلي | 6 | **A-2**, `S-AIC-026` "I don't know" | Refusal + honesty are repository contracts, not prompts |
| و | الوكيل المفوَّض | 5 | **A-5 vs Rule 7/26** | **CONFLICT-WITH-FROZEN candidate → ADR-038** (see §5) |

---

## 4. Full specifications — the constitutional spine (12)

Spec template per Section B phase 3. `R#` = constitution rule.

---

### 4.1 `S-ADM-003` — ربط جهاز الابن بـQR (pair child device)

| Field | Content |
|---|---|
| **Purpose** | Bind a physical device to a child identity and thereby **determine its role** — the only legitimate way a device becomes a child device |
| **Primary role** | Father (owner) |
| **Other affected** | Child (scans), Mother (sees result), Advisor (none) |
| **Entry screens** | `SCR-FAT-004` (QR code), `SCR-CHD-002` (scan), `SCR-FAT-006` / `SCR-CHD-003` (success + transparency ack) |
| **Inputs** | `ChildId`, short-lived pairing token |
| **Outputs** | `device` row (`mode = CHILD_LOCKED`), first-value location fix |
| **Settings** | Token TTL; retry limit |
| **Business rules** | Token expires; single-use; **no role picker ever** (R4 of Register / SCR-SHR-004 deleted); child device cannot self-declare a parent role |
| **Permissions** | Owner-only issue; child device may only consume |
| **State** | `pairing_token`, `device`, `device_permission`, `device_health` |
| **Backend** | Token issue/verify endpoint; device registration |
| **Database** | `pairing_token`, `device`, `device_permission` (existing) |
| **API** | `POST /pairing/token`, `POST /pairing/claim` (extends `API_CONTRACT.md`) |
| **Notifications** | Father: "device linked"; Child: transparency acknowledgment |
| **Dependencies** | `S-ADM-002` family creation, `S-ADM-014` QR rotation, `S-ADM-004` permissions explainer |
| **Validation** | Token signature + expiry; child not already paired |
| **Error / empty / loading / success** | Expired token · no camera permission · scanning spinner · success screen with first location |
| **Security** | Triple lock; token rotation; no fingerprinting (schema forbids AAID/phone) |
| **Audit** | Pairing + unlock attempts (`mode_unlock_attempt`) |
| **Testing** | Unit: token lifecycle. Widget: both sides render + buttons act. Integration: pair → role resolved → child shell loads |
| **Status / missing** | Prototype screens exist; **no code** (F0 not started) |
| **Ambiguities** | None |

---

### 4.2 `S-ADM-010` — إدارة الأدوار (manage roles / delegation)

| Field | Content |
|---|---|
| **Purpose** | Father sets and changes the mother's delegation level; invites observer guardians |
| **Primary role** | Father (owner) — **exclusively** (ADR-035) |
| **Other affected** | Mother (notified), Guardian (observer), Child (indirect) |
| **Entry screens** | `SCR-FAT-027` members, `SCR-FAT-031` mother level, `SCR-FAT-008` invite |
| **Inputs** | member id, target `perm_level` |
| **Outputs** | updated `member.permission_level`, audit entry, notification |
| **Settings** | Default level = **PARTNER** (doc 20) |
| **Business rules** | OWNER always FULL (schema CHECK) · GUARDIAN pinned OBSERVER (CHECK) · **downgrade needs double confirmation** · three rights never graded: SOS receipt, contact/chat with children, seeing location · **editing the level itself is owner-only even at FULL** (ADR-035) |
| **Permissions** | `DELEGATION_EDIT` = owner-only |
| **State** | `member`, `audit_log` |
| **Backend** | Level mutation with owner assertion + audit write |
| **Database** | `member` (exists) — needs no new table |
| **API** | `PATCH /members/{id}/permission-level` |
| **Notifications** | Mother on **both** upgrade and downgrade, in trust language ("عبدالله يثق بك أكثر") |
| **Dependencies** | `S-ADM-009` invite, `S-ADM-011` accept, `S-ADM-034` audit |
| **Validation** | Cannot demote owner; cannot promote guardian |
| **Error / empty / loading / success** | Permission denied · single-member family · saving · confirmation sheet |
| **Security** | Server-side owner assertion (never client trust) |
| **Audit** | **Every** level change, append-only |
| **Testing** | Unit: matrix resolution per level. Widget: downgrade double-confirm. Cross-role: mother's UI degrades immediately |
| **Status / missing** | Law complete (doc 20 + ADR-035); no code |
| **Ambiguities** | Resolved by ADR-035 |

---

### 4.3 `S-SEC-001` — حد يومي للشاشة (daily screen-time cap)

| Field | Content |
|---|---|
| **Purpose** | Define the daily entertainment-time budget per child |
| **Primary role** | Father · Mother **FULL** only |
| **Other affected** | Child (countdown), Advisor (suggests) |
| **Entry screens** | Per-child limit screens + shared settings (with "active individual exceptions" list per ruling D) |
| **Inputs** | `Minutes` cap, per-child scope |
| **Outputs** | Effective policy for `TimeEngine.resolve()` |
| **Settings** | cap value · `dailyCapIncludesWallet` (**true** default) · `allowWalletOverflow` (**off** default) |
| **Business rules** | Ruling **B**: wallet minutes count inside the cap by default · Ruling **D**: per-child overrides shared · **S-1**: education/Qur'an/calls not countable · **P-2**: exhaustion ⇒ auto-lock of countable apps |
| **Permissions** | Father; Mother FULL; never child |
| **State** | policy store + derived countdown stream |
| **Backend** | Policy persistence + push to child device |
| **Database** | Needs a **screen-time policy table** — *not present in the 20-table schema* → phase 10 `ALTER`-style proposal (gap D-1) |
| **API** | `GET/PUT /children/{id}/time-policy` |
| **Notifications** | **T-5min** gentle warning (S-3); bedtime screen at night expiry (S-4) |
| **Dependencies** | `S-SEC-006` per-app wallets, `S-SEC-047` instant lock, modes (§3) |
| **Validation** | Non-negative `Minutes`; sane upper bound |
| **Error / empty / loading / success** | Sync failure (offline honest state) · no children yet · saving · toast + child-side reflection |
| **Security** | Child device is display-only; decisions resolve in signed local policy layer (P-1) |
| **Audit** | Cap changes logged |
| **Testing** | Unit: `TimeEngine.resolve()` ladder order. Widget: slider binds + persists. Cross-role: child countdown changes |
| **Status / missing** | Registry "موجودة"; **DB representation missing** |
| **Ambiguities** | None (rulings A–D sealed) |

---

### 4.4 `S-SEC-006` — حد لكل تطبيق على حدة (per-app wallet)

| Field | Content |
|---|---|
| **Purpose** | Give **every app its own time wallet** (Register **S-2**) |
| **Primary role** | Father · Mother FULL |
| **Other affected** | Child (per-app countdown), Advisor (suggests) |
| **Entry screens** | Per-child app list / app info card (`S-SEC-013` related) |
| **Inputs** | `appId`, `Minutes`, countable flag |
| **Outputs** | Per-app availability decision |
| **Settings** | per-app cap · `countable{appId: bool}` (entertainment=counted; Qur'an/education/calls=not) |
| **Business rules** | **Ruling A**: blocked ⇒ `false` **always**, regardless of balance · wallet is per `appId`, not global · mode-allowed apps still governed by remaining time (M-A #4) |
| **Permissions** | Father / Mother FULL |
| **State** | wallet per (child, app) |
| **Backend** | Wallet ledger + reconciliation |
| **Database** | **Missing**: `wallet` / `app_policy` tables (gap D-2) |
| **API** | `GET/PUT /children/{id}/apps/{appId}/policy` |
| **Notifications** | Per-app T-5 warning |
| **Dependencies** | `S-SEC-001`, `S-SEC-008` block/allow, modes |
| **Validation** | App must exist on device inventory |
| **Error/empty/loading/success** | Unknown app · no apps synced · loading · applied |
| **Security** | Blocked list readable only by `FatherSession` (P-3) |
| **Audit** | Policy changes |
| **Testing** | Unit: blocked-app invariant (property test: no balance value unlocks it) |
| **Status / missing** | "جديدة" — new build; DB missing |
| **Ambiguities** | None |

---

### 4.5 `S-SEC-004` — طلب وقت إضافي (extra-time request) — **cross-role loop**

| Field | Content |
|---|---|
| **Purpose** | Child asks for more time; parent decides; effect is immediate and visible |
| **Primary role** | Child (initiates) |
| **Other affected** | Father (decides), Mother **②/③** (may approve, ≤30 min per doc 20), Advisor (may suggest) |
| **Entry screens** | Child request sheet → parent request inbox / alert |
| **Inputs** | requested `Minutes`, reason |
| **Outputs** | approve → grant; reject → reason; **both** visible to child |
| **Settings** | mother approval ceiling (≤30 min) · quiet-hours behavior |
| **Business rules** | **Ruling C**: a manual grant intersecting a scheduled mode must raise the conflict dialog with `complete` \| `freeze` chosen at grant time · grant respects cap unless `allowWalletOverflow` · **Rule 24**: approval must actually deposit and reflect on the child side |
| **Permissions** | Mother ① cannot approve |
| **State** | request entity + grant entity |
| **Backend** | Request queue; grant application; push |
| **Database** | **Missing**: `time_request`, `time_grant` (gap D-3) |
| **API** | `POST /time-requests`, `POST /time-requests/{id}/decision` |
| **Notifications** | Parent: new request (urgency tier 2) · Child: decision + new balance |
| **Dependencies** | `S-SEC-001`, `S-SEC-047`, modes, `PolicyEngine` |
| **Validation** | Ceiling per approver level; duplicate-request throttle |
| **Error/empty/loading/success** | Offline queued · no pending requests · deciding · toast + balance change |
| **Security** | Child cannot self-approve; server asserts approver level |
| **Audit** | Every decision + approver identity |
| **Testing** | Integration: request → mother② approve → child balance +N → audit row |
| **Status / missing** | Registry "موجودة"; DB + loop closure missing |
| **Ambiguities** | Whether mother ③ also has the 30-min ceiling → **clarify with owner** (doc 20 states the ceiling under level ②) |

---

### 4.6 `S-SEC-005` — مكافأة وقت بالإنجاز (earn minutes by achievement)

| Field | Content |
|---|---|
| **Purpose** | One of the five constitutionally protected earning channels |
| **Primary role** | Child (earns) |
| **Other affected** | Father (sets amount, approves), Mother ②/③ (approves), Advisor (suggests) |
| **Entry screens** | Task/achievement screens + approval surfaces |
| **Inputs** | achievement evidence, reward `Minutes` (set at creation) |
| **Outputs** | wallet deposit via `PolicyEngine.earn()` |
| **Settings** | reward amount (**required at creation — no default**, E-2) |
| **Business rules** | **E-1** minutes only · **E-3** five channels, additive changes only · **E-5** instant deposit on approval · direct balance writes forbidden (R5) |
| **Permissions** | Approver = father or mother ②/③ |
| **State** | achievement → approval → wallet |
| **Backend** | `TaskApproved` event → deposit → push |
| **Database** | **Missing**: wallet/ledger + task tables (gap D-2/D-4) |
| **API** | `POST /achievements/{id}/approve` |
| **Notifications** | Child: "+N minutes" celebratory; father: pending approvals |
| **Dependencies** | `S-COM-034/035`, `PolicyEngine`, EDU studio services |
| **Validation** | `Minutes` type only (never raw int, R4) |
| **Error/empty/loading/success** | Approval conflict · nothing to approve · approving · instant balance change |
| **Security** | Server-side reward integrity; child cannot forge evidence |
| **Audit** | Every deposit with source channel |
| **Testing** | CI integration walking **all five** channels: create → complete → approve → deposit (E-3 mandate) |
| **Status / missing** | Law complete; no code; DB missing |
| **Ambiguities** | Interaction with `S-EDU-030/032/033` legacy naming → **ADR-036** |

---

### 4.7 `S-COM-035` — ربط المهمة بمكافأة (link task to reward)

| Field | Content |
|---|---|
| **Purpose** | Attach a father-set minute reward to a family task |
| **Primary role** | Father |
| **Other affected** | Child (earner), **Mother (assignee without minutes — E-4)**, Advisor (suggests) |
| **Entry screens** | `SCR-FAT-055` (create task with reward), `SCR-FAT-045` (assign + reward) |
| **Inputs** | task, assignee, `Minutes` |
| **Outputs** | task with reward contract |
| **Settings** | reward amount (required), due date, reminder |
| **Business rules** | **E-4**: a task assigned to the mother is a "help request 🤝" + thanks in Moments — it **never** passes through `RewardService` · child tasks always carry father-set minutes |
| **Permissions** | Father; Mother ②/③ may add/edit tasks |
| **State** | task entity + reward link |
| **Backend** | Task CRUD + reward binding |
| **Database** | **Missing**: `task`, `task_assignment` (gap D-4) |
| **API** | `POST /tasks`, `PATCH /tasks/{id}` |
| **Notifications** | Assignee notified; child sees reward up-front |
| **Dependencies** | `S-COM-032/033/034`, `S-SEC-005` |
| **Validation** | Assignee type decides whether a reward field is even permitted |
| **Error/empty/loading/success** | Invalid assignee/reward combo · no tasks · saving · task appears both sides |
| **Security** | Reward amount server-validated |
| **Audit** | Task creation + reward value |
| **Testing** | Unit: mother-assignee path has **no** reward field. Widget: reward is mandatory for child tasks |
| **Status / missing** | Screens exist; **screen notes still say "مكافأة نقاط/وقت"** → ADR-036 |
| **Ambiguities** | Naming only (ADR-036) |

---

### 4.8 `S-SEC-026` — زر الاستغاثة (SOS button)

| Field | Content |
|---|---|
| **Purpose** | The product's highest-priority safety guarantee |
| **Primary role** | Child (triggers) |
| **Other affected** | Father, Mother (**all levels**), Guardian (**all**), national emergency (escalation) |
| **Entry screens** | `SCR-CHD-005` button, `SCR-CHD-006` in-progress, `SCR-FAT-018` alert |
| **Inputs** | 3-second press |
| **Outputs** | location + audio broadcast, siren piercing silent mode, live map |
| **Settings** | escalation ladder delays + enable/disable (father, `SCR-FAT-028`) |
| **Business rules** | **P-4**: works with **no internet, expired time, expired subscription** · **R9/R11**: never gated, never disabled, never locked · **P-5**: escalation to backup contact then national number |
| **Permissions** | No permission can remove SOS receipt from any guardian (doc 20 ungraded right) |
| **State** | `sos_alert` (ACTIVE → ACKNOWLEDGED → RESOLVED) |
| **Backend** | Critical-alert channel outside every gate; LiveKit/audio path |
| **Database** | `sos_alert` (**exists**) |
| **API** | `POST /sos`, `POST /sos/{id}/ack` |
| **Notifications** | Critical alerts bypassing DND (special iOS/Android permissions) |
| **Dependencies** | `S-SEC-027` live location, `S-SEC-028` auto-call, `S-SEC-030` national link |
| **Validation** | Accidental-press protection (3s) without weakening reachability |
| **Error/empty/loading/success** | Offline → local siren + queued broadcast · n/a · broadcasting · acknowledged |
| **Security** | Cannot be suppressed by child, plan, mode, or lock |
| **Audit** | Full SOS lifecycle |
| **Testing** | Must pass with subscription expired, time expired, and airplane mode (three separate tests) |
| **Status / missing** | Screens + table exist; channel not built |
| **Ambiguities** | None |

---

### 4.9 `S-SEC-047` — قفل فوري للجهاز (instant lock)

| Field | Content |
|---|---|
| **Purpose** | Top of the priority ladder — immediate protective lock |
| **Primary role** | Father |
| **Other affected** | **Mother FULL — allowed (ADR-035)**, Child (locked), Advisor (may suggest) |
| **Entry screens** | Child profile quick actions / lock control |
| **Inputs** | target child/device, optional timer (`S-SEC-049`) |
| **Outputs** | lock overlay on child device |
| **Settings** | timer duration; internet-only variant (`S-SEC-048`) |
| **Business rules** | **Instant lock overrides everything**, including active modes (§2/§3 ladders) · **never** locks chat / Qur'an / SOS (R11) · father can reverse a mother's lock; **father wins** on simultaneous conflict (ADR-035) |
| **Permissions** | `INSTANT_LOCK`: father + mother FULL |
| **State** | lock state + resolver short-circuit |
| **Backend** | Lock command push + reconciliation on reconnect |
| **Database** | **Missing**: lock-state persistence (gap D-5) |
| **API** | `POST /children/{id}/lock`, `DELETE …/lock` |
| **Notifications** | Child: honest lock reason · Father: "mother locked X" |
| **Dependencies** | TimeEngine ladder, modes, `S-SEC-048/049` |
| **Validation** | Cannot lock exempt surfaces |
| **Error/empty/loading/success** | Offline (queued, honest) · n/a · locking · overlay confirmed |
| **Security** | Child cannot dismiss; anti-tamper interplay (owner-only switches) |
| **Audit** | Actor, target, timestamp, reversal — always |
| **Testing** | Unit: exempt surfaces stay reachable while locked. Cross-role: mother lock → father sees + can reverse |
| **Status / missing** | No code; conflict-resolution semantics newly settled (ADR-035) |
| **Ambiguities** | Resolved by ADR-035 |

---

### 4.10 `S-COM-001` — محادثة عائلية جماعية (family group chat)

| Field | Content |
|---|---|
| **Purpose** | The family's untouchable communication right |
| **Primary role** | All primary actors |
| **Other affected** | Guardian (per invite) |
| **Entry screens** | `SCR-FAT-021/022`, `SCR-CHD-007/…` |
| **Inputs** | messages, media, voice notes |
| **Outputs** | delivered + read state |
| **Settings** | notification preferences only — **no disable switch** |
| **Business rules** | **C-1** never locked (exempt from TimeEngine, even at expiry/lock) · **C-2** E2EE, visibly stated · **C-3** 15-minute edit + delete-for-all · **C-6** media stays in the family circle · **R9** never subscription-gated |
| **Permissions** | Membership by family, not by level |
| **State** | `conversation`, `message` |
| **Backend** | E2EE relay (ciphertext only) |
| **Database** | `conversation`, `message` (**exist**) |
| **API** | send/edit/delete/sync endpoints |
| **Notifications** | Standard tier; check-in calls use critical tier (C-4) |
| **Dependencies** | `S-COM-002` direct, media services, contact policy (P-9) |
| **Validation** | Edit window enforced server-side |
| **Error/empty/loading/success** | Offline queue · empty conversation (SHR-006 template) · loading · sent/read ticks |
| **Security** | Server cannot read; no external sharing |
| **Audit** | Message metadata only (no surveillance archive) |
| **Testing** | Must remain usable with time expired **and** subscription expired |
| **Status / missing** | Screens + tables exist; E2EE transport not built |
| **Ambiguities** | None |

---

### 4.11 `S-AIC-003` — تقييم درجة الخطورة (risk scoring → alert pipeline)

| Field | Content |
|---|---|
| **Purpose** | Turn detected events into ranked, excerpt-based parent alerts |
| **Primary role** | Advisor (SYSTEM) |
| **Other affected** | Father (decides), Mother (notified per `S-AIC-029`), Child (transparency) |
| **Entry screens** | `SCR-FAT-019` alert center, `SCR-FAT-020` alert detail |
| **Inputs** | `FamilyEvent` stream (anonymized on device, Rule 26) |
| **Outputs** | `ai_event` + ranked alert, `ai_confidence` tier |
| **Settings** | AI level + monitoring scope per child — **father-only** (`S-ADM-033`, doc 20) |
| **Business rules** | **Rule 26**: no in-app inference; gateway repositories only · `S-AIC-006`: excerpt not archive · **Rule 23**: alerts emitted by a real pipeline, never planted · A-6 anonymity · three urgency tiers (`S-ADM-028`) |
| **Permissions** | Child never configures; mother informed, not in control |
| **State** | `ai_event`, `ai_suggestion` |
| **Backend** | Detection + scoring server-side |
| **Database** | `ai_event`, `ai_suggestion` (**exist**) |
| **API** | `GET /insights/alerts`, `POST /suggestions/{id}/decision` |
| **Notifications** | Tiered; critical patterns escalate |
| **Dependencies** | `S-AIC-001/002/004/005/006`, `S-ADM-033`, `S-ADM-035` |
| **Validation** | Confidence tier required; no verse generation (A-4) |
| **Error/empty/loading/success** | Gateway unavailable → honest empty state · no alerts · loading · decision recorded |
| **Security** | Identity abstraction before events leave the device |
| **Audit** | Father decisions on suggestions |
| **Testing** | Mock repo reproduces the frozen prototype's alerts exactly (Rule 26 last clause) |
| **Status / missing** | Mock-first build; no gateway |
| **Ambiguities** | None here (delegated-agent tension is separate → ADR-038) |

---

### 4.12 `S-ADM-034` — سجل التدقيق (audit log)

| Field | Content |
|---|---|
| **Purpose** | Tamper-proof record of every consequential action |
| **Primary role** | Father (owner-only screen) |
| **Other affected** | Mother (her level changes recorded), Advisor (its actions recorded per A-5) |
| **Entry screens** | Audit log screen (RoleGuard owner-only) |
| **Inputs** | domain events |
| **Outputs** | append-only entries |
| **Settings** | Retention — **must not offer deletion** |
| **Business rules** | **R10**: repository interface contains **no** `update`/`delete` · wipe flow writes an audit entry · "forget button" never touches the audit log · ADR-035: conflicts + overrides recorded |
| **Permissions** | Owner read-only; system append |
| **State** | `audit_log` |
| **Backend** | Append endpoint + query |
| **Database** | `audit_log` (**exists**) |
| **API** | `GET /audit` (+ internal append) |
| **Notifications** | None |
| **Dependencies** | Every mutating service |
| **Validation** | Immutability enforced at API + DB level |
| **Error/empty/loading/success** | Fetch failure · empty log · loading · list |
| **Security** | Non-owner access denied centrally by RoleGuard |
| **Audit** | It *is* the audit |
| **Testing** | Static check: audit repository has no update/delete symbols (CI) |
| **Status / missing** | Table exists; interface/UI not built |
| **Ambiguities** | Retention duration → minor, owner may set later |

---

## 5. Conflicts & decisions raised by phase 3

| ID | Item | Status |
|---|---|---|
| **ADR-036** | Registry points/XP labels vs minutes-only law | **RESOLVED-BY-OWNER-AUDIT** — legacy naming; map `S-EDU-030`→minutes ledger · `S-EDU-032`→`SUPERSEDED-BY-E-1` · `S-EDU-033`→badges only |
| **ADR-037** | `S-EDU-036` vs G-8 | **RESOLVED-BY-OWNER-AUDIT** — cooperative challenges, no ranking; P2 post-v1 |
| **ADR-038** | Delegated agent vs AI execute | **RESOLVED-BY-OWNER-AUDIT** — `RulesEngine` ≠ `AiSuggestion`; auto-run under conditions (a–f) |
| **T-1** (traceability) | `S-SEC-058/059/060` rebound off tombstone FAT-039 | **Resolved** — primary host **`SCR-FAT-085`**; status **`SCR-CHD-004`** / **`SCR-FAT-063`**; focus **`SCR-CHD-018`** |
| **D-1…D-5** (data) | No tables for screen-time policy, per-app wallets/ledger, time requests/grants, tasks, lock state | Phase 10 `ALTER`-style proposals |

### 5.1 ADR-038 architecture note (settled)

Two systems, no conflict: (1) AI gateways produce `AiSuggestion` with approve/reject only; (2) father-authored deterministic **`RulesEngine`** may auto-execute under ADR-038 conditions (a–f). RulesEngine lives **outside** Advisor/Insights/Tutor repositories.

---

## 6. Batching plan for the remaining 228 services

Dependency-ordered so each batch consumes settled semantics:

| Batch | Scope | Services (approx) | Blocked by |
|---|---|---:|---|
| **B1** | ADM onboarding + members + devices + notifications + privacy (remaining) | 37 | — |
| **B2** | SEC time/apps/web/location/emergency (remaining) | 45 | D-1…D-3 proposals |
| **B3** | COM chat/calls/media/contacts/calendar/chores (remaining) | 36 | — |
| **B4** | EDU subjects/homework/assessment/tutor/adaptive/focus + studio | 58 | ADR-036 for reward-linked items |
| **B5** | EDU motivation + Qur'an | 8 | **ADR-036 / ADR-037** |
| **B6** | AIC detection/patterns/knowledge/advisor/assistant | 29 | — |
| **B7** | AIC delegated agent | 5 | **ADR-038** |
| **B8** | SEC monitoring/social/anti-tamper/driving/school-mode/reports | 30 | T-1 host screen |

*(Batch sizes overlap where a subsystem spans concerns; total reconciles to 228 unspecified + 12 specified = 240.)*

---

## 7. Annex A — derived service index (all 240)

Generated from `_REGISTRY` on 2026-09-19. `Screens` and `Journeys` are **reverse-derived** (the registry's own `screens` column is empty for every row). Tombstoned `SCR-FAT-039` is marked `†`.

| Service | Dom | Subsystem | Name | P | Status | W | Screens (derived) | Journeys (derived) |
|---|---|---|---|---|---|---|---|---|
| `S-SEC-001` | SEC | أ إدارة وقت الشاشة | حد يومي للشاشة | P0 | موجودة | 2 | CHD-021 FAT-032 FAT-085 | FAT-15 FAT-44 |
| `S-SEC-002` | SEC | أ إدارة وقت الشاشة | جداول ذكية | P0 | موجودة | 2 | FAT-032 FAT-085 | FAT-15 FAT-44 |
| `S-SEC-003` | SEC | أ إدارة وقت الشاشة | جدول وقت النوم | P0 | موجودة | 2 | CHD-021 FAT-032 FAT-085 | FAT-15 FAT-44 |
| `S-SEC-004` | SEC | أ إدارة وقت الشاشة | طلب وقت إضافي | P0 | موجودة | 2 | CHD-020 FAT-033 | CHD-06 MOT-07 |
| `S-SEC-005` | SEC | أ إدارة وقت الشاشة | مكافأة وقت بالإنجاز | P0 | موجودة | 2 | CHD-019 FAT-033 | MOT-07 |
| `S-SEC-006` | SEC | أ إدارة وقت الشاشة | حد لكل تطبيق على حدة | P0 | جديدة | 2 | FAT-032 FAT-085 | FAT-15 FAT-44 |
| `S-SEC-007` | SEC | أ إدارة وقت الشاشة | وقت التعليم لا يُحتسب | P0 | جديدة | 2 | CHD-018 FAT-032 | FAT-15 |
| `S-SEC-008` | SEC | ب التحكم بالتطبيقات | حظر/سماح تطبيق | P0 | موجودة | 2 | FAT-034 | FAT-16 |
| `S-SEC-009` | SEC | ب التحكم بالتطبيقات | قواعد فئات التطبيقات | P0 | موجودة | 2 | FAT-034 | FAT-16 |
| `S-SEC-010` | SEC | ب التحكم بالتطبيقات | موافقة على التطبيقات الجديدة | P0 | موجودة | 2 | FAT-035 | FAT-16 |
| `S-SEC-011` | SEC | ب التحكم بالتطبيقات | تنبيه تثبيت تطبيق | P0 | جديدة | 2 | FAT-035 | FAT-16 |
| `S-SEC-012` | SEC | ب التحكم بالتطبيقات | تنبيهات الألعاب | P1 | موجودة | 2 | FAT-034 | — |
| `S-SEC-013` | SEC | ب التحكم بالتطبيقات | بطاقة معلومات التطبيق | P1 | جديدة | 2 | FAT-034 | — |
| `S-SEC-014` | SEC | ج فلترة الإنترنت | فلترة ٢٩ فئة | P0 | موجودة | 2 | FAT-036 | FAT-17 |
| `S-SEC-015` | SEC | ج فلترة الإنترنت | استثناءات | P0 | موجودة | 2 | FAT-036 | FAT-17 |
| `S-SEC-016` | SEC | ج فلترة الإنترنت | فرض البحث الآمن | P0 | جديدة | 2 | FAT-036 | FAT-17 |
| `S-SEC-017` | SEC | ج فلترة الإنترنت | حجب التصفح الخفي | P0 | موجودة | 2 | FAT-036 | FAT-17 |
| `S-SEC-018` | SEC | ج فلترة الإنترنت | فلترة الراوتر | P2 | موجودة | 3 | FAT-075 FAT-078 | FAT-38 FAT-40 |
| `S-SEC-019` | SEC | د الموقع والمناطق الآمنة | تتبع لحظي | P0 | موجودة | 1 | FAT-006 FAT-013 FAT-014 | FAT-06 FAT-07 MOT-03 MOT-06 |
| `S-SEC-020` | SEC | د الموقع والمناطق الآمنة | سجل المواقع | P0 | موجودة | 1 | FAT-015 | FAT-07 |
| `S-SEC-021` | SEC | د الموقع والمناطق الآمنة | مناطق آمنة | P0 | موجودة | 1 | FAT-016 FAT-017 | FAT-08 |
| `S-SEC-022` | SEC | د الموقع والمناطق الآمنة | تنبيه وصول/مغادرة | P0 | موجودة | 1 | FAT-016 FAT-017 | FAT-08 MOT-06 |
| `S-SEC-023` | SEC | د الموقع والمناطق الآمنة | الأماكن المتكررة | P1 | موجودة | 1 | FAT-015 | — |
| `S-SEC-024` | SEC | د الموقع والمناطق الآمنة | تنبيه عدم الوصول | P0 | جديدة | 1 | FAT-017 | FAT-08 MOT-06 |
| `S-SEC-025` | SEC | د الموقع والمناطق الآمنة | مستوى البطارية | P0 | جديدة | 1 | CHD-004 FAT-013 FAT-014 | CHD-02 FAT-06 FAT-07 |
| `S-SEC-026` | SEC | هـ الطوارئ والاستغاثة | زر الاستغاثة | P0 | موجودة | 1 | CHD-005 FAT-018 FAT-028 | CHD-03 FAT-09 MOT-05 |
| `S-SEC-027` | SEC | هـ الطوارئ والاستغاثة | بث الموقع اللحظي | P0 | موجودة | 1 | CHD-005 CHD-006 FAT-018 | CHD-03 FAT-09 MOT-05 |
| `S-SEC-028` | SEC | هـ الطوارئ والاستغاثة | اتصال تلقائي بالأب | P0 | جديدة | 1 | CHD-006 FAT-018 | CHD-03 FAT-09 MOT-05 |
| `S-SEC-029` | SEC | هـ الطوارئ والاستغاثة | جهات اتصال خارج العائلة | P0 | جديدة | 1 | FAT-028 | — |
| `S-SEC-030` | SEC | هـ الطوارئ والاستغاثة | ربط الطوارئ الوطنية | P0 | جديدة | 1 | FAT-018 FAT-028 | FAT-09 |
| `S-SEC-031` | SEC | هـ الطوارئ والاستغاثة | الاستغاثة تعمل دائمًا | P0 | جديدة | 1 | CHD-005 | CHD-03 |
| `S-SEC-032` | SEC | و مراقبة المحتوى الذكية | كشف الكلمات المريبة | P0 | موجودة | 3 | FAT-065 FAT-066 | FAT-31 |
| `S-SEC-033` | SEC | و مراقبة المحتوى الذكية | تحليل المشاعر | P0 | موجودة | 3 | FAT-065 FAT-066 | FAT-31 |
| `S-SEC-034` | SEC | و مراقبة المحتوى الذكية | كشف العامية والعربيزي | P0 | موجودة | 3 | FAT-065 | FAT-31 |
| `S-SEC-035` | SEC | و مراقبة المحتوى الذكية | كشف الصور الحساسة | P1 | موجودة | 3 | FAT-065 | FAT-31 |
| `S-SEC-036` | SEC | و مراقبة المحتوى الذكية | منع الرسائل الجنسية | P1 | موجودة | 3 | FAT-065 | FAT-31 |
| `S-SEC-037` | SEC | و مراقبة المحتوى الذكية | قائمة مراقبة جهات الاتصال | P1 | موجودة | 3 | FAT-067 | FAT-32 |
| `S-SEC-038` | SEC | ز مراقبة منصات التواصل | مراقبة واتساب | P1 | جديدة | 3 | FAT-068 | FAT-32 |
| `S-SEC-039` | SEC | ز مراقبة منصات التواصل | مراقبة سناب شات | P1 | جديدة | 3 | FAT-068 | FAT-32 |
| `S-SEC-040` | SEC | ز مراقبة منصات التواصل | مراقبة إنستغرام | P1 | جديدة | 3 | FAT-068 | FAT-32 |
| `S-SEC-041` | SEC | ز مراقبة منصات التواصل | مراقبة تيك توك | P1 | جديدة | 3 | FAT-068 | FAT-32 |
| `S-SEC-042` | SEC | ح مقاومة التحايل | منع إلغاء التثبيت | P0 | موجودة | 2 | FAT-038 | FAT-19 |
| `S-SEC-043` | SEC | ح مقاومة التحايل | كشف VPN | P0 | جديدة | 2 | FAT-038 | FAT-19 |
| `S-SEC-044` | SEC | ح مقاومة التحايل | كشف تعطيل الأذونات | P0 | جديدة | 2 | FAT-038 | FAT-19 |
| `S-SEC-045` | SEC | ح مقاومة التحايل | كشف تغيير وقت الجهاز | P0 | جديدة | 2 | FAT-038 | FAT-19 |
| `S-SEC-046` | SEC | ح مقاومة التحايل | كشف الوضع الآمن / المستخدم الثانوي | P0 | جديدة | 2 | FAT-038 | FAT-19 |
| `S-SEC-047` | SEC | ط القفل الفوري | قفل فوري للجهاز | P0 | موجودة | 2 | FAT-037 | FAT-18 |
| `S-SEC-048` | SEC | ط القفل الفوري | إيقاف الإنترنت فقط | P0 | موجودة | 2 | FAT-037 | FAT-18 |
| `S-SEC-049` | SEC | ط القفل الفوري | قفل مؤقت بمؤقت | P1 | جديدة | 2 | FAT-037 | FAT-18 |
| `S-SEC-050` | SEC | ي التقارير والتحليلات | تقارير الاستخدام | P0 | موجودة | 3 | FAT-069 | FAT-33 |
| `S-SEC-051` | SEC | ي التقارير والتحليلات | تحليلات متقدمة | P1 | موجودة | 3 | FAT-069 | FAT-33 |
| `S-SEC-052` | SEC | ي التقارير والتحليلات | الاحتفاظ ٣٠ يومًا | P0 | جديدة | 3 | FAT-069 | FAT-33 |
| `S-SEC-053` | SEC | ي التقارير والتحليلات | الملخص الأسبوعي بالبريد | P1 | جديدة | 3 | FAT-073 | FAT-36 |
| `S-SEC-054` | SEC | ي التقارير والتحليلات | المقارنة مع الأقران | P3 | موجودة | 3 | FAT-075 FAT-081 | FAT-38 |
| `S-SEC-055` | SEC | ك السلامة الحركية والقيادة | كشف الحوادث | P2 | جديدة | 3 | FAT-075 FAT-077 | FAT-38 FAT-39 |
| `S-SEC-056` | SEC | ك السلامة الحركية والقيادة | تقرير القيادة | P2 | موجودة | 3 | FAT-075 FAT-077 | FAT-38 FAT-39 |
| `S-SEC-057` | SEC | ك السلامة الحركية والقيادة | تنبيه استخدام الجوال أثناء القيادة | P2 | جديدة | 3 | FAT-075 FAT-077 | FAT-38 FAT-39 |
| `S-SEC-058` | SEC | ل وضع المدرسة | جدول وضع المدرسة | P0 | موجودة | 2 | FAT-039† | FAT-20 |
| `S-SEC-059` | SEC | ل وضع المدرسة | التفعيل التلقائي بالموقع | P1 | جديدة | 2 | FAT-039† | FAT-20 |
| `S-SEC-060` | SEC | ل وضع المدرسة | حالة Focus | P0 | موجودة | 2 | CHD-018 FAT-039† | CHD-09 FAT-20 |
| `S-COM-001` | COM | أ المحادثات | محادثة عائلية جماعية | P0 | موجودة | 1 | CHD-007 CHD-008 FAT-021 FAT-022 | CHD-04 FAT-11 MOT-04 |
| `S-COM-002` | COM | أ المحادثات | محادثة فردية | P0 | موجودة | 1 | CHD-007 CHD-008 FAT-021 FAT-022 | CHD-04 FAT-11 MOT-04 |
| `S-COM-003` | COM | أ المحادثات | مجموعات فرعية | P0 | موجودة | 1 | FAT-021 | — |
| `S-COM-004` | COM | أ المحادثات | الرد على رسالة | P0 | موجودة | 1 | CHD-008 FAT-022 | FAT-11 |
| `S-COM-005` | COM | أ المحادثات | تأكيد القراءة | P0 | موجودة | 1 | CHD-008 FAT-022 | FAT-11 |
| `S-COM-006` | COM | أ المحادثات | تعديل الرسالة | P0 | جديدة | 1 | CHD-008 FAT-022 | FAT-11 |
| `S-COM-007` | COM | أ المحادثات | حذف للجميع | P0 | جديدة | 1 | CHD-008 FAT-022 | FAT-11 |
| `S-COM-008` | COM | أ المحادثات | تثبيت رسالة | P1 | جديدة | 1 | FAT-022 | — |
| `S-COM-009` | COM | أ المحادثات | قفل المحادثة | P1 | موجودة | 1 | CHD-008 | — |
| `S-COM-010` | COM | ب المكالمات | مكالمة صوتية | P0 | موجودة | 1 | CHD-009 FAT-023 | CHD-04 FAT-12 MOT-04 |
| `S-COM-011` | COM | ب المكالمات | مكالمة فيديو | P0 | موجودة | 1 | CHD-009 FAT-023 | CHD-04 FAT-12 MOT-04 |
| `S-COM-012` | COM | ب المكالمات | مكالمة جماعية | P1 | موجودة | 1 | FAT-023 | — |
| `S-COM-013` | COM | ب المكالمات | سجل المكالمات | P0 | جديدة | 1 | FAT-024 | FAT-12 |
| `S-COM-014` | COM | ب المكالمات | الاتصال يعمل دائمًا | P0 | جديدة | 1 | CHD-009 | CHD-04 FAT-12 |
| `S-COM-015` | COM | ب المكالمات | ألعاب ورسم أثناء المكالمة | P2 | جديدة | 3 | CHD-031 CHD-036 | CHD-16 CHD-17 |
| `S-COM-016` | COM | ج الوسائط والملفات | صور وفيديو | P0 | موجودة | 2 | CHD-023 FAT-086 | CHD-11 FAT-45 |
| `S-COM-017` | COM | ج الوسائط والملفات | الملفات | P0 | موجودة | 2 | CHD-023 | CHD-11 |
| `S-COM-018` | COM | ج الوسائط والملفات | الرسائل الصوتية | P0 | موجودة | 2 | CHD-023 | CHD-11 |
| `S-COM-019` | COM | ج الوسائط والملفات | تفريغ الرسالة الصوتية نصًا | P1 | جديدة | 2 | CHD-023 | CHD-11 |
| `S-COM-020` | COM | ج الوسائط والملفات | الملصقات والخلفيات | P2 | موجودة | 3 | CHD-031 CHD-037 | CHD-16 CHD-17 |
| `S-COM-021` | COM | د دائرة الاتصال الآمنة | جهات اتصال خارجية بموافقة الأب | P0 | جديدة | 3 | FAT-070 | FAT-34 |
| `S-COM-022` | COM | د دائرة الاتصال الآمنة | طلب إضافة صديق | P0 | جديدة | 3 | CHD-030 FAT-071 | CHD-13 FAT-34 |
| `S-COM-023` | COM | د دائرة الاتصال الآمنة | حظر المجهولين تمامًا | P0 | جديدة | 3 | CHD-030 FAT-070 FAT-071 | CHD-13 FAT-34 |
| `S-COM-024` | COM | د دائرة الاتصال الآمنة | دائرة الأقارب | P0 | جديدة | 3 | FAT-070 | FAT-34 |
| `S-COM-025` | COM | د دائرة الاتصال الآمنة | جدول التواصل | P1 | جديدة | 3 | FAT-070 | FAT-34 |
| `S-COM-026` | COM | هـ التقويم العائلي | إضافة حدث | P0 | موجودة | 2 | FAT-052 FAT-053 | FAT-24 MOT-08 |
| `S-COM-027` | COM | هـ التقويم العائلي | تعديل/حذف حدث | P0 | موجودة | 2 | FAT-052 | FAT-24 |
| `S-COM-028` | COM | هـ التقويم العائلي | التقويم الهجري + الميلادي | P0 | جديدة | 2 | FAT-052 FAT-053 | FAT-24 |
| `S-COM-029` | COM | هـ التقويم العائلي | ألوان لكل فرد | P0 | جديدة | 2 | FAT-052 FAT-053 | FAT-24 |
| `S-COM-030` | COM | هـ التقويم العائلي | مواقيت الصلاة في التقويم | P0 | جديدة | 2 | FAT-052 FAT-053 | FAT-24 |
| `S-COM-031` | COM | هـ التقويم العائلي | الملخص اليومي/الأسبوعي | P1 | جديدة | 2 | FAT-052 | FAT-24 MOT-08 |
| `S-COM-032` | COM | و المهام والمسؤوليات | إنشاء مهمة وتذكير | P0 | موجودة | 2 | CHD-022 FAT-054 FAT-055 | CHD-12 FAT-25 MOT-08 |
| `S-COM-033` | COM | و المهام والمسؤوليات | إسناد مهمة لابن | P0 | جديدة | 2 | FAT-054 FAT-055 | FAT-25 |
| `S-COM-034` | COM | و المهام والمسؤوليات | تأكيد الإنجاز | P0 | جديدة | 2 | CHD-022 FAT-054 | CHD-12 FAT-25 MOT-08 |
| `S-COM-035` | COM | و المهام والمسؤوليات | ربط المهمة بمكافأة | P0 | جديدة | 2 | CHD-022 FAT-054 FAT-055 | CHD-12 FAT-25 |
| `S-COM-036` | COM | و المهام والمسؤوليات | ChoreAI | P2 | موجودة | 3 | FAT-075 FAT-082 | FAT-38 FAT-42 |
| `S-COM-037` | COM | ز الموقع في التواصل | بث الموقع اللحظي | P0 | موجودة | 2 | CHD-024 | CHD-11 |
| `S-COM-038` | COM | ز الموقع في التواصل | «أنا وصلت» بضغطة | P0 | جديدة | 2 | CHD-024 | CHD-11 |
| `S-COM-039` | COM | ز الموقع في التواصل | طلب موقع | P0 | جديدة | 2 | CHD-024 | CHD-11 |
| `S-EDU-001` | EDU | أ المواد والدروس | إضافة مادة | P0 | موجودة | 2 | FAT-048 | FAT-23 |
| `S-EDU-002` | EDU | أ المواد والدروس | عرض المواد | P0 | موجودة | 2 | CHD-012 FAT-048 | CHD-07 FAT-23 |
| `S-EDU-003` | EDU | أ المواد والدروس | إضافة درس | P0 | موجودة | 2 | FAT-048 | FAT-23 |
| `S-EDU-004` | EDU | أ المواد والدروس | عرض درس | P0 | موجودة | 2 | CHD-013 | CHD-07 |
| `S-EDU-005` | EDU | أ المواد والدروس | استيراد درس من مصدر خارجي | P0 | جديدة | 2 | CHD-013 FAT-048 | FAT-23 |
| `S-EDU-006` | EDU | أ المواد والدروس | مكتبة فيديو | P1 | موجودة | 2 | FAT-048 | — |
| `S-EDU-007` | EDU | ب الواجبات | إنشاء واجب | P0 | موجودة | 2 | FAT-049 | FAT-23 |
| `S-EDU-008` | EDU | ب الواجبات | عرض واجب | P0 | موجودة | 2 | CHD-014 | CHD-07 |
| `S-EDU-009` | EDU | ب الواجبات | إرسال واجب | P0 | موجودة | 2 | CHD-014 | CHD-07 |
| `S-EDU-010` | EDU | ب الواجبات | تصحيح تلقائي بالعقل | P0 | موجودة | 2 | CHD-014 FAT-050 | — |
| `S-EDU-011` | EDU | ب الواجبات | حالة الواجب | P0 | موجودة | 2 | CHD-014 FAT-050 | FAT-23 |
| `S-EDU-012` | EDU | ب الواجبات | تنبيه الواجب المتأخر | P0 | جديدة | 2 | FAT-050 | FAT-23 |
| `S-EDU-013` | EDU | ج الاختبارات والتقييم | إنشاء اختبار | P0 | موجودة | 2 | FAT-049 | FAT-23 |
| `S-EDU-014` | EDU | ج الاختبارات والتقييم | أداء اختبار | P0 | موجودة | 2 | CHD-015 | CHD-07 |
| `S-EDU-015` | EDU | ج الاختبارات والتقييم | نتائج الاختبار | P0 | موجودة | 2 | CHD-016 FAT-050 | CHD-07 FAT-23 |
| `S-EDU-016` | EDU | ج الاختبارات والتقييم | اختبار تحديد المستوى | P0 | موجودة | 2 | CHD-015 | CHD-07 |
| `S-EDU-017` | EDU | ج الاختبارات والتقييم | توليد أسئلة من الدرس | P0 | جديدة | 2 | FAT-049 | FAT-23 |
| `S-EDU-018` | EDU | ج الاختبارات والتقييم | تقارير فجوات المهارات | P1 | موجودة | 2 | FAT-050 | FAT-23 |
| `S-EDU-019` | EDU | د المعلم الذكي | معلم خصوصي ذكي | P0 | موجودة | 2 | CHD-017 | CHD-08 |
| `S-EDU-020` | EDU | د المعلم الذكي | شرح بالتدرّج لا بالجواب | P0 | جديدة | 2 | CHD-017 | CHD-08 |
| `S-EDU-021` | EDU | د المعلم الذكي | حل مسألة بالكاميرا | P1 | جديدة | 2 | CHD-017 | CHD-08 |
| `S-EDU-022` | EDU | د المعلم الذكي | توصيات مهارات | P1 | موجودة | 2 | CHD-017 | CHD-08 |
| `S-EDU-023` | EDU | د المعلم الذكي | كتابة إبداعية | P1 | موجودة | 2 | CHD-017 | CHD-08 |
| `S-EDU-024` | EDU | د المعلم الذكي | قصص تفاعلية | P2 | موجودة | 3 | CHD-031 CHD-033 | CHD-16 CHD-17 |
| `S-EDU-025` | EDU | هـ التعلّم التكيفي | تعلّم تكيفي | P0 | موجودة | 3 | CHD-028 | CHD-15 |
| `S-EDU-026` | EDU | هـ التعلّم التكيفي | تمارين متدرجة | P0 | موجودة | 3 | CHD-028 | CHD-15 |
| `S-EDU-027` | EDU | هـ التعلّم التكيفي | مسارات بصرية | P1 | موجودة | 3 | CHD-028 | CHD-15 |
| `S-EDU-028` | EDU | هـ التعلّم التكيفي | المراجعة المتباعدة | P0 | جديدة | 3 | CHD-029 | CHD-15 |
| `S-EDU-029` | EDU | هـ التعلّم التكيفي | كشف المفهوم المفقود | P1 | جديدة | 3 | CHD-028 | CHD-15 |
| `S-EDU-030` | EDU | و التحفيز والمكافآت | نقاط | P0 | موجودة | 2 | CHD-019 FAT-086 | CHD-10 FAT-45 |
| `S-EDU-031` | EDU | و التحفيز والمكافآت | شارات | P0 | موجودة | 2 | CHD-019 | CHD-10 |
| `S-EDU-032` | EDU | و التحفيز والمكافآت | استبدال النقاط بوقت شاشة | P0 | موجودة | 2 | CHD-019 | CHD-10 |
| `S-EDU-033` | EDU | و التحفيز والمكافآت | XP ومستويات | P0 | موجودة | 2 | CHD-012 CHD-019 | CHD-10 |
| `S-EDU-034` | EDU | و التحفيز والمكافآت | سلسلة الأيام المتتالية | P0 | جديدة | 2 | CHD-012 CHD-019 | CHD-10 |
| `S-EDU-035` | EDU | و التحفيز والمكافآت | تحديات يومية | P1 | موجودة | 2 | CHD-019 | CHD-10 |
| `S-EDU-036` | EDU | و التحفيز والمكافآت | أقسام تنافسية | P2 | موجودة | 3 | CHD-031 CHD-034 | CHD-16 CHD-17 |
| `S-EDU-037` | EDU | ز القرآن والتربية الإسلامية | تحفيظ القرآن | P0 | موجودة | 3 | CHD-025 FAT-072 | CHD-14 FAT-35 |
| `S-EDU-038` | EDU | ز القرآن والتربية الإسلامية | تلاوة القرآن | P0 | موجودة | 3 | CHD-025 | CHD-14 |
| `S-EDU-039` | EDU | ز القرآن والتربية الإسلامية | متابعة الحفظ ومراجعته | P0 | جديدة | 3 | CHD-026 FAT-072 | CHD-14 FAT-35 |
| `S-EDU-040` | EDU | ز القرآن والتربية الإسلامية | تصحيح التلاوة بالعقل | P2 | جديدة | 3 | CHD-032 FAT-075 | CHD-18 FAT-38 |
| `S-EDU-041` | EDU | ز القرآن والتربية الإسلامية | الأذكار والعبادات اليومية | P1 | جديدة | 3 | CHD-027 | CHD-14 |
| `S-EDU-042` | EDU | ح التركيز وبيئة الدراسة | وضع التركيز | P0 | موجودة | 2 | CHD-018 | CHD-09 |
| `S-EDU-043` | EDU | ح التركيز وبيئة الدراسة | مؤقّت التركيز | P0 | موجودة | 2 | CHD-018 | CHD-09 |
| `S-EDU-044` | EDU | ح التركيز وبيئة الدراسة | وقت التعليم مجاني دائمًا | P0 | قاعدة حاكمة | 2 | CHD-018 | CHD-09 |
| `S-EDU-045` | EDU | ح التركيز وبيئة الدراسة | جدول المذاكرة | P1 | جديدة | 2 | CHD-018 | CHD-09 |
| `S-EDU-046` | EDU | ح التركيز وبيئة الدراسة | تقرير التركيز للأب | P1 | جديدة | 2 | FAT-051 | — |
| `S-EDU-047` | EDU | ح التركيز وبيئة الدراسة | صوت خلفي للتركيز | P2 | جديدة | 3 | CHD-031 CHD-035 | CHD-16 CHD-17 |
| `S-EDU-048` | EDU | ط استوديو الأب | إنشاء من الكاميرا — تصوير صفحة الكتاب | P0 | جديدة | 2 | FAT-041 FAT-042 | FAT-21 |
| `S-EDU-049` | EDU | ط استوديو الأب | إنشاء من رابط | P0 | جديدة | 2 | FAT-041 | FAT-21 |
| `S-EDU-050` | EDU | ط استوديو الأب | إنشاء من ملف | P0 | جديدة | 2 | FAT-041 | FAT-21 |
| `S-EDU-051` | EDU | ط استوديو الأب | إنشاء من موضوع فقط | P0 | جديدة | 2 | FAT-041 | FAT-21 |
| `S-EDU-052` | EDU | ط استوديو الأب | إنشاء من شرح صوتي | P1 | جديدة | 2 | FAT-041 | FAT-21 |
| `S-EDU-053` | EDU | ط استوديو الأب | استيراد من مكتبة المجتمع | P0 | جديدة | 2 | FAT-041 FAT-046 | FAT-22 |
| `S-EDU-054` | EDU | ط استوديو الأب | توليد درس | P0 | جديدة | 2 | FAT-043 FAT-044 | FAT-21 |
| `S-EDU-055` | EDU | ط استوديو الأب | توليد واجب | P0 | جديدة | 2 | FAT-043 | FAT-21 |
| `S-EDU-056` | EDU | ط استوديو الأب | توليد اختبار | P0 | جديدة | 2 | FAT-043 FAT-044 | FAT-21 |
| `S-EDU-057` | EDU | ط استوديو الأب | توليد بطاقات حفظ | P0 | جديدة | 2 | FAT-043 | FAT-21 |
| `S-EDU-058` | EDU | ط استوديو الأب | توليد تحدٍّ بمكافأة | P0 | جديدة | 2 | FAT-043 FAT-045 | FAT-21 |
| `S-EDU-059` | EDU | ط استوديو الأب | توليد لعبة مراجعة | P1 | جديدة | 2 | FAT-043 | FAT-21 |
| `S-EDU-060` | EDU | ط استوديو الأب | توليد ورد حفظ قرآني | P0 | جديدة | 2 | FAT-043 | FAT-21 |
| `S-EDU-061` | EDU | ط استوديو الأب | بناء مسار تعليمي | P1 | جديدة | 2 | FAT-047 | FAT-23 |
| `S-EDU-062` | EDU | ط استوديو الأب | إنشاء مشروع بمراحل | P2 | جديدة | 3 | FAT-075 FAT-084 | FAT-38 FAT-43 |
| `S-EDU-063` | EDU | ط استوديو الأب | النشر في مكتبة المجتمع | P0 | جديدة | 2 | FAT-046 | FAT-22 |
| `S-EDU-064` | EDU | ط استوديو الأب | شاشة «اقتراحات العقل اليوم» | P0 | جديدة | 2 | FAT-040 | FAT-21 |
| `S-EDU-065` | EDU | ط استوديو الأب | إسناد المحتوى وتحديد المكافأة | P0 | جديدة | 2 | FAT-045 | FAT-21 |
| `S-AIC-001` | AIC | أ محرك الرصد | مصنّف الكلمات الخطرة | P0 | موجودة | 1 | FAT-020 | FAT-10 |
| `S-AIC-002` | AIC | أ محرك الرصد | رصد الأحداث من كل المجالات | P0 | جديدة | 1 | FAT-019 FAT-029 | FAT-10 |
| `S-AIC-003` | AIC | أ محرك الرصد | تقييم درجة الخطورة | P0 | جديدة | 1 | FAT-011 FAT-013 FAT-019 FAT-020 FAT-029 | FAT-06 FAT-10 MOT-03 |
| `S-AIC-004` | AIC | أ محرك الرصد | كشف الصور الحساسة | P0 | موجودة | 1 | FAT-029 | — |
| `S-AIC-005` | AIC | أ محرك الرصد | قائمة القواعد القابلة للتحديث | P0 | جديدة | 1 | FAT-029 | — |
| `S-AIC-006` | AIC | أ محرك الرصد | مقتطف التنبيه لا الأرشيف | P0 | قاعدة حاكمة | 1 | FAT-019 FAT-020 | FAT-10 |
| `S-AIC-007` | AIC | ب محرك الأنماط والشذوذ | بناء خط الأساس | P0 | جديدة | 2 | FAT-062 | FAT-29 |
| `S-AIC-008` | AIC | ب محرك الأنماط والشذوذ | كشف شذوذ النوم والنشاط | P0 | موجودة | 2 | FAT-062 | FAT-29 |
| `S-AIC-009` | AIC | ب محرك الأنماط والشذوذ | كشف شذوذ التواصل | P0 | جديدة | 2 | FAT-062 | FAT-29 |
| `S-AIC-010` | AIC | ب محرك الأنماط والشذوذ | كشف شذوذ التعليم | P0 | جديدة | 2 | FAT-062 | FAT-29 |
| `S-AIC-011` | AIC | ب محرك الأنماط والشذوذ | مؤشر الثقة | P0 | جديدة | 2 | FAT-062 | FAT-29 |
| `S-AIC-012` | AIC | ج مخزن المعرفة العائلية | الخط الزمني الموحّد لكل فرد | P0 | جديدة | 2 | FAT-063 | FAT-29 |
| `S-AIC-013` | AIC | ج مخزن المعرفة العائلية | ملف الأنماط السلوكية | P0 | جديدة | 2 | FAT-063 | FAT-29 |
| `S-AIC-014` | AIC | ج مخزن المعرفة العائلية | خريطة الشبكة الاجتماعية | P1 | جديدة | 2 | FAT-064 | FAT-29 |
| `S-AIC-015` | AIC | ج مخزن المعرفة العائلية | خريطة المسار التعليمي | P0 | جديدة | 2 | FAT-064 | FAT-29 |
| `S-AIC-016` | AIC | ج مخزن المعرفة العائلية | الربط عبر المجالات | P0 | جديدة | 2 | FAT-063 | FAT-29 |
| `S-AIC-017` | AIC | ج مخزن المعرفة العائلية | زر النسيان | P0 | جديدة | 2 | FAT-059 | FAT-28 |
| `S-AIC-018` | AIC | د المستشار والتقارير | المعلم الذكي | P0 | موجودة | 3 | CHD-017 | CHD-15 |
| `S-AIC-019` | AIC | د المستشار والتقارير | التقرير الأسبوعي بتوصية | P1 | موجودة | 3 | FAT-073 FAT-086 | FAT-36 FAT-45 |
| `S-AIC-020` | AIC | د المستشار والتقارير | تصحيح الواجبات | P0 | موجودة | 3 | CHD-014 CHD-016 | CHD-15 |
| `S-AIC-021` | AIC | د المستشار والتقارير | توليد محتوى الاستوديو | P0 | موجودة | 3 | FAT-043 FAT-044 | — |
| `S-AIC-022` | AIC | د المستشار والتقارير | تنبيه النمط الخطر | P1 | جديدة | 3 | FAT-065 FAT-066 | FAT-31 |
| `S-AIC-023` | AIC | د المستشار والتقارير | تحليل تلاوة القرآن | P2 | موجودة | 3 | CHD-032 FAT-075 | CHD-18 FAT-38 |
| `S-AIC-024` | AIC | هـ المساعد التفاعلي | سؤال العقل بلغة طبيعية | P1 | موجودة | 3 | FAT-074 | FAT-37 |
| `S-AIC-025` | AIC | هـ المساعد التفاعلي | الاسترجاع من مخزن المعرفة | P1 | جديدة | 3 | FAT-074 | FAT-37 |
| `S-AIC-026` | AIC | هـ المساعد التفاعلي | «لا أعلم» عند نقص البيانات | P1 | جديدة | 3 | FAT-074 | FAT-37 |
| `S-AIC-027` | AIC | هـ المساعد التفاعلي | محادثة صوتية | P2 | موجودة | 3 | FAT-075 FAT-083 | FAT-38 |
| `S-AIC-028` | AIC | هـ المساعد التفاعلي | اقتراحات استباقية للأب | P1 | جديدة | 3 | FAT-073 | MOT-09 |
| `S-AIC-029` | AIC | هـ المساعد التفاعلي | إخطار الأم بالتحليلات | P1 | قاعدة حاكمة | 3 | FAT-076 | MOT-09 |
| `S-AIC-030` | AIC | و الوكيل المفوَّض | بناء قاعدة تفويض | P2 | جديدة | 3 | FAT-075 FAT-079 | FAT-38 FAT-41 |
| `S-AIC-031` | AIC | و الوكيل المفوَّض | التنفيذ التلقائي ضمن التفويض | P2 | جديدة | 3 | FAT-075 FAT-080 | FAT-38 FAT-41 |
| `S-AIC-032` | AIC | و الوكيل المفوَّض | إشعار فوري بكل تصرّف | P2 | جديدة | 3 | FAT-075 FAT-080 | FAT-38 FAT-41 |
| `S-AIC-033` | AIC | و الوكيل المفوَّض | زر التراجع خلال ١٠ دقائق | P2 | جديدة | 3 | FAT-075 FAT-080 | FAT-38 FAT-41 |
| `S-AIC-034` | AIC | و الوكيل المفوَّض | سجل تدقيق دائم | P2 | جديدة | 3 | FAT-075 FAT-080 | FAT-38 FAT-41 |
| `S-ADM-001` | ADM | أ الإعداد الأول | إنشاء حساب | P0 | جديدة | 1 | SHR-001 SHR-002 SHR-003 SHR-007 | FAT-01 |
| `S-ADM-002` | ADM | أ الإعداد الأول | معالج الإعداد المتدرج | P0 | جديدة | 1 | CHD-011 FAT-001 FAT-002 FAT-003 FAT-030 SHR-008 | FAT-01 |
| `S-ADM-003` | ADM | أ الإعداد الأول | ربط جهاز الابن بـQR | P0 | موجودة | 1 | CHD-001 CHD-002 FAT-004 | CHD-01 FAT-02 |
| `S-ADM-004` | ADM | أ الإعداد الأول | شرح الصلاحيات بالفيديو | P0 | جديدة | 1 | CHD-003 CHD-010 FAT-005 | CHD-01 CHD-05 FAT-02 |
| `S-ADM-005` | ADM | أ الإعداد الأول | مؤشر اكتمال الإعداد | P0 | جديدة | 1 | FAT-002 FAT-006 | FAT-02 |
| `S-ADM-006` | ADM | أ الإعداد الأول | وضع التجربة قبل الربط | P0 | جديدة | 1 | FAT-007 | FAT-03 |
| `S-ADM-007` | ADM | أ الإعداد الأول | استئناف الإعداد لاحقًا | P0 | جديدة | 1 | FAT-002 | FAT-03 |
| `S-ADM-008` | ADM | ب العائلة والأعضاء | لوحة الإدارة | P0 | موجودة | 1 | FAT-001 FAT-027 | FAT-01 |
| `S-ADM-009` | ADM | ب العائلة والأعضاء | دعوة أعضاء | P0 | موجودة | 1 | FAT-008 | FAT-04 |
| `S-ADM-010` | ADM | ب العائلة والأعضاء | إدارة الأدوار | P0 | موجودة | 1 | FAT-008 FAT-027 FAT-031 | FAT-04 MOT-01 |
| `S-ADM-011` | ADM | ب العائلة والأعضاء | قبول/رفض دعوة | P0 | موجودة | 1 | FAT-009 | FAT-04 MOT-01 |
| `S-ADM-012` | ADM | ب العائلة والأعضاء | حدود متدرجة حسب الباقة | P0 | موجودة | 1 | FAT-003 FAT-027 | — |
| `S-ADM-013` | ADM | ب العائلة والأعضاء | الوصي البديل | P1 | جديدة | 1 | FAT-027 | — |
| `S-ADM-014` | ADM | ج الأجهزة | ربط جهاز الابن | P0 | موجودة | 1 | CHD-002 FAT-004 | FAT-02 |
| `S-ADM-015` | ADM | ج الأجهزة | إدارة الأجهزة | P0 | موجودة | 1 | FAT-012 FAT-025 | FAT-13 |
| `S-ADM-016` | ADM | ج الأجهزة | صحة الجهاز | P0 | جديدة | 1 | FAT-025 FAT-026 | FAT-13 FAT-14 |
| `S-ADM-017` | ADM | ج الأجهزة | تنبيه فقدان الاتصال | P0 | جديدة | 1 | FAT-026 SHR-005 SHR-006 | FAT-13 FAT-14 SHR-01 |
| `S-ADM-018` | ADM | ج الأجهزة | فصل جهاز | P0 | موجودة | 1 | FAT-025 FAT-026 | FAT-13 |
| `S-ADM-019` | ADM | د الاشتراك والفوترة | الباقات الثلاث | P0 | موجودة | 2 | FAT-056 | FAT-26 |
| `S-ADM-020` | ADM | د الاشتراك والفوترة | الخطة السنوية | P0 | جديدة | 2 | FAT-056 | FAT-26 |
| `S-ADM-021` | ADM | د الاشتراك والفوترة | صفحة الاشتراك | P0 | موجودة | 2 | FAT-056 | FAT-26 |
| `S-ADM-022` | ADM | د الاشتراك والفوترة | تجربة ١٤ يومًا بلا خصم تلقائي | P0 | موجودة | 2 | FAT-056 | FAT-26 |
| `S-ADM-023` | ADM | د الاشتراك والفوترة | الترقية والتخفيض | P0 | جديدة | 2 | FAT-057 | FAT-26 |
| `S-ADM-024` | ADM | د الاشتراك والفوترة | استرجاع المشتريات | P0 | جديدة | 2 | FAT-057 | FAT-26 |
| `S-ADM-025` | ADM | هـ الإشعارات | تفضيلات الإشعارات | P0 | موجودة | 2 | FAT-058 | FAT-27 FAT-44 |
| `S-ADM-026` | ADM | هـ الإشعارات | قنوات الإشعارات | P0 | موجودة | 2 | FAT-058 | FAT-27 |
| `S-ADM-027` | ADM | هـ الإشعارات | جدولة الإشعارات | P0 | موجودة | 2 | FAT-058 | FAT-27 |
| `S-ADM-028` | ADM | هـ الإشعارات | ثلاث درجات إلحاح | P0 | جديدة | 2 | FAT-058 | FAT-27 |
| `S-ADM-029` | ADM | هـ الإشعارات | ملخص بدل تكرار | P0 | جديدة | 2 | FAT-058 | FAT-27 |
| `S-ADM-030` | ADM | و الخصوصية والبيانات | إعدادات الخصوصية | P0 | موجودة | 2 | FAT-059 | FAT-28 |
| `S-ADM-031` | ADM | و الخصوصية والبيانات | خصوصية الطفل | P0 | موجودة | 2 | FAT-059 | FAT-28 |
| `S-ADM-032` | ADM | و الخصوصية والبيانات | تصدير وحذف البيانات | P0 | موجودة | 2 | FAT-059 | FAT-28 |
| `S-ADM-033` | ADM | و الخصوصية والبيانات | لوحة تحكم العقل | P0 | قاعدة حاكمة | 2 | FAT-029 | — |
| `S-ADM-034` | ADM | و الخصوصية والبيانات | سجل التدقيق | P0 | جديدة | 2 | FAT-060 | FAT-28 |
| `S-ADM-035` | ADM | و الخصوصية والبيانات | شاشة «ماذا يُجمع عني» للابن | P0 | قاعدة حاكمة | 2 | CHD-010 | — |
| `S-ADM-036` | ADM | ز لوحة اليوم | لوحة اليوم | P0 | موجودة | 1 | CHD-004 FAT-010 | CHD-02 FAT-05 MOT-02 |
| `S-ADM-037` | ADM | ز لوحة اليوم | جدول المدرسة | P0 | موجودة | 1 | FAT-010 | FAT-05 MOT-02 |
| `S-ADM-038` | ADM | ز لوحة اليوم | بطاقة لكل ابن | P0 | جديدة | 1 | FAT-010 FAT-012 FAT-013 | FAT-05 FAT-06 MOT-02 MOT-03 |
| `S-ADM-039` | ADM | ز لوحة اليوم | اقتراحات العقل اليوم | P0 | جديدة | 1 | FAT-010 FAT-011 | FAT-05 |
| `S-ADM-040` | ADM | ح الإعدادات والدعم | اللغة | P0 | موجودة | 2 | FAT-061 | FAT-30 |
| `S-ADM-041` | ADM | ح الإعدادات والدعم | مركز المساعدة بالعربية | P0 | جديدة | 2 | FAT-061 | FAT-30 |
| `S-ADM-042` | ADM | ح الإعدادات والدعم | التواصل مع الدعم | P1 | جديدة | 2 | FAT-061 | FAT-30 |

### Annex A.1 — coverage findings

- Services with at least one derived screen: **240** / 240
- Services with at least one derived journey: **222** / 240
- **Orphan services** (no screen and no journey binding anywhere in the registry): **0**


**Services bound to a screen but to no journey (18):** a screen exists, yet no user journey exercises the service — phase 6/12 must either attach a journey or confirm the service is reached only via events (Register **G-6**/**G-9**: some screens are reachable by alert only).

- `S-SEC-012` — تنبيهات الألعاب (SEC, P1, W2)
- `S-SEC-013` — بطاقة معلومات التطبيق (SEC, P1, W2)
- `S-SEC-023` — الأماكن المتكررة (SEC, P1, W1)
- `S-SEC-029` — جهات اتصال خارج العائلة (SEC, P0, W1)
- `S-COM-003` — مجموعات فرعية (COM, P0, W1)
- `S-COM-008` — تثبيت رسالة (COM, P1, W1)
- `S-COM-009` — قفل المحادثة (COM, P1, W1)
- `S-COM-012` — مكالمة جماعية (COM, P1, W1)
- `S-EDU-006` — مكتبة فيديو (EDU, P1, W2)
- `S-EDU-010` — تصحيح تلقائي بالعقل (EDU, P0, W2)
- `S-EDU-046` — تقرير التركيز للأب (EDU, P1, W2)
- `S-AIC-004` — كشف الصور الحساسة (AIC, P0, W1)
- `S-AIC-005` — قائمة القواعد القابلة للتحديث (AIC, P0, W1)
- `S-AIC-021` — توليد محتوى الاستوديو (AIC, P0, W3)
- `S-ADM-012` — حدود متدرجة حسب الباقة (ADM, P0, W1)
- `S-ADM-013` — الوصي البديل (ADM, P1, W1)
- `S-ADM-033` — لوحة تحكم العقل (ADM, P0, W2)
- `S-ADM-035` — شاشة «ماذا يُجمع عني» للابن (ADM, P0, W2)

