# CONTROL & EXPERIENCE AUDIT

**Date:** 2026-09-25  
**Phase:** Frontend + Local Product Hardening  
**Mode:** READ-ONLY AUDIT ONLY  
**Production code changes:** NONE  
**Native:** CLOSED (not authorized)  
**Backend / Remote:** CLOSED (not authorized)  
**Prior FS-001→FS-010 analysis:** NOT reopened; referenced as evidence only  

**Owner standard under audit:**

> The frontend must not only exist and be honest; it must provide a complete, professional user experience for **control, management, communication, navigation, states, and local data usage** within currently available capabilities.

---

## Progress header

```
CURRENT PHASE: Frontend + Local Product Hardening (post Full Frontend Closure)
TASK PHASE: CONTROL & EXPERIENCE AUDIT (read-only)
STATUS: ALIGNED
REQUIRED GATE: Owner authorization before any implementation from this audit
WILL MODIFY PRODUCTION CODE: NO
```

---

## 1. Scope & method

| Dimension | Count | Source |
|-----------|------:|--------|
| Systems | **42** | Phase 3 `01_SYSTEM_MAP` + services.csv |
| Services | **240** | Phase 3 `01_SYSTEM_MAP` |
| Journeys | **73** | Phase 3 `06_JOURNEY_INTEGRITY_MAP` |
| Screens | **130** | screens.csv + FRONTEND_COMPLETION_MATRIX |

**Evidence bases (not re-analyzed as FS packs):**

- `docs/experience_discovery/FRONTEND_COMPLETION_MATRIX.md` (128/130 FRONTEND COMPLETE)
- Phase 3 maps 01–10 (system / screen / journey / native / backend / gaps)
- Phase 4 dependency graph + wave plan (execution batch names only)
- Composition root: `app/lib/main.dart`, `fs_composition_runtime.dart`
- Feature repositories / screens for P0–P1 honesty and local-binding spot checks
- `GAP_LOG.md` residual OPEN rows

**Classification vocabulary (this audit):**

| Label | Meaning |
|-------|---------|
| `REAL_LOCAL` | Persisted / domain-bound on device; restart-safe where claimed; consequence is local |
| `LOCAL_DEMO` | Local store or roster seeded with demo fixtures; bound but not “family reality” |
| `MOCK` | InMemory / prototype fixture as production default; simulation-shaped |
| `NATIVE_CLOSED` | Requires OS plane (GPS, VPN/DNS, Device Admin, LiveKit, MediaProjection, FCM receive, etc.) — **not authorized** |
| `REMOTE_CLOSED` | Requires Backend / AI Gateway / chat relay / billing / licensed remote — **not authorized** |

**Severity:**

| Sev | Meaning |
|-----|---------|
| P0 | Safety-critical false success or control that lies about protection |
| P1 | Misleading live/success language OR MOCK default where peer domains already REAL_LOCAL |
| P2 | Known CLOSED plane with residual UX debt; banners often present |
| P3 | Hygiene / catalog / OOS / registry debt |

**Critical rules obeyed:** no production edits · no invented policy · no Native/Backend authorization · no redo of completed FS analysis.

---

## 2. Executive verdict

**Frontend Closure ≠ Control/Experience Completeness.**

| Claim | Truth |
|-------|-------|
| UI reachability / routes / ARB / RBAC shells | **Met** for 128 live screens |
| Honesty banners on most NAT/REM planes | **Mostly met** |
| Professional **control** depth (configure → operate → adjust → exception → history → recovery) on every system | **Partial** — strong on ST / Prefs-misc / Identity / SOS prefs / WF prefs / Audit; thin on MOCK-primary day-life systems |
| Professional **local data usage** (empty/loading/error/offline/stale; no prototype numerals as “live”) | **Partial** — ~55–65 screens still MOCK-primary at composition default |
| Native enforcement / remote delivery | **Correctly CLOSED** — must not be implied as live |

**Bottom line for Owner:** The product is a **real local Flutter shell with a strong control spine** (Screen Time, prefs, identity, SOS prefs, education assignments/results, audit) and a **large MOCK/LOCAL_DEMO day-life surface**. Highest remaining risk is not “missing screens” — it is **success-shaped chrome** (✓✓, Synced, Device locked, “sent to child’s screen”) and **InMemory defaults** outside the Phase 1.75 bind spine.

---

## 3. Inventory audited

### 3.1 Systems (42) — control & data posture

| system_key | name | Primary screens (abbrev.) | Data posture (dominant) | Control completeness | Experience | Honesty |
|---|---|---|---|---|---|---|
| ADM:أ | First setup | SHR-001…003, FAT-001…007, CHD-001…003,011, SHR-007/008, FAT-030 | MIXED REAL_LOCAL / candidacy | Configure+operate OK; recovery honesty on login | Clear journeys | Invite “sent” language needs REM honesty continuity |
| ADM:ب | Family & members | FAT-008/009/027/031 | REAL_LOCAL (+ LOCAL_DEMO roster) | Invite/RBAC mother level strong | Clear | Email/FCM delivery CLOSED (bannered) |
| ADM:ج | Devices | FAT-025/026, SHR-005/006 | REAL_LOCAL Identity fail-closed + LOCAL_DEMO | Health UI OK; OS permission repair NAT CLOSED | Templates OK | Fail-closed good |
| ADM:د | Subscription | FAT-056/057 | REMOTE_CLOSED UI contract | Owner-only; SOS never gated | Clear | Billing REM CLOSED honest |
| ADM:هـ | Notifications | FAT-058 | REAL_LOCAL prefs | Channels+urgency; SOS never muted | Clear | FCM delivery NAT/REM CLOSED |
| ADM:و | Privacy & data | FAT-059/060, CHD-010, FAT-029 | REAL_LOCAL audit; privacy MIXED | Audit append-only strong | Clear | AI Gateway REM CLOSED on privacy |
| ADM:ز | Day board | FAT-010…013, CHD-004 | LOCAL_DEMO | Overview OK; GPS cards NAT CLOSED | Clear | Demo honesty banners |
| ADM:ح | Settings/support | FAT-061 | REAL_LOCAL language/help | Sufficient | Clear | — |
| AIC:أ | Monitoring engine | FAT-019/020/029 | MOCK / candidacy | Alerts hub thin vs full control matrix | OK | Stage flags honesty |
| AIC:ب | Patterns | FAT-062 | MOCK + REMOTE_CLOSED | Review-only mock | OK | Insights Gateway CLOSED |
| AIC:ج | Knowledge store | FAT-063/064 | MOCK + REMOTE_CLOSED | Review-only mock | OK | Gateway CLOSED |
| AIC:د | Advisor & reports | FAT-043/044/065/066/069/073/086… | MIXED local UI + REMOTE_CLOSED | Suggest-only (Rule 7) | OK | Gateway CLOSED |
| AIC:هـ | Interactive assistant | FAT-074/076/083 | MOCK + REMOTE_CLOSED | Suggest-only | OK | Assistant CLOSED |
| AIC:و | Delegated agent | FAT-079/080 | MOCK + REMOTE_CLOSED | No execute() structural | OK | Agent CLOSED |
| COM:أ | Conversations | FAT-021/022, CHD-007/008 | LOCAL_DEMO list/thread; REMOTE_CLOSED delivery | Local compose OK; multi-device CLOSED | Clear | **✓✓ ticks = P1 honesty** |
| COM:ب | Calls | FAT-023/024, CHD-009/036 | NATIVE_CLOSED | UI only | Clear | LiveKit CLOSED |
| COM:ج | Media/files | CHD-023/037 | MOCK + NATIVE_CLOSED | Intent queue only | OK | Camera/mic CLOSED |
| COM:د | Safe circle | FAT-070/071, CHD-030 | MOCK InMemory | Approve loop local | OK | Needs Local KV deepen |
| COM:هـ | Family calendar | FAT-052/053 | MOCK InMemory | CRUD simulation | OK | Local bind gap |
| COM:و | Tasks | FAT-054/055/082, CHD-022 | MOCK; **raw int minutes** | Loop UI exists; Rule 4 debt | OK | Local bind + Minutes VO |
| COM:ز | Location-in-comms | CHD-024 | MOCK + NATIVE_CLOSED | Check-in journal RAM | OK | GPS/FCM honesty |
| EDU:أ | Materials | FAT-048, CHD-012/013 | REMOTE_CLOSED licensed | Catalog UI | OK | Licensed REM CLOSED |
| EDU:ب | Assignments | FAT-049/050, CHD-014 | REAL_LOCAL assignment KV (partial path) | Create/followup OK | OK | create_assignment still mixed InMemory |
| EDU:ج | Assessments | CHD-015/016, FAT-050 | REAL_LOCAL results KV | Quiz/result OK | OK | Parent notify REM CLOSED |
| EDU:د | Smart tutor | CHD-017/033 | LOCAL UI + REMOTE_CLOSED | Suggest-only tutor | OK | Tutor Gateway CLOSED |
| EDU:هـ | Adaptive | CHD-028/029 | MOCK / local candidacy | Plan/review UI | OK | — |
| EDU:و | Rewards | CHD-019/034, FAT-045 | REAL_LOCAL Minutes path + LOCAL_DEMO streak | Wallet OK if PolicyEngine | OK | No XP/coins in copy |
| EDU:ز | Quran | FAT-072, CHD-025…027/032 | LOCAL UI + REMOTE_CLOSED; **GapClose 004–007 OPEN** | Incomplete local deepen | OK | Licensed REM CLOSED |
| EDU:ح | Focus | FAT-051, CHD-018/035 | MIXED MOCK | Praise “sent to screen” P1 | OK | OS wake NAT CLOSED on focus |
| EDU:ط | Father studio | FAT-040…047/084 | MIXED local + REMOTE_CLOSED Advisor | Approve gate (Rule 7) | OK | Generate REM CLOSED |
| SEC:أ | Screen time | FAT-032/033/085, CHD-020/021 | **REAL_LOCAL** strong | Configure/operate/adjust/exception/loop strong | Strong | OS enforce NAT CLOSED; sync chip ≠ remote |
| SEC:ب | App control | FAT-034/035 | LOCAL_DEMO + NATIVE_CLOSED | Allow/block local; OS intercept CLOSED | OK | Prototype app inventory |
| SEC:ج | Web filter | FAT-036/078 | REAL_LOCAL prefs + MOCK router | Categories real; VPN/DNS CLOSED; router Synced P1 | OK | Home router fixture |
| SEC:د | Location | FAT-014…017, CHD-004 | NATIVE_CLOSED (+ local zone CRUD UI) | Zones configurable; live fix CLOSED | OK | GPS banners present |
| SEC:هـ | SOS | FAT-018/028, CHD-005/006 | REAL_LOCAL fire + REMOTE_CLOSED delivery | Ladder/break-glass strong | Strong | Delivered ≠ local fire |
| SEC:و | Smart content | FAT-065…067 | MOCK + NATIVE_CLOSED MediaProjection | Prefs honesty | OK | Capture CLOSED |
| SEC:ز | Platform monitoring | FAT-068 | LOCAL UI honesty matrix | SET-017 honesty | OK | Capability matrix |
| SEC:ح | Anti-cheat hub | FAT-038 | REAL_LOCAL prefs + NATIVE_CLOSED signals | Alerts local | OK | OS signals CLOSED |
| SEC:ط | Instant lock | FAT-037 | REAL_LOCAL prefs + NATIVE_CLOSED OS | Prefs persist; **“Device locked” language P1** | OK | Device Admin CLOSED |
| SEC:ي | Reports | FAT-069/073/081 | MOCK numerals + REMOTE_CLOSED export | Review UI | OK | Email/PDF CLOSED; prototype metrics |
| SEC:ك | Road safety | FAT-077 | **OOS** | — | — | Keep closed |
| SEC:ل | School mode | FAT-039 | **OOS tombstone ADR-034** | Modes live on FAT-085 instead | — | OS wake CLOSED on 085 |

**Extra (not in CSV letter):** FS-008 One-Way Audio — **zero screens / zero journeys** (DESIGN GAP; policy AUD-C* open). Not invented here.

### 3.2 Screens (130)

| Status | Count |
|--------|------:|
| FRONTEND COMPLETE (prior gate) | 128 |
| OUT OF SCOPE | 2 (`SCR-FAT-039`, `SCR-FAT-077`) |
| Audited for control/experience in this gate | **130** |

Role counts: FAT **86** · CHD **37** · SHR **7** · MOT IDs **0** (mother journeys reuse FAT screens).

### 3.3 Journeys (73)

All 73 journeys remain **linked** (Phase 3 integrity). Experience audit does not reopen journey→service refs. Control gaps map to journeys via screen ownership in the Gap Register.

### 3.4 Services (240)

18 services still never listed on any journey (Phase 3 REGISTRY GAP P3-G011) — inventory holes, **not** product deletions. Control audit does not invent UI for them.

---

## 4. Cross-cutting findings

### 4.1 CONTROL COMPLETENESS

**Strong (within Local capabilities):**

- Screen Time: caps, schedules, time-request approve/deny loop, child expiry (chat/Quran/SOS never locked)
- Prefs-misc: notifications, privacy collection, anti-tamper prefs, device-lock prefs, monitoring prefs
- Identity: family context, roster LOCAL_DEMO, mother permission levels, invite token accept fail-closed
- SOS prefs / ladder / break-glass local fire
- Education assignment + result local KV (spine)
- Audit append-only

**Weak / incomplete for “professional control” without Native/Remote:**

| Gap class | Examples |
|-----------|----------|
| Operate without enforce | Instant lock prefs without Device Admin; WF without VPN/DNS; AC without OS intercept; ST without OS enforce |
| Fake operate check | Home router “protection check” returns fixture snap |
| Missing Local deepen | Tasks, calendar, outer circle, media share, arrival, focus sounds, many EDU child surfaces still InMemory |
| History/review thin | Usage/peer/moments default prototype numerals as if live analytics |
| Exceptions | Time unlock / web unlock local OK; remote notify CLOSED |
| Recovery | Login recovery honesty present; multi-device recovery REMOTE_CLOSED |

### 4.2 EXPERIENCE

| Area | Verdict |
|------|---------|
| Purpose clarity | Generally strong (KEEP+REFINE ports) |
| childId / context | ST/AC/WF scoped; Identity fail-closed; residual risk on MOCK repos |
| Navigation / back | Shell + hubs wired (PRT-2); OOS screens correctly unrouted |
| Primary action | Clear on control screens; AI surfaces correctly suggest→approve |
| Dead ends | Coming-soon catalog FAT-075 honest; call/media intending NAT CLOSED without fake completion |
| States (L/E/E/O/S) | SHR-005/006 templates exist; **MOCK-default screens rarely exercise empty** |
| AR + RTL | ARB-bound; IBM Plex Sans Arabic; no systemic redesign flagged |
| Touch / readability | Constitution targets ≥48dp; no redesign in this audit |

### 4.3 LOCAL REALITY

| Posture | Approx. screens | Notes |
|---------|----------------:|-------|
| REAL_LOCAL-strong | ~25–35 | ST, prefs-misc, identity, SOS prefs, audit, EDU assign/result spine |
| LOCAL_DEMO | ~15–25 | Day board, children list, devices demo honesty |
| MOCK-primary default | ~55–65 | Tasks, calendar, circle, many EDU/AIC, reports, router, media… |
| NATIVE_CLOSED dependency | ~40 (FCM col) | GPS, LiveKit, VPN, MediaProjection, OS wake, FCM… |
| REMOTE_CLOSED dependency | ~52 (FCM col) | AI Gateway, chat relay, billing, Quran licensed, Email/PDF… |

### 4.4 HONESTY — residual risk after Frontend Closure

Banners are widespread. Remaining **P1** issues are UI that still **reads as live success**:

1. Chat **✓✓** for `delivered`/`read` while multi-device REMOTE_CLOSED  
2. Home router tag **Synced** + fixture `dnsActive: true`, `deviceCount: 12`  
3. Focus praise **“sent to {name}'s screen”** without remote delivery  
4. Instant lock status **Device locked/unlocked** without OS lock  
5. Prototype metrics on usage / peer / moments as default “report”  
6. Family tasks `rewardMinutes` as raw `int` (Rule 4 Minutes VO debt)

### 4.5 VISUAL / DESIGN (KEEP + REFINE only)

| Finding | Sev | Note |
|---------|-----|------|
| Design system tokens / card language | P3 | No systemic KEEP+REFINE violation inventory in this pass |
| Empty/error under-use when fixtures pre-fill lists | P2 | Experience density hides empty states |
| Catalog templates SHR-005/006 | P3 | Present; adoption uneven |
| No redesign authorized | — | Audit only |

---

## 5. System-by-system control checklist (summary)

For every system the audit checked: Configure · Operate · Adjust · Exceptions · Scope · RBAC · State visibility · Review/history · Recovery · Clear consequence.

| system | Configure | Operate | Adjust | Exceptions | Scope | RBAC | State vis. | History | Recovery | Consequence clarity |
|--------|-----------|---------|--------|------------|-------|------|------------|---------|----------|---------------------|
| SEC:أ ST | ✓ | ✓ local | ✓ | ✓ time-req | childId | ✓ | ✓ | partial | partial | ✓ local; OS NAT closed |
| SEC:ب AC | ✓ | partial | ✓ | install card | childId | ✓ | ✓ | thin | — | OS intercept closed |
| SEC:ج WF | ✓ | prefs ✓ | ✓ | unlock | childId | ✓ | ✓ | thin | — | VPN closed; router P1 |
| SEC:د Loc | zones ✓ | live ✗ | ✓ | — | childId | ✓ | banner | history UI | — | GPS closed |
| SEC:هـ SOS | ✓ | fire ✓ | ✓ | break-glass | family | ✓ | ✓ | alerts | ladder | delivery REM closed |
| SEC:ط Lock | ✓ | prefs ✓ | ✓ | timer | device | ✓ | **misleading** | — | unlock prefs | OS closed |
| ADM:ب Id | ✓ | ✓ | mother lvl | invite fail-closed | family | ✓ | ✓ | thin | token | email REM closed |
| ADM:هـ Notif | ✓ | prefs ✓ | ✓ | SOS unmute | family | owner | ✓ | — | — | FCM closed |
| COM:أ Chat | ✓ | local ✓ | edit UI | — | thread | ✓ | **✓✓ risk** | local | — | relay closed |
| COM:و Tasks | ✓ UI | mock | ✓ | approve | family | ✓ | mock | thin | — | Minutes VO debt |
| EDU:* | mixed | mixed | mixed | — | childId | ✓ | mixed | mixed | — | Gateway/licensed closed |
| AIC:* | stage UI | suggest | approve | refuse | child/family | ✓ | mock | logs UI | — | no execute; Gateway closed |
| ADM:د Bill | view | — | — | — | owner | owner | mock | — | restore UI | REM closed |
| SEC:ك/ل | OOS | — | — | — | — | — | — | — | — | Keep closed |

Full per-finding rows: `CONTROL_EXPERIENCE_GAP_REGISTER.md`.

---

## 6. Native-closed & Remote-closed (inventory)

### Native-closed (must not claim live)

GPS/live locate · VPN/DNS block · OS app intercept / Device Admin · MediaProjection / camera OS · OS wake/Modes · Telephony/LiveKit · FCM receive · SMS fallback · ambient mic (FS-008) · PDF share sheet (until REP-C1)

### Remote-closed (must not claim live)

Cloud auth · multi-device policy sync · Advisor/Insights/Tutor Gateways · push fanout · SOS remote delivery · chat relay · Email/PDF delivery · licensed Quran/materials · home-router appliance · billing · FS-008 mic sync

---

## 7. Items requiring Owner decisions (policy — do not invent)

Carried from Phase 2/3; still blocking deeper Local/NAT slices for FS-008/009/010:

| ID | Topic |
|----|-------|
| AUD-C1…C3, AUD-C6 | FS-008 clip / trigger / SOS / iOS mic |
| REP-C1, REP-C2 | PDF export mandate / retention |
| CHAT-C1, CHAT-C2 | Edit revision depth / delete-for-all audit |

**New control/experience decisions (optional Owner calls — not invented as law):**

| Proposed question ID | Topic | Why |
|----------------------|-------|-----|
| Q-CEX-001 | Chat delivery ticks while REMOTE_CLOSED | Show `sent` only vs keep ✓✓ with stronger local banner |
| Q-CEX-002 | Instant-lock copy | Prefer “Lock requested (local)” vs “Device locked” until NAT |
| Q-CEX-003 | Tasks Minutes VO | Mandate Minutes value object on COM:و before Local bind |
| Q-CEX-004 | Quran GapClose 004–007 | Authorize Local deepen batch vs keep OPEN until licensed REM |

---

## 8. Recommended execution order (batches)

**Do not implement until Owner authorizes.** Batches align with Phase 4 waves; scoped to control/experience debt:

| Batch | Name | Goal | Blocks Native/Remote? |
|------:|------|------|------------------------|
| **CE-B0** | Honesty hotfix | Remove/relabel ✓✓, Synced, Device locked, “sent to screen”, router fixture truths | No — Local copy/state only |
| **CE-B1** | Local bind deepen — family ops | Tasks (Minutes VO), calendar, outer circle, arrival, media intents prefs | No |
| **CE-B2** | Local bind deepen — reports | Usage / peer / moments empty-first + derived from Local facts (no prototype live) | No |
| **CE-B3** | Control spine polish | ST sync-chip wording; AC inventory empty-first; WF unlock consequence clarity; lock copy | No |
| **CE-B4** | Quran Local GapClose 004–007 | Only if Owner answers Q-CEX-004 | No (licensed REM still closed) |
| **CE-B5** | EDU/AIC mock honesty | Uniform MOCK/LOCAL_DEMO banners; empty states; no fake Gateway success | No |
| **CE-B6** | Policy-gated FS-008/009/010 Local | After AUD*/REP*/CHAT* answers | Still no NAT/REM |
| **CE-B7** | Native wave | GPS, VPN, Device Admin, LiveKit, MediaProjection, FCM… | **Requires Phase 5 auth** |
| **CE-B8** | Remote wave | AI Gateway, chat relay, billing, Email/PDF… | **Requires Backend auth** |

---

## 9. Exit counts (required report)

| # | Metric | Count / answer |
|---|--------|----------------|
| 1 | Systems audited | **42** (+ FS-008 noted as registry/design gap, no screens) |
| 2 | Screens audited | **130** (128 live FE-complete + 2 OOS) |
| 3 | Control gaps | **22** register rows (category CONTROL) |
| 4 | Local-binding gaps | **28** register rows (category LOCAL) |
| 5 | UX gaps | **12** register rows (category EXPERIENCE) |
| 6 | Visual gaps | **4** register rows (category VISUAL) |
| 7 | Honesty gaps | **24** register rows (category HONESTY) |
| 8 | Native-closed items | **13** capability planes · **~40** screens with NAT dependency |
| 9 | Remote-closed items | **13** capability planes (+1 policy) · **~52** screens with REM dependency |
| 10 | Items requiring Owner decisions | **8** carried policy (AUD*/REP*/CHAT*) + **4** proposed Q-CEX-* |
| 11 | Recommended execution order | **CE-B0 → CE-B5** (Local) then **CE-B6** (policy) then **CE-B7/B8** (NAT/REM gated) |

**Register file:** `CONTROL_EXPERIENCE_GAP_REGISTER.md`  
**Total gap rows:** **90** (some findings span multiple categories; primary category counted above)

---

## 10. Stop condition

Audit complete. **No production code modified.**  
**Awaiting Owner authorization** before any CE-B* implementation.

---

## Appendix A — Evidence anchors

| Topic | Path |
|-------|------|
| FE matrix | `docs/experience_discovery/FRONTEND_COMPLETION_MATRIX.md` |
| System map | `docs/experience_discovery/phase3_reconciliation/01_SYSTEM_MAP.md` |
| Native map | `…/07_NATIVE_CAPABILITY_MAP.md` |
| Backend map | `…/08_BACKEND_CAPABILITY_MAP.md` |
| Phase 3 gaps | `…/10_PHASE_3_GAP_REGISTER.md` |
| Phase 4 deps | `docs/experience_discovery/phase4_master_plan/05_IMPLEMENTATION_DEPENDENCY_GRAPH.md` |
| Composition | `app/lib/main.dart`, `app/lib/core/fs_foundation/fs_composition_runtime.dart` |
| Chat ticks | `app/lib/features/n02_day/conversation_screen.dart` |
| Router Synced | `app/lib/features/n04_web_filter/home_router_filter_*.dart` |
| Tasks Minutes | `app/lib/features/n16_tasks/family_tasks_models.dart` |
| Quran OPEN | `GAP_LOG.md` (004–007) |
