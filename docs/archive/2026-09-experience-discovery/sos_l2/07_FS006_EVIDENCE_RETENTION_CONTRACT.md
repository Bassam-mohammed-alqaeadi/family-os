# 07 — FS-006 Evidence Retention Contract (L2 Wrapper) — FROZEN

**Status:** **FROZEN** — imports OD-10 · OD-11 · RD-03 / Q-SOS-RD-03A · OD-16  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Evidence composition (conceptual)

May include: location honesty samples · device/battery/connectivity snapshots · delivery attempts/results · escalation events · communication state · lifecycle actors/times.

**Must not include:** audio · video.

---

## 2. Retention (exact frozen numbers — do not invent new)

| Layer | Retention |
|---|---|
| Operational samples | **90 days** |
| Core incident header + immutable lifecycle audit (incl. break-glass audit) | **Indefinite** |
| Audio / video | **Forbidden** |

Resolve/cancel must **not** erase the indefinite audit layer.

---

## 3. Location attachment

- Location failure **must not** prevent SOS activation (OD-16).  
- Honesty classes: READY / ACQUIRING / STALE / UNAVAILABLE.  
- **FS-001** owns location facts/history/geofence truth; SOS **consumes/attaches** evidence (T-SOS-05 for pipeline).

---

## 4. Evidence pack

Product requires evidence packaging capability; export/job implementation = **T-SOS-09**. Stage-1 fixture labels ≠ pack.
