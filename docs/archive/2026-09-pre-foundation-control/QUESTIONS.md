# QUESTIONS — owner decision channel

When an agent hits ambiguity: stop, append a question below, do not guess.  
Owner answers under the question with a date.

---

### Q-PREFLIGHT-001 — Flutter / Dart pin (blocks Stage 1)
**Date asked:** 2026-09-20  
**Why:** FVM + pubspec must match every agent session (handoff/10 A1).  
**Question:** Which Flutter stable channel version should we pin (e.g. 3.24.x / latest stable you want named)?  
**Answer:** use my flutter version that's existing in my pc , i don't need to struggle with other versions or graddle issues so use my ones  
**Resolved (2026-09-20):** Flutter **3.35.7** (stable) · Dart **3.9.2** · path `C:\src\flutter` · no FVM — pin documented in `app/README.md` + `app/pubspec.yaml` `environment`

### Q-PREFLIGHT-002 — Arabic font (blocks F0-A)
**Date asked:** 2026-09-20  
**Why:** handoff/06 left IBM Plex Sans Arabic vs Cairo open; tokens/gallery need a literal choice.  
**Question:** Bundle **IBM Plex Sans Arabic** or **Cairo** (both OFL)?  
**Answer:** use the existing best one  that suites this app  
**Resolved (2026-09-20):** **IBM Plex Sans Arabic** (400/700/800) — primary in `prototype/15_DESIGN_SYSTEM.md`; Cairo remains alternate only

<!-- Append new questions below this line -->

### Q-SPEED-001 — Fast path to Phase 1.5 (Wave 3 deferral)
**Date asked:** 2026-09-22  
**Why:** Calendar wait to Phase 1.5 is dominated by 40+ `blocked_until_stage1` SCR rows. Owner asked to execute the speed plan without lowering ship quality (still one card · verify_ship · P1–P12).  
**Question:** Enter Phase 1.5 after Wave 2 child SCR cluster ships, by **deferring** Wave 3 + non-P0 leftovers until Phase 1.5 / later re-open cards?  
**Answer:** Yes — execute fast path B: finish Wave 2 child (`SCR-CHD-012…024` except already-done `021`), defer Wave 3 + `SCR-FAT-086`, keep quality gates unchanged, then Phase 1.5 Education vertical first.  
**Resolved (2026-09-22):** Owner directive in chat (“نفذ هذه الخطه”). Deferred SCR ids listed under each BACKLOG row (`deferred · Q-SPEED-001`). Re-open only via Phase 1.5 GapClose or new ready cards — never silent.

### Q-SPEED-002 — Full catalog before Phase 1.5 + 5m loop (supersedes deferral)
**Date asked:** 2026-09-22  
**Why:** Owner clarified: keep the new shipping speed, but **do not defer any real screen** to later phases. Phase 1.5 only after every SCR is `done` (tombstones like FAT-039 excepted). Also prefers `/loop` **5m** when leaving (was 15m).  
**Question:** Cancel Wave 3 / FAT-086 deferrals from Q-SPEED-001, restore them to `ready`, keep ≥3 ships/wake cadence, arm loop at 5m?  
**Answer:** Yes — no deferrals of real screens; finish entire ScreenBuild catalog then Phase 1.5; keep fast cadence; `/loop` **5m** when leaving.  
**Resolved (2026-09-22):** Owner chat. Q-SPEED-001 deferral path **superseded**. Wave 3 + FAT-086 flipped back to `ready`. FAT-039 remains tombstone deferred (ADR-034).

### Q-VERIFY-TIERED — Scoped tests per ship + full suite every 3
**Date asked:** 2026-09-22  
**Why:** Full `flutter test` (~949 cases, ~2.5–3 min) after every card dominates wall-clock as the suite grows. Owner asked whether skipping full suite hurts quality; approved a tiered gate that keeps card-local proof + periodic full regression.  
**Question:** Adopt tiered P9 verify — (1) every card: analyze + scoped feature/shared tests; (2) every 3 ships / end of wake: full suite; (3) hard full before Phase 1.5, merge to main, Stage 3 — without weakening P1–P12 or card widget tests?  
**Answer:** Yes — implement and use as the default ship gate.  
**Resolved (2026-09-22):** Owner chat (“تمام اعتمد هذه ثم نفذها”). Spec: [`harness/12_VERIFY_TIER.md`](harness/12_VERIFY_TIER.md). Gate: `python .cursor/hooks/verify_ship.py verify` (auto tier). Force full: `--full`.

### Q-PRT-1 — kids tab count 23 vs tombstone exclusion
**Date asked:** 2026-09-22  
**Why:** PRT-1 acceptance said kids `screenIds.length == 23`, but also (a) every one of 129 **active** ids appears exactly once and (b) tombstone `SCR-FAT-039` appears nowhere. CSV has 23 rows on `أبنائي` including FAT-039; excluding the tombstone yields **22**. 14+23+11+13+15+17+32+5 = 130 (all rows); 14+22+… = 129 (actives).  
**Question:** Prefer kids=23 (include tombstone, breaking criteria 4–5) or kids=22 (exclude tombstone)?  
**Answer (agent resolution, authority order):** kids=**22** — criteria 4–5 + ADR-034/router tombstone skip override the literal “23”. Owner may overturn.  
**Resolved (2026-09-22):** Implemented kids=22; documented as PRT-1 deviation in tick report.

### Q-PRT-2 — Reopen shell wiring now (prototype phone parity)
**Date asked:** 2026-09-22  
**Why:** BACKLOG deferred PRT-2 until after Phase 1.5 Education cards. Owner installed the APK and found many screens unreachable/empty because tab chrome + hubs were never wired — ScreenBuild catalog alone ≠ prototype-shaped app.  
**Question:** Reopen **PRT-2** (FamilyShell / TabsBar / hub / FABs) **now**, ahead of remaining P15-EDU-005…007, so the Flutter app matches the frozen HTML phone shell navigation?  
**Answer:** Yes — complete wiring until the app navigates like the web prototype (`اكمل عمليه الربط الى ان تصل بالتطبيق كنفس حقنا النموذج الاولي حق صفحه الويب`).  
**Resolved (2026-09-22):** Owner chat. PRT-2 reopened; Phase 1.5 Education resumes after shell parity ships.

### Q-P175-SLICE01 — OD-B / OD-C for Slice 01 binds
**Date asked:** 2026-09-24
**Why:** Integrity OD-B (zone host Domain vs Stage-1) and OD-C (Modes-only vs Prefs fallback) blocked AUTH-FS001/005.
**Question:** Does Slice 01 authorization resolve OD-B = Domain defaults on FAT-015/016/017 and OD-C = Modes production authority (Prefs test-inject only)?
**Answer:** Yes — Owner Slice 01 authorization (controlled execution). OD-D ScheduleWindow remains ST-only (unchanged).
**Resolved (2026-09-24):** See `docs/experience_discovery/PHASE_1_75_SLICE_01_PREFLIGHT.md`.

### Q-PHASE2-FS810-IDENTITY — Name FS-008 / FS-009 / FS-010 (blocks Phase 2 analysis loop)
**Date asked:** 2026-09-25  
**Why:** Owner authorized PHASE 2 to complete L2–L3 for `FS-008 → FS-010`. Authoritative packs name **only FS-001…FS-007**. No discovery/L2/L3 titles, blueprint tree, or registry mapping exists for FS-008/009/010. Inventing titles would invent product law (forbidden).  
**Question:** What are the official system titles for **FS-008**, **FS-009**, and **FS-010**? (Assign exactly three; order = analysis order unless you specify otherwise.)  
**Evidence-only candidates (not pre-assigned):** Screen Time Final · Road Safety · Communications (COM) · Identity Final · Education/Studio/Quran cluster · Anti-tamper/Device Lock Domain · Advisor/Insights/Tutor — see `docs/experience_discovery/PHASE_2_EXECUTION_STATE.md`.  
**Answer:** **FS-008 — One-Way Audio** · **FS-009 — PDF Activity Reports** · **FS-010 — Ephemeral Family Chat** (Owner chat 2026-09-25). Canonical analysis IDs: `FS_008_One_Way_Audio` · `FS_009_PDF_Activity_Reports` · `FS_010_Ephemeral_Family_Chat`.  
**Resolved (2026-09-25):** Unblocks Phase 2 analysis loop. See `docs/experience_discovery/PHASE_2_EXECUTION_STATE.md`.

### Q-PHASE2-FS010-VS-SCOM050 — FS-010 Ephemeral Family Chat vs Domain-2 deletion of S-COM-050
**Date asked:** 2026-09-25  
**Why:** Owner named FS-010 = Ephemeral Family Chat. Domain 2 (`07_DOMAIN_2_COMMUNICATION.md`) permanently deleted `S-COM-050` temporary/disappearing messages (14 Sep 2026) as incompatible with child-protection accountability. Inventing disappearing-chat L2 would contradict Domain 2.  
**Question:** How should FS-010 be interpreted?  
**(A)** FS-010 = durable Family Chat + sync architecture where “ephemeral” means transport/relay only (not disappearing UX) — Domain 2 deletion stands.  
**(B)** Overturn Domain 2 and re-authorize disappearing/temporary messages under FS-010 (new dated Owner law).  
**(C)** Other (specify exact product law).  
**Answer:** **(A)** — FS-010 remains Ephemeral Family Chat title; product chat is **DURABLE**. “Ephemeral” = transport/relay/session semantics only. Domain-2 deletion of `S-COM-050` stands. No disappearing messages / TTL / self-destruction. (Owner chat 2026-09-25)  
**Resolved (2026-09-25):** Unblocks FS-010 L2/L3. See `docs/experience_discovery/fs010_ephemeral_family_chat/`.

### Q-FVX-D12 — Authorize the Final Visual · UX · Journey Verification gate
**Date asked:** 2026-09-25  
**Why:** `PROJECT_EXECUTION_PLAN.md` had no marker for this gate; execution batches VX-B0→B7 could not start.  
**Question:** Add a plan marker authorizing the gate?  
**Answer:** Yes — AUTHORIZED. Native/Backend still NOT authorized; KEEP + REFINE; staged batches with Owner test gates; final STOP rule.  
**Resolved (2026-09-25):** Owner chat. Marker added to `PROJECT_EXECUTION_PLAN.md` (CURRENT STATE + section) and `AGENTS.md`.

### Q-FVX-D1 — English interface
**Date asked:** 2026-09-25  
**Why:** FAT-061 English option only showed a "coming later" toast; locale hard-coded to Arabic; full English ARB exists (finding FVX-S-07).  
**Question:** Real AR/EN switch now, or Arabic-only?  
**Answer:** Turn on a REAL Arabic/English switch now — bound, persisted locally, applied app-wide.  
**Resolved (2026-09-25):** Owner chat. Extends Register G-3 (full Arabic RTL stays; English LTR added). Unblocks VX-B3 (S-07); adds EN/LTR checks to VX-B4 and VX-B7.

### Q-FVX-D2 — Wording for unavailable-capability messages
**Date asked:** 2026-09-25  
**Why:** ~50 honesty strings use engineering terms (Native/Remote/FCM/MOCK) — finding FVX-G-02.  
**Question:** Approve a short plain-language glossary? Child screens: one gentle line or none?  
**Answer:** Approve a short glossary of plain phrases; child screens get ONE gentle line.  
**Resolved (2026-09-25):** Owner chat. Glossary v1 recorded in `docs/experience_discovery/final_product_experience/FINAL_VISUAL_UX_JOURNEY_EXECUTION_PLAN.md §8.1`. Unblocks VX-B3.

### Q-FVX-D5 — Numerals on Arabic screens
**Date asked:** 2026-09-25  
**Why:** Eastern and Western digits mixed on the same screen (FVX-G-15).  
**Question:** Eastern Arabic digits or Western digits?  
**Answer:** WESTERN digits (0123) on Arabic screens.  
**Resolved (2026-09-25):** Owner chat. Supersedes prototype sample digits (sample rendering only). Unblocks VX-B3.

### Q-FVX-D7 — SOS sender when a parent triggers SOS
**Date asked:** 2026-09-25  
**Why:** SOS actor recorded inconsistently ('family', 'self', 'demo-child', call id) — FVX-G-06.  
**Question:** Record acting parent, "family", or parent + child being viewed?  
**Answer:** Record the parent PLUS the child being viewed.  
**Resolved (2026-09-25):** Owner chat. When no child is in view, record the parent only (no invented child). Unblocks VX-B2 (SOS part).

### Q-FVX-D9 — Family chat data source
**Date asked:** 2026-09-25  
**Why:** Chat repositories are empty in-memory defaults never bound; a fresh install has no thread (FVX-S-01).  
**Question:** Local seeded thread vs designed empty state?  
**Answer (Owner, Arabic):** "Seed the database for everything related to this area, then use data from a real database, not mock data."  
**Recorded interpretation (Backend/Remote still NOT authorized):** family chat uses the existing on-device persistence authority (`FsSessionKernel` → `LocalDatabase`, SQLite, same pattern as family tasks) — no second authority. On first run, family thread(s) are seeded into that local database from the REAL roster/identity (family members), and the UI reads only from it. **No mock or sample messages are seeded** — threads start empty with an honest empty state. Multi-device delivery stays REMOTE_CLOSED; calls/call history stay NATIVE_CLOSED (seeding call records that never happened would be fake data). If SQLite is unavailable and the kernel falls back to memory, the screen must say so honestly.  
**Resolved (2026-09-25):** Owner chat. Unblocks VX-B6 (chat). No remote database is required for this interpretation.

### Q-FVX-D3 — Secondary text contrast (`ink2` token)
**Date asked:** 2026-09-25  
**Why:** `ink2` grey on light surfaces falls below WCAG AA for small text (FVX-G-14); `tokens.dart` is frozen by constitution rule 21.  
**Question:** Change the token, work around it, or accept?  
**Answer:** YES — update the grey/`ink2` token where needed to meet WCAG AA 4.5:1 for body/small text. Keep the existing design; no redesign.  
**Resolved (2026-09-25):** Owner chat. **Explicit Owner authorization of a `tokens.dart` change under constitution rule 21**, limited to the contrast value(s) needed for AA. Applies in VX-B4.

### Q-FVX-D4 — Role-guard blocked landing
**Date asked:** 2026-09-25  
**Why:** A blocked role landed on the developer gallery (FVX-G-07).  
**Question:** Where does a blocked user land?  
**Answer:** YES — a child blocked from an owner-only screen lands on **My Day** (SCR-CHD-004) with a polite, human message (ARB, AR+EN). Generalized: any blocked role lands on its own home (father/mother → Today SCR-FAT-010) with the message; the developer gallery is never the landing.  
**Resolved (2026-09-25):** Owner chat. Implemented in VX-B1.

### Q-FVX-D6 — `core/policy` default IDs
**Date asked:** 2026-09-25  
**Why:** `core/policy` holds demo default child/family IDs (FVX-G-03 partial).  
**Question:** Authorize a minimal `core/policy` change?  
**Answer:** NO CHANGE — leave `core/policy` defaults untouched. Features must pass the real explicit childId/context.  
**Resolved (2026-09-25):** Owner chat. VX-B2 fixes call sites only.

### Q-FVX-D8 — Mock files inside `features/`
**Date asked:** 2026-09-25  
**Why:** Sample/demo-data files live in `features/` (rule 23, FVX-G-16).  
**Question:** Relocate now, later, or defer to Backend?  
**Answer:** YES — move sample/demo-data files into `mock/` as organizational cleanup only; no runtime behavior change, no second authority. Own optional/late batch — not VX-B1.  
**Resolved (2026-09-25):** Owner chat. Scheduled as VX-B8 (tidy), after VX-B7 and before the Final Device Pass.

### Q-FVX-D10 — Settings "other" shortcuts
**Date asked:** 2026-09-25  
**Why:** Settings shows shortcuts to FAT-009 (accept invite) and FAT-018 (SOS alert) that are redundant/dead there (FVX-S-09).  
**Question:** Remove or keep?  
**Answer:** YES — remove the two redundant/dead Settings shortcuts (accept invite, SOS alert). Keep Settings structure and all valid navigation unchanged.  
**Resolved (2026-09-25):** Owner chat. Applies in VX-B5.

### Q-FVX-D11 — SCR-FAT-077 Road safety
**Date asked:** 2026-09-25  
**Why:** FAT-077 is out of scope / archived but its route was live (FVX-C-05).  
**Question:** Redirect like FAT-039, or keep?  
**Answer:** YES — treat as a non-live legacy path; redirect to the appropriate existing live experience (FAT-039 precedent); no new feature.  
**Resolved (2026-09-25):** Owner chat. Target = SCR-FAT-075 Coming soon, which already lists Road safety as coming later (matches the prototype archive row). Implemented in VX-B1; registry row unchanged.

**All FVX Owner decisions D1–D12 are now answered.**

### Q-FVX-OD13 — SOS record: parent + viewed child together (CLOSED)
**Date asked:** 2026-09-25 (raised by VX-B2)  
**Date closed:** 2026-09-26  
**Why:** D7 asks the SOS record to hold the acting parent **and** the child being viewed. The only SOS entry, `SosFireService.fire(childId:)` in `core/policy`, carried one id, and a parent-raised SOS created no durable incident.  
**Question:** (a) authorize a minimal `core/policy` change — an optional actor field on `SosFireService.fire` and a durable incident for parent-raised SOS; or (b) keep as delivered?  
**Answer:** **(a)** — Owner direction 2026-09-26: close properly; change `core/policy` / related contracts as needed; do not preserve the prior limitation.  
**Resolved:** `SosFireService.fire` + `SosFireResult` carry `childId` (subject) + `actorId` (who pressed). `SosAlert.raisedByActorId` + `SosIncident.raisedByActorId` / `SosTriggerSource.parentAlert`. Parent `SosSender.fireThrough` opens a durable `sos_final` incident (schema v11). Child HOLD still records the child as actor. Evidence: `.verify/OD-13-SOS-PARENT-CHILD.json`.

### Q-FVX-OD14 — Education loops keyed on the `child_a` fixture (CLOSED)
**Date asked:** 2026-09-25 (raised by VX-B2)  
**Date closed:** 2026-09-26  
**Why:** child learn home, child quiz and the father's assignment/task/event/results/focus/attribution pickers all used the fixture id `child_a` on **both** sides, so loops did not follow the real roster child.  
**Question:** (a) move both sides to roster children in a later VX batch; or (b) keep until Backend?  
**Answer:** **(a)** — Owner direction 2026-09-26: remove the education dependency on sample `child_a` and bind to the real active child/family context now.  
**Resolved:** `core/identity/roster_children.dart` maps active-family children; create assignment / attribution / tasks / calendar / focus / results bind on load; child learn home + quiz resolve via `ActiveChildResolver` (default subject = `demo-child` / active roster child, never planted `child_a`). Evidence: `.verify/OD-14-EDU-ROSTER.json`.
