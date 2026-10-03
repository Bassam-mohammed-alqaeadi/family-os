# 03 — FS-007 State Matrix (L3)

**Master:** [13_FS007_L3_MASTER_CONTRACT.md](13_FS007_L3_MASTER_CONTRACT.md)

---

## 1. Capability / model states (per child device · per tool)

| State | Meaning | Parent UX | Child card |
|---|---|---|---|
| `off` | Tool not configured | Off | Row off / hidden if never on |
| `configured_pending_model` | On but no usable signed model | Honesty: waiting for model | Degraded/waiting |
| `active` | Configured + signed model + ack | May claim classifying | Active + on-device named |
| `degraded` | Running with limits (OCR fail class, thermal, etc.) | Degraded honesty | Degraded |
| `unsupported` | Device/OS cannot run plane | Unsupported | Unsupported |
| `stale_model` | Version behind approved | Stale banner; classify policy per T-AI (default: keep last-good if signed) | Stale/limited |
| `integrity_failed` | Signature fail | Refuse run | Unavailable |
| `unknown` | Cannot determine | Unknown honesty | Unknown |

**Law:** Never show `active` protection copy unless truly active.

---

## 2. Classification result states

| State | Notify | Ticket | Notes |
|---|---|---|---|
| Completed + certainty `preliminary`/`unknown` | ✅ | ❌ | AI-OD-03-GATE |
| Completed + `analysis`/`confirmed` | ✅ | ✅ | |
| Failed / error | Optional tech honesty to Primary+Full | ❌ | Not a safety “hit” |
| No-op (tool off) | ❌ | ❌ | |

---

## 3. Ticket states

`open` → `in_review` → `resolved` | `dismissed_fp` | `escalated_suggestion_pending`  

On `resolved` / `dismissed_fp`: **purge redacted preview** (AI-OD-12). Metadata+audit remain.

---

## 4. Sync / offline states

| State | UX |
|---|---|
| Online sync OK | Last synced visible |
| Offline | Local classify may still run if `active`; notify/ticket queue for parent devices |
| Queued outbox | Honest “waiting to sync” |
| Sync conflict | Deterministic merge later (T-AI-22); no silent drop without honesty |

---

## 5. Cloud classify states

**N/A in v1** (AI-OD-10). UI must not offer “cloud classify” as active v1 path. If future OD enables it, add explicit provenance states then.
