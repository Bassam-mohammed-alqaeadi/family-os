# 03 — FS-004 L3 State Matrix

**Authority:** L2 Policy / Enforcement / Offline / Monitoring  
**Master:** [12_FS004_L3_MASTER_CONTRACT.md](12_FS004_L3_MASTER_CONTRACT.md)

---

## 1. Policy intent states (per pillar)

| Pillar | Off | On (configured) | Notes |
|---|---|---|---|
| OS camera restrict | `cam_intent_off` | `cam_intent_on` | ≠ package block |
| Capture prevention | `prev_intent_off` | `prev_intent_on` | Claim only if plane allows |
| Monitoring | `mon_off` | `mon_on` + scope | Transparency required if on |
| Surface protect | `prot_off` | `prot_on` | Family OS surfaces |

Effective = baseline ⊕ child override (override wins).

---

## 2. Overlay / context

| State | Meaning |
|---|---|
| `mode_tightened` | Modes tightened FS-004 (cannot permanently remove policy) |
| `exception_active` | Explicit FS-004 exception for protected workflow |
| `exception_pending` | Ticket awaiting parent |

Exceptions do **not** silently erase underlying policy rows.

---

## 3. Sync / ack

| State | UI |
|---|---|
| `local_saved` | Saved locally |
| `pending_delivery` | Outbox / awaiting device |
| `acked` | Device acked version |
| `offline_queued` | No fake cloud success |
| `stale_risk` | Honesty only — TTL **T-SC-11** |

---

## 4. Plane honesty (per device)

`enforced` · `degraded` · `pending_policy` · `unavailable` · `unsupported` · `unknown` · `disabled_by_permission`

Claims forbidden unless `enforced` + acked (or explicit degraded disclosure).

Pillars may have **independent** capability: e.g. monitoring `unsupported` while camera restrict `enforced`.

---

## 5. Monitoring observation

| State | Meaning |
|---|---|
| `obs_none` | No events / monitoring off / unsupported |
| `obs_item` | Real `sc_capture.observed` |
| `obs_capability_gap` | Monitoring on but plane cannot observe — honesty, **no fake events** |

---

## 6. Source-of-restriction codes

| Code | Meaning |
|---|---|
| `sor_fs004_camera` | OS/device camera restricted |
| `sor_fs003_package` | Camera package blocked (App Control) |
| `sor_fs004_prevent` | Capture prevention |
| `sor_fs004_monitor` | Monitoring active (informational, not always deny) |
| `sor_fs004_protect` | Surface protection |
| `sor_mode` | Mode tighten |
| `sor_st` / `sor_wf` / `sor_lock` | Other systems |

---

## 7. Multi-device

Per-device plane + ack; child-scoped policy version; divergent ack visible on SC-P-DEVICE.
