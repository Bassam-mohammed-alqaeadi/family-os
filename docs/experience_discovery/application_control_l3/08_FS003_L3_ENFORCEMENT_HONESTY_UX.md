# 08 — FS-003 L3 Enforcement Honesty UX

**Authority:** APP-OD-14 · APP-SF-09/10 · L2 Enforcement Contract  
**Master:** [11_FS003_L3_MASTER_CONTRACT.md](11_FS003_L3_MASTER_CONTRACT.md)

---

## 1. Principle

Parents may only be told the device is enforcing App Control when:

1. Policy is **acknowledged** (`acked`), and  
2. Capability plane is **`enforced`** (verified hybrid plane — mechanism TBD in T-APP-02).

Never claim protection for: `unsupported` · `unknown` · `unavailable` · equivalent unverified states.

---

## 2. Honesty strip (global parent chrome)

| Plane state | Strip treatment | Claim language |
|---|---|---|
| `enforced` + acked | Neutral/positive | “Enforcing on device” |
| `enforced` + pending ack | Warning | “Enforcing previous policy — update pending” |
| `degraded` | Warning | “Partial enforcement — residual risk” |
| `pending_policy` | Info | “Waiting for device to apply policy” |
| `unavailable` | Critical | “Not enforcing — do not assume blocked” |
| `unsupported` | Critical | “Not supported on this device — no protection claim” |
| `unknown` | Critical | “Status unknown — no protection claim” |
| `disabled_by_permission` | Critical + CTA | “Permission needed” → remediation (no API name freeze) |

---

## 3. Ack / pending / stale

| UX element | Behavior |
|---|---|
| Version chip | Show policyVersion saved vs acked |
| Multi-device | Per-device rows; divergent ack visible |
| Stale | Honesty only; **no invented TTL number** (T-APP-04) |
| Offline save | “Queued on this device” — **no fake cloud success** |

---

## 4. Forbidden honesty anti-patterns

| Anti-pattern | Forbidden |
|---|---|
| Green “Protected” on unsupported device | Yes |
| “Device Owner active” as product claim without verified plane | Yes |
| Equating parent toggle with child enforcement | Yes |
| Hiding degraded residual risk | Yes |
| Child admin of plane diagnostics | Yes |

---

## 5. Child honesty

- Disclosure: “Family protection is active” when policy intends protection — **non-interactive**  
- If plane unsupported on child device: still show deny for policy intent where last-acked says deny, plus honest “protection may be limited” if Kernel supplies honesty flag — **without** admin  
- SOS/Chat/Quran remain reachable regardless  

---

## 6. Anti-tamper separation

Honesty may deep-link “Device integrity / Anti-tamper” as **separate subsystem**.  
App Control screens must not own uninstall-resistance toggles (APP-OD-15).

---

## 7. Mechanism language

UI may say “on-device enforcement” / “verified protection plane”.  
UI must **not** freeze “uses Accessibility / Device Owner / VPN” as the product mechanism (T-APP-02 open).
