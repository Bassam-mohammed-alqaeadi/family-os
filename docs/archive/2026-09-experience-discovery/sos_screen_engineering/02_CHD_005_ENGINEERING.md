# 02 — SCR-CHD-005 Engineering (Child SOS Trigger)

**Screen:** SCR-CHD-005 · زر الاستغاثة  
**Decision:** MODIFY  
**Widget:** `ChildSosButtonScreen` · Route: `/scr-chd-005`  
**Authority:** Frozen SOS contract OD-06/14, RD-01 (Panic Quiet does not remove trigger)

---

## 1. Purpose

Let the child start an SOS **incident** with accidental-press protection (3-second hold), even when offline, time-expired, locked, or unsubscribed.

## 2. Audience

| Role | UI |
|---|---|
| Child | Full trigger body |
| Father / Mother (any level) | Parent lean empty state — no hold |

## 3. Entry points

- Family Shell SOS FAB (hidden when already on CHD-005/006)  
- SCR-CHD-021 time-expiry SOS CTA  
- Deep link `/scr-chd-005`  
- Resume navigation when user chooses “open SOS button” from CHD-006 empty  

**Not an entry:** Break-glass (parent-only on FAT-018).

## 4. Exit / navigation

| Condition | Destination |
|---|---|
| Hold completed + local incident created | `/scr-chd-006?alertId=&childId=` |
| Parent lean | Stay / back |
| Persist hard-fail after retries | Stay with error + retry (still attempt local create) |

## 5. Information hierarchy

1. **Primary:** Hold control (large coral circle)  
2. **Secondary:** Hold instruction + countdown status  
3. **Critical status:** Idle / holding / cancelled-early / firing / sync-will-follow  
4. **Contextual:** Always-on / never-gated honesty banner (OD-14)  
5. **Actions:** Hold only (no mute, no audio, no setup)

## 6. Controls

| Control | Label (intent) | Roles | Condition | Enabled | Confirm | Event | Resulting state |
|---|---|---|---|---|---|---|---|
| Hold button | Hold SOS / استغاثة | Child | Not firing, not already completed | Yes while idle/holding | No (hold duration is protection) | pointer down→hold; complete→`SosIncidentCreated` | HOLDING→FIRING→nav CHD-006 |
| Early release | (release) | Child | Holding | N/A | No | none (no incident) | IDLE + cancelled-early message |
| Retry persist | Retry | Child | Persist error | Yes | No | retry create | FIRING / ACTIVE local |

## 7. State inventory (this screen)

| State | UI |
|---|---|
| initial / idle | Instruction + hold button + always-on banner |
| holding | Countdown 3·2·1; pulse (respect reduce-motion) |
| early_release | Status: released early; button idle again |
| firing | “Sending / creating…”; button disabled |
| loading (persist) | Spinner overlay optional brief |
| offline | Still allow hold; status “SOS starts on device — will sync” |
| permission_missing (location/notif) | Do **not** block hold; optional soft honesty line |
| retrying | Retry control visible |
| recovery | After successful persist → leave screen |
| parent_lean | Empty lean — no hold |
| low_battery | Optional honesty chip; never disable hold |
| network_degraded | Same as offline honesty |

**Not on this screen:** acknowledged, escalating, resolved, delivery chips (those are CHD-006/FAT-018).

## 8. Hold interaction machine

```
IDLE --pointerDown--> HOLDING (t=3s countdown)
HOLDING --pointerUp/Cancel before 3s--> IDLE (early_release message)
HOLDING --timer 3s--> FIRING (local durable create)
FIRING --persist ok--> navigate CHD-006
FIRING --persist fail--> ERROR + retry (remain on CHD-005)
```

- Accidental protection = require full 3s continuous hold.  
- Haptic: light on down; success on complete (if platform allows).  
- Visual: coral gradient + pulse while holding; stop pulse on release/complete.  
- Reduce-motion: no pulse scale; countdown text still updates.

## 9. Role-specific UI

- **Child:** Full body.  
- **All parents:** Lean title/message only.  
- **Observer/Partner/Full:** Same lean (not a config surface).

## 10. Empty / error / recovery

- Empty N/A (always show hold for child).  
- Error: persist failure — honest, retry; never claim parents notified.  
- Recovery: success → CHD-006.

## 11. IA placement

- Full-screen child UI; hero = hold button; banner inline; no sheets on happy path.

## 12. Design system

- `FamilyUiMode.child`; coral gradient / `shCoral`; Semantics on hold (≥48dp, actually ~190dp circle).  
- ARB strings only.
