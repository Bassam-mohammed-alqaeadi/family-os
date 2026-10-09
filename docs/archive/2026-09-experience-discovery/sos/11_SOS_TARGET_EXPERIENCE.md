# 11 — SOS Target Experience

**PROPOSED DESIGN** grounded in P-4, P-5, UF-08, S-SEC-026…030.  
Not implemented. Owner decisions in doc 12 can alter branches.

---

## Happy path

```
CHILD TRIGGERS SOS (3s hold on CHD-005 or shell FAB)
  → local activation (ACTIVE UI immediately; haptic)
  → SOS canonical event (request_id; local persist + outbox)
  → immediate acknowledgement to child (“sent / sending…”)
  → location acquisition (FG then BG stream)
  → family notification (critical push father + mother all levels)
  → delivery tracking (receipts update CHD-006 + FAT-018)
  → parent action (call / open live map / ACK)
  → escalation (timer if unresponsive OR manual escalate CTA)
  → evidence updates (location trail; audio if approved)
  → resolution (parent resolve and/or child confirm-safe per OWNER)
  → audit (immutable lifecycle)
  → recovery (stop stream, clear siren, optional post-mortem)
```

---

## Role-colored target journeys

### Child
FAB → CHD-005 hold → CHD-006 live status from receipts → call parent → confirm safe → day board.  
Always available under lock / expiry / offline (local ACTIVE).

### Father
Critical alert → FAT-018 → ACK → call child → live map → escalate if needed → resolve → audit.

### Mother (all levels receive)
Same piercing alert. Action rights per OWNER (today Observer can act — may tighten).

---

## Degraded path summary

See [07_SOS_FAILURE_RECOVERY.md](07_SOS_FAILURE_RECOVERY.md). Headline rule: **degraded ACTIVE > false “all clear”**.

---

## Experience principles

1. **Reachability over polish** — SOS never gated.  
2. **Honesty over reassurance** — no fake live map or fake “delivered”.  
3. **Ladder over single parent** — P-5.  
4. **Receipts over static copy** — replace CHD-006 static “seen” lines.  
5. **ACK before close** (if OWNER confirms schema intent).  
6. **Not a substitute for emergency services** — explicit honesty.  

---

## Screen mapping to target

| Beat | Screen |
|---|---|
| Trigger | CHD-005 (+ FAB) |
| In progress | CHD-006 |
| Parent board | FAT-018 |
| Setup | FAT-028 |
| Live map detail | FAT-014 |
| Quiet hours honesty | FAT-058 |
| Expiry still reachable | CHD-021 |

---

## Success criteria (acceptance sketch)

- [ ] Fire with expired plan, quiet hours ON, device lock ON, time expired  
- [ ] Airplane mode: local ACTIVE + queued sync when online  
- [ ] Parent receives OS-level critical alert (or documented platform waiver)  
- [ ] Location updates while ACTIVE or honest unavailable  
- [ ] Ladder fires backups after configured delay when parents unresponsive  
- [ ] Resolve writes audit; alert cannot be silently deleted  
- [ ] No mute-SOS control anywhere  
