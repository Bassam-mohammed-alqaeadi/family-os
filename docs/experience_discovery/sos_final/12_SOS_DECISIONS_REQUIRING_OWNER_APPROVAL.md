# 12 — SOS Decisions Requiring Owner Approval

**Status:** **NONE REMAINING**  
**Updated:** 2026-09-23  

**OD-01…OD-21:** FROZEN — do not reopen.  
**RD-01…RD-05:** Defaults applied and closed.  
**Q-SOS-RD-02A / 02B / 03A:** **CLOSED** by Owner 2026-09-23.

**SOS PRODUCT CONTRACT STATUS: FROZEN**

Related: [01_SOS_OWNER_DECISIONS.md](01_SOS_OWNER_DECISIONS.md) · [13_SOS_FINAL_MASTER_CONTRACT.md](13_SOS_FINAL_MASTER_CONTRACT.md) · [SOS_CONTRACT_CLOSURE_REPORT.md](SOS_CONTRACT_CLOSURE_REPORT.md)

---

## Open questions

**None.**

---

## Closed this freeze

### Q-SOS-RD-02A — Break-glass roles — **CLOSED**

| Role | Break-glass |
|---|---|
| Primary Parent | ✅ Allowed |
| Mother Full | ✅ Allowed |
| Mother Partner | ❌ Not allowed |
| Mother Observer | ❌ Not allowed |
| Child | ❌ Not allowed |

**Rule:** Authorization must come from **RBAC** (role + MotherLevel). It must **never** be inferred merely from device ownership.

---

### Q-SOS-RD-02B — Break-glass capability allowlist — **CLOSED**

**Nature:** Narrowly scoped **temporary** emergency override. Time-bounded. Auto-revoked. Never silently modifies permanent policy.

#### ALLOWED temporarily

- Child device lock / restricted shell bypass required for SOS response  
- Screen-time restriction bypass required for SOS response  
- Web/app restriction bypass required for emergency communication or response  
- Emergency communication surface  
- Access to active SOS and location context  
- Parent SOS notification handling  

#### FORBIDDEN

- Permanent policy changes  
- Role/permission changes  
- Billing/entitlement changes  
- Disabling SOS  
- Disabling audit  
- Deleting SOS incidents/evidence  
- Bypassing privacy/audit safeguards  
- Creating permanent exceptions  
- Any unrestricted “unlock everything” capability  

#### Required lifecycle

```
START → REASON/CONTEXT → OVERRIDE_ACTIVE → EXPIRY → AUTO_REVOKE → AUDIT
```

---

### Q-SOS-RD-03A — Evidence retention — **CLOSED**

| Class | Retention |
|---|---|
| Operational SOS evidence samples | **90 days** |
| Core incident header + immutable lifecycle audit | **Indefinitely** |

**90-day operational evidence** (where available): location samples; delivery attempts/results; device state snapshots; battery/connectivity samples; escalation events; communication state.

**Indefinite lifecycle/audit:** incident identity; family/child references; trigger timestamp; acknowledgement; escalation; resolution/cancellation; actor identity; Break-glass audit; core lifecycle events.

**No audio or video evidence.**

---

## Previously closed RD defaults (unchanged)

| ID | Default |
|---|---|
| RD-01 | Active-SOS child critical-only UI |
| RD-02 core | Parent explicit override (roles/allowlist now closed above) |
| RD-03 core | 90d samples / indefinite audit (split now closed above) |
| RD-04 | Verification UNVERIFIED→PENDING→VERIFIED→REVOKED |
| RD-05 | Max 5 backups; priority 1…5 |

---

## Exception rule (only thaw path)

The only exception to this freeze is a **demonstrated platform constraint** that makes a frozen requirement technically impossible. Such a conflict must be reported explicitly (e.g. `QUESTIONS.md` / platform constraint note) and must **NOT** be silently redesigned.
