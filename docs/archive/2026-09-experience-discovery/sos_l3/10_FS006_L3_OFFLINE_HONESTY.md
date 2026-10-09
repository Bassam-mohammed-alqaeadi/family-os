# 10 — FS-006 L3 Offline Honesty UX

**Authority:** OD-17 · L2 offline contract  
**Master:** [13_FS006_L3_MASTER_CONTRACT.md](13_FS006_L3_MASTER_CONTRACT.md)

---

## 1. Principles in UI

| Situation | UX |
|---|---|
| No network | Create/persist local ACTIVE; delivery `offline_queued` |
| Reconnect | Retry visible; state updates only on proven results |
| Process restart | Restore open incident from durable store (required law; Stage-1 memory = debt) |
| Multi-device | Divergence honesty until converge |
| Ordinary sync down | SOS path still operable |

---

## 2. Forbidden

- “Cloud confirmed” on local-only create  
- Hiding failed retries  
- Clearing incident because offline  

---

## 3. Parent offline banner

```
Offline / queued — showing last known delivery facts
Incident still ACTIVE on child device (if known)
```

Transports/algorithms = **T-SOS-03/06/07/08** — not claimed.
