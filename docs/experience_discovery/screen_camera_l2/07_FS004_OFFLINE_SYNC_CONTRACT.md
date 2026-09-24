# 07 — FS-004 Offline & Sync Contract (L2 Target) — FROZEN

**Status:** **FROZEN** principles · **T-SC-11 OPEN**  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Principles

| Law | Ref |
|---|---|
| No fake cloud success | SC-SF-06 |
| `enforced` only with **acked** policy + verified plane | SC-OD-04 · SC-SF-07 |
| Durable **outbox** for FS-004 policy & exception decisions | Offline-first |
| Identity envelope | family + child + device/enrollment |
| Child evaluates **last-acked** when offline | Mandatory rule 10 |
| Multi-device converges via offline-first architecture | SC-OD-12 |

---

## 2. Authoritative vs mirror

| Store | Role |
|---|---|
| Family baseline | Versioned FS-004 document |
| Child override | Versioned; **wins when present** |
| Local child mirror | Last acked policy + monitoring active state |
| Parent pending | Saved > acked |

Smart Alerts must **not** hold a divergent second config (SC-OD-09).

---

## 3. Offline behavior

| Actor | Behavior |
|---|---|
| Parent edits offline | Outbox; honesty `offline_queued` / pending — no fake “on child now” |
| Child offline | Last-acked prevent/monitor/protect; transparency reflects last-acked monitoring flag |
| Monitoring observe while offline | Queue Domain facts locally if agent capable; sync later |
| Stale | Honesty; fail-safe must **not** cut SOS / Required Chat / Quran; numeric TTL **T-SC-11** |

---

## 4. Mode context offline

Last-acked Mode tighten context may apply; Modes cannot permanently erase FS-004 policy (SC-SF-11).

---

## 5. Open technical

**T-SC-11** — ack/stale TTL numbers and conflict algorithms. No invented values.
