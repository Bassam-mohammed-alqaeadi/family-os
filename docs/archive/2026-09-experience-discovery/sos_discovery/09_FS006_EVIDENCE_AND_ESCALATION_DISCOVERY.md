# 09 — FS-006 Evidence and Escalation Discovery

**Authority:** OD-07…10 · OD-15 · RD-03…05  
**Master:** [12_FS006_DISCOVERY_CLOSURE_REPORT.md](12_FS006_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Evidence (frozen)

| Layer | Retention | Stage-1 |
|---|---|---|
| Operational samples | 90 days | **MISSING** pack/job |
| Core header + lifecycle audit | Indefinite | **MISSING** durable |
| Audio/video | Forbidden | **MISSING** (correct) |

Evidence fields conceptually present as **labels** on `SosAlert` (battery, movement, accuracy, location label) — **MOCK fixtures**, not sensor-backed packs.

---

## 2. Escalation (frozen)

| Rule | Stage-1 |
|---|---|
| Trusted-only auto-call/escalate | Ladder verified backups — domain **PARTIAL** |
| Never national numbers | Tests + OD-08 — **aligned** |
| Max 5 backups; priority 1…5; rung-1 immutable | Ladder model **PARTIAL** |
| Verification UNVERIFIED→…→VERIFIED | Domain **PARTIAL**; transport **MISSING** |
| Timer-based ladder escalation | **MISSING** worker; manual escalate status |

---

## 3. Location evidence

| Rule | Stage-1 |
|---|---|
| Attach location honesty classes | Enums + UI **PARTIAL** |
| Fail still activates | Model allows unavailable — fire still mocks success |
| FS-001 owns location truth | Handoff **DOCUMENTED**; live bind **MISSING** |
