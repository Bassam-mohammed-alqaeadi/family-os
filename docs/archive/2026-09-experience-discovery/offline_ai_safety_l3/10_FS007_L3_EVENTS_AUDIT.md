# 10 — FS-007 Events, Audit, Notifications (L3)

**Authority:** AI-SF-16 · AI-OD-02/03/09  
**Master:** [13_FS007_L3_MASTER_CONTRACT.md](13_FS007_L3_MASTER_CONTRACT.md)

---

## Event kinds (catalog intent)

| Kind | When |
|---|---|
| `safety.classify.completed` | Signal emitted |
| `safety.classify.failed` | Error path |
| `safety.notify.created` | Notify |
| `safety.ticket.opened` | Gate pass |
| `safety.ticket.resolved` | Resolve |
| `safety.ticket.dismissed_fp` | FP |
| `safety.preview.purged` | Retention |
| `safety.model.apply` / `rollback` / `integrity_failed` | Model lifecycle |
| `safety.suggest.created` | Hand-off suggestion to WF/AC/Mode |

Payload: excerpt/metadata — **not** full raw archive (schema spirit).

---

## Audit

Append-only. Who viewed ticket, who resolved, who applied model. No update/delete APIs.

---

## Notifications

Parent safety notifications only (AI-OD-04 recipients).  
Not SOS critical channel.  
Amber/descriptive tone preferred (Smart Alerts spirit) — behavioral description, not child-shaming.
