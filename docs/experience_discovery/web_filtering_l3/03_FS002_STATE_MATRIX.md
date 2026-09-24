# 03 — FS-002 State Matrix (L3.3)

**Authority:** L2 Enforcement · Offline/Sync · Filtering Model · Exception  
**Rule:** States are UX-visible. **Do not invent TTL numbers, durations, or vendor thresholds** (T-WF-01…05 remain TBD).

---

## 1. Policy states

| State ID | Meaning | Parent UX | Child UX |
|---|---|---|---|
| `policy_none` | No family baseline yet | Empty CTA: create family filter | Disclosure may still say inactive / not configured (honest) |
| `policy_family_active` | Family baseline exists; child has no override | “Family baseline applies” | Filter-active disclosure if enforced |
| `policy_child_override_active` | Child override present | Badge: “Override for {child}” · effective = override | Same disclosure class |
| `policy_saving` | Save in flight | Disable double-save · spinner | — |
| `policy_saved` | Saved to Domain / outbox accepted | Success · version bump | — |
| `policy_pending_ack` | Saved > device acked version | “Awaiting child device acknowledgement” — **not** “enforced” | May still run prior acked version |
| `policy_stale` | Ack overdue / stale signal (TTL = T-WF-04 TBD) | Stale honesty chip — no fake enforced | — |
| `policy_sync_degraded` | Offline / sync failure | Queued / failed honesty | — |

**Law:** `policy_saved` alone must never render as “device protected” (L3.6).

---

## 2. Enforcement / capability plane states

| State ID | Meaning | Allowed claim |
|---|---|---|
| `enf_enforced` | Verified active plane + applicable policy acked | May say filtering is active on this device |
| `enf_degraded` | Partial / limited plane | “Limited protection” + what still works |
| `enf_unavailable` | Plane temporarily unavailable (e.g. permission) | No protected claim |
| `enf_unsupported` | Platform cannot provide verified mechanism | Unsupported honesty |
| `enf_unknown` | Capability not yet assessed | No protected claim |
| `enf_pending_policy` | Plane OK but policy not yet acknowledged | “Policy pending on device” |

Map from L2: `enforced` · `degraded` · `unsupported` · `disabled_by_permission` · `unknown` · `pending_policy`.

**Forbidden copy:** “fully protected” / “webFilter=full” Stage-1 table as proof.

---

## 3. Filtering verdict states (decision outcome)

| State ID | Meaning | Source hint for UX |
|---|---|---|
| `v_allowed` | Navigation allowed by Web Filter path | — |
| `v_blocked` | Denied (generic) | Show reason class |
| `v_allowlisted` | Allowlist hit | Web Filter · allowlist |
| `v_blocklisted` | Blocklist hit | Web Filter · blocklist |
| `v_dictionary` | Keyword dictionary hit | Web Filter · dictionary |
| `v_category` | Category model hit | Web Filter · category (label TBD T-WF-02) |
| `v_temp_allow_active` | Timed temporary allow matches | Exception active |
| `v_temp_allow_expired` | Exception ended; base resumed | Resume baseline |
| `v_stricter_app_control` | App/System Control deny (intersection) | Source = App Control (or both) |
| `v_mode_tightened` | Mode added restriction caused deny | Mode + Web Filter |

Verdict presentation for parents uses **family-safe reason classes**, not raw classifier internals.

---

## 4. Unlock / exception ticket states

| State ID | Meaning |
|---|---|
| `ticket_none` | No open request |
| `ticket_pending` | Child requested; awaiting decide |
| `ticket_approved_pending_ack` | Approved; timed allow not yet on device |
| `ticket_active` | Timed temporary allow active |
| `ticket_denied` | Denied |
| `ticket_expired` | Temporary allow expired |
| `ticket_queued_offline` | Request or decision queued |

Duration values: **T-WF-01 TBD** — UI shows placeholder “temporary period” until Technical freeze.

---

## 5. Safe Search states (WF-OD-06)

| State ID | Meaning |
|---|---|
| `ss_enforced` | Policy requires it + platform can enforce |
| `ss_not_supported` | Platform cannot enforce |
| `ss_unavailable` | Temporarily cannot enforce |
| `ss_unknown` | Capability unknown |
| `ss_off_by_policy` | Editors turned off (only Primary/Full) |

Never show universal “Safe Search on everywhere” when state ≠ `ss_enforced`.

---

## 6. Private / incognito honesty (WF-OD-07)

| State ID | Meaning |
|---|---|
| `pb_restricted` | Platform verified restriction where applicable |
| `pb_not_supported` | Cannot restrict — honesty only |
| `pb_unknown` | Unknown |
| `pb_partial` | Some browsers/apps only — disclose coverage |

**Forbidden:** Fake “incognito blocked” success when unsupported.

---

## 7. Mode context states (consume-only)

| State ID | Meaning |
|---|---|
| `mode_none` | No tightening from Modes |
| `mode_tighten_active` | Active Mode adds restriction |
| `mode_schedule_owned_elsewhere` | Link to FS-005 — no local scheduler |

Modes never expose a “relax filter” control inside Web Filter.

---

## 8. Router add-on states (WF-OD-11)

| State ID | Meaning |
|---|---|
| `router_not_configured` | Optional add-on unused |
| `router_configured_unverified` | Mock/setup without verified protection — **honesty** |
| `router_optional_active_honest` | Explicit add-on labeled non-core |

Never merge router state into `enf_enforced` core claim.

---

## 9. Composite honesty rule

```
Parent “protection” headline =
  f(policy state, enforcement state, ack state, Safe Search capability)
```

If any of `enf_unsupported` | `enf_unavailable` | `enf_unknown` | `policy_pending_ack` (when claiming current version) → **must not** show full-protection success.
