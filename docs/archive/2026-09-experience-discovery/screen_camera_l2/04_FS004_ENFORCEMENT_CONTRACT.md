# 04 — FS-004 Enforcement Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · SC-OD-04 · SC-OD-06 · SC-SF-06/07 · **T-SC OPEN**  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Product vs platform

| Layer | Law |
|---|---|
| **Product** | Hybrid verified capability plane (SC-OD-04). Device-level camera restriction may be **product intent**. |
| **Platform** | Concrete APIs = **T-SC-01…04, 10, 12** after verification — **not** frozen here |

**Do not** freeze Device Owner, AppOps, Accessibility, VPN, MediaProjection, or other APIs as *the* product mechanism.

Discovery CURRENT: **zero** OS enforcement — evidence only.

---

## 2. Honesty states (normative — FROZEN)

| State | Parent claim |
|---|---|
| `enforced` | May claim restriction/monitoring/protection **on device** when ack + verified |
| `degraded` | Partial — disclose residual risk (incl. third-party capture limits) |
| `pending_policy` | Saved ≠ applied yet |
| `unavailable` | **No** success claim |
| `unsupported` | **No** success claim (common iOS path per SC-OD-06) |
| `unknown` | **No** success claim |
| `disabled_by_permission` | Honesty + remediation |

Aligns with FS-002 / FS-003 honesty family.

---

## 3. Prevention vs monitoring honesty

| Pillar | Claim rule |
|---|---|
| **Prevention** | Only assert “child cannot capture / camera restricted” when plane supports that claim |
| **Monitoring** | Only assert “screenshots observed/reported” when monitoring agent actually capable |
| **Protect** | Only assert Family OS surface protection when mechanism verified |
| **Universal third-party block** | **Forbidden** as product claim (SC-OD-03) |

---

## 4. iOS (SC-OD-06)

Same product intents where meaningful; unsupported controls → `unsupported` / degraded honesty — never fake Android parity.

---

## 5. Multi-device

Per enrolled child device: own plane state + acked version. Divergent ack must be visible. Child-scoped policy (SC-OD-12).

---

## 6. Open technical

T-SC-01…04, 09–12 remain **OPEN**. No durations invented.
