# 02 — FS-003 L3 Role Matrix

**Authority:** L2 Role Access · APP-OD-02…07, 17, 20  
**Master:** [11_FS003_L3_MASTER_CONTRACT.md](11_FS003_L3_MASTER_CONTRACT.md)

```
OWNER DECISIONS: FROZEN
```

---

## 1. Legend

| Symbol | Meaning |
|---|---|
| ✅ | Allowed |
| ⛔ | Forbidden (hide or disable with honest reason) |
| ◐ | View only |
| → | Deep-link to other system (not FS-003 authoring) |

---

## 2. Parent / Co-Parent / Child matrix

| Surface / action | Primary | Full | Partner | Observer | Child |
|---|:-:|:-:|:-:|:-:|:-:|
| Open AC-P-HUB / view honesty | ✅ | ✅ | ✅ | ✅ | ⛔ |
| Edit family baseline | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| Create/edit child override | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| View inventory / app detail | ✅ | ✅ | ◐ | ◐ | ⛔ |
| Allow package | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| Set Permanent Block | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| **Reopen Permanent Block** | ✅ | **⛔** | ⛔ | ⛔ | ⛔ |
| Set App Access Exempt | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| Lock Now / clear Lock Now | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| Restore Baseline | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| Install inbox decide | ✅ | ✅ | ✅ | ⛔ | ⛔ |
| Exception inbox decide / revoke | ✅ | ✅ | ✅ | ⛔ | ⛔ |
| View audit (lifecycle) | ✅ | ✅ | ◐ | ◐ | ⛔ |
| Export evidence packs | ✅ | ⛔ default | ⛔ | ⛔ | ⛔ |
| Edit ST Limit/Unlimited/Countable | → ST | → ST | → ST | → ST | ⛔ |
| Request Temporary Grant minutes | — | — | — | — | → ST |
| Edit Modes schedule | → Modes | → Modes | → Modes | → Modes | ⛔ |
| Edit Web Filter policy | → WF | → WF | → WF | → WF | ⛔ |
| AC-C-DENY / disclosure | — | — | — | — | ✅ |
| Exception Request | — | — | — | — | ✅ |
| SOS / Required Chat / Quran | ✅ | ✅ | ✅ | ✅ | ✅ reachable |

---

## 3. Role UX patterns

| Role | Chrome pattern |
|---|---|
| Primary | Full controls; reopen Permanent Block visible when blocked |
| Full | Same configure as Primary; **reopen control hidden/disabled** with copy: only Primary can reopen |
| Partner | Hub + install/exception inboxes + read-only inventory; no Allow/Block/Exempt/Lock Now/Restore |
| Observer | Status/honesty/summary only; taps on mutate → toast “view only” |
| Child | Interstitial only; no settings gear |

---

## 4. Forbidden inheritances

| Forbidden | Why |
|---|---|
| Stage-1 Partner edits Allow/Block | APP-OD-02 |
| Full reopens Permanent Block | APP-OD-04 |
| Observer decides tickets | APP-OD-20 |
| Child configures anything | APP-OD-17 |
| AuthZ from “who holds the phone” | APP-SF-02 |

---

## 5. Notification recipients (UX expectation)

| Event | Typical recipients |
|---|---|
| Install pending | Primary + Partner + Full (decide-capable) |
| Exception requested | Primary + Partner + Full |
| Plane degraded | All parent roles with view (incl. Observer) |
| Decision made | Requester child (local) + deciding parents (confirm) |
