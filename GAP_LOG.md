# Gap Log
Incomplete settings, dead-ends, and unclosed loops discovered during conversion (Constitution Rule 24).

**Discovery note (2026-09-20):** `SET-001…024` are **conversion backlog** seeded from Phase 4 settings audit (`docs/project-plan/05-settings-audit.md`). Per Rule 23 and owner audit, prototype `VISUAL` / mock toggles are **deliberate sample rendering**, not defects. Status `CONVERSION-BACKLOG` = bind → persist → enforce in `core/policy/` → close cross-role loop. Phase 13 imports these IDs (Section A5 — extend, do not fork).

| Screen ID | Gap found | Closure | Status |
|---|---|---|---|
| SCR-FAT-032 | SET-001: Sleep/prayer/study toggles are VISUAL-only in prototype | Bind schedule toggles → schedule store → TimeEngine/modes → child calm/pause UI | CONVERSION-BACKLOG |
| SCR-FAT-032 | SET-002: No DB tables yet for daily policy / per-app wallets | Add Drift/policy + wallet persistence (schema deltas in phase 10); PolicyEngine reads store | CONVERSION-BACKLOG |
| SCR-FAT-032 | SET-003: Child side may lag parent schedule/cap edits | Same-session sync after parent save; CHD-004/019 streams update before next open | CONVERSION-BACKLOG |
| SCR-FAT-036 | SET-004: Category filter rows toggle CSS only | Each category → WebFilterPolicy persist → child block decisions | CONVERSION-BACKLOG |
| SCR-FAT-036 | SET-005: Polite block page + father preview not wired | Child block page + father preview share same policy snapshot | CONVERSION-BACKLOG |
| SCR-FAT-036 | SET-006: Child→father unlock-request not first-class | Request flow → father/mother²⁺ inbox → approve/deny → filter exception + audit | CONVERSION-BACKLOG |
| SCR-FAT-037 | SET-007: Anti-tamper must not appear for mother | RoleGuard omits surface at every mother level (**ADR-035-b** invisible, not greyed) | CONVERSION-BACKLOG |
| SCR-FAT-037 | SET-008: Anti-tamper switches lack documented enable effects | Per-switch “when enabled” lines from Register P-6; persist + OS intents + father alerts | CONVERSION-BACKLOG |
| SCR-FAT-037 | SET-009: Mother lock vs father unlock conflict | Father wins; both actions + supersession write `audit_log` (ADR-035) | CONVERSION-BACKLOG |
| SCR-FAT-058 | SET-010: Quiet hours must never silence SOS/critical | Enforce existing **Register P-4** (Rules 9/11): critical channel outside every gate including quiet hours — no new rule | CONVERSION-BACKLOG |
| SCR-FAT-058 | SET-011: Mother notification identity must not clone father | Mother prefs per R-3 / `S-AIC-029`; SOS receipt uncancellable | CONVERSION-BACKLOG |
| SCR-FAT-059 | SET-012: Child transparency must mirror collection toggles | Father privacy flips → child «ماذا يُجمع عني» updates (P-7) | CONVERSION-BACKLOG |
| SCR-FAT-059 | SET-013: Forget vs wipe need separate confirmations | Distinct flows: Advisor forget ≠ family wipe; wipe = double confirm + 7-day regret + audit | CONVERSION-BACKLOG |
| SCR-FAT-029 | SET-014: AI stages are server flags, not local inference unlocks | Stage UI = coming-soon/inactive until server flag; no on-device inference (Rule 26) | CONVERSION-BACKLOG |
| SCR-FAT-029 | SET-015: Mother must not open brain control even at FULL | RoleGuard owner-only route; deny at all mother levels | CONVERSION-BACKLOG |
| SCR-FAT-067 | SET-016: Platform toggles must read capability table | full / reports-only / unavailable from capability matrix — no fake “on” | CONVERSION-BACKLOG |
| SCR-FAT-068 | SET-017: Disabled iOS claims must not look enabled | Honest disabled UI when platform capability unavailable | CONVERSION-BACKLOG |
| SCR-FAT-085 | SET-018: School services must not route via tombstone FAT-039 | Router skips FAT-039; school config on FAT-085 only (T-1 / ADR-034) | CONVERSION-BACKLOG |
| SCR-CHD-004 | SET-019: Child status card must follow active mode stream | CHD-004/018 subscribe to active smart-mode state after parent activate | CONVERSION-BACKLOG |
| SCR-FAT-028 | SET-020: Parents cannot be removed from SOS rung 1 | Ladder editor blocks removing father/mother from step 1 (P-5) | CONVERSION-BACKLOG |
| SCR-FAT-028 | SET-021: No SOS mute settings for mother/guardian | Receipt always on; no preference row that disables SOS (P-4 / Rule 9) | CONVERSION-BACKLOG |
| SCR-FAT-079 | SET-022: Separate “AI suggestions” from “My rules” UI | Two surfaces: AiSuggestion approve/reject vs RulesEngine authored rules (ADR-038) | CONVERSION-BACKLOG |
| SCR-FAT-079 | SET-023: Rule editor blocks owner-only consequents | RulesEngine cannot author anti-tamper / block-override / delegation-edit (ADR-035 / 038) | CONVERSION-BACKLOG |
| SCR-FAT-032 | SET-024: Wallet overflow father switch missing (Ruling B) | Explicit father toggle default off; PolicyEngine enforces overflow behavior | CONVERSION-BACKLOG |
