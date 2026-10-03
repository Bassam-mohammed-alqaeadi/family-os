# 11 — Location Final Master Contract

# LOCATION PRODUCT CONTRACT STATUS: L2 POLICY FROZEN — READY FOR L3 COMMISSIONING

**Authoritative entry point for Family OS System #4 — Location & Safe Zones (L2 Policy Freeze).**

**Date:** 2026-09-23  
**Frozen Owner Qs:** Q-LOC-01, 02, 03, 04 (taxonomy), 06 (kinds), 07, 08, 09, 10, 11, 12, 14, 16, 18 (+ LOC-OD-01…25)  
**Owner/Product decisions remaining:** **NONE**  
**Open (Technical/Platform parameters only — do not block L3):** Q-LOC-05 · Q-LOC-15 · Q-LOC-17 · numeric parts of Q-LOC-03/04/06/07  

**Application code modified:** **NO**  
**Screens created:** **NO**  
**L3 screen engineering started:** **NO**  
**L3 readiness:** **READY FOR L3 COMMISSIONING**  
**L3 package (UX design):** [`../location_l3/10_LOCATION_L3_MASTER.md`](../location_l3/10_LOCATION_L3_MASTER.md) — docs only; no app implementation  
**Other systems rewritten:** **NO**

**Evidence baseline:** System #4 Discovery report · Policy Register · Constitution · SOS Final · prototype/schema/app mocks as **evidence only**  
**Closure:** [10_DECISION_CLOSURE_REPORT.md](10_DECISION_CLOSURE_REPORT.md)  
**Sprint apply:** [12_L2_DECISION_CLOSURE_SPRINT.md](12_L2_DECISION_CLOSURE_SPRINT.md)  
**OD register:** [01_LOCATION_OWNER_DECISIONS.md](01_LOCATION_OWNER_DECISIONS.md)

**Exception rule:** Only a demonstrated platform constraint that makes a frozen requirement technically impossible may surface a new question — and must be reported explicitly, never silently redesigned.

---

## 1. Authority order

When sources conflict, obey in this order:

1. **This `location_final/` package** (Owner L2 freeze)  
2. **Policy Register / Cursor Constitution** (forever-free SOS · location · chat; audit append-only; RoleGuard)  
3. **SOS Final** (`sos_final/`) for incident/Break-glass/SOS evidence semantics  
4. **System #3 Identity** contracts/code for family/child/device/enrollment identity  
5. **Frozen prototype + `schema.sql` + Stage-1 app** — **evidence of capability/gaps only; never silent authority**

Polygon support, silent-child laws, explicit child assignment (Q-LOC-12=B), and L-S7 geofence-only scope (Q-LOC-18=A) in this package **override** conflicting legacy prototype/schema defaults.

---

## 2. Document index

| # | Artifact | File |
|---|---|---|
| 01 | OWNER_DECISIONS | [01_LOCATION_OWNER_DECISIONS.md](01_LOCATION_OWNER_DECISIONS.md) |
| 02 | POLICY_CONTRACT | [02_LOCATION_POLICY_CONTRACT.md](02_LOCATION_POLICY_CONTRACT.md) |
| 03 | ROLE_ACCESS_CONTRACT | [03_LOCATION_ROLE_ACCESS_CONTRACT.md](03_LOCATION_ROLE_ACCESS_CONTRACT.md) |
| 04 | LOCATION_RETENTION_CONTRACT | [04_LOCATION_RETENTION_CONTRACT.md](04_LOCATION_RETENTION_CONTRACT.md) |
| 05 | GEO_FENCE_CONTRACT | [05_GEO_FENCE_CONTRACT.md](05_GEO_FENCE_CONTRACT.md) |
| 06 | EVENT_LIFECYCLE_CONTRACT | [06_EVENT_LIFECYCLE_CONTRACT.md](06_EVENT_LIFECYCLE_CONTRACT.md) |
| 07 | CHILD_SILENT_LOCATION_CONTRACT | [07_CHILD_SILENT_LOCATION_CONTRACT.md](07_CHILD_SILENT_LOCATION_CONTRACT.md) |
| 08 | SOS_LOCATION_HANDOFF_CONTRACT | [08_SOS_LOCATION_HANDOFF_CONTRACT.md](08_SOS_LOCATION_HANDOFF_CONTRACT.md) |
| 09 | OFFLINE_LOCATION_CONTRACT | [09_OFFLINE_LOCATION_CONTRACT.md](09_OFFLINE_LOCATION_CONTRACT.md) |
| 10 | DECISION_CLOSURE_REPORT | [10_DECISION_CLOSURE_REPORT.md](10_DECISION_CLOSURE_REPORT.md) |
| 11 | LOCATION_FINAL_MASTER_CONTRACT | this file |
| 12 | L2 DECISION CLOSURE SPRINT | [12_L2_DECISION_CLOSURE_SPRINT.md](12_L2_DECISION_CLOSURE_SPRINT.md) |

---

## 3. All frozen decisions (summary)

### Product / safety

- Core **location + SOS + chat** availability **never** subscription-gated.  
- Normal trail retention **90 days** — **not** 24h baseline.  
- Location Domain = facts/geometry/history/integrity/evidence.  
- Policy Kernel = interpretation + action.  
- Offline **honest**; **no fake cloud success**.  
- Child cache **bounded**; cloud **authoritative** after successful sync.  
- Every event carries **family + child + device/enrollment** identity.  
- Legacy mocks = evidence only.

### Roles / history

- Live Location per existing role permissions (mother live view does not grade).  
- History operational access ≠ Primary-equivalent Co-Parent powers.  
- **Export / Archive = Primary only**; sensitive actions **audited**.  
- **Mother Full ≠ Primary**.

### Child silence

- Fully silent child location UI.  
- Check-In = **Child Safety** acknowledgement; silent evidence.  
- Silent Location Request = no child interactive UX; device executes; parent gets honest result.  
- Disclosure = non-interactive compliance only; no data exposure; no weaken controls.  
- SOS exception = **status words only** while ACTIVE (acquiring / located / stale·last-known / unavailable).

### Geometry / fences / alerts

- **Circle and Polygon** both first-class; circle kept; no destructive removal.  
- **New zones require explicit child multi-select** before save (Q-LOC-12=B) — no silent family-all default.  
- Lifecycle: Definition → Geometry → Assignment → Local Policy Context → Local Evaluation → Dwell/Hysteresis → Canonical Event → Policy Interpretation → Notification/Action → Audit → Offline Queue → Sync.  
- **L-S7 / v1 parent alert kinds:** ENTER · EXIT · NO_SHOW only (Q-LOC-18=A · Q-LOC-06=A).  
- **FAT-077 Road Safety** remains a **separate** system boundary.

### Live View / sampling / integrity

- Parent Live View states: **Standard watch** · **Elevated live** (Q-LOC-03=B); intervals not invented.  
- Sampling bands: `normal` · `low_battery` · `sos_active` (Q-LOC-04=A); seconds not invented.  
- Integrity: **soft parent warning** only (Q-LOC-07=C); no child integrity UI; no Kernel punish; no spoof-proof claim; no invented scores.

### SOS boundary

- Break-glass = SOS **response override** only — **not** Find My Child.  
- Future Emergency Find = **separate Owner decision**.

---

## 4. Unresolved parameters (Technical/Platform — not L3 blockers)

| ID | Remains undecided | Class | L3 rule |
|---|---|---|---|
| **Q-LOC-03** (numeric) | Refresh ms / cadence per Live View state | Platform/Technical | Show **Standard watch** / **Elevated live**; no invented intervals in copy |
| **Q-LOC-04** (numeric) | Seconds per sampling band | Platform/Technical | Name bands only |
| **Q-LOC-05** | Cloud density / batching | Technical | No density claims |
| **Q-LOC-06** (numeric) | Dwell / hysteresis / NO_SHOW grace | Technical | Kinds frozen; parameters configurable later |
| **Q-LOC-07** (engineering) | Internal signal scores | Technical | Soft warning allowed; no score invention; no auto-punish |
| **Q-LOC-15** | Map SDK / provider | Platform/Technical | Provider-agnostic seam |
| **Q-LOC-17** | Cache size / TTL numbers | Technical/Privacy | “Bounded” honesty |

Details: [10_DECISION_CLOSURE_REPORT.md](10_DECISION_CLOSURE_REPORT.md) §3.

---

## 5. Non-goals

1. Inventing sampling intervals, refresh rates, alert grace periods, anti-spoof scores, cache byte/TTL, or cloud density numbers.  
2. Building Find-My-Child from SOS Break-glass.  
3. Child maps, coordinates, history, geofence editors, diagnostics, or disable/weaken controls.  
4. Subscription gating of core location existence.  
5. Treating Stage-1 InMemory/decorative maps as product law.  
6. Starting L3 without an **explicit L3 commission** (readiness ≠ auto-start).  
7. Rewriting SOS Final, Screen Time Final, or unrelated docs.  
8. Absorbing Road Safety (FAT-077) into Location.  
9. Silent family-all geofence create default.  
10. Automatic Kernel punishment from integrity signals / spoof-proof claims.

---

## 6. Platform / technical feasibility items (not open product forks)

These may later force an **explicit** Owner exception report if impossible — they do **not** reopen silent redesign:

| Item | Nature |
|---|---|
| Background location / Play & App Store disclosure flows | Platform |
| iOS `locationAlways` = reports-only capability honesty (existing matrix) | Platform |
| GPS accuracy, indoor failure, OEM battery kills | Platform |
| Outbox durability across process death | Technical |
| Polygon validation (self-intersection, vertex caps) | Technical |
| Map SDK licensing/cost (Q-LOC-15) | Platform/commercial |
| Sampling interval tuning (Q-LOC-04 numbers) | Platform trials |
| Live View refresh tuning (Q-LOC-03 numbers) | Platform trials |
| Anti-spoof signal quality (Q-LOC-07 engineering) | Technical |
| Dwell/hysteresis parameter tuning (Q-LOC-06 numbers) | Technical |
| Schema additive migration for polygon + explicit assignment | Technical / contracts |

---

## 7. Cross-system dependencies

| System | Dependency |
|---|---|
| **#3 Identity / Family / Device / Enrollment** | Identity envelope; enrollment; **explicit child assignment lists** |
| **#1 SOS** | L-S12 attach; child status exception; Break-glass boundary; evidence class split; `sos_active` band coordination |
| **Screen Time** | Must not disable location/SOS under expiry/modes |
| **Device Health** | `locationAlways` / battery → `low_battery` band input |
| **FAT-077 Road Safety** | **Separate** — not Location L-S7 |
| **Notifications** | Geofence ENTER/EXIT/NO_SHOW + Check-In + Silent Request; SOS critical channel remains SOS |
| **Audit** | Append-only for config, export/archive, silent request, sensitive history |
| **Policy Kernel** | Interprets canonical events → notify/action; **no** auto-punish from integrity (LOC-OD-22) |
| **Offline Sync** | Outbox; cloud authority after ack |
| **Billing / Entitlement** | Must not gate core location modules |

---

## 8. Slice coverage under freeze (L-S1…L-S12)

| Slice | Freeze posture |
|---|---|
| L-S1 Live Location | Parent surfaces; **Standard watch** / **Elevated live**; interval numbers open |
| L-S2 History | 90d; Primary export/archive; Co-Parent ≠ Primary |
| L-S3 Geofence Library | Circle+Polygon; Domain-owned; **explicit child assign on create** |
| L-S4 Geofence Rules | ENTER/EXIT/NO_SHOW kinds; dwell numbers open |
| L-S5 Check-In | Child Safety ack; silent evidence |
| L-S6 Silent Location Request | Fully silent child execution |
| L-S7 Movement Alerts | **= geofence ENTER/EXIT/NO_SHOW only**; FAT-077 separate |
| L-S8 Protection Posture | Device Health; band taxonomy frozen |
| L-S9 Offline Geofence Engine | Required by lifecycle; implementation later |
| L-S10 Anti-Spoof | Soft parent warning; no auto-punish; scores not invented |
| L-S11 Battery-Aware Sampling | Bands `normal` / `low_battery` / `sos_active`; seconds open |
| L-S12 SOS Attachment | Handoff contract; SOS Final supreme for incident |

---

## 9. Exact handoff to L3

**Status:** **READY FOR L3 COMMISSIONING**

L3 (screen engineering / UX contracts) may begin when **explicitly commissioned**, under these rules:

1. **Obey** this Master + child contracts; do **not** reopen LOC-OD-01…25.  
2. Zone authoring: **explicit child multi-select before save** (Q-LOC-12=B).  
3. Alert IA: **ENTER / EXIT / NO_SHOW** only; do not fold FAT-077.  
4. Live Map: expose **Standard watch** / **Elevated live**; **no invented refresh numbers**.  
5. Integrity: optional **soft parent warning** only; no child integrity UI; no spoof-proof / score claims.  
6. Sampling: may name `normal` / `low_battery` / `sos_active`; **no invented seconds**.  
7. **Do not** invent numbers for Q-LOC-05/06/17 numerics in screen specs.  
8. **Reshape** CHD-024 to Child Safety Check-In (no live location card).  
9. **Omit** child location tooling; keep SOS status-only exception.  
10. **Provider-agnostic** map seams until Q-LOC-15.  
11. **No application feature code** until L3 contracts are commissioned and then implemented under a declared task.  
12. Produce L3 artifacts analogous to SOS/Screen Time screen-engineering packs.

**L3 entry checklist**

- [ ] Explicit L3 commission received  
- [ ] Read Master + Child Silent + Role Access + Geo-Fence + SOS Handoff + Closure Report  
- [ ] Parent families: Live Map (two states) · History · Zone Library · Zone Authoring (multi-select) · Silent Request result · soft integrity warning · Protection posture  
- [ ] Child: Safety Check-In only (+ SOS status via SOS L3)  
- [ ] Mark Technical/Platform Q-LOC items as parameters/TBD — never fake closed  
- [ ] Trace every control to Domain event or Kernel action (Gap-Closing)

---

## 10. Verdict

| Item | Status |
|---|---|
| Owner/Product L2 law | **FROZEN** (LOC-OD-01…25) |
| Owner/Product L3 blockers | **NONE** |
| Remaining opens | Technical/Platform parameters only |
| **L3 readiness** | **READY FOR L3 COMMISSIONING** |

Discovery remains evidence. Mocks remain non-authority.  
**STOP** — documentation freeze complete; do **not** auto-start L3, wireframes, or app code without an explicit L3 commission.
