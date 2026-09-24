# 07 — FS-003 L3 Install & Exception Flows (detail)

**Authority:** L2 Install/Exception · APP-OD-05…08, 13, 18, 19  
**Complements:** [04_FS003_L3_FLOW_CATALOG.md](04_FS003_L3_FLOW_CATALOG.md) F11–F14  
**Master:** [11_FS003_L3_MASTER_CONTRACT.md](11_FS003_L3_MASTER_CONTRACT.md)

---

## 1. New-install end-to-end

```
Device observes package
  → install.observed
  → pending_decision
  → Child: pending_unknown DENY (no class default)
  → Notify Primary+Partner+Full
  → Parent opens AC-P-INSTALL-D
       ├─ Approve → child-scoped allowed · install.approved
       └─ Deny    → denied/block · install.denied
  → Child device ack · interstitial clears or stays denied
```

### State transitions

| From | Action | To |
|---|---|---|
| (none) | observe | `pending_decision` + child deny |
| `pending_decision` | approve (child scope) | `allowed` for that child |
| `pending_decision` | deny | deny/block disposition |
| any | offline decide | outbox → same terminal on replay |

### UX invariants

- Default scope label: **This child only**  
- No silent family-wide  
- No WF list write  
- No Temporary Grant / Unlimited mint  
- Partner may decide; may not edit baseline  

### Class default branch

If applicable class default exists (T-APP-08): pending may follow class rule instead of hard deny — **UI must show which default applied**. Core protected four never pending-deny.

---

## 2. App Access Exception end-to-end

```
Child on AC-C-DENY → Request
  → exception.requested / pending
  → Notify decide-capable parents
  → Parent AC-P-EXCEPT-D
       ├─ Approve timed → active overlay (block row UNCHANGED)
       ├─ Deny → denied
       └─ later Revoke / Expiry → overlay cleared; block resumes
```

### Invariants (must appear in copy + logic)

1. **App Access Exception ≠ Temporary Grant ≠ ST Unlimited**  
2. **Exception is temporary evaluation override; does not delete/rewrite Permanent Block**  
3. Duration control is parent-side; numeric values **T-APP-06** (placeholder UI only)  
4. Active Exception still subject to Instant Lock, Modes tighten, WF, ST rules where applicable  

### Parallel ST request

If deny reason includes time exhaustion, child may see **separate** “Request more time” → ST — never merged into Exception approve.

---

## 3. Lock Now vs Exception vs Permanent Block

| | Permanent Block | Lock Now | App Access Exception |
|---|---|---|---|
| Intent | Hard policy deny | Temporary deny overlay | Temporary allow overlay |
| Who sets | Primary+Full | Primary+Full | Decide: Primary+Partner+Full |
| Clears by Restore? | **No** (needs Primary reopen) | **Yes** | **Yes** (active/pending) |
| Opens with Grant? | **No** | N/A | N/A |

---

## 4. Restore Baseline interaction

Restore (Primary/Full):

- Clears override document toward family baseline  
- Clears Lock Now + Exception overlays (+ applicable pending holds)  
- **Leaves Permanent Block entries** unless Primary uses reopen  

Confirm sheet must list both columns: cleared vs retained.

---

## 5. Notifications map

| Event | Parent | Child |
|---|---|---|
| Install pending | Decide roles | Interstitial pending |
| Install decided | Confirm | Interstitial update |
| Exception requested | Decide roles | “Sent” |
| Exception decided/expired | Confirm | Deny or access |
| Plane degraded | View roles | Disclosure only |

Delivery channel **T-APP-10** TBD — UX must not assume FCM.

---

## 6. Audit map

install.* · app_exception.* · app_lock_now.* · app_baseline.restored · app_rule.blocked/allowed · relevant app_access.denied · app_plane.state_changed  

No default full open-app stream.
