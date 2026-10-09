# 06 — FS-006 Break-Glass and Panic Discovery

**Authority:** OD-12 · OD-13 · RD-01 · RD-02 · Q-SOS-RD-02A/02B  
**Master:** [12_FS006_DISCOVERY_CLOSURE_REPORT.md](12_FS006_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Break-glass (frozen summary)

| Aspect | Frozen law |
|---|---|
| Who | Primary + Mother Full only |
| AuthZ | RBAC — never device ownership |
| What | Temporary bypass of **allowlisted** response blockers |
| Not what | Permanent policy, unlock-everything, disable audit/SOS, delete evidence, privacy bypass |
| Lifecycle | START → REASON → OVERRIDE_ACTIVE → EXPIRY → AUTO_REVOKE → AUDIT |
| Not | Child SOS create path |

---

## 2. Stage-1 break-glass evidence

| Piece | Class |
|---|---|
| `SosBreakGlassPhase` / `SosBreakGlassSession` | **PARTIAL** domain |
| `InMemorySosBreakGlassStore` | **MOCK** — no permanent ladder mutation (aligns “not permanent”) |
| `showSosBreakGlassSheet` | **PARTIAL** UI — reason + confirm |
| RBAC gate | **IMPLEMENTED** in store.start |
| Auto-revoke | **PARTIAL** — lazy on `active` getter when past `expiresAt` |
| Durable audit / cloud worker | **MISSING** |
| Actual unlock of ST/web/app/lock planes | **MISSING** — session does not drive Policy Kernel overrides |
| Duration | Sheet uses minutes from l10n — **do not treat UI number as new Owner freeze**; frozen pack governs semantics |

**Important:** Stage-1 correctly **avoids** rewriting permanent policy in the break-glass store — but also does **not** yet deliver real temporary override enforcement.

---

## 3. Panic Quiet Mode (frozen RD-01 / OD-12)

| Law | Stage-1 |
|---|---|
| Active SOS child = emergency-critical only | Eng docs + settings title/subtitle; full critical-only shell **PARTIAL** |
| Entertainment must not suppress SOS | Exempt patterns elsewhere |
| FAT-028 Panic Quiet toggle | UI / settings **PARTIAL** |

---

## 4. Audio

Frozen **OD-11 EXCLUDED**. Stage-1 has no audio capture path for SOS — **correct absence**. Do not reintroduce. Register “siren” language = notification honesty / historical — not audio recording.
