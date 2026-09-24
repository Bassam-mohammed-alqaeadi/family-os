# 07 — FS-003 Offline & Sync Contract (L2 Target) — FROZEN

**Status:** **FROZEN** principles · **T-APP-04/05/09/10 OPEN**  
**Non-authority:** Stage-1 parent prefs · PolicySyncBus without app rules  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Principles (FROZEN)

| Law | Ref |
|---|---|
| No fake cloud success | APP-SF-09 |
| `enforced` only with **acked policy version** + verified plane | APP-SF-09/10 · APP-OD-14 |
| Durable **outbox** for policy mutations & install/exception/Lock Now decisions | Offline-first |
| Identity envelope on sync items | family + child + device/enrollment |
| Child evaluates from **local last-acked mirror** when offline | — |
| Entertainment-class fail-closed spirit for stale policy | ST-OD-009 analog — TTL **T-APP-04** |
| **SOS / Required Family Chat / Quran remain reachable and cannot be denied by App Control** even if policy stale | APP-SF-04 |

---

## 2. Authoritative policy vs device mirror (APP-OD-01)

| Store | Role |
|---|---|
| **Family baseline** | Versioned family App Control document |
| **Child override** | Versioned; **wins when present** |
| **Local child mirror** | Last successfully acknowledged effective policy + overlays |
| **Parent pending** | Saves not yet acked |

---

## 3. Versioning & acknowledgement

- Version family baseline and each child override.  
- Each enrolled child device tracks `ackedVersion`.  
- Idempotent re-delivery on same version.  
- Parent UI: pending when saved > acked.

---

## 4. Offline behavior

| Actor offline | Behavior |
|---|---|
| Parent edits / decides | Outbox; show pending |
| Child offline | Enforce last-acked; deny-until-approved for unknowns without class default; queue Exception requests locally |
| Conflict | **T-APP-05** — no invented algorithm; must not drop audit |

Unknown packages while offline still follow **Deny-until-approved** when no class default (APP-OD-08) under last-acked rules.

---

## 5. Replay / recovery

- Outbox replay after reconnect.  
- After reboot / force-stop: restore last-acked (**T-APP-09**).  
- Stale beyond grace: fail-closed for controllable entertainment apps; never deny SOS / Required Chat / Quran.

---

## 6. Multi-device

- Decisions are **child-scoped** (APP-OD-18 for installs); applied on each enrolled device for that child.  
- ST multi-device **minutes** budget remains ST-OD-001 (independent).

---

## 7. Open technical

T-APP-04 · T-APP-05 · T-APP-09 · T-APP-10 — **OPEN**; no invented numbers.
