# 04 — FS-006 SOS Policy and AuthZ Discovery

**Mode:** Map Stage-1 AuthZ evidence to **frozen** SOS Final — do not reopen OD/RD.  
**Master:** [12_FS006_DISCOVERY_CLOSURE_REPORT.md](12_FS006_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Frozen AuthZ (authority)

From SOS Final OD-01…04 · RD-02 · Q-SOS-RD-02A:

| Role | Frozen powers |
|---|---|
| Primary | Full SOS control |
| Mother Full | Partner + configure + **break-glass** |
| Mother Partner | Receive; view; ack; respond; escalate — **no** nuclear config / break-glass |
| Mother Observer | Receive; view essential; contact — **no** resolve/escalate/configure/break-glass |
| Child | Trigger; cancel own with confirm → false-alarm path; **no** break-glass |

AuthZ = **RBAC only** — never device-ownership inference.

---

## 2. Stage-1 evidence

| Check | Code | Aligns? |
|---|---|---|
| `SosRoleActions.canConfigure` | Primary + Full | **Yes** |
| `canBreakGlass` | Same as configure | **Yes** vs Q-SOS-RD-02A |
| `canResolve` / `canEscalate` | Primary + Partner + Full | **Yes** vs OD-01/02 |
| `canAcknowledge` | Includes Observer | Compatible with OD-01 receive/view (ack allowed in code) |
| `canCancelOwnSos` | Child | **Yes** OD-06 |
| Break-glass store denies non-Full | Throws | **Yes** |
| FAT-028 historically any navigator | Prior truth pack | **Gap** vs configure AuthZ — honesty/gap |

---

## 3. Policy precedence (frozen)

OD-14: never gated by subscription, quiet hours, screen-time, entertainment, device lock.

Stage-1: paywall boundary tests; mute forbidden; SOS exempt surfaces — **PARTIAL** proof.

---

## 4. Break-glass policy (frozen — not rediscovered as Q)

Allowlist / forbidden / lifecycle — see `sos_final` + discovery doc 06. Stage-1 implements **UI session** only.

---

## 5. Owner questions

**None.** All product AuthZ decisions already frozen. Gaps are **implementation**, not new Q-SOS.
