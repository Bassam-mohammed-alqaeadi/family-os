# 01 — Screen Time Owner Decisions (FROZEN)

**System:** #2 Screen Time + Minutes Economy  
**Status:** **FROZEN** — 2026-09-23  
**Authority:** Owner-approved freeze (this package)  
**Evidence base:** `docs/experience_discovery/screen_time/01–20`  
**Owner decisions remaining:** **NONE** (except later platform feasibility reviews)

---

## ST-OD-001 — Multi-device model · FROZEN

**Decision:** CHILD-LEVEL shared daily entertainment budget across all enrolled child devices.

| Rule | Frozen meaning |
|---|---|
| Daily entertainment allowance | Child-level (one budget) |
| Enforcement state | Device-level (per device) |
| Separate full allowance per device | **Forbidden** |
| Device-specific schedules/enforcement | **Allowed** |
| Silent budget multiplication across devices | **Forbidden** |

---

## ST-OD-002 — Earned Minutes expiry · FROZEN

Earned Minutes **NEVER expire by default**.

| Bucket | Lifecycle |
|---|---|
| Daily Allowance | Resets (family/home timezone end-of-day) |
| Earned Wallet | Persists |
| Temporary Grant | Expires |

---

## ST-OD-003 — Wallet model · FROZEN

**Per-app earned wallets only** for this phase.

- No general free wallet.
- Earned Minutes stay attributed to source/app wallet (S-2 aligned).

---

## ST-OD-004 — Temporary Grant · FROZEN (G-A)

Temporary Grant **increases today’s remaining entertainment time**.

- **Not** an Earned Wallet credit.
- Parent/mother grant ≠ earned reward channel.

---

## ST-OD-005 — Grant vs hard schedule · FROZEN

Temporary Grant does **NOT** bypass hard schedule/mode restriction.

- More time ≠ changed rule.
- To allow an app during hard mode/schedule → separate **ModeException** / parent override.

---

## ST-OD-006 — Pending requests · FROZEN

Maximum **ONE** pending time request per child.

---

## ST-OD-007 — Request timeout · FROZEN

Pending expires at **min(12 hours, local end-of-day)** in family/home timezone (ST-OD-008).

---

## ST-OD-008 — Timezone · FROZEN

Use **family/home timezone** controlled by Primary Parent.

- Do not silently trust child-device timezone.
- Travel-timezone behavior must be explicit + auditable (future; not invented here).

---

## ST-OD-009 — Stale policy · FROZEN

`LAST KNOWN POLICY → bounded grace → FAIL CLOSED` for entertainment.

- Permanent numeric TTL: **not defined yet** (platform/ops later).
- **SOS** remains exempt.
- Chat / Quran: existing constitutional exemptions.

---

## ST-OD-010 — Unlimited entertainment · FROZEN

Unlimited is a **separate explicit rule** — do not merge with Allowed / Blocked / Countable.

| May | Must not |
|---|---|
| Bypass daily entertainment cap | Bypass permanent block |
| — | Bypass instant lock |
| — | Silently become non-countable |
| — | Erase usage history |

---

## ST-OD-011 — Self-discipline reward · FROZEN

**NO automatic credit.**

- AI/system may **suggest**.
- Parent approval required before Minutes credit.

### Conflict report (Register)

Register **S-5** states focus self-discipline has **automatic reward** and `rewardSelfDiscipline` is **untouchable**.

**Owner freeze ST-OD-011 supersedes S-5 automatic-credit wording for product contract purposes.**  
Formal Register/ADR amendment is a documentation-law follow-up — not an open product fork. See [12_SCREEN_TIME_DECISION_CLOSURE_REPORT.md](12_SCREEN_TIME_DECISION_CLOSURE_REPORT.md).

---

## ST-OD-012 — Mother Full overflow · FROZEN

Mother Full **MAY** modify the overflow switch when:

- role-authorized  
- audited  
- visible to Primary Parent  
- never treated as ownership transfer  

---

## Additional frozen decisions

| ID | Decision |
|---|---|
| **ST-ADD-001** | Temporary Grant is **child-wide**, not app-specific |
| **ST-ADD-002** | Earned Minutes do **NOT** bypass hard schedules/modes |
| **ST-ADD-003** | No mandatory `LOW_TIME` state — use AVAILABLE / WARNING (≤5m) / EXPIRED |
| **ST-ADD-004** | Keep independently visible: Daily remaining · Temporary Grant remaining · Earned Wallet balance |

---

## Already defined law (unchanged — do not re-ask)

E-1…E-5 · Rules 4–6, 9, 11 · Ruling A/B · S-1…S-4 · ADR-035/035-b/039 · Instant lock ladder · Chat/Quran/SOS exemptions · AI suggests never executes.

See: [13_SCREEN_TIME_FINAL_MASTER_CONTRACT.md](13_SCREEN_TIME_FINAL_MASTER_CONTRACT.md).
