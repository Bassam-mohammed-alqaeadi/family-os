# 07 — User Flows
**Mission:** Discovery phase 6 · Branch `discovery/master-plan`  
**Date:** 2026-09-20 · **Authority:** Section A · Policy Register · spine specs in [`04-service-catalog.md`](04-service-catalog.md) §4 · cross-role maps in [`06-cross-role-dependencies.md`](06-cross-role-dependencies.md)  
**Scope:** Complete journeys for the **12 constitutional spine** services (major services every other batch depends on). Remaining 228 services inherit these patterns in later batches / phase 7 UI audit.

---

## 0. Freeze & method

| Constraint | Status |
|---|---|
| Docs only under `docs/project-plan/` | **Honored** |
| No handoff / HTML / registry edits | **Honored** |
| Rebased on `main` @ ADR-035-b Arabic registers | **Honored** |
| Quiet hours / SOS → **P-4** only | **Honored** |
| Anti-tamper invisible to mother (**ADR-035-b**) | **Honored** |

**Chain (every flow):**  
Entry → Action → Validation → Confirmation → Processing → Result → Next → Error → Recovery

**State matrix (required columns on each flow):**  
first-time · normal · edge · empty · loading · failure · permission-denied · network · invalid-input · expired-session · conflicting · cancellation

**Composite walkthroughs:** Acceptance S1–S5 in `handoff/05_ACCEPTANCE_SCENARIOS.md` (device tests later) — mapped in §14.

---

## 1. Flow ID legend

| ID | Spine service | Primary initiator |
|---|---|---|
| UF-01 | `S-ADM-003` Pair child device (QR) | Father → Child |
| UF-02 | `S-ADM-010` Manage roles / mother level | Father OWNER |
| UF-03 | `S-SEC-001` Daily screen-time cap | Father / Mother FULL |
| UF-04 | `S-SEC-006` Per-app wallet | Father / Mother FULL |
| UF-05 | `S-SEC-004` Extra-time request | Child → Parent |
| UF-06 | `S-SEC-005` Earn minutes by achievement | Child → Approver |
| UF-07 | `S-COM-035` Link task to reward | Father |
| UF-08 | `S-SEC-026` SOS | Child → All guardians |
| UF-09 | `S-SEC-047` Instant lock | Father / Mother FULL |
| UF-10 | `S-COM-001` Family group chat | Any primary |
| UF-11 | `S-AIC-003` Risk score → alert | Advisor → Father |
| UF-12 | `S-ADM-034` Audit log | Father OWNER (read) |

---

## 2. UF-01 — Pair child device (`S-ADM-003`)

**Happy path:** FAT-004 show QR → CHD-002 scan → validate token → FAT-006 / CHD-003 success + transparency ack → child shell `CHILD_LOCKED`.

| Step | Behavior |
|---|---|
| Entry | Father: FAT-004 · Child: CHD-002 camera |
| Action | Father issues token; child claims |
| Validation | Signature, TTL, single-use, child not already paired |
| Confirmation | Transparency ack on child (WHY permissions) |
| Processing | `device` + `device_permission` + first location fix |
| Result | Role resolved by pairing — **never** a picker (SCR-SHR-004 deleted) |
| Next | Permissions explainer FAT-005 · day board |
| Error | Expired / used token · camera denied · already paired |
| Recovery | Rotate QR (`S-ADM-014`); re-grant camera; unlink then re-pair |

| State | Expected |
|---|---|
| First-time | Full FAT-001…006 onboarding chain (S1) |
| Normal | Add sibling: new QR for new `ChildId` |
| Edge | Token expires mid-scan → rotate |
| Empty | N/A (QR always generated) |
| Loading | Scanning spinner / “linking…” |
| Failure | Network drop after claim → reconcile device row on retry |
| Permission denied | Non-owner cannot issue token |
| Network | Offline child queues claim; father sees pending until ack |
| Invalid input | Malformed QR |
| Expired session | Father re-auth before new token |
| Conflicting | Second device claims same child → reject |
| Cancellation | Father dismisses QR; token invalidated |

**Cross-role:** Mother sees new device on members; Guardian none. **Law:** R-4.

---

## 3. UF-02 — Mother delegation level (`S-ADM-010`)

**Happy path:** FAT-031 select level → (downgrade: double-confirm) → save → mother notified → audit → mother’s UI matrix updates.

| Step | Behavior |
|---|---|
| Entry | FAT-027 / FAT-031 (owner-only) |
| Action | Set OBSERVER / PARTNER / FULL |
| Validation | Cannot demote owner; cannot promote guardian above OBSERVER |
| Confirmation | Downgrade = explicit double sheet |
| Processing | `member.permission_level` + `audit_log` |
| Result | Mother sees trust-language notice |
| Next | Mother opens tools; RoleGuard reflects level |
| Error | Non-owner attempt; save fail |
| Recovery | Retry; audit still records failed attempt if asserted server-side |

| State | Expected |
|---|---|
| First-time | Default **PARTNER** on invite accept |
| Normal | Upgrade PARTNER → FULL |
| Edge | Downgrade FULL → OBSERVER (double-confirm) |
| Empty | Single-parent family — still show mother invite CTA |
| Loading | Saving indicator |
| Failure | Sync fail → honest error; level unchanged locally until ack |
| Permission denied | Mother/Guardian/Child cannot open editor |
| Network | Father queues; mother updates on reconnect |
| Invalid input | Illegal level enum |
| Expired session | Re-auth owner |
| Conflicting | N/A (single writer = owner) |
| Cancellation | Dismiss confirm → no change |

**Cross-role:** Anti-tamper remains **invisible** to mother at every level (**ADR-035-b**). **SET:** none new.

---

## 4. UF-03 — Daily screen-time cap (`S-SEC-001`)

**Happy path:** Open per-child time settings → set `Minutes` cap → save → TimeEngine recalculates → child countdown updates same session after sync (**SET-003**).

| Step | Behavior |
|---|---|
| Entry | FAT-032 / profile tools (G-5) |
| Action | Edit daily entertainment cap (+ overflow flag **SET-024**) |
| Validation | `Minutes` ≥ 0; required value (no silent default) |
| Confirmation | Optional summary of exceptions list (ruling D) |
| Processing | Policy persist + push |
| Result | Child CHD-004 remaining time |
| Next | T-5 warning path; bedtime if schedule |
| Error | Sync failure; no children |
| Recovery | Offline honest last-synced; retry sync |

| State | Expected |
|---|---|
| First-time | Cap must be set before child countable use (product: force complete) |
| Normal | Adjust cap midday |
| Edge | Cap = 0 → countable locked; chat/Quran/SOS up |
| Empty | No child selected |
| Loading | Saving… |
| Failure | Persist error toast |
| Permission denied | Mother ①/② cannot edit; Mother FULL can |
| Network | Child keeps last policy until sync |
| Invalid input | Non-Minutes / negative |
| Expired session | Re-auth |
| Conflicting | Mode + grant conflict → Ruling C dialog (see UF-05) |
| Cancellation | Discard edits |

**Law:** S-1 (edu free), Ruling B, P-2. **GAP:** SET-001…003, SET-024.

---

## 5. UF-04 — Per-app wallet (`S-SEC-006`)

**Happy path:** Open app policy → set per-app `Minutes` + countable → save → child CHD-019 wallets update.

| Step | Behavior |
|---|---|
| Entry | App list / app card from child profile |
| Action | Cap + countable flag |
| Validation | App exists; blocked apps stay `countable` irrelevant — **blocked ⇒ closed** (Ruling A) |
| Confirmation | — |
| Processing | Wallet policy write |
| Result | Child per-app countdown |
| Next | T-5 per app |
| Error | Unknown app; inventory not synced |
| Recovery | Refresh inventory; retry |

| State | Expected |
|---|---|
| First-time | Empty inventory → empty-state sync CTA |
| Normal | Edit YouTube wallet |
| Edge | Balance > 0 but father-blocked → still locked (P-3) |
| Empty | No apps |
| Loading | Syncing apps… |
| Failure | Write fail |
| Permission denied | Child read-only; Mother below FULL denied |
| Network | Last-synced wallets |
| Invalid input | Bad appId |
| Expired session | Re-auth |
| Conflicting | Mode allows app but wallet empty → lock entertainment |
| Cancellation | Discard |

**GAP:** D-2 schema; SET-002 companion.

---

## 6. UF-05 — Extra-time request (`S-SEC-004`) — cross-role loop

**Happy path:** CHD-020 choose duration → submit → parent inbox → approve/reject → PolicyEngine grant → child balance + both see reason.

| Step | Behavior |
|---|---|
| Entry | CHD-020 · parent request surface / FAT-033 |
| Action | Child requests `Minutes` + reason |
| Validation | Throttle duplicates; Mother ② **and** ③ capped at **active ceiling** (default ≤30 min per doc 20 / **ADR-039**); over-ceiling grant = OWNER-only |
| Confirmation | Parent decision sheet |
| Processing | Grant or reject; Ruling C if intersects mode |
| Result | Child toast + new remaining |
| Next | Continue day / lock if still exhausted |
| Error | Offline queue; approver lacking level |
| Recovery | Queue flush; escalate to father if mother denied by level |

| State | Expected |
|---|---|
| First-time | Empty inbox template (SHR-006) |
| Normal | Approve 15 min |
| Edge | Request during active school mode → conflict dialog `complete` \| `freeze` |
| Empty | No pending |
| Loading | Deciding… |
| Failure | Deposit fail → no false success UI |
| Permission denied | Mother ① cannot approve; Mother ②/③ cannot approve **above active ceiling** (ADR-039) |
| Network | Child offline queues request; parent decides when online |
| Invalid input | 0 / over active ceiling (mother path rejects; father may still grant) |
| Expired session | Parent re-auth |
| Conflicting | Simultaneous father reject + mother approve → **father wins** + audit |
| Cancellation | Child cancels pending; parent dismisses |

**Ceiling (ADR-039):** Doc 20 table — **«منح وقت إضافي (≤٣٠ د)»** applies to PARTNER **and** FULL. FULL may edit the ceiling **rule** only if father exposed it under rules-edit; a single grant never exceeds the active ceiling; in-the-moment over-ceiling is OWNER-only.

**GAP:** D-3 `time_request` / `time_grant`.

---

## 7. UF-06 — Earn minutes by achievement (`S-SEC-005`)

**Happy path:** Child completes task/proof → parent approves → **PolicyEngine.earn()** → wallet ↑ instantly → Moments/thanks as designed.

| Step | Behavior |
|---|---|
| Entry | CHD tasks · FAT approval inbox |
| Action | Approve / reject proof |
| Validation | `Minutes` type only; reward set at creation (E-2) |
| Confirmation | Approve confirm if high value (optional UX) |
| Processing | Deposit + audit source channel |
| Result | Child celebration “+N minutes” |
| Next | Continue tasks / wallets CHD-019 |
| Error | Forged proof; approval conflict |
| Recovery | Re-submit proof; father override |

| State | Expected |
|---|---|
| First-time | Empty achievements |
| Normal | Approve homework |
| Edge | Mother assignee task → **no** minutes path (E-4) — route UF-07 |
| Empty | Nothing to approve |
| Loading | Approving… |
| Failure | Earn() fail → surface error; no silent balance |
| Permission denied | Mother ① cannot approve |
| Network | Queue approval; apply on reconnect |
| Invalid input | Missing proof |
| Expired session | Re-auth |
| Conflicting | Double-approve → idempotent single deposit |
| Cancellation | Reject with reason (visible to child) |

**Law:** E-1…E-5; Rule 5. **Test:** all five earning channels (E-3).

---

## 8. UF-07 — Link task to reward (`S-COM-035`)

**Happy path:** FAT-055 create task → if assignee = child, require `Minutes` → save → child sees reward up front.

| Step | Behavior |
|---|---|
| Entry | FAT-045 / FAT-055 |
| Action | Create/edit task + reward binding |
| Validation | Child assignee ⇒ reward **required**; Mother assignee ⇒ **no reward field** (help-request) |
| Confirmation | — |
| Processing | Task + reward contract |
| Result | Appears both sides |
| Next | UF-06 on completion |
| Error | Invalid assignee/reward combo |
| Recovery | Fix fields; resave |

| State | Expected |
|---|---|
| First-time | Empty task list CTA |
| Normal | Child task + 20 minutes |
| Edge | Mother assignee → thanks/Moments only |
| Empty | No tasks |
| Loading | Saving… |
| Failure | Persist error |
| Permission denied | Child cannot create reward tasks |
| Network | Offline draft optional; sync later |
| Invalid input | Points/XP labels forbidden in UI (ADR-036) |
| Expired session | Re-auth |
| Conflicting | Edit reward after child started → audit + notify |
| Cancellation | Discard form |

**GAP:** D-4 task tables. **ADR-036** naming.

---

## 9. UF-08 — SOS (`S-SEC-026`) — outside every gate

**Happy path:** CHD-005 3s press → local siren + location/audio → FAT-018 / mother / guardian critical alert → ack → escalate per ladder (P-5).

| Step | Behavior |
|---|---|
| Entry | Floating SOS / CHD-005 |
| Action | Hold 3 seconds |
| Validation | Accidental-press protection only — **never** blocks reachability |
| Confirmation | In-progress CHD-006 |
| Processing | `sos_alert` ACTIVE; broadcast best-effort |
| Result | Parents live map + piercing silent |
| Next | Ack → resolve; backup contacts; national link |
| Error | No network → **still works locally**; queue cloud |
| Recovery | Retry sync; ladder continues |

| State | Expected |
|---|---|
| First-time | Permissions for mic/location explained earlier; SOS still tries |
| Normal | Online SOS |
| Edge | Time expired / subscription expired / quiet hours / instant lock → **SOS still fires** (**P-4**, Rules 9/11) |
| Empty | N/A |
| Loading | Broadcasting… |
| Failure | Partial (audio fail) → location still; honest status |
| Permission denied | **No role may disable receipt**; mother has no mute SOS pref (**SET-021**) |
| Network | Airplane mode test must PASS |
| Invalid input | N/A |
| Expired session | Irrelevant — SOS not gated by session UX |
| Conflicting | Multiple SOS → coalesce/alert storm control without dropping |
| Cancellation | Child cancel only if product allows before ACTIVE; once ACTIVE, parent resolves |

**Law:** P-4, P-5. **SET-010/020/021.** Anti-tamper UI not involved for mother.

---

## 10. UF-09 — Instant lock (`S-SEC-047`)

**Happy path:** Parent lock control → confirm → child overlay → chat/Quran/SOS remain → unlock by father (or timer).

| Step | Behavior |
|---|---|
| Entry | Child profile quick action |
| Action | Lock / internet-only / timed |
| Validation | Exempt surfaces never targeted |
| Confirmation | Confirm destructive lock |
| Processing | Lock command + audit |
| Result | Child overlay + reason |
| Next | Unlock / timer end |
| Error | Offline child → queued lock; honest parent status |
| Recovery | Father force unlock |

| State | Expected |
|---|---|
| First-time | Explain what remains available |
| Normal | Father locks |
| Edge | Mother FULL locks; father reverses (**ADR-035**) |
| Empty | N/A |
| Loading | Locking… |
| Failure | Push fail → retry; do not show false locked on parent |
| Permission denied | Mother ①/② cannot; anti-tamper never shown (**ADR-035-b**) |
| Network | Queue |
| Invalid input | Bad timer |
| Expired session | Re-auth |
| Conflicting | Mother lock + father unlock → father wins + audit (**SET-009**) |
| Cancellation | Dismiss confirm |

**GAP:** D-5 lock state.

---

## 11. UF-10 — Family group chat (`S-COM-001`)

**Happy path:** Open family thread → compose → send → delivered/read → optional edit <15m / delete-for-all.

| Step | Behavior |
|---|---|
| Entry | FAT-021/022 · CHD-007 |
| Action | Send text/media/voice |
| Validation | Membership; edit window server-side |
| Confirmation | Delete-for-all confirm |
| Processing | E2EE relay (ciphertext) |
| Result | Ticks; media stays in circle (C-6) |
| Next | Call / check-in (C-4 critical ring) |
| Error | Offline queue; decrypt fail rare |
| Recovery | Retry send; resync |

| State | Expected |
|---|---|
| First-time | Empty conversation template |
| Normal | Send message |
| Edge | Time expired / subscription expired / device locked → **chat still works** (C-1, R9, R11) |
| Empty | SHR-006 empty |
| Loading | Sending… |
| Failure | Honest failed tick |
| Permission denied | Non-member |
| Network | Outbox |
| Invalid input | Empty send blocked |
| Expired session | Re-auth for sync; local cache readable offline |
| Conflicting | Edit after window → reject |
| Cancellation | Cancel upload |

---

## 12. UF-11 — Risk alert pipeline (`S-AIC-003`)

**Happy path:** Device emits anonymized `FamilyEvent` → gateway scores → FAT-019 alert (excerpt only) → father opens FAT-020 → approve/reject suggestion → audit.

| Step | Behavior |
|---|---|
| Entry | Alert center / push tier |
| Action | Father decides on suggestion |
| Validation | Confidence tier present; no verse generation |
| Confirmation | Approve suggestion (FatherSession) |
| Processing | Decision recorded; **no execute()** on AI object |
| Result | If approved into RulesEngine → separate UF path (ADR-038) |
| Next | Mother notified of analysis (`S-AIC-029`); child transparency |
| Error | Gateway down → honest empty |
| Recovery | Retry fetch; mock repo in dev |

| State | Expected |
|---|---|
| First-time | Coming-soon stages if flag off (**SET-014**) |
| Normal | New medium-tier alert |
| Edge | Critical pattern → higher urgency (still not SOS channel unless escalated by product rules) |
| Empty | No alerts empty-state |
| Loading | Loading alerts… |
| Failure | Gateway error template |
| Permission denied | Mother cannot open brain control (**SET-015**); cannot approve suggestions |
| Network | Cached alerts + offline banner |
| Invalid input | Decision without session |
| Expired session | Re-auth for approve |
| Conflicting | Stale suggestion already decided → idempotent |
| Cancellation | Dismiss detail without decision (remains pending) |

**Law:** Rule 7/26; S-AIC-006 excerpt; ADR-038 seam.

---

## 13. UF-12 — Audit log (`S-ADM-034`)

**Happy path:** Owner opens FAT-060 → scroll append-only list → filter by actor/time → **no delete control**.

| Step | Behavior |
|---|---|
| Entry | FAT-060 (RoleGuard owner-only) |
| Action | View / filter |
| Validation | — |
| Confirmation | — |
| Processing | Query only |
| Result | List of consequential actions |
| Next | Navigate to related entity if linked |
| Error | Fetch fail |
| Recovery | Retry |

| State | Expected |
|---|---|
| First-time | Empty log after family create |
| Normal | See pairing, level change, lock, earn |
| Edge | Wipe flow still **appends** wipe audit; forget never touches log |
| Empty | Empty-state |
| Loading | Loading… |
| Failure | Error template |
| Permission denied | Mother/Child blocked (S5 sovereignty) |
| Network | Cached page + banner |
| Invalid input | Bad filter |
| Expired session | Re-auth |
| Conflicting | N/A |
| Cancellation | N/A |

**Law:** R10 — repository has no update/delete.

---

## 14. Acceptance composites (S1–S5)

| Scenario | Flows exercised | Phase later |
|---|---|---|
| **S1** New father | UF-01 (+ family create ADM) | F3 |
| **S2** Morning board | UF-05 inbox · UF-11 Advisor FAB | F3 |
| **S3** Manage child (×N children) | UF-03, UF-04, UF-09, filter, Quran | F4 |
| **S4** Child full day | UF-06, UF-05, UF-08, UF-10, wallets, focus | F5 |
| **S5** Edges & sovereignty | UF-12, privacy wipe, subscription never gates SOS/chat | F6 |

Walk rule: only navigate via **visible** buttons (no deep-link cheating).

---

## 15. Open decisions & gaps

| ID | Item | Status |
|---|---|---|
| **ADR-039** | Mother FULL inherits ≤30 min per-grant ceiling (doc 20); over-ceiling = OWNER-only | `RESOLVED-BY-OWNER-AUDIT` → [`16-decision-register.md`](16-decision-register.md) |
| SET / schema gaps | SET-001…024, D-1…D-5 | Full specs: [`08-gap-closure-specs.md`](08-gap-closure-specs.md); index: `GAP_LOG.md` |
| UI completeness | UI-001…018 | Full specs: [`09-ui-ux-gap-analysis.md`](09-ui-ux-gap-analysis.md) §8 |
| No new SOS/quiet-hours ADR | Bound to **P-4** | Sealed |

---

## 16. Phase 6 exit criteria

- [x] Flow template + state matrix defined
- [x] All 12 spine services mapped end-to-end
- [x] Cross-links to P-4, ADR-035 / 035-b, ADR-038, GAP_LOG
- [x] Acceptance S1–S5 composite map
- [x] Ambiguity logged then resolved (**ADR-039**)

**Next:** Phase 7 — UI/UX completeness (`09-ui-ux-gap-analysis.md`) after Phase 6.5 gap closures (`08-gap-closure-specs.md`).
