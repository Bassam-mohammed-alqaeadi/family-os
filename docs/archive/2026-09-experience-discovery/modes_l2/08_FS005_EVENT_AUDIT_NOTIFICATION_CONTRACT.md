# 08 — FS-005 Event / Audit / Notification Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · MODE-SF-15 · MODE-OD-05 · MODE-OD-10 · MODE-OD-13  
**Technical open:** T-MODE-06 · T-MODE-09 · T-MODE-10  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Audit (append-only)

Mode domain **must** emit append-only audit facts for, at minimum:

| Class | Examples (conceptual — enum = T-MODE-10) |
|---|---|
| Definition mutations | create / edit / delete Mode; scope change; schedule change |
| Activation | activate / deactivate (manual or evaluated) |
| Composition | multi-mode stricter-result material change (when notifiable) |
| Exceptions | ModeException grant / expire / revoke |
| Sync honesty | ack / stale transitions (as facts) |

**No update/delete** of audit rows (Constitution Rule 10 spirit).

---

## 2. Notifications (product requirements)

| Audience | Required classes |
|---|---|
| Primary / Full | Mode activations relevant to their children; conflict/stricter-result notices; schedule transitions as product requires |
| Partner | Relevant Mode notifications; not policy-editor alerts by default |
| Observer | View-class notifications only |
| Child | Active Mode + restriction/grace disclosure — not admin |

Transports (FCM vs local) = **not claimed** until proven (**T-MODE-06/09**).

---

## 3. AI

AI may **suggest** Mode configurations or activations. Execution requires **authorized human approval** (Primary/Full per AuthZ). No autonomous Mode policy mutation.

---

## 4. SOS notifications

Mode quiet hours / Mode state must **never** mute or block SOS critical delivery (SOS Final).

---

## 5. Stage-1 non-authority

Activation bus `notifyListeners` and soft toasts ≠ audit log ≠ push pipeline.
