# 08 — FS-003 Event, Audit & Notification Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · APP-OD-16 · **T-APP-10 OPEN**  
**Non-authority:** Unaudited Stage-1 FAT-034 toggles  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Separation of concerns

| Layer | Owner |
|---|---|
| Event generation | FS-003 Domain |
| Interpretation → notify/action | Policy Kernel |
| Notification delivery | Global Notifications (**T-APP-10**) |
| Append-only audit | Audit infrastructure |
| Evidence packs | Audit + Kernel; export Primary-leaning (APP-SF-03) |

---

## 2. Canonical events (v1 — APP-OD-16)

| Event family | Examples | Required |
|---|---|---|
| Policy mutation | `app_policy.saved`, `app_rule.blocked`, `app_rule.allowed`, `app_rule.exempt_set`, `app_baseline.restored` | **Yes** |
| Install lifecycle | `install.observed`, `install.pending`, `install.approved`, `install.denied` | **Yes** |
| Exception lifecycle | `app_exception.requested` … `.revoked` | **Yes** (enabled) |
| Lock Now | `app_lock_now.set` / `.cleared` | **Yes** |
| Enforcement honesty | `app_plane.state_changed` | **Yes** |
| Relevant deny / launch-block | `app_access.denied` | **Yes** (relevant denies — not full surveillance) |
| Full foreground open timeline | — | **Forbidden as default** |

---

## 3. Audit mutations

Every authorized write changing effective access appends: actor · childId/familyId · packageId · before/after · policyVersion · timestamp.  

Exception activate/expire must record that **underlying Permanent Block was not rewritten**.

AI never writes policy without approval (APP-SF-11).

---

## 4. Notifications

| Class | When |
|---|---|
| New install pending | `install.pending` |
| Install decided | approve/deny |
| Exception requested / decided | APP-OD-06 enabled |
| Plane degraded / unsupported | honesty transition |
| Child deny / pending interstitial | Local child UX |

Quiet hours must **never** mute SOS. Delivery channel = **T-APP-10**.

---

## 5. Explicit non-goals

- Full open-app / foreground surveillance as default  
- Equating FAT-069 fixtures with enforcement evidence  
- Claiming FCM until proven  
