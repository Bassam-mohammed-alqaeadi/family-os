# 03 — FS-003 Role Access Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · APP-OD-02…07 · APP-OD-17 · APP-OD-20  
**Vocabulary:** Primary Parent · Co-Parent Observer · Partner · Full · Child  
**Non-authority:** Stage-1 Father/Mother Partner-edit on FAT-034  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Hard rules

| Rule | Law |
|---|---|
| RBAC only | APP-SF-02 — never device-holder inference |
| Vocabulary | APP-SF-01 — Primary / Co-Parent / Child |
| Configure policy | **Primary + Co-Parent Full** only (APP-OD-02) |
| Partner / Observer configure | **Forbidden** |
| Set Permanent Block | **Primary + Full** (APP-OD-03) |
| Reopen Permanent Block | **Primary only** (APP-OD-04) |
| New-install decide | **Primary + Partner + Full** (APP-OD-05) |
| App Access Exception decide | **Primary + Partner + Full** (APP-OD-07) |
| Observer | View-only — no mutation, no decide (APP-OD-20) |
| Child | Deny/pending + disclosure + Exception Request; **no admin** (APP-OD-17) |
| Stage-1 Partner-edit | **Rejected** |
| Primary ≠ Full for reopen Permanent Block | APP-OD-04 · APP-SF-03 |

---

## 2. Capability matrix (authoritative)

| Capability | Primary | Observer | Partner | Full | Child |
|---|:-:|:-:|:-:|:-:|:-:|
| View effective status / honesty / policy summary | ✅ | ✅ | ✅ | ✅ | deny/pending + disclosure only |
| Edit family baseline / child override | ✅ | ⛔ | ⛔ | ✅ | ⛔ |
| Set Permanent Block | ✅ | ⛔ | ⛔ | ✅ | ⛔ |
| Reopen Permanent Block | ✅ | ⛔ | ⛔ | ⛔ | ⛔ |
| Approve / deny new install | ✅ | ⛔ | ✅ | ✅ | ⛔ |
| Request App Access Exception | — | — | — | — | ✅ |
| Approve / deny App Access Exception | ✅ | ⛔ | ✅ | ✅ | ⛔ |
| Set / clear per-app Lock Now | ✅ | ⛔ | ⛔ | ✅* | ⛔ |
| Restore Baseline | ✅ | ⛔ | ⛔ | ✅* | ⛔ |
| Request Screen Time minutes | — | — | — | — | ✅ (ST) |
| Approve Temporary Grant / minutes | ST Role Contract | ⛔ | ST | ST | ⛔ |
| Author Limit / Unlimited / Countable | ST (APP-OD-12) | ⛔ | ⛔† | ST† | ⛔ |
| Export audit / evidence packs | ✅ (Primary-leaning) | ⛔ | ⛔ | ⛔ default | ⛔ |
| SOS | Always per SOS Final | Always | Always | Always | Trigger / own |

\* Lock Now / Restore Baseline are **policy-configure class** actions → Primary + Full (same as APP-OD-02), unless a later OD splits them; Partner has **ticket decide** only (install/exception), not baseline configure.  
† Screen Time authorship follows ST Role Contract / APP-OD-12 — not FS-003.

---

## 3. Child authority (FROZEN)

| Allowed | Forbidden |
|---|---|
| Reach SOS / Required Chat / Quran | Edit policy / lists / admin |
| See deny/pending + general disclosure | Approve installs |
| Request App Access Exception | Reopen Permanent Block |
| Request ST minutes (ST system) | Bypass block via wallet / Grant / Unlimited |

---

## 4. Audited role actions

Policy save · Permanent Block set · Permanent Block reopen (Primary) · install decide · exception request/decide · Lock Now set/clear · Restore Baseline · capability-state transitions affecting claims · relevant deny events (APP-OD-16).
