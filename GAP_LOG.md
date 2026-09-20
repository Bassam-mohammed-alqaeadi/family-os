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
