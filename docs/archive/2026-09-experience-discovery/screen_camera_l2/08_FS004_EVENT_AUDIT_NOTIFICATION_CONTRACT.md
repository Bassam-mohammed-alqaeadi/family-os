# 08 — FS-004 Event, Audit & Notification Contract (L2 Target) — FROZEN

**Status:** **FROZEN** catalog intent · delivery **TBD**  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Separation

| Layer | Owner |
|---|---|
| Event generation | FS-004 Domain |
| Interpretation → notify/action | Policy Kernel |
| Delivery | Global Notifications |
| Append-only storage | Audit infrastructure |

---

## 2. Canonical events (minimum v1)

| Family | Examples | Required |
|---|---|---|
| Policy mutation | `sc_policy.saved`, camera restrict on/off, prevention on/off, protect on/off | **Yes** |
| Monitoring lifecycle | `sc_monitor.configured` / `.activated` / `.deactivated` / `.scope_changed` | **Yes** |
| Capture observation | `sc_capture.observed` | **Only when actually observed** |
| Exceptions | `sc_exception.requested` / `.approved` / `.denied` / `.revoked` | When tickets exist |
| Plane honesty | `sc_plane.state_changed` | **Yes** |
| Full open-app stream | — | **Forbidden as default** |

---

## 3. Audit requirements

Every authorized configure/decide write: actor · family/child · before/after · policyVersion · timestamp.  

Monitoring activation must be auditable and correlated with child transparency state.  

No SOS audio events (SC-OD-08). No mic ambient events under FS-004 (SC-OD-05).

---

## 4. Notifications (types — not transport)

| Type | When |
|---|---|
| Monitoring activated/deactivated | Configure |
| Capture observed (if capable) | Agent fact |
| Plane degraded / unsupported | Honesty transition |
| Exception ticket | If applicable |
| Child local transparency update | Monitoring flag change |

Smart Alerts may **display** notifications but must not own policy (SC-OD-09).  
Transport = technical TBD — do not assume FCM.

---

## 5. Non-goals

Silent capture audit without transparency · Full surveillance feed as default product · Fake observed events without capability.
