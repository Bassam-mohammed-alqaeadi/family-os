# 02 — FS-006 SOS Policy Contract (L2 Wrapper) — FROZEN

**Status:** **FROZEN** — imports [`../sos_final/03_SOS_POLICY_CONTRACT.md`](../sos_final/03_SOS_POLICY_CONTRACT.md)  
**Authority:** SOS Final · SOS-SF-* · SOS-OD-01…21  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Nature of SOS

SOS is a **safety incident path**, not ordinary parental-control policy.

| Rule | Law |
|---|---|
| Always reachable | OD-14 / SOS-OD-14 |
| Outside ST minutes/grants/budget | Cross-system |
| Outside Modes gating | FS-005 MODE-OD-14 |
| Outside ordinary FS-002/003/004 deny of SOS | Sibling L2 protected surfaces |
| Local create first | OD-17 |
| Location fail does not cancel activation | OD-16 |

---

## 2. Activation

| Rule | Spec |
|---|---|
| Primary child trigger | Hold gesture (product: ~3s hold — Final) |
| Release early | No incident |
| Offline | Create locally first |
| Break-glass | Parent response override — **not** child create path |

---

## 3. Permanent exemptions

SOS must remain fireable/receivable regardless of: subscription · quiet hours · screen-time expiry · entertainment lock · device/instant lock · active Modes · Web Filter · App Control package deny of SOS · FS-004 camera/capture restrict.

---

## 4. Explicit exclusions (unchanged)

1. Audio / video evidence  
2. National/local emergency numbers  
3. Auto emergency-service dial  
4. SOS microphone / audio broadcast  

---

## 5. Implementation honesty

Stage-1 `MockSosFireService` always-success ≠ product “delivered”. Policy requires delivery honesty (doc 06).
