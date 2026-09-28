# CONTROL EXPERIENCE GAP REGISTER

**Date:** 2026-09-25  
**Mode:** READ-ONLY  
**Companion:** `CONTROL_EXPERIENCE_AUDIT.md`  
**Rule:** Document gaps. Do not invent policy. Do not authorize Native/Backend. Do not modify production code.

## Schema

`gap_id` · `system` · `screen` · `journey` · `category` · `severity` · `current_behavior` · `expected_behavior` · `required_fix` · `data_source` · `native_remote_dependency` · `policy_decision_required` · `execution_batch`

**Categories:** `CONTROL` · `EXPERIENCE` · `LOCAL` · `HONESTY` · `VISUAL` · `NATIVE_CLOSED` · `REMOTE_CLOSED` · `OWNER_DECISION`

---

## Register

| gap_id | system | screen | journey | category | severity | current_behavior | expected_behavior | required_fix | data_source | native_remote_dependency | policy_decision_required | execution_batch |
|--------|--------|--------|---------|----------|----------|------------------|-------------------|---------------|-------------|--------------------------|--------------------------|-----------------|
| CE-G001 | COM:أ | SCR-FAT-022 | JRN-FAT-11;JRN-MOT-04 | HONESTY | P1 | Message UI shows ✓✓ for `delivered`/`read`; default status `delivered`; REMOTE banner also present | Within Local capability: ticks must not imply multi-device delivery; prefer `sent`/local-only or explicit local label | Relabel status model + UI ticks; keep REMOTE CLOSED banner | LOCAL_DEMO | Chat relay REMOTE_CLOSED | Yes — Q-CEX-001 | CE-B0 |
| CE-G002 | COM:أ | SCR-CHD-008 | JRN-CHD-04 | HONESTY | P1 | Child thread mirrors delivery chrome pattern | Same as CE-G001 for child thread | Same honesty remap as FAT-022 | LOCAL_DEMO | Chat relay REMOTE_CLOSED | Yes — Q-CEX-001 | CE-B0 |
| CE-G003 | SEC:ج | SCR-FAT-078 | JRN-FAT-40 | HONESTY | P1 | Fixture defaults `dnsActive:true`, `categoriesSynced:true`, `deviceCount:12`; UI tag “Synced” | Default empty/off until real Local config; never claim Synced/DNS live while NAT CLOSED | Empty-first snap; rename tag to local-config honesty; disable fake protection-check success | MOCK | VPN/DNS NATIVE_CLOSED | No | CE-B0 |
| CE-G004 | SEC:ج | SCR-FAT-078 | JRN-FAT-40 | CONTROL | P1 | `runProtectionCheck` increments counter and returns same fixture snap | Operate check must either be real Local validation or honest “not available until Native” | Remove fake success path; surface NATIVE_CLOSED state | MOCK | VPN/DNS NATIVE_CLOSED | No | CE-B0 |
| CE-G005 | EDU:ح | SCR-FAT-051 | JRN-FAT-23 | HONESTY | P1 | Praise copy/toast: “sent to {name}'s screen” | Local-only: save encouragement locally; do not claim delivery to child device | ARB + flow honesty; optional local journal without remote claim | LOCAL_DEMO | Child notify REMOTE_CLOSED | No | CE-B0 |
| CE-G006 | SEC:ط | SCR-FAT-037 | JRN-FAT-18 | HONESTY | P1 | Status language “Device locked/unlocked” while Device Admin mock | Copy must state local preference / request only until OS lock NAT | Relabel status + consequence; keep prefs REAL_LOCAL | REAL_LOCAL + NATIVE_CLOSED | Device Admin NATIVE_CLOSED | Yes — Q-CEX-002 | CE-B0 |
| CE-G007 | SEC:ط | SCR-FAT-037 | JRN-FAT-18 | CONTROL | P1 | Prefs persist lock mode but OS lock not enforced | Control consequence = local intent recorded; OS enforce gated Native | Keep prefs; clarify consequence UI; no fake grant | REAL_LOCAL + NATIVE_CLOSED | Device Admin NATIVE_CLOSED | No | CE-B3 |
| CE-G008 | SEC:ي | SCR-FAT-069 | JRN-FAT-33 | LOCAL | P1 | Default repository prototype metrics (e.g. weekHours 18, chart heights) | Empty or derived from Local ST facts; no live-looking prototype as default | Empty-first + bind to Local ST usage facts where owned | MOCK | Email/PDF REMOTE_CLOSED | No | CE-B2 |
| CE-G009 | SEC:ي | SCR-FAT-081 | JRN-FAT-33 | LOCAL | P1 | Peer compare prototype metrics + ageYears sample | Anonymous compare UI must not present sample as live cohort | Empty/MOCK banner; no live claim | MOCK | Email/PDF REMOTE_CLOSED | No | CE-B2 |
| CE-G010 | AIC:د | SCR-FAT-086 | JRN-FAT-45 | LOCAL | P1 | Family moments default prototype numerals (learnHours/verses/tasks) | Moments aggregate from Local facts or honest empty | Empty-first; remove live prototype default | MOCK | Advisor REMOTE_CLOSED | No | CE-B2 |
| CE-G011 | SEC:و | SCR-FAT-065 | JRN-FAT-31 | LOCAL | P1 | Smart alerts default `smartAlertsPrototypeFixture()` | Empty until Local events / FS-007 facts; no planted alerts as live | Empty-first + bind to local alert pipeline | MOCK | MediaProjection NATIVE_CLOSED; Advisor REMOTE_CLOSED | No | CE-B5 |
| CE-G012 | COM:و | SCR-FAT-054 | JRN-FAT-25;JRN-MOT-08 | LOCAL | P1 | InMemory + prototype seed; no Local KV bind (unlike ST/EDU spine) | REAL_LOCAL tasks store with restart proof | Add Local persistence seam; empty-first | MOCK | None for Local bind | No | CE-B1 |
| CE-G013 | COM:و | SCR-FAT-055 | JRN-FAT-25 | LOCAL | P1 | Create task uses same InMemory authority | Same Local store as FAT-054 | Share Local repository | MOCK | None | No | CE-B1 |
| CE-G014 | COM:و | SCR-CHD-022 | JRN-CHD-12 | LOCAL | P1 | Child tasks projection still InMemory-backed | Father↔child loop on REAL_LOCAL store | Bind child view to Local family tasks | MOCK | None | No | CE-B1 |
| CE-G015 | COM:و | SCR-FAT-054 | JRN-FAT-25 | CONTROL | P1 | `rewardMinutes` is raw `int` (Rule 4) | Minutes value object; earn via PolicyEngine | Migrate model + approve path to Minutes/PolicyEngine.earn | MOCK | None | Yes — Q-CEX-003 | CE-B1 |
| CE-G016 | COM:هـ | SCR-FAT-052 | JRN-FAT-24;JRN-MOT-08 | LOCAL | P1 | Calendar InMemory + prototype fixture | REAL_LOCAL calendar events | Local KV/SQLite bind; empty-first | MOCK | None | No | CE-B1 |
| CE-G017 | COM:هـ | SCR-FAT-053 | JRN-FAT-24 | LOCAL | P1 | Add event writes InMemory only | Persist via Local calendar store | Bind create to Local | MOCK | None | No | CE-B1 |
| CE-G018 | COM:د | SCR-FAT-070 | JRN-FAT-34 | LOCAL | P1 | Outer circle InMemory + prototype | REAL_LOCAL circle authority | Local bind + strangers-locked policy preserved | MOCK | Chat apply REMOTE_CLOSED | No | CE-B1 |
| CE-G019 | COM:د | SCR-FAT-071 | JRN-FAT-34;JRN-CHD-13 | LOCAL | P1 | Friend approval InMemory | Approve/deny persist Local and update circle | Local bind shared with FAT-070 | MOCK | None | No | CE-B1 |
| CE-G020 | COM:د | SCR-CHD-030 | JRN-CHD-13 | LOCAL | P1 | Child friends projection InMemory | Project from Local circle | Bind projection | MOCK | LiveKit NATIVE_CLOSED for call CTA | No | CE-B1 |
| CE-G021 | COM:ج | SCR-CHD-023 | JRN-CHD-11 | LOCAL | P1 | Media share prototype + RAM intent queue | Local journal of share intents; camera/mic remain NAT CLOSED | Persist intents; honesty for capture | MOCK + NATIVE_CLOSED | Camera/mic NATIVE_CLOSED; chat REMOTE_CLOSED | No | CE-B1 |
| CE-G022 | COM:ز | SCR-CHD-024 | JRN-CHD-11 | LOCAL | P1 | Arrival check-in journal in RAM; prototype zones | Local check-in journal; GPS still NAT CLOSED | Persist journal; keep GPS honesty | MOCK + NATIVE_CLOSED | GPS NATIVE_CLOSED; FCM REMOTE_CLOSED | No | CE-B1 |
| CE-G023 | EDU:ح | SCR-CHD-035 | JRN-CHD-17 | LOCAL | P1 | Focus sounds prototype + InMemory prefs (no persistence) | Local prefs for selected sounds | Persist selection | MOCK | None | No | CE-B1 |
| CE-G024 | SEC:ب | SCR-FAT-034 | JRN-FAT-16 | LOCAL | P1 | Default app inventory seeds prototype apps/usage minutes | Empty or device-discovered inventory; Local dispositions only | Empty-first inventory; keep allow/block Local | LOCAL_DEMO | OS intercept NATIVE_CLOSED | No | CE-B3 |
| CE-G025 | SEC:ب | SCR-FAT-034 | JRN-FAT-16 | CONTROL | P1 | Allow/block Local; OS intercept MOCK-REMOTE | Consequence = Local policy only until Native | Keep honesty badge; clarify control consequence | LOCAL_DEMO + NATIVE_CLOSED | OS intercept NATIVE_CLOSED | No | CE-B3 |
| CE-G026 | SEC:ج | SCR-FAT-036 | JRN-FAT-17 | CONTROL | P1 | Categories/prefs Local; VPN/DNS not enforced | Same: Local policy configured; enforce NAT gated | Keep MOCK-REMOTE honesty; strengthen consequence copy | REAL_LOCAL + NATIVE_CLOSED | VPN/DNS NATIVE_CLOSED | No | CE-B3 |
| CE-G027 | SEC:أ | SCR-FAT-032 | JRN-FAT-15 | CONTROL | P2 | Strong Local ST bind; OS enforce closed; sync chip can show `delivered` | Sync chip = local bus only wording | Relabel PolicySyncStatus UI | REAL_LOCAL + NATIVE_CLOSED | OS enforce NATIVE_CLOSED; sync REMOTE_CLOSED | No | CE-B3 |
| CE-G028 | SEC:أ | SCR-CHD-004 | JRN-CHD-02 | HONESTY | P2 | `isChildOnline` / last-synced line = same-session bus | Do not imply true network online | Relabel online/sync as local session | REAL_LOCAL | Multi-device REMOTE_CLOSED | No | CE-B0 |
| CE-G029 | SEC:د | SCR-FAT-014 | JRN-FAT-07;JRN-MOT-06 | NATIVE_CLOSED | P2 | Map UI + GPS NOT_IMPLEMENTED banner | Keep designed UI; never claim live fix | No Fake live; Native later | NATIVE_CLOSED | GPS NATIVE_CLOSED | No | CE-B7 |
| CE-G030 | SEC:د | SCR-FAT-015 | JRN-FAT-07 | NATIVE_CLOSED | P2 | History UI without GPS plane | Local history of recorded points only when available | Keep honesty | NATIVE_CLOSED | GPS NATIVE_CLOSED | No | CE-B7 |
| CE-G031 | SEC:د | SCR-FAT-016 | JRN-FAT-08 | NATIVE_CLOSED | P2 | Safe zones CRUD UI; geofence events NAT closed | Zones Local; enter/exit events Native later | Persist zones Local deepen if missing | LOCAL UI + NATIVE_CLOSED | GPS NATIVE_CLOSED | No | CE-B3 |
| CE-G032 | SEC:د | SCR-FAT-017 | JRN-FAT-08 | NATIVE_CLOSED | P2 | Create zone UI; radius alerts NAT closed | Same as CE-G031 | Same | LOCAL UI + NATIVE_CLOSED | GPS NATIVE_CLOSED | No | CE-B3 |
| CE-G033 | ADM:ز | SCR-FAT-013 | JRN-FAT-06;JRN-MOT-03 | HONESTY | P2 | Profile shows location cards; GPS NAT CLOSED honesty present | Maintain honesty; LOCAL_DEMO roster | Keep banners; deepen Local non-GPS fields | LOCAL_DEMO | GPS NATIVE_CLOSED | No | CE-B3 |
| CE-G034 | ADM:أ | SCR-FAT-006 | JRN-FAT-02 | EXPERIENCE | P2 | Link success can celebrate without enrolled device path | Fail-closed enrollment path primary | Prefer managed enrollment state | LOCAL_DEMO | GPS NATIVE_CLOSED | No | CE-B3 |
| CE-G035 | SEC:هـ | SCR-FAT-018 | JRN-FAT-09;JRN-MOT-05 | HONESTY | P2 | Local SOS fire real; delivery enum includes delivered; FCM CLOSED banner | Delivery states must not claim remote delivered | Align delivery UI to Local vs REMOTE_CLOSED | REAL_LOCAL + REMOTE_CLOSED | FCM/SMS NATIVE+REMOTE | No | CE-B0 |
| CE-G036 | SEC:هـ | SCR-CHD-005 | JRN-CHD-03 | HONESTY | P2 | Child SOS button; remote delivery closed | Same delivery honesty | Same | REAL_LOCAL + REMOTE_CLOSED | FCM/SMS | No | CE-B0 |
| CE-G037 | SEC:هـ | SCR-CHD-006 | JRN-CHD-03 | HONESTY | P2 | In-progress UI; auto-call/delivery closed | Honest in-progress = Local ladder only | Same | REAL_LOCAL + REMOTE_CLOSED | Telephony/FCM | No | CE-B0 |
| CE-G038 | SEC:هـ | SCR-FAT-028 | JRN-FAT-08;JRN-FAT-09 | CONTROL | P2 | Emergency contacts Local UI; external SMS closed | Contacts Local; SMS NAT/REM later | Keep Local contacts; honesty | LOCAL UI + REMOTE_CLOSED | SMS/FCM | No | CE-B3 |
| CE-G039 | COM:ب | SCR-FAT-023 | JRN-FAT-12;JRN-MOT-04 | NATIVE_CLOSED | P2 | Active call UI without LiveKit | Designed call UI; NAT CLOSED toast/banner | Keep; no fake connected media | NATIVE_CLOSED | LiveKit NATIVE_CLOSED | No | CE-B7 |
| CE-G040 | COM:ب | SCR-FAT-024 | JRN-FAT-12 | NATIVE_CLOSED | P2 | Call history Local UI / mock | Local history of attempted sessions only | Persist Local call attempts if desired | LOCAL UI + NATIVE_CLOSED | LiveKit | No | CE-B1 |
| CE-G041 | COM:ب | SCR-CHD-009 | JRN-CHD-04 | NATIVE_CLOSED | P2 | Child active call UI | Same as FAT-023 | Same | NATIVE_CLOSED | LiveKit | No | CE-B7 |
| CE-G042 | COM:ب | SCR-CHD-036 | JRN-CHD-17 | NATIVE_CLOSED | P2 | Call play UI | Same | Same | NATIVE_CLOSED | LiveKit | No | CE-B7 |
| CE-G043 | SEC:و | SCR-FAT-067 | JRN-FAT-32 | NATIVE_CLOSED | P2 | Supervision prefs; MediaProjection CLOSED honesty | Prefs Local; capture NAT later | Keep SET-016 honesty | LOCAL UI + NATIVE_CLOSED | MediaProjection | No | CE-B7 |
| CE-G044 | SEC:أ | SCR-FAT-085 | JRN-FAT-44 | NATIVE_CLOSED | P2 | Smart modes UI; OS wake MOCK-REMOTE | Modes Local schedule; wake NAT later | Keep honesty badge | LOCAL UI + NATIVE_CLOSED | OS wake | No | CE-B7 |
| CE-G045 | EDU:ح | SCR-CHD-018 | JRN-CHD-09 | NATIVE_CLOSED | P2 | Focus mode UI; OS wake closed | Focus Local timer; wake NAT later | Keep honesty | LOCAL UI + NATIVE_CLOSED | OS wake | No | CE-B7 |
| CE-G046 | ADM:د | SCR-FAT-056 | JRN-FAT-26 | REMOTE_CLOSED | P2 | Plans UI; billing REM CLOSED | Catalog only; SOS never gated | Keep honesty | REMOTE_CLOSED | Billing backend | No | CE-B8 |
| CE-G047 | ADM:د | SCR-FAT-057 | JRN-FAT-26 | REMOTE_CLOSED | P2 | Manage subscription UI mock | Same | Keep honesty | REMOTE_CLOSED | Billing | No | CE-B8 |
| CE-G048 | ADM:هـ | SCR-FAT-058 | JRN-FAT-27 | NATIVE_CLOSED | P2 | Notif prefs REAL_LOCAL; FCM delivery closed | Prefs Local; push NAT/REM later | Keep SOS unmute; honesty on delivery | REAL_LOCAL | FCM | No | CE-B7 |
| CE-G049 | AIC:ب | SCR-FAT-062 | JRN-FAT-29 | REMOTE_CLOSED | P2 | Patterns UI on Insights mock | Suggest/review mock; Gateway later | Uniform MOCK/REM banner | MOCK + REMOTE_CLOSED | Insights Gateway | No | CE-B5 |
| CE-G050 | AIC:ج | SCR-FAT-063 | JRN-FAT-29 | REMOTE_CLOSED | P2 | Timeline mock | Same | Same | MOCK + REMOTE_CLOSED | Knowledge Gateway | No | CE-B5 |
| CE-G051 | AIC:ج | SCR-FAT-064 | JRN-FAT-29 | REMOTE_CLOSED | P2 | Knowledge maps mock | Same | Same | MOCK + REMOTE_CLOSED | Knowledge Gateway | No | CE-B5 |
| CE-G052 | AIC:هـ | SCR-FAT-074 | JRN-FAT-37 | REMOTE_CLOSED | P2 | Advisor hub mock; suggest-only | Rule 7 approve/reject only | Keep; no execute | MOCK + REMOTE_CLOSED | Assistant Gateway | No | CE-B5 |
| CE-G053 | AIC:هـ | SCR-FAT-076 | JRN-MOT-09 | REMOTE_CLOSED | P2 | Mother AI feed mock | Same | Same | MOCK + REMOTE_CLOSED | Assistant Gateway | No | CE-B5 |
| CE-G054 | AIC:هـ | SCR-FAT-083 | JRN-FAT-37 | REMOTE_CLOSED | P2 | Voice advisor UI mock | Same | Same | MOCK + REMOTE_CLOSED | Assistant Gateway | No | CE-B5 |
| CE-G055 | AIC:و | SCR-FAT-079 | JRN-FAT-41 | REMOTE_CLOSED | P2 | Delegated agent rules UI | Suggest-only structural | Keep no execute() | MOCK + REMOTE_CLOSED | Agent Gateway | No | CE-B5 |
| CE-G056 | AIC:و | SCR-FAT-080 | JRN-FAT-41 | REMOTE_CLOSED | P2 | Agent action log UI | Local log of suggestions only | Keep honesty | MOCK + REMOTE_CLOSED | Agent Gateway | No | CE-B5 |
| CE-G057 | EDU:أ | SCR-FAT-048 | JRN-FAT-23 | REMOTE_CLOSED | P2 | Materials UI; licensed remote closed | Catalog Local UI only | Keep honesty | REMOTE_CLOSED | Licensed materials | No | CE-B8 |
| CE-G058 | EDU:ز | SCR-FAT-072 | JRN-FAT-35 | LOCAL | P1 | Quran progress Local UI; GapClose 004–007 OPEN in GAP_LOG | Complete Local Quran deepen authorized by Owner | Execute Quran GapClose 004–007 | LOCAL UI + REMOTE_CLOSED | Licensed Quran REMOTE_CLOSED | Yes — Q-CEX-004 | CE-B4 |
| CE-G059 | EDU:ز | SCR-CHD-025 | JRN-CHD-14 | LOCAL | P1 | Quran ward OPEN residual | Same batch | Same | LOCAL UI + REMOTE_CLOSED | Licensed Quran | Yes — Q-CEX-004 | CE-B4 |
| CE-G060 | EDU:ز | SCR-CHD-026 | JRN-CHD-14 | LOCAL | P1 | Memorization OPEN residual | Same | Same | LOCAL UI + REMOTE_CLOSED | Licensed Quran | Yes — Q-CEX-004 | CE-B4 |
| CE-G061 | EDU:ز | SCR-CHD-027 | JRN-CHD-14 | LOCAL | P1 | Athkar OPEN residual | Same | Same | LOCAL UI + REMOTE_CLOSED | Licensed Quran | Yes — Q-CEX-004 | CE-B4 |
| CE-G062 | EDU:ب | SCR-FAT-049 | JRN-FAT-23 | LOCAL | P2 | create_assignment still InMemory while LearningAssignment has Local rebind path | Single Local authority for assignments | Rebind create path to EducationLocalPersistence | MIXED | None | No | CE-B1 |
| CE-G063 | EDU:د | SCR-CHD-017 | JRN-CHD-08 | REMOTE_CLOSED | P2 | Socratic tutor Local UI; Tutor Gateway CLOSED | Local scripted/mock tutor only | Keep honesty; no on-device LLM claim | LOCAL UI + REMOTE_CLOSED | Tutor Gateway | No | CE-B5 |
| CE-G064 | EDU:د | SCR-CHD-033 | JRN-CHD-17 | REMOTE_CLOSED | P2 | Interactive stories Tutor REM CLOSED | Same | Same | REMOTE_CLOSED | Tutor Gateway | No | CE-B5 |
| CE-G065 | AIC:د | SCR-FAT-043 | JRN-FAT-21 | REMOTE_CLOSED | P2 | Studio outputs Local; Advisor generate CLOSED | Parent approve Local; no fake generate success | Keep Rule 7 | LOCAL UI + REMOTE_CLOSED | Advisor Gateway | No | CE-B5 |
| CE-G066 | AIC:د | SCR-FAT-044 | JRN-FAT-21 | CONTROL | P2 | Preview approve Local OK | Keep approve/reject; never auto-execute | None if already Rule 7 | LOCAL UI + REMOTE_CLOSED | Advisor Gateway | No | CE-B5 |
| CE-G067 | SEC:ي | SCR-FAT-073 | JRN-FAT-36 | REMOTE_CLOSED | P2 | Weekly report Local UI; Email/PDF + Gateway CLOSED | Local text report; export gated | Keep honesty; REP-C1 blocks PDF | LOCAL UI + REMOTE_CLOSED | Email/PDF; Advisor | Yes — REP-C1 | CE-B6 |
| CE-G068 | ADM:ب | SCR-FAT-008 | JRN-FAT-04 | HONESTY | P2 | Invite Local; toast “Invite sent…”; email/FCM CLOSED | Local invite token created; delivery REM CLOSED | Soften “sent” to local-created if needed | REAL_LOCAL | Email/FCM REMOTE_CLOSED | No | CE-B0 |
| CE-G069 | ADM:ب | SCR-FAT-009 | JRN-MOT-01 | EXPERIENCE | P2 | Accept invite Local fail-closed | Keep fail-closed; no role picker | None if already compliant | REAL_LOCAL | Backend join REMOTE_CLOSED | No | CE-B3 |
| CE-G070 | ADM:ز | SCR-FAT-010 | JRN-FAT-05;JRN-MOT-02 | LOCAL | P2 | Day board Identity roster LOCAL_DEMO honesty | Keep LOCAL_DEMO banner; no prototype numerals as live telemetry | Audit residual prototype numerals | LOCAL_DEMO | None | No | CE-B3 |
| CE-G071 | ADM:ز | SCR-FAT-012 | JRN-FAT-06;JRN-MOT-03 | LOCAL | P2 | Children list Local KV + LOCAL_DEMO_SEEDED banner | Keep honesty | None critical | LOCAL_DEMO | None | No | CE-B3 |
| CE-G072 | COM:أ | SCR-FAT-021 | JRN-FAT-11;JRN-MOT-04 | EXPERIENCE | P2 | Local thread list; empty InMemory default; REMOTE banner | Empty state via AppEmptyState; never plan-gate | Ensure empty template when no threads | LOCAL_DEMO | Chat relay REMOTE_CLOSED | No | CE-B1 |
| CE-G073 | COM:أ | SCR-CHD-007 | JRN-CHD-04 | EXPERIENCE | P2 | Child chat list same | Same | Same | LOCAL_DEMO | Chat relay | No | CE-B1 |
| CE-G074 | ADM:ج | SCR-SHR-005 | JRN-SHR-01 | VISUAL | P3 | Network error catalog template present | Production screens should reuse AppErrorState | Adoption pass where missing | candidacy | None | No | CE-B5 |
| CE-G075 | ADM:ج | SCR-SHR-006 | JRN-SHR-01 | VISUAL | P3 | Empty catalog template present | Production lists should reuse AppEmptyState | Adoption pass on MOCK-default lists | candidacy | None | No | CE-B5 |
| CE-G076 | CROSS | many MOCK screens | many | VISUAL | P2 | Prototype fixtures hide empty/error states | Full state range: empty/loading/error/offline/stale | Empty-first defaults + state coverage | MOCK | Varies | No | CE-B5 |
| CE-G077 | CROSS | — | — | VISUAL | P3 | KEEP+REFINE tokens largely followed; no redesign | Maintain consistency; no brand redesign | Spot-fix density only if Owner authorizes | N/A | None | No | CE-B5 |
| CE-G078 | SEC:ك | SCR-FAT-077 | JRN-FAT-39 | EXPERIENCE | P3 | OUT OF SCOPE / unrouted | Remain OOS until Owner reopens | Do not resurrect | OOS | None | Yes if reopen | — |
| CE-G079 | SEC:ل | SCR-FAT-039 | JRN-FAT-20 | EXPERIENCE | P3 | Tombstone ADR-034 | Remain tombstone; Modes on FAT-085 | Do not resurrect | OOS | OS wake | No | — |
| CE-G080 | FS-008 | — | — | OWNER_DECISION | P1 | Zero SCR / zero JRN; AUD-C* open | Owner policy before Local/NAT | Answer AUD-C1/C2/C3/C6 | DESIGN GAP | Mic NATIVE_CLOSED | Yes — AUD-C* | CE-B6 |
| CE-G081 | FS-009 | SCR-FAT-069;073 | JRN-FAT-33;36 | OWNER_DECISION | P1 | PDF/export mandate OPEN (REP-C1) | Owner PDF law before share plane | Answer REP-C1/C2 | DESIGN GAP | Share sheet NATIVE; Email REMOTE | Yes — REP-C* | CE-B6 |
| CE-G082 | FS-010 | SCR-FAT-022;CHD-008 | JRN-FAT-11;CHD-04 | OWNER_DECISION | P1 | CHAT-C1/C2 open for edit/delete audit depth | Owner chat law before deepen those UX | Answer CHAT-C1/C2 | DESIGN GAP | Relay REMOTE_CLOSED | Yes — CHAT-C* | CE-B6 |
| CE-G083 | ADM:ب | — | — | OWNER_DECISION | P3 | 18 services never on journeys incl. S-ADM-012/013 | Inventory coverage (not product deletion) | Registry hygiene separate | REGISTRY GAP | None | No | W6 / CE-B5 |
| CE-G084 | AIC:أ | SCR-FAT-019 | JRN-FAT-10 | EXPERIENCE | P2 | Alerts hub empty InMemory until seed | Empty template + real event pipeline types | Bind to LocalEvent / safety alerts | MOCK | None | No | CE-B5 |
| CE-G085 | ADM:و | SCR-FAT-060 | JRN-FAT-28 | CONTROL | P3 | Audit append-only Local strong | Keep no update/delete | None | REAL_LOCAL | None | No | — |
| CE-G086 | SEC:أ | SCR-FAT-033 | JRN-FAT-15;JRN-MOT-07 | CONTROL | P2 | Time-request approve Local loop; FCM notify closed | Local inbox loop sufficient; push later | Keep request inbox honesty banner | REAL_LOCAL | FCM REMOTE_CLOSED | No | CE-B3 |
| CE-G087 | SEC:أ | SCR-CHD-020 | JRN-CHD-06 | CONTROL | P2 | Child time request Local | Same loop | Keep | REAL_LOCAL | FCM | No | CE-B3 |
| CE-G088 | SEC:أ | SCR-CHD-021 | JRN-CHD-06 | CONTROL | P2 | Time expiry; chat/Quran/SOS never locked | Keep Rules 9/11 | None if already proven | REAL_LOCAL | None | No | — |
| CE-G089 | COM:و | SCR-FAT-082 | JRN-FAT-42 | HONESTY | P2 | ChoreAI suggest→approve into tasks; REM CLOSED honesty | Keep suggest-only; write tasks Local after approve | After CE-G012 Local bind, approve writes Local | LOCAL UI + REMOTE_CLOSED | Advisor REMOTE_CLOSED | No | CE-B1 |
| CE-G090 | CROSS | — | — | EXPERIENCE | P3 | Composition soft-fail may retain InMemory with debug note | Fail-closed honesty already preferred | Monitor bind failures; never claim durable on Memory fallback | MIXED | None | No | CE-B3 |

---

## Counts by category

| category | count |
|----------|------:|
| HONESTY | 12 |
| CONTROL | 14 |
| LOCAL | 22 |
| EXPERIENCE | 10 |
| VISUAL | 4 |
| NATIVE_CLOSED | 12 |
| REMOTE_CLOSED | 16 |
| OWNER_DECISION | 4 |
| **Total rows** | **90** |

> Note: Audit §9 rollup groups some NATIVE/REMOTE rows under Honesty/Control for Owner reporting; this register uses primary category per row.

## Counts by severity

| severity | count |
|----------|------:|
| P0 | 0 |
| P1 | 28 |
| P2 | 52 |
| P3 | 10 |

## Counts by execution batch

| batch | count | intent |
|-------|------:|--------|
| CE-B0 | 12 | Honesty hotfix (copy/ticks/Synced/locked/sent) |
| CE-B1 | 18 | Local bind — family ops (tasks/calendar/circle/media/arrival) |
| CE-B2 | 3 | Reports empty-first |
| CE-B3 | 16 | Control spine polish |
| CE-B4 | 4 | Quran GapClose (Owner Q-CEX-004) |
| CE-B5 | 16 | EDU/AIC mock honesty + state templates |
| CE-B6 | 4 | Policy-gated FS-008/009/010 |
| CE-B7 | 12 | Native wave (gated) |
| CE-B8 | 3 | Remote wave (gated) |
| — (none / keep) | 2 | OOS / already strong |

## Policy / Owner decision index

| id | gaps | blocks |
|----|------|--------|
| Q-CEX-001 | CE-G001, CE-G002 | Chat ticks honesty |
| Q-CEX-002 | CE-G006 | Instant-lock copy |
| Q-CEX-003 | CE-G015 | Tasks Minutes VO |
| Q-CEX-004 | CE-G058…061 | Quran Local GapClose |
| AUD-C* | CE-G080 | FS-008 |
| REP-C* | CE-G067, CE-G081 | PDF/export |
| CHAT-C* | CE-G082 | Chat edit/delete audit |

---

## Stop

Register complete. **Await Owner authorization** before CE-B* implementation.
