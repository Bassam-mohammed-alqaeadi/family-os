# 03 — FS-003 L3 State Matrix

**Authority:** L2 Policy / Enforcement / Offline / Install-Exception  
**Master:** [11_FS003_L3_MASTER_CONTRACT.md](11_FS003_L3_MASTER_CONTRACT.md)

---

## 1. Package access dispositions (policy)

| State ID | Meaning | Child launch (if plane `enforced`) |
|---|---|---|
| `allowed` | Explicit allow (or effective allow from baseline/override) | Subject to ST / Modes / Lock / WF |
| `permanent_blocked` | Permanent Block set | **DENY** unless active Exception |
| `exempt` | App Access Exempt | Access-plane not denied by AC; still Instant Lock / SOS / higher layers; **≠ Unlimited** |
| `pending_unknown` | Unknown/new; no class default | **DENY** (deny-until-approved) |
| `class_default_*` | Class default applies (T-APP-08 content) | Per class rule |
| `protected` | SOS / Family OS / Required Chat / Quran | **Always reachable**; controls locked |

---

## 2. Overlay states

| Overlay | Meaning | Interaction with Permanent Block |
|---|---|---|
| `exception_active` | Timed App Access Exception | Evaluation may allow; **policy row unchanged** |
| `exception_pending` | Child requested; awaiting parent | Underlying disposition unchanged |
| `lock_now_active` | Per-app temporary deny | Independent overlay; ≠ Permanent Block |
| `mode_tightened` | Modes context denies | Cannot reopen Permanent Block |
| `instant_device_lock` | P1 device lock | Distinct system |

---

## 3. Sync / ack states (parent-visible)

| State | UI meaning |
|---|---|
| `local_saved` | Saved on parent; not yet outbox-complete |
| `pending_delivery` | Outbox queued / awaiting device |
| `acked` | Device acknowledged `policyVersion` |
| `stale_risk` | Ack older than grace (**T-APP-04** TBD — show honesty, no invented number) |
| `offline_queued` | Parent offline edit queued — **no fake cloud success** |

---

## 4. Enforcement plane states (honesty)

| State | Parent claim |
|---|---|
| `enforced` | May claim blocked/allowed on device |
| `degraded` | Partial — must disclose residual risk |
| `pending_policy` | Policy not yet applied |
| `unavailable` | Plane down — **no** “protected” claim |
| `unsupported` | **no** “protected” claim |
| `unknown` | **no** “protected” claim |
| `disabled_by_permission` | Honesty + remediation CTA |

---

## 5. Install ticket states

`observed` → `pending_decision` → `approved` | `denied`  
Approve → child-scoped `allowed` (APP-OD-18).  
Deny → deny/block disposition.  
While `pending_decision` + no class default → child `pending_unknown` deny-until-approved.

---

## 6. Exception ticket states

`requested` → `pending` → `approved` → `active` → `expired` | `revoked`  
OR `denied` from pending.  

**Invariant:** transitions never delete Permanent Block row.

---

## 7. Combined deny reasons (source-of-deny)

| Code | Label (conceptual) |
|---|---|
| `sod_app_block` | Permanent Block / Lock Now / pending unknown |
| `sod_app_exception_expired` | Exception ended; block resumes |
| `sod_mode` | Mode tighten |
| `sod_st` | Screen Time cap / limit (not AC) |
| `sod_wf` | Web Filter |
| `sod_both_ac_wf` | App Control + Web Filter |
| `sod_instant_lock` | Instant Device Lock |

UX must show **explicit source** when presenting deny (APP-SF-08).

---

## 8. Multi-device child state

| View | Meaning |
|---|---|
| Per-device plane state | Each enrolled device honesty row |
| Shared child policy version | Child override / baseline version |
| Divergent ack | One device acked, another pending — show split honesty |

ST multi-device **minutes** budget remains ST-owned (not shown as AC budget).
