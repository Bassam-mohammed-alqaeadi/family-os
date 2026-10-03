# 06 — FS-006 Escalation and Delivery Contract (L2 Wrapper) — FROZEN

**Status:** **FROZEN** — imports OD-07…09 · OD-15 · OD-20 · RD-04 · RD-05  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Trusted ladder (frozen)

| Rule | Law |
|---|---|
| Rung-1 | Immutable family parents (Primary / Co-Parent as configured) |
| Backups | Max **5**; priority **1…5** |
| Escalate only if | Contact **VERIFIED** (RD-04) |
| Phone change | Re-verify |
| National numbers | **Excluded** |
| Auto emergency-service dial | **Excluded** |
| Auto-call / escalate | Family/trusted first only |

Verification: UNVERIFIED → PENDING → VERIFIED → REVOKED · audited · transport abstract (**T-SOS-14**).

Escalation **timing** semantics remain as frozen Final; exact timer implementation = **T-SOS-14** — do not invent new durations in L2.

---

## 2. Delivery honesty (mandatory)

| Concept | Meaning |
|---|---|
| Incident | Lifecycle state exists |
| Delivery attempt | Channel try started |
| Delivery result | Proven outcome |
| Acknowledgement | Human ACK on incident (≠ delivery) |

### Allowed UX result classes

| Class | When |
|---|---|
| `pending` | Attempt not finished |
| `attempted` / sent-claim | Only when attempt **proven** started |
| `delivered` | Only when delivery **proven** |
| `failed` | Proven failure |
| `unavailable` | Channel cannot run |
| `degraded` | Partial capability |
| `offline_queued` | Queued for retry |

**Forbidden:** showing “sent” / “delivered” merely because a local incident was created (mock fire always-true is non-authority).

Channels (product classes): push · in-app · SMS fallback · call fallback — mechanisms **T-SOS-01…04**.
