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

## Batch GH-2 — CHILD-APP (Session Pass 6) · merged 2026-09-21

Source: external gap-hunter, fresh public-repo clone. Verified line-by-line against frozen prototype (verdict: docs/project-plan/11-gap-hunter-batch2-verdict.md). 20 findings: 18 merged, 2 revised-then-merged, 0 rejected (rejection archive: docs/gap-review/rejected.md). Closure specs (11-field) adopted by reference; transplant into docs/project-plan/08-gap-closure-specs.md #GH-2 during conversion planning. IDs keep domain suffix (normalization deferred to spec transplant — see verdict doc).

| ID | Sev | Where | Finding (verified evidence) | Class |
|---|---|---|---|---|
| GAP-A-CHILD-003 | P1 | CHD-001/002/003/005/006/011 | bare:true screens outside stateGuard — no offline/empty/error states | ANALYSIS-GAP |
| GAP-A-CHILD-004 | P0 | approve flow | L1067 depositWallet(req.appId||'youtube') — no wallet-routing contract, silent misroute | ANALYSIS-GAP |
| GAP-A-CHILD-005 | P0 | CHD-023/CHD-036 | Off-channel minting: L3658 & L4405 pay +10 min outside the 5 sacred channels | ANALYSIS-GAP |
| GAP-A-CHILD-006 | P0 | quran flow | Contradictory prices L3640(+35)/L3170(+50)/L3735(+20)/L3739(+70)/L4352(hardcoded +30 vs q.rewardMins) | ANALYSIS-GAP |
| GAP-A-CHILD-007 | P0 | CHD-025 quiz | L3729 qList[0] single question; correct:0 x6 -> first-option-wins; attempts never consumed (farmable) | ANALYSIS-GAP |
| GAP-A-CHILD-008 | P0 | CHD-011 | One-click reveal L2747; promised 3-strike/24h lockout (L2406/L2751) has zero logic | ANALYSIS-GAP |
| GAP-A-CHILD-009 | P1 | CHD-020/004 | L2478 reply map hardcodes father attribution; mother grants (ADR-039) invisible to child | ANALYSIS-GAP |
| GAP-A-CHILD-010 | P0 | CHD-003 | Consent = setRole('child') only (L2467); no consent record/version/timestamp anywhere | ANALYSIS-GAP |
| GAP-A-CHILD-011 | P1 | CHD-010 | No retention/export/disclosure content in privacy screen | ANALYSIS-GAP |
| GAP-A-CHILD-012 | P1 | global | No ChildId param: 'خالد' x244 literals; L3921 t.kid filter; L977 KIDS[0] | ANALYSIS-GAP |
| GAP-A-CHILD-013 | P1 | CHD-018/035 | Focus start = toast only (L3813); no session record; S-5 auto-reward absent; inert swt toggles | ANALYSIS-GAP |
| GAP-A-CHILD-014 | P1 | time requests | tradeOffer written (L393/L3884) never read by decideTimeRequest — child bargain dropped | ANALYSIS-GAP |
| GAP-A-CHILD-015 | P0 | family modes | Child-side onclick nulls S.familyModes.graceLeft (L2485); setFamilyMode actorless toggle (L1063) — ADR-035 breach path | ANALYSIS-GAP |
| GAP-D-CHILD-002 | P2 | CHD-022/004 | 3rd-person pronoun on child screen; dual field extraMins||points (L2654) | ANALYSIS-GAP |
| GAP-D-CHILD-003 | P1 | CHD-019 | Blocked apps filtered out of child wallet WITH their balances (L878) | ANALYSIS-GAP |
| GAP-D-CHILD-004 | P2 | CHD-023 | 'احتاج مراجعة' = card flip + toast, no review queue (L3698) | ANALYSIS-GAP |
| GAP-D-CHILD-005 | P1 | arrival alert | REVISED: father widget DOES render battery/sentLove (L1817-1916); real gap = promised child-side received-love never rendered; battery has no data contract (static everywhere) | ANALYSIS-GAP |
| GAP-OPP-CHILD-001 | OPP | refusals | Fairness receipt on refusal (why/who/what-next) | V1.1-SUPREMACY |
| GAP-OPP-CHILD-002 | OPP | child home | Weekly child trust digest | V1.1-SUPREMACY |
| GAP-OPP-CHILD-003 | OPP | offline | Offline promise card (what still works offline) | V1.1-SUPREMACY |

P0 cumulative after GH-2 = 10. Economic-integrity cluster (GH-1 SEC-002 + A-004/005/006/007) closes as ONE architecture: the Minute Ledger (single source of truth; channel whitelist = the 5; one rewards price table; server-side attempt consumption).

## Batch GH-3 — SEC Session Pass 2 · merged 2026-09-21

Source: external gap-hunter, current repo clone (read GAP_LOG + handoff/04 + prior batches; exclusion discipline verified). Verified line-by-line (verdict: docs/project-plan/12-gap-hunter-batch3-verdict.md). 22 findings: 21 merged, 1 revised-then-merged, 0 rejected. Verifier added bonus evidence on A-006/A-011 (add-sheet hardcodes delay:60 + location:true) and A-016 (routerGuide fake verification toast, L903). Auditor note: emergencyContacts fixture duplicated at L454 and L2323 with divergent shapes — conversion cleanup item.

| ID | Sev | Where | Finding (verified evidence) | Class |
|---|---|---|---|---|
| GAP-A-SEC-005 | P0 | FAT-017/016 | Safe-zone alert switches DOM-only (classList.toggle x3); saved zone has no alert/radius/child fields (L2184); S-SEC-022/024 P0 orphaned | ANALYSIS-GAP |
| GAP-A-SEC-006 | P0 | FAT-028/018 | Escalation ladder stateless; delay read-only + add-sheet hardcodes delay:60; FAT-018 L2432 contradicts: 'no escalation exists' | ANALYSIS-GAP |
| GAP-A-SEC-007 | P0 | FAT-018 · CHD-006 | No ack model; child told 'he is on his way' by string literal (L2693); close toast claims a safety log that does not exist | ANALYSIS-GAP |
| GAP-A-SEC-008 | P0 | FAT-018 · CHD-005/006 | REVISED: audio named only in desktop doc-aside note (hidden mobile); child in-app copy is location-only — audio leg unserviced + undisclosed (P-7) | ANALYSIS-GAP |
| GAP-A-SEC-009 | P0 | FAT-018/038/065/069 | No security-event store anywhere; announced VPN auto-action leaves no record; substrate finding | ANALYSIS-GAP |
| GAP-A-SEC-010 | P1 | FAT-015/069/065 | Retention asserted 4 ways (90d/30d/device-forever/S-SEC-052=30d); wipe+forget flows surfaceless | ANALYSIS-GAP |
| GAP-A-SEC-011 | P0 | FAT-028/018 | External contacts seeded verified:true with location:true; add flow grants location by default, no verification/consent artifact | ANALYSIS-GAP |
| GAP-A-SEC-012 | P1 | FAT-038 | Anti-tamper: no runtime contract; S-SEC-046 (P0) surfaceless (confirmed x0); simAlert/settingsPin serviceless; S-SEC-048 also unsurfaced | ANALYSIS-GAP |
| GAP-A-SEC-013 | P1 | FAT-038 | settingsPin = boolean with no key: no set/change/recover/lockout path (PIN field x0) | ANALYSIS-GAP |
| GAP-A-SEC-014 | P1 | FAT-013 + child screens | CHILDPREVIEW = live role switch (L666); S.preview read once (visual bar); every child action stays armed in preview | ANALYSIS-GAP |
| GAP-A-SEC-015 | P1 | FAT-036 | Web filter family-global while tiles are age-labelled; no child binding (G-5 / Ruling D) | ANALYSIS-GAP |
| GAP-A-SEC-016 | P1 | FAT-078 | Router: '12 devices' literal; guest 'protected automatically' unbacked; routerGuide test = hardcoded success toast (L903) | ANALYSIS-GAP |
| GAP-A-SEC-017 | P1 | FAT-028 | National emergency hardcoded '911'; no region resolution/fallback; S-SEC-030 P0 unbound | ANALYSIS-GAP |
| GAP-A-SEC-018 | P1 | CHD-004 · FAT-036 | Site-unlock loop one-way: decideSiteRequest toasts to father; child screen has no approved/denied branch | ANALYSIS-GAP |
| GAP-A-SEC-019 | P2 | FAT-015 | Repeated-places inference uncorrectable/unprovenanced (no confidence/threshold/actions) | ANALYSIS-GAP |
| GAP-A-SEC-020 | P2 | FAT-065/069 | Screenshot capture: no retention/access/scope contract; copy contradicts report model | ANALYSIS-GAP |
| GAP-D-SEC-002 | P0 | FAT-036/032/038 | Registered P0 controls inert: safe-search + incognito-block switches have NO handler (S-SEC-016/017); category+schedule toggles persist nothing | ANALYSIS-GAP |
| GAP-D-SEC-003 | P2 | FAT-017/016 | Zone radius persisted as prose in desc; center coords never persisted; geofence unconsumable | ANALYSIS-GAP |
| GAP-OPP-SEC-001 | OPP | SOS surfaces | Emergency receipt: who knows / who acked / what next — parent + child alike | V1.1-SUPREMACY |
| GAP-OPP-SEC-002 | OPP | FAT-038/013 | Protection-health surface admitting silent monitoring death + one-tap restore | V1.1-SUPREMACY |
| GAP-OPP-SEC-003 | OPP | FAT-028 · CHD-005/006 | Region-aware emergency intelligence + offline emergency card for the child | V1.1-SUPREMACY |
| GAP-OPP-SEC-004 | OPP | FAT-038/069/018 | Signed exportable tamper-evident security ledger (rides on A-009 store; ADR-031 already append-only) | V1.1-SUPREMACY |

P0 cumulative after GH-3 = 17. Emergency-chain cluster (A-006/007/008 + OPP-001) closes as ONE architecture: EmergencyService (events + acks + escalation runs + capture sessions); A-009's security-event store is the shared substrate for both this and the GH-2 Minute Ledger.
