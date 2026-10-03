# 06 — Cross-Role Dependencies
**Mission:** Discovery phase 5 · Branch `discovery/master-plan`  
**Date:** 2026-09-20 · **Authority:** Section A · Policy Register (supreme) · ADR-035 / **ADR-035-b** · ADR-038 · Register **P-4**  
**Actor model:** 3 primary (Father OWNER, Mother PARENT, Child) + 2 secondary (Guardian OBSERVER, Family Advisor proposes-only)

---

## 0. Freeze statement

| Constraint | Status |
|---|---|
| Discovery docs only under `docs/project-plan/` | **Honored** |
| No edits to handoff / frozen HTML / `_REGISTRY` | **Honored** |
| Quiet hours / DND never invent a new SOS rule — bind to **P-4** | **Honored** |
| Anti-tamper invisible to mother at every level (**ADR-035-b**) | **Honored** |
| SET-001…024 = conversion backlog in `GAP_LOG.md` (Rule 23) | **Honored** |

**Mandate:** No isolated settings. Every mutating action defines what the other affected role sees or experiences.

**Conversion backlog:** [`GAP_LOG.md`](../../GAP_LOG.md) (SET IDs). Permission matrix companions: [`03-role-permission-matrix.md`](03-role-permission-matrix.md). Settings evidence: [`05-settings-audit.md`](05-settings-audit.md).

---

## 1. Map template

Every row below follows:

| Column | Meaning |
|---|---|
| **Action** | Who does what (role + capability) |
| **Other-role UX** | What Father / Mother / Child / Guardian / Advisor sees or feels |
| **Domain state** | In-app policy / device / wallet state that changes |
| **FamilyEvent / sync** | Typed event → EventBus → sync queue (Rule 26 hooks) |
| **DB write** | Tables from `_CONTRACTS/schema.sql` (or named gap if missing) |
| **Notification?** | Who is notified; critical vs normal channel |
| **Timing** | Immediate after sync vs next refresh |
| **Offline** | Behavior when actor or peer is offline |
| **SET / law** | Backlog ID and sealed law |

---

## 2. Economy loops

| Action | Other-role UX | Domain state | FamilyEvent / sync | DB write | Notification? | Timing | Offline | SET / law |
|---|---|---|---|---|---|---|---|---|
| Father approves child task proof | Child sees wallet balance ↑; Moments/thanks path as designed | `Minutes` deposit via **PolicyEngine.earn() only** | `TaskApproved` → sync | ledger / wallet (phase 10 drift); `audit_log` | Child success toast; optional Moments | **Immediate** after sync ack | Queue approve; deposit applies on reconnect; child shows pending if designed | E-1/E-2; matrix §5 |
| Mother ②/③ approves **time** request | Child balance ↑ within ceiling; over-ceiling denied for mother | Grant ≤ active ceiling | `TimeGranted` | grant + audit | Child decision toast | Immediate after sync | Queue | **ADR-039**; UF-05 |
| Mother ②/③ approves task proof | Same child wallet path; Father sees actor = mother in audit | Same PolicyEngine deposit | `TaskApproved` (actor=PARENT) | same + audit actor | Child same; Father optional digest | Immediate after sync | Same queue rules | E-4 (mother tasks ≠ minutes when she is assignee) |
| Father sets reward `Minutes` at task create | Child sees reward on task card (no hidden default) | Task reward bound | `TaskCreated` | task store | Child new-task | On create sync | Child sees after sync | Rule 6; SET economy law-bound |
| Father wallet overflow switch (default off) | Child overflow behavior matches flag | Ruling B flag | `WalletPolicyChanged` | policy store (**SET-024**) | None critical | Same session after sync | Last-synced flag | **SET-024** |

**Invariant:** raw int rewards forbidden; Advisor may **suggest** amounts only — never deposit.

---

## 3. Delegation & owner surfaces

| Action | Other-role UX | Domain state | FamilyEvent / sync | DB write | Notification? | Timing | Offline | SET / law |
|---|---|---|---|---|---|---|---|---|
| Father changes mother level (↑/↓) | Mother sees new level + notification; downgrade needs double-confirm | `PermissionMatrix` level | `DelegationChanged` | `member` level fields; `audit_log` | Mother **required**; never silent | Immediate | Father action queues; mother sees on reconnect | R-2; ADR-035 `DELEGATION_EDIT` |
| Mother navigates device-defense / anti-tamper | **Surface absent** — no rows, no greyed switches | No mother write path | — | — | — | — | — | **ADR-035-b**; **SET-007** |
| Father toggles anti-tamper ×6 | Child device enforces; Mother UI still omits surface | Defense flags | `AntiTamperChanged` | device_permission / defense store | Father alerts on bypass attempt | After sync to child device | Child uses last-synced defenses | P-6; **SET-008** |
| Mother FULL instant-locks child | Child overlay lock; Father sees lock + can reverse | Lock state | `InstantLock` | lock state (**D-5 gap**) + audit | Father notified | Immediate | Lock applies locally on child when delivered | ADR-035; **SET-009** |
| Father unlocks while mother locks (conflict) | Child ends unlocked (father wins); both see audit | Lock cleared; supersession recorded | `LockSuperseded` | `audit_log` both | Father + Mother | Immediate | Resolve on sync with owner precedence | ADR-035; **SET-009** |
| Mother attempts unlock of father-blocked app | Denied; no UI affordance if blocked by father | Block remains | — | audit if attempted | — | — | — | P-3; ADR-035 |

Guardian: **never** edits delegation or anti-tamper. Advisor: may suggest level change → Father approves only.

---

## 4. Time, schedules & smart modes

| Action | Other-role UX | Domain state | FamilyEvent / sync | DB write | Notification? | Timing | Offline | SET / law |
|---|---|---|---|---|---|---|---|---|
| Father/Mother FULL edits daily cap / sleep / prayer / study | Child countdown / calm / pause UI updates | TimeEngine budgets + schedules | `ScheduleChanged` | policy/schedule (**SET-002**) | Soft T-5 near end | **Same session after sync** | Child last-synced schedule | **SET-001…003** |
| Entertainment time expires | Child entertainment locks; **chat / Quran / SOS stay up** | Countable wallets empty | `AllowanceExpired` | wallet + audit | Child calm lock UI | Immediate locally | Local TimeEngine with last policy | Rules 9/11; P-4 companions |
| Father activates smart mode on FAT-085 | Child CHD-004 status card + CHD-018 focus tint follow stream | Active mode id + allowed apps | `SmartModeActivated` | mode store (not FAT-039) | Optional | Same session after sync | Last active mode | T-1; **SET-018**, **SET-019** |
| Router/codegen encounters FAT-039 | **No route** — tombstone skipped | — | — | — | — | — | — | ADR-034; **SET-018** |

---

## 5. Web filter

| Action | Other-role UX | Domain state | FamilyEvent / sync | DB write | Notification? | Timing | Offline | SET / law |
|---|---|---|---|---|---|---|---|---|
| Father/Mother FULL changes filter level / lists | Child hits polite block page; Father can preview same decision | WebFilterPolicy | `WebFilterChanged` | web_filter_policy (gap) | None unless unlock request | Immediate after sync | Child uses last-synced filter | P-8; **SET-004**, **SET-005** |
| Child requests unlock of blocked site | Father (+ Mother ②⁺ if delegated) inbox request | Pending request | `UnlockRequested` | request store | Father/Mother inbox | Immediate to parents | Queue request until online | **SET-006** |
| Parent approves unlock | Child site allowed (scoped); audit | Exception list | `UnlockApproved` | filter exceptions + audit | Child result | Immediate after sync | Apply on reconnect | **SET-006** |

---

## 6. Instant lock & exemptions

| Action | Other-role UX | Domain state | FamilyEvent / sync | DB write | Notification? | Timing | Offline | SET / law |
|---|---|---|---|---|---|---|---|---|
| Instant lock (Father or Mother FULL) | Child overlay; chat / Quran / SOS remain reachable | Lock above modes ladder | `InstantLock` | lock + audit | Other parent | Immediate | Delivered lock persists offline | ADR-035; Rule 11 |
| Time/subscription expiry during lock | Same exemptions hold | — | — | — | — | — | — | Rules 9/11; P-4 |

---

## 7. Notifications & quiet hours (**P-4**)

| Action | Other-role UX | Domain state | FamilyEvent / sync | DB write | Notification? | Timing | Offline | SET / law |
|---|---|---|---|---|---|---|---|---|
| Father enables quiet hours / DND | Non-critical muted; **SOS/critical still pierce silent** on Father & Mother | Quiet schedule; critical channel always armed | `QuietHoursChanged` | prefs | — | Immediate | Critical uses OS critical-alert path | **P-4** verbatim; Rules 9/11; **SET-010** — **no new ADR** |
| Mother notification prefs | Distinct identity (not father clone); SOS receipt **not** togglable off | Mother prefs | `NotifPrefsChanged` | prefs | — | On save | — | R-3; **SET-011**, **SET-021** |

---

## 8. Privacy & transparency

| Action | Other-role UX | Domain state | FamilyEvent / sync | DB write | Notification? | Timing | Offline | SET / law |
|---|---|---|---|---|---|---|---|---|
| Father flips collection scopes | Child «ماذا يُجمع عني» card updates | Collection policy | `PrivacyScopeChanged` | privacy prefs | Child transparency (not alarm) | Same session after sync | Last-synced copy on child | P-7; **SET-012** |
| Father Advisor “forget” | Advisor memory cleared; **messages & audit untouched** | Advisor memory only | `AdvisorForget` | ai memory store | — | Immediate | — | **SET-013**; R10 |
| Father family wipe | Double confirm + 7-day regret; audit entry remains | Wipe flow | `FamilyWipeRequested` | wipe + **audit append** | Owner | Multi-step | — | **SET-013**; Rule 10 |

---

## 9. Brain control, AI & RulesEngine (**ADR-038**)

| Action | Other-role UX | Domain state | FamilyEvent / sync | DB write | Notification? | Timing | Offline | SET / law |
|---|---|---|---|---|---|---|---|---|
| Father opens brain control / stage flags | Mother **cannot** open (all levels); inactive stages = coming-soon UI | Server feature flags | flag sync | remote config | — | On fetch | Offline shows last flags + honest inactive | Rule 26; **SET-014**, **SET-015** |
| Advisor emits `AiSuggestion` | Father sees approve/reject only; **no execute()** | Suggestion pending | `AiSuggestionCreated` | `ai_suggestion` | Father (+ Mother notify per R-3) | Immediate | Queue | Rule 7/26; ADR-038 |
| Father approves suggestion into RulesEngine | Suggestion becomes authored rule; then may auto-run under (a–f) | RulesEngine rule active | `RuleApproved` | rules store + audit | Action feed | Immediate | — | ADR-038; **SET-022** |
| RulesEngine fires authored rule | Child/parent see effect + feed + 10-min undo; **never** anti-tamper / block-override / delegation-edit | Deterministic automation | `RuleExecuted` | audit + feed | Visible feed | Immediate | Local evaluate with synced rules | ADR-038 (d); **SET-023**; ADR-035 |

**Architecture seam:** AI path ≠ RulesEngine path. Type system forbids `AiSuggestion.execute()`.

---

## 10. SOS ladder

| Action | Other-role UX | Domain state | FamilyEvent / sync | DB write | Notification? | Timing | Offline | SET / law |
|---|---|---|---|---|---|---|---|---|
| Child triggers SOS (3s) | Father & Mother get piercing siren + live map; Guardian receives; subscription/time/network **irrelevant** | `sos_alert` active | `SosTriggered` (local-first) | `sos_alert`, `location_ping` | **Critical channel** (P-4) | Immediate local + best-effort sync | Works offline → queues escalate | **P-4**, P-5; Rules 9/11; **SET-020**, **SET-021** |
| Father edits ladder | Cannot remove parents from rung 1; no “mute SOS” prefs for mother/guardian | Ladder config | `SosLadderChanged` | SOS config | — | On save | Last ladder | **SET-020**, **SET-021** |

---

## 11. Offline child (global)

| Action | Other-role UX | Domain state | FamilyEvent / sync | DB write | Notification? | Timing | Offline | SET / law |
|---|---|---|---|---|---|---|---|---|
| Child loses network | Honest offline template; last-synced family state (limits, chat cache, SOS still local) | Cached policy | Outbox queue | local cache | Deferred non-critical | On reconnect flush | **This row** | Register offline-first; matrix §5 |
| Parent changes policy while child offline | Child applies on reconnect; until then last-synced | Pending sync | Queued events | — | — | Next sync | Parent sees “pending device sync” if UI designed | **SET-003** companion |

---

## 12. Secondary actors (summary)

| Secondary | May initiate | Experiences |
|---|---|---|
| **Guardian** | No transactional use case | Observes; **always** receives SOS; never anti-tamper / delegation / brain |
| **Family Advisor** | Proposals only | Surfaces suggestions; father (or RulesEngine after approve) acts; mother notified per R-3 — never executes |

---

## 13. Coverage checklist (Phase 5 seed)

| Loop cluster | Mapped | SET / law anchors |
|---|:-:|---|
| Economy approve → wallet | ✅ | PolicyEngine; E-1/E-2 |
| Delegation level change | ✅ | ADR-035 |
| Anti-tamper invisible | ✅ | **ADR-035-b**; SET-007 |
| Time / modes / tombstone | ✅ | SET-001…003, 018, 019; T-1 |
| Web filter + unlock request | ✅ | SET-004…006 |
| Instant lock + father wins | ✅ | SET-009; ADR-035 |
| Quiet hours ≠ mute SOS | ✅ | **P-4**; SET-010 |
| Privacy → child transparency | ✅ | SET-012 |
| Brain / RulesEngine seam | ✅ | ADR-038; SET-014, 015, 022, 023 |
| SOS ladder always-on | ✅ | P-4/P-5; SET-020, 021 |
| Offline child | ✅ | Register G-1 / offline-first |
| Platform capability honesty | ✅ (pointer) | SET-016, 017 — detail in phase 7 UI audit |
| Wallet overflow switch | ✅ | SET-024 |

No new `REQUIRES PRODUCT DECISION` items opened in this phase.

---

## 14. Phase 5 exit criteria

- [x] Cross-role map template defined
- [x] Seed loops from matrix §5 + settings spine + spine services covered
- [x] P-4 bound for quiet hours / SOS (no parallel rule)
- [x] ADR-035-b encoded (anti-tamper invisible)
- [x] SET IDs cross-linked to `GAP_LOG.md`
- [x] Actor model 3+2 respected

**Next:** Phase 6 — user flow analysis (`07-user-flows.md`) — **complete**; continue Phase 7.
