# 10 — FS-006 Cross-System Boundaries (L2 Wrapper) — FROZEN

**Status:** **FROZEN** · SOS-SF-03 · SOS-SF-08 · SOS-SF-10/11 · sibling L2  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Ownership map

| System | Owns | SOS may | SOS must not |
|---|---|---|---|
| **FS-006 / SOS Final** | Incident · delivery honesty · ladder · break-glass · Panic Quiet · evidence retention law | — | Invent location geometry; invent minutes; rewrite lists |
| **FS-001** | Location facts / history / geofences | Attach/consume location evidence | Move ownership into SOS |
| **FS-002** | URL policy | Remain reachable; never blocked | Edit URL lists |
| **FS-003** | Package policy / Permanent Block | Remain reachable; break-glass temp response only | Clear Permanent Block; rewrite package store |
| **FS-004** | Camera/capture | Remain reachable | Introduce SOS audio/mic; use capture as SOS evidence A/V |
| **FS-005** | Modes / lifestyle schedule | Never gated by Modes; temp response override per break-glass allowlist only | Mutate Mode definitions |
| **Screen Time** | Minutes/grants/wallets | Outside ST economy | Spend/mint minutes for SOS |
| **Policy Kernel** | Merge/interpret | Apply temporary override facts | Invent SOS domain facts |
| **Audit** | Append-only log | Receive SOS facts | Allow SOS to delete audit |
| **Identity** | RBAC roles | Gate SOS AuthZ | Device-possession AuthZ |

---

## 2. Consistency check

| Check | Result |
|---|---|
| Modes never gate SOS | **PASS** (MODE-OD-14) |
| App Control cannot deny SOS | **PASS** (APP-OD-09) |
| Web Filter cannot block emergency path | **PASS** |
| FS-004 no SOS audio | **PASS** (OD-11 + SC) |
| FS-001 owns location | **PASS** |
| Break-glass ≠ permanent mutation | **PASS** |
| ST minutes separate | **PASS** |
| No contradictory audio product law in this wrapper | **PASS** (OD-11) |

---

## 3. Implementation gaps ≠ law gaps

Discovery gaps (mock delivery, no outbox, etc.) are **implementation debt** under frozen law — not reasons to reopen OD/RD.
