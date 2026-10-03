# 03 — FS-006 Role Access Contract (L2 Wrapper) — FROZEN

**Status:** **FROZEN** — imports SOS Final OD-01…04 · role policy  
**Vocabulary:** Primary Parent · Co-Parent Full · Co-Parent Partner · Co-Parent Observer · Child  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Action × role (permissions unchanged from Final)

| Action | Primary | Co-Parent Full | Co-Parent Partner | Co-Parent Observer | Child |
|---|---|---|---|---|---|
| Trigger SOS | — | — | — | — | ✓ |
| Receive critical | ✓ | ✓ | ✓ | ✓ | — |
| View essential incident | ✓ | ✓ | ✓ | ✓ | Own |
| Contact child / parent | ✓ | ✓ | ✓ | ✓ (contact child) | Contact parents |
| Acknowledge | ✓ | ✓ | ✓ | **✗** | — |
| Respond (call/map tools) | ✓ | ✓ | ✓ | Contact only | — |
| Escalate (trusted) | ✓ | ✓ | ✓ | **✗** | — |
| Resolve | ✓ | ✓ | ✓ | **✗** | Cancel only (false-alarm path) |
| Configure (nuclear) | ✓ | ✓ | **✗** | **✗** | **✗** |
| Panic Quiet config | ✓ | ✓ | **✗** | **✗** | Effect on active UI only |
| Break-glass | ✓ | ✓ | **✗** | **✗** | **✗** |

**Nuclear configuration** = settings, trusted contacts (verify/priority), escalation delays/enablement, Panic Quiet config — Primary + Co-Parent Full only.

**Break-glass AuthZ** = Primary + Co-Parent Full · RBAC only · never device-ownership inference.

---

## 2. Child cancel

Only via frozen confirm → false-alarm → parents informed → auditable path (OD-06). Not break-glass. Not silent dismiss.

---

## 3. Stage-1 note (non-authority)

If Stage-1 `SosRoleActions.canAcknowledge` allows Observer, that is **implementation debt** vs Final Observer **No** ack — target law is this matrix.
