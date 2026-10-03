# 09 — FS-005 Cross-System Boundaries (L2 Target) — FROZEN

**Status:** **FROZEN** · MODE-SF-04…12 · MODE-OD-06…09 · MODE-OD-11…14  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Ownership map

| System | Owns | Modes may | Modes must not |
|---|---|---|---|
| **FS-005 Modes** | Lifestyle Mode model · schedule/evaluation authority · activation semantics · ModeException · Mode overlay facts | Tighten overlays; consume location context | Own minutes, URL lists, package store, geofences, camera mechanisms |
| **Policy Kernel** | Final merge / interpretation / action | Consume Mode facts | Invent Mode definitions |
| **Screen Time** | Minutes · caps · grants · wallets · Unlimited · countable | Receive Mode **context** via Kernel | Run a second Mode scheduler; author Mode activation |
| **FS-003** | Package Allow/Block / Permanent Block / install / App Access Exception | Be tightened by Mode overlay | Lose Permanent Block to Mode; host Mode scheduler |
| **FS-002** | URL / category / keyword lists · unlock | Be tightened by Mode overlay | Have lists rewritten by Mode; host Mode scheduler |
| **FS-004** | Camera / capture prevent·monitor·protect | Be tightened temporarily by Mode | Be permanently weakened/removed by Mode; host Mode scheduler |
| **FS-001 Location** | Geofence geometry · location truth · ENTER/EXIT/NO_SHOW facts | Provide context for Mode activation | Be replaced by a Modes geofence engine |
| **SOS Final** | Emergency reachability & ladder | — | Be gated / muted / lockout by Mode |
| **Anti-tamper / Instant Lock** | Integrity / P1 lock | Remain above Modes | Be bypassed by Mode |
| **Identity** | RBAC roles | Gate Mode AuthZ | Device-possession AuthZ |

---

## 2. Critical separations

```
FS-005 Mode schedule evaluator
    ≠
Screen Time ScheduleWindow (legacy — reconcile; not Mode authority)

ModeException
    ≠
FS-003 App Access Exception
    ≠
ST Temporary Grant

FS-001 geofence truth
    ≠
FS-005 Mode activation decision (consumes context)

Mode overlay tighten
    ≠
Silent mutation of FS-002/003/004 permanent stores
```

---

## 3. Consistency check vs FS-001…FS-004 (L2)

| Check | Result |
|---|---|
| No second WF scheduler | **PASS** — Modes own lifestyle schedule; WF consumes |
| No second AC scheduler | **PASS** |
| No second SC scheduler | **PASS** |
| Geofence ownership stays FS-001 | **PASS** — MODE-OD-09 |
| Modes tighten-only vs WF-OD-13 / APP-OD-11 / SC-SF-11 | **PASS** — MODE-OD-07 |
| Modes cannot reopen Permanent Block | **PASS** |
| Modes cannot rewrite URL lists | **PASS** |
| Modes cannot permanently weaken FS-004 | **PASS** |
| ST owns minutes not Mode schedule | **PASS** — MODE-OD-06/08 |
| SOS never gated | **PASS** — MODE-OD-14 |
| ScheduleWindow not second Mode authority | **PASS** — MODE-OD-06 (legacy reconcile) |
| Explicit child targeting aligns LOC-OD-20 spirit | **PASS** — MODE-OD-01 no silent family-all |

---

## 4. Forbidden patterns (regression watch)

| Pattern | Status |
|---|---|
| Vacation reopen blocked apps | **FORBIDDEN** |
| ModeException → package mutation | **FORBIDDEN** |
| Child cancel Mode via grace | **FORBIDDEN** |
| AuthZ from device holding | **FORBIDDEN** |
| Claim Stage-1 already enforced | **FORBIDDEN** |
| Dual `modeActive` evaluators | **FORBIDDEN** |

---

## 5. Source-of-deny (future L3)

When access fails, distinguish Mode overlay vs FS-003 vs FS-002 vs FS-004 vs ST vs Instant Lock vs SOS — no wrong-system CTA.
