# 18 — Screen Time Owner Decisions

**Date:** 2026-09-23  
**Rule:** Ask only decisions that change behavior, UX, precedence, Minutes, or roles.  
**Do not re-ask** what Register/Constitution already seals.

---

## ALREADY DEFINED (do not ask)

| Topic | Source |
|---|---|
| Minutes only currency | E-1 / Rule 4 |
| Father sets reward amounts | E-2 / Rule 6 |
| Mother tasks earn 0 | E-4 |
| Earn via policy path not direct writes | Rule 5 |
| Chat/Quran/SOS never lock on expiry | Rule 11 |
| SOS never subscription-gated | Rule 9 / P-4 |
| Instant lock > modes > caps > wallet | Register §2 / TimeEngine |
| Wallet never opens permanent blocks | Ruling A |
| Wallet inside cap; overflow opt-in default off | Ruling B |
| Per-app wallets | S-2 |
| Entertainment countable; Quran/edu/calls not by default | S-1 |
| 5-minute warning | S-3 |
| Calm expiry | S-4 |
| Mother levels & ≤30 grant ceiling | Doc 20 / ADR-039 |
| Father unlock supersedes mother lock | ADR-035 |
| Anti-tamper invisible to mother | ADR-035-b |
| FAT-039 tombstone → FAT-085 | ADR-034 |
| Offline-first honesty | G-1 |

---

## CURRENT BUT WRONG / INCOMPLETE

| Issue | Expected law | Current code |
|---|---|---|
| Mother FULL edit schedules/caps | Allowed | FAT-032 father-only |
| Time approve deposits usable time | Doc 33 / loop closure | TimeGrant inert |
| Child request → parent inbox | P12 loop | CHD-020 disconnected |
| Child wallet = ledger | S-2 / ADR-036 | Fixture |
| App rules → engine | FAT-034 purpose | Mock only |
| Consume / meter | Doc 33 deduct | Missing |
| S-3 warning | Register | Missing pipeline |
| Per-app limit in ladder | Doc 33 | Missing in TimeEngine |

These are **engineering closures**, not new Owner product inventions — unless Owner changes the law.

---

## OWNER DECISION REQUIRED

| ID | Decision | Why material | Options (non-exhaustive) |
|---|---|---|---|
| **ST-OD-001** | Multi-device daily Minutes model | Changes remaining math & sync | Per-device · Shared pool · Hybrid |
| **ST-OD-002** | Do earned wallet Minutes expire? | Economy longevity | Never · Rolling TTL · End of day |
| **ST-OD-003** | Free wallet vs per-app only | CHD-019 / attribution UX | Per-app only · Free pool · Both |
| **ST-OD-004** | Temporary grant credit model | Request loop meaning | Bonus remaining today (G-A) · Wallet deposit (G-B) · Both with toggle |
| **ST-OD-005** | Can grants bypass schedule hard windows? | Precedence | Never · With warning · Father-only override |
| **ST-OD-006** | Pending request policy | Child spam / UX | One pending · N pending · Cooldown |
| **ST-OD-007** | Pending request timeout | Stale inbox | 2h · 12h · 24h · none |
| **ST-OD-008** | Family timezone / travel rollover | Cap reset fairness | Home TZ · Device TZ · Manual |
| **ST-OD-009** | Stale policy fail mode | Safety vs availability | Fail closed entertainment · Fail last-known · Soft grace |
| **ST-OD-010** | Unlimited entertainment vs S-1 countable | Competitor Always Allowed semantics | Unlimited skips cap · Unlimited still counts · Separate switches |
| **ST-OD-011** | Focus self-discipline auto-reward | S-5 untouchable vs father proof | Auto credit · Still needs father approve |
| **ST-OD-012** | Mother Full may edit overflow switch? | Role boundary | Yes with audit · Father-only |

---

## PLATFORM CONSTRAINT (not Owner preference)

| Constraint | Implication |
|---|---|
| iOS FamilyControls entitlements | Weaker parity; honesty badges mandatory |
| Android OEM battery / Accessibility fragility | Device Owner path may be required for hard claims |
| No perfect tamper-proof on BYOD | FAT-038 = signals, not guarantees |
| Apple emergency numbers always reachable | Align SOS communication exemptions |

---

## Suggested Owner review order

1. ST-OD-004 (grant effect) — unblocks loop design  
2. ST-OD-001 (multi-device) — unblocks sync architecture  
3. ST-OD-002 / 003 (economy shape)  
4. ST-OD-005 / 010 (precedence edge cases)  
5. Remainder  

**Do not put these in `QUESTIONS.md` until Owner wants the harness to halt** — this discovery pack is the decision backlog for System #2.
