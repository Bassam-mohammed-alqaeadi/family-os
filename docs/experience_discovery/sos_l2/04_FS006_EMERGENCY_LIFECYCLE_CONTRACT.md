# 04 — FS-006 Emergency Lifecycle Contract (L2 Wrapper) — FROZEN

**Status:** **FROZEN** — imports SOS Final state machine · OD-05 · OD-06 · OD-18…20  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Incident lifecycle (exact)

```
IDLE → HOLDING → FIRING → ACTIVE → ACKNOWLEDGED → ESCALATING → RESOLVED
```

| Transition | Who | Rules |
|---|---|---|
| → HOLDING | Child hold | Release before complete → IDLE |
| → FIRING | System | Local incident begin |
| → ACTIVE | System | Durable incident exists |
| → ACKNOWLEDGED | Primary / Full / Partner | **≠** resolve; does not close |
| → ESCALATING | Primary / Full / Partner or auto-timer | Trusted only; never emergency services |
| → RESOLVED | Primary / Full / Partner | **Does not delete**; audit retained |
| Cancel / false-alarm | Child confirm path | Parents informed; auditable; terminal reason false-alarm |

Observer cannot drive ACK / ESCALATE / RESOLVE.

---

## 2. Separations (mandatory)

```
Incident state
  ≠ Delivery attempt
  ≠ Delivery result
  ≠ Acknowledgement
```

Creating a local incident must **never** alone render “sent”.

---

## 3. Persistence

RESOLVED / cancelled incidents remain auditable. Soft-close ≠ erase core header or lifecycle audit (OD-18 · RD-03).
