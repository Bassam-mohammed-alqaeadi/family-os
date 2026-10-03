# 08 — FS-006 Offline / Sync Contract (L2 Wrapper) — FROZEN

**Status:** **FROZEN** — imports OD-17 · SOS Final failure/offline · SOS-SF-14  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Product principles (frozen)

| Principle | Law |
|---|---|
| Local incident creation | Immediate on fire path |
| Durable persistence | Required — survive process death / restart |
| Offline firing | Must not silently fail; queue + honesty |
| Outbox / retry / replay | Required implementation behavior |
| Fake “cloud sent” | **Forbidden** |
| Multi-device | Incident state must converge |
| Ordinary policy sync down | SOS remains operational even if ordinary sync unavailable |
| Fallbacks | SMS/call classes when push unavailable (mechanisms TBD) |

---

## 2. Technical TBD (do not solve here)

Algorithms, store choice, TTL numbers beyond retention law, FCM wiring = **T-SOS-06 · T-SOS-07 · T-SOS-08 · T-SOS-10**.

---

## 3. Stage-1

In-memory repositories = **non-authority** vs durable persist requirement.
