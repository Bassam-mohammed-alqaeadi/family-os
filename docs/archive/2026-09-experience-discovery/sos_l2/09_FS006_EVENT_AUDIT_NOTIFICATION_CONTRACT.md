# 09 — FS-006 Event / Audit / Notification Contract (L2 Wrapper) — FROZEN

**Status:** **FROZEN** — imports OD-09 · OD-18 · OD-20 · OD-21 · RD-03 · SOS-SF-12/13  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Audit (append-only)

Must emit immutable audit for at least:

- Incident create / hold / fire / active  
- Acknowledge / escalate / resolve / child cancel (false-alarm)  
- Delivery attempts/results (as facts)  
- Break-glass START→…→AUDIT  
- Contact verify transitions  
- Readiness material changes (as appropriate)

No update/delete of audit rows. RESOLVED does not wipe audit.

---

## 2. Notifications

| Rule | Law |
|---|---|
| Critical delivery classes | Push / in-app; SMS/call fallbacks |
| Quiet hours | Must not mute SOS |
| Success claim | Only after proven delivery result |
| Readiness | Visible honestly to appropriate parents (OD-21) |
| Transport | **T-SOS-02 · T-SOS-04** — not claimed until proven |

---

## 3. AI

Suggest only. Authorized human approval required for any SOS policy/config suggestion execution. No autonomous emergency policy action.

---

## 4. Events vs UI

Typed FamilyEvent catalog may be implementation (**T-SOS** / engineering). Product requires auditable facts regardless of bus technology.
