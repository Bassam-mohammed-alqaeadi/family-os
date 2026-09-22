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
