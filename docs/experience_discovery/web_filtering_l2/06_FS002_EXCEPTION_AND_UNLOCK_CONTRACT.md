# 06 — FS-002 Exception & Unlock Contract (L2 Target) — FROZEN

**Status:** FROZEN · WF-OD-03 · WF-OD-09 · WF-OD-14 · WF-OD-15

---

## 1. Lifecycle

```
DENY (enforced)
  → Child Request Unlock (optional CTA on interstitial)
  → Ticket PENDING
  → Primary | Partner | Full → APPROVE | DENY
  → If APPROVE: create TIMED TEMPORARY ALLOW (not permanent allowList)
  → Audit (request + decision)
  → Notify + device ack
  → On expiry: exception ends; base policy resumes
```

Observer cannot decide (WF-OD-03).

---

## 2. Approve semantics (WF-OD-09)

| Rule | Law |
|---|---|
| Exception type | **Timed temporary allow** only |
| Permanent allowList mutation on approve | **Forbidden** as silent default |
| Duration values | **T-WF-01** — not invented in product contracts |
| Explicit permanent allowlist edit | Separate configure action by Primary/Full (lists editor) — not unlock approve |

---

## 3. Relation to Screen Time

Unlock ≠ Temporary Grant ≠ wallet credit (WF-SF-01).

---

## 4. Child UX (WF-OD-15)

Interstitial may offer request CTA.  
No policy lists or admin on child.

---

## 5. Offline

Queue request/decision; apply on ack; no fake “approved on device” early.
