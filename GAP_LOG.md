# Gap Log
Incomplete settings, dead-ends, and unclosed loops discovered during conversion (Constitution Rule 24).

**Discovery note (2026-09-20):** `SET-001…024` are **conversion backlog** seeded from Phase 4 (`docs/project-plan/05-settings-audit.md`). Per Rule 23, prototype `VISUAL` / mock toggles are deliberate sample rendering, not defects.

**Phase 6.5 (owner directive):** One-line closures are insufficient. Full analytical closure for every SET lives in [`docs/project-plan/08-gap-closure-specs.md`](docs/project-plan/08-gap-closure-specs.md). The Closure column below is a **pointer** only. UI gaps: [`docs/project-plan/09-ui-ux-gap-analysis.md`](docs/project-plan/09-ui-ux-gap-analysis.md) §8. Phase 13 imports these IDs (Section A5 — extend, do not fork).

| Screen ID | Gap found | Closure | Status |
|---|---|---|---|
| SCR-FAT-032 | SET-001: Sleep/prayer/study toggles are VISUAL-only in prototype | See [08-gap-closure-specs.md#GAP-CLOSURE-SET-001](docs/project-plan/08-gap-closure-specs.md) | CONVERSION-BACKLOG |
| SCR-FAT-032 | SET-002: No DB tables yet for daily policy / per-app wallets | See 08-gap-closure-specs.md SET-002 | CONVERSION-BACKLOG |
| SCR-FAT-032 | SET-003: Child side may lag parent schedule/cap edits | See 08-gap-closure-specs.md SET-003 | CONVERSION-BACKLOG |
| SCR-FAT-036 | SET-004: Category filter rows toggle CSS only | See 08-gap-closure-specs.md SET-004 | CONVERSION-BACKLOG |
| SCR-FAT-036 | SET-005: Polite block page + father preview not wired | See 08-gap-closure-specs.md SET-005 | CONVERSION-BACKLOG |
| SCR-FAT-036 | SET-006: Child→father unlock-request not first-class | See 08-gap-closure-specs.md SET-006 | CONVERSION-BACKLOG |
| SCR-FAT-037 | SET-007: Anti-tamper must not appear for mother | See 08-gap-closure-specs.md SET-007 | CONVERSION-BACKLOG |
| SCR-FAT-037 | SET-008: Anti-tamper switches lack documented enable effects | See 08-gap-closure-specs.md SET-008 | CONVERSION-BACKLOG |
| SCR-FAT-037 | SET-009: Mother lock vs father unlock conflict | See 08-gap-closure-specs.md SET-009 | CONVERSION-BACKLOG |
| SCR-FAT-058 | SET-010: Quiet hours must never silence SOS/critical | See 08-gap-closure-specs.md SET-010 | CONVERSION-BACKLOG |
| SCR-FAT-058 | SET-011: Mother notification identity must not clone father | See 08-gap-closure-specs.md SET-011 | CONVERSION-BACKLOG |
| SCR-FAT-059 | SET-012: Child transparency must mirror collection toggles | See 08-gap-closure-specs.md SET-012 | CONVERSION-BACKLOG |
| SCR-FAT-059 | SET-013: Forget vs wipe need separate confirmations | See 08-gap-closure-specs.md SET-013 | CONVERSION-BACKLOG |
| SCR-FAT-029 | SET-014: AI stages are server flags, not local inference unlocks | See 08-gap-closure-specs.md SET-014 | CONVERSION-BACKLOG |
| SCR-FAT-029 | SET-015: Mother must not open brain control even at FULL | See 08-gap-closure-specs.md SET-015 | CONVERSION-BACKLOG |
| SCR-FAT-067 | SET-016: Platform toggles must read capability table | See 08-gap-closure-specs.md SET-016 | CONVERSION-BACKLOG |
| SCR-FAT-068 | SET-017: Disabled iOS claims must not look enabled | See 08-gap-closure-specs.md SET-017 | CONVERSION-BACKLOG |
| SCR-FAT-085 | SET-018: School services must not route via tombstone FAT-039 | See 08-gap-closure-specs.md SET-018 | CONVERSION-BACKLOG |
| SCR-CHD-004 | SET-019: Child status card must follow active mode stream | See 08-gap-closure-specs.md SET-019 | CONVERSION-BACKLOG |
| SCR-FAT-028 | SET-020: Parents cannot be removed from SOS rung 1 | See 08-gap-closure-specs.md SET-020 | CONVERSION-BACKLOG |
| SCR-FAT-028 | SET-021: No SOS mute settings for mother/guardian | See 08-gap-closure-specs.md SET-021 | CONVERSION-BACKLOG |
| SCR-FAT-079 | SET-022: Separate “AI suggestions” from “My rules” UI | See 08-gap-closure-specs.md SET-022 | CONVERSION-BACKLOG |
| SCR-FAT-079 | SET-023: Rule editor blocks owner-only consequents | See 08-gap-closure-specs.md SET-023 | CONVERSION-BACKLOG |
| SCR-FAT-032 | SET-024: Wallet overflow father switch missing (Ruling B) | See 08-gap-closure-specs.md SET-024 | CONVERSION-BACKLOG |
| (UI cross-cut) | UI-001…018: production UI completeness gaps | See [09-ui-ux-gap-analysis.md §8](docs/project-plan/09-ui-ux-gap-analysis.md) | CONVERSION-BACKLOG |


---

## Batch GH-1 — Gap-Hunter sweep (2026-09-20) · verdict: docs/project-plan/10-gap-hunter-batch1-verdict.md
Verified locally against current main (line-level evidence in verdict doc). 20 merged / 1 rejected (GAP-A-AIC-002 = countdown snapshot, not a violation → replaced by conversion note: central `undo_window=600s`).

| ID | Sev (post-audit) | Screen(s) | Gap | Class |
|---|---|---|---|---|
| GAP-A-SEC-001 | P1 | all non-bare (stateGuard) | No offline/partial-sync/expired states; lastSync hardcoded | ANALYSIS-GAP |
| GAP-A-SEC-002 | **P0** | CHD-019, FAT-072/054/037/033 | No minute_ledger: every ±minute lacks an auditable transaction (E-1) | ANALYSIS-GAP |
| GAP-D-SEC-001 | P1 (revised) | CHD-020 | Duration choice works but send button ignores S.timeReqMins → always 30 | CONVERSION-BACKLOG |
| GAP-A-SEC-003 | P1 | CHD-020, FAT-033 | No request-spam cap; father screen renders only first pending request | ANALYSIS-GAP |
| GAP-A-SEC-004 | P1 (revised from P0) | FAT-037, FAT-080, FAT-085 | These 3 control screens have zero can() gating (others ARE gated) | ANALYSIS-GAP |
| GAP-D-COM-001 | P1 (revised from P0) | FAT-022, CHD-008 | Send is mock-toast (Rule 23); real gap = no message-insert/delivery spec, no Enter-key path | CONVERSION-BACKLOG |
| GAP-A-COM-001 | P1 | FAT-022, CHD-023 | Voice-note Arabic transcript promised in UI copy but specified nowhere | ANALYSIS-GAP |
| GAP-OPP-COM-001 | OPP | FAT-052, FAT-085 | Prayer times as mode-engine trigger (culturally unclonable) | V1.1-SUPREMACY |
| GAP-A-EDU-001 | P1 | FAT-049/050, CHD-028/012 | No placement test — adaptive plan without baseline (EDU rule 3) | ANALYSIS-GAP |
| GAP-A-EDU-002 | P1 | CHD-019/012/026, FAT-072 | No streak-freeze despite approved recommendation (09 §و-5) | ANALYSIS-GAP |
| GAP-A-EDU-003 | P1 | FAT-043/044/045 | Editing already-assigned content undefined; need content_version + pinned_version | ANALYSIS-GAP |
| GAP-OPP-EDU-001 | OPP | CHD-025/026/029, FAT-072 | Unified spaced-repetition engine across Quran + flashcards | V1.1-SUPREMACY |
| GAP-A-AIC-001 | P1 | FAT-079/080 | Agent rule-conflict resolution undefined (modes have "strictest wins", agent doesn't) | ANALYSIS-GAP |
| ~~GAP-A-AIC-002~~ | REJECTED | FAT-080 | 5:42 is a mid-countdown snapshot of the 10-min window; conversion note: central undo_window=600s | — |
| GAP-OPP-AIC-001 | OPP | FAT-074/062/073 | Evidence-backed insights: source + freshness + confidence per claim | V1.1-SUPREMACY |
| GAP-A-ADM-001 | **P0** | FAT-056/057 | No purchase-restore or downgrade surface — S-ADM-024 registered but surfaceless; store-rejection risk | ANALYSIS-GAP |
| GAP-A-ADM-002 | P1 | FAT-027/031 | No backup-guardian flow — S-ADM-013 registered but "لا يُرقّى" only | ANALYSIS-GAP |
| GAP-D-ADM-001 | P1 | FAT-061 | English row dead; zero LTR path | CONVERSION-BACKLOG |
| GAP-A-CHILD-001 | **P0** | CHD-006 | SOS cancel = one tap + sheet confirm, zero authentication (violates 06 §هـ) | ANALYSIS-GAP |
| GAP-D-CHILD-001 | P1 | CHD-010 | Objection button is toast-only; no storage, no father inbox | ANALYSIS-GAP |
| GAP-A-CHILD-002 | P1 | FAT-034, CHD-010 | No age-band engine or band-transition event (consent at 13, independence at 18) | ANALYSIS-GAP |

**Closure specs**: the 11-field specs from the hunter report are ADOPTED as drafted (with the 3 revisions above) — to be transplanted into 08-gap-closure-specs.md §GH-1 during conversion planning. Nothing touches frozen v1.0 surfaces; all closures are additive spec-layer work.
