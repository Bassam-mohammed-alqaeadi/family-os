# 05 — FS-006 Emergency Lifecycle Discovery

**Authority target:** SOS Final state machine · OD-05 · OD-06 · OD-18…20  
**Master:** [12_FS006_DISCOVERY_CLOSURE_REPORT.md](12_FS006_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Frozen incident lifecycle (authority)

```
IDLE → HOLDING → FIRING → ACTIVE → ACKNOWLEDGED → ESCALATING → RESOLVED
```

ACK ≠ RESOLVED (OD-05). RESOLVED does not delete (OD-18). Incident ≠ delivery (OD-20).

---

## 2. Stage-1 mapped states

| Frozen | Stage-1 `SosAlertStatus` | Notes |
|---|---|---|
| HOLDING | CHD-005 hold timer (UI) | Not a persisted status |
| FIRING | `SosFireService.fire` | Mock always succeeds |
| ACTIVE | `active` | Seeded |
| ACKNOWLEDGED | `acknowledged` | Repo method |
| ESCALATING | `escalating` | Manual escalate |
| RESOLVED | `resolved` | Resolve + terminal reason enums |

**Gap:** Full HOLDING/FIRING not first-class persisted states; delivery separate enums exist (**PARTIAL**).

---

## 3. Child activation path (evidence)

```
CHD-005 hold ≥3s → fireAndSeedSosAlert → MockSosFireService
  → InMemorySosAlertRepository seed → navigate CHD-006
```

---

## 4. Parent response path (evidence)

```
FAT-018 load alert → acknowledge / resolve / escalate / break-glass sheet
  → role checks → in-memory mutation
```

Auto-call: UI timer / note — **not** real dial.

---

## 5. Cancel / false alarm

| Element | Class |
|---|---|
| `SosCancelConfirmation` component | **PARTIAL** UI |
| OD-06 confirm → inform parents → audit | Audit durable **MISSING** |
| Terminal reasons helped/falseAlarm/other | **PARTIAL** enums |

---

## 6. Multi-device / persistence

Lifecycle state is **process-memory** — not multi-device emergency consensus (**MISSING**).
