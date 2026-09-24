# 09 — FS-003 Cross-System Boundaries (L2 Target) — FROZEN

**Status:** **FROZEN** · APP-OD-10…15 · APP-SF-07/08/14/16/17/18  
**Consumes:** WF-OD-12 · ST Precedence Final · SOS Final · Identity vocabulary  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Ownership map (FROZEN)

| System | Owns | Does not own |
|---|---|---|
| **FS-003 App Control** | Package Allow/Block/Exempt; install governance; App Access Exception; Lock Now; app-plane honesty | Minutes; Limit/Unlimited/Countable; URL filter; SOS lifecycle; uninstall resistance; scheduling |
| **Screen Time** | Daily budget; Temporary Grant minutes; wallets; **Limit / Unlimited / Countable** | Permanent package block truth |
| **FS-002 Web Filter** | URL/category/Safe Search; timed host allows | Package launch allow |
| **FS-005 Modes** | **All scheduling** / lifestyle overlays | Second App Control scheduler; reopening Permanent Block |
| **Instant Lock** | Device-wide P1 | Permanent Block; per-app Lock Now |
| **Anti-tamper** | Uninstall / management-removal resistance | Substituting for verified app block |
| **SOS** | Emergency lifecycle | — |
| **Policy Kernel** | Merge / notify / action | Domain fact invention |
| **Notifications / Audit** | Delivery / append storage | Policy semantics |

---

## 2. App Control vs Screen Time

### Frozen

- Permanent Block → ST **P2**; Minutes/grants/Unlimited never open.  
- **APP-OD-12:** ST owns Limit / Unlimited / Countable authorship; FS-003 owns package access only.  
- **APP-SF-07:** App Access Exception ≠ Temporary Grant ≠ ST Unlimited.  
- Temporary Grant = minutes only, child-wide (ST-ADD-001).

### Outcome matrix

| App | Time | Mode | Grant | Result |
|---|---|---|---|---|
| Permanent Block (no Exception) | any | any | any | **DENY** (App) |
| Block + active Exception | any | any | any | May allow for exception TTL; **block policy remains** |
| Allowed | Exhausted | ok | none / no Unlimited | **DENY** (ST) |
| Allowed | Exhausted | ok | Temporary Grant > 0 | May continue under grant (still P0–P3) |
| Allowed | ok | Tightened | any | **DENY** (Mode) — Mode cannot reopen Permanent Block |
| Lock Now active | any | any | any | Temporary **DENY** (overlay) |

---

## 3. App Control vs Web Filtering (WF-OD-12)

| App | Web | Result | Source-of-deny |
|---|---|---|---|
| DENY | ALLOW | DENY | App Control |
| ALLOW | DENY | DENY | Web Filter |
| DENY | DENY | DENY | Both |
| ALLOW | ALLOW | Continue to ST/Modes/Lock | — |

Unlock ownership: WF unlock ≠ App Exception ≠ ST Grant.  
No silent cross-system mutation.

---

## 4. App Control vs Modes (APP-OD-10/11)

| Topic | Frozen law |
|---|---|
| Scheduling | **Modes only** — FS-003 has **no** second scheduler |
| Effect | Modes **tighten-only** |
| Permanent Block | Modes **cannot reopen** Permanent Block |
| Offline | Last-acked Mode context; honesty if stale |

---

## 5. Safety (FROZEN)

**SOS / Required Family Chat / Quran remain reachable and cannot be denied by App Control.**  

Break-glass (SOS) may temporarily override for emergency response per SOS Final — temporary, audited, auto-revoke; **not** permanent policy mutation.

---

## 6. Anti-tamper (APP-OD-15)

Separate subsystem. FS-003 consumes integrity/capability facts only.

---

## 7. Duplicated ownership — closed

| Former risk | Resolution |
|---|---|
| FAT-034 owning Unlimited + Block | APP-OD-12 — ST owns Unlimited/Limits |
| Per-app schedules in FS-003 | APP-OD-10 — Modes only |
| Grant as app unlock | APP-SF-07 · APP-OD-06 |
| Partner configure | APP-OD-02 — rejected |
| Modes reopen block | APP-OD-11 — forbidden |

---

## 8. Policy Kernel

Receives App Control dispositions + ST + Modes + WF + Lock + honesty → single outcome.  
FS-003 does not reimplement Kernel.
