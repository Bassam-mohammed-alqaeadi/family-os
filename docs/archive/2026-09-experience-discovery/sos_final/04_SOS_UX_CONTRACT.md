# 04 — SOS UX Contract

**Status:** FROZEN UX CONTRACT  
**SOS PRODUCT CONTRACT STATUS: FROZEN**  
**Principle:** Never make a capability appear real when infrastructure is unavailable. Classify: AVAILABLE / DEGRADED / UNAVAILABLE / NOT CONFIGURED.

---

## 1. Global UX laws

1. Coral / danger visual language reserved for ACTIVE incidents (existing FAT-018/CHD-006).  
2. Honesty banners for P-4 exemptions remain.  
3. No mute-SOS control anywhere.  
4. No audio UI.  
5. No emergency-service number picker or “call 911/997” as product SOS escalate.  
6. Delivery badges ≠ incident lifecycle badges.  
7. Role-appropriate controls: hide/disable forbidden actions (Observer).  
8. Touch targets ≥ 48dp; Semantics on all actions (Rule 16).  
9. All strings via ARB (Rule 12).

---

## 2. Information hierarchy

### Parent active incident (FAT-018)

1. Incident headline (child identity via repo — not hardcoded)  
2. Lifecycle chip: ACTIVE / ACKNOWLEDGED / ESCALATING  
3. Delivery summary (separate): who confirmed / pending / failed  
4. Location honesty block: READY|ACQUIRING|STALE|UNAVAILABLE + map if usable  
5. Device strip: battery, connection  
6. Primary actions (role-filtered): Contact child → Acknowledge → Escalate → Resolve  
7. Evidence / timeline expand  
8. Recipients / ladder footer (read-only for Partner/Observer)

### Child in progress (CHD-006)

1. “Help is activating / active”  
2. Location honesty  
3. Delivery honesty (from receipts — never static fake “seen”)  
4. Contact parent  
5. Cancel (explicit confirmation only)

### Child trigger (CHD-005)

1. Hold instruction  
2. Hold control  
3. Status (idle / holding / cancelled / firing)  
4. Always-on / exemption honesty (OD-14)  
5. No entertainment chrome that blocks the hold control

### Setup (FAT-028)

1. Protocol + cannot-disable-receipt banners  
2. Rung-1 parents locked  
3. Trusted backups (max 5, priority 1…5) + verification badges  
4. Channel readiness (push/SMS/call)  
5. Panic Quiet Mode toggle (Full/Primary) — configures active-incident child focus  
6. Break-glass is **not** configured here as a child trigger; parent override lives on response surfaces  
7. **No** national emergency number field

---

## 3. Exact journeys

### J1 — Child triggers SOS

FAB/CHD-005 → hold 3s → local FIRING → durable ACTIVE incident → CHD-006 → outbox sync + channel attempts → parents notified as confirmed.

### J2 — Parent receives SOS

Critical push/in-app → open FAT-018 → see incident + delivery + location honesty → act per role.

### J3 — Mother Observer receives SOS

Same receive → FAT-018 **Observer variant**: essential info + Contact child only. No Ack / Escalate / Resolve / Setup. Soft explanation if they attempt (or controls absent).

### J4 — Mother Partner responds

Receive → view → Acknowledge → Contact child / map → Escalate trusted if needed → Resolve when safe. No FAT-028 edit.

### J5 — Mother Full manages SOS

All Partner flows + FAT-028 configure contacts, delays, Panic Quiet Mode, channel preferences (not mute SOS).

### J6 — Primary Parent responds

Full control including resolve, escalate, configure, break-glass audit review.

### J7 — Child cancels SOS

CHD-006 → Cancel → confirmation sheet (“I am safe”) → emit FALSE_ALARM/cancel event → incident closed with cancel reason → parents notified → audit → child returns to day board.

### J8 — Parent acknowledges

FAT-018 → Acknowledge → state ACKNOWLEDGED → child status updates via receipts → incident remains open until Resolve.

### J9 — Parent escalates

FAT-018 → Escalate → ESCALATING → notify next trusted rung / trigger configured auto paths → never emergency-service dispatch. Show channel results honestly.

### J10 — Parent resolves

FAT-018 → Resolve → RESOLVED → stop live updates → retain record → notify other guardians → audit. No delete.

### J11 — Location unavailable

Trigger still succeeds → location UNAVAILABLE chip → map placeholder honesty → continue delivery.

### J12 — Child offline

Local ACTIVE → queue → CHD-006 shows sync pending → SMS/call fallbacks if configured/supported → sync on reconnect.

### J13 — Parent offline

Incident ACTIVE on child → delivery pending/failed for that parent → other guardians may still receive → on parent reconnect: fetch active incidents + show missed SOS honestly.

### J14 — Notification delivery failure

Mark DELIVERY_FAILED for channel → try SMS/call fallback → incident stays ACTIVE → UI never says Delivered.

### J15 — SMS fallback

If SMS AVAILABLE and configured → send → confirm provider/device result → update delivery history. If NOT CONFIGURED / UNAVAILABLE → show that state; no fake SMS.

### J16 — Call fallback

Auto or manual call to family/trusted if AVAILABLE → log attempt result. Never auto national emergency.

### J17 — Low battery

Show battery in evidence → may degrade location cadence → never block SOS.

### J18 — Reconnection and sync

Outbox drains → reconcile incident + deliveries → upgrade PENDING→DELIVERED/FAILED with truth → refresh both sides.

### J19 — Break-glass flow (parent override) — FROZEN

Primary or Mother Full only (RBAC) on/near ACTIVE incident → START with REASON/CONTEXT → OVERRIDE_ACTIVE for allowlisted capability only → respond (contact/map/escalate/notify) → EXPIRY → AUTO_REVOKE → AUDIT. Partner/Observer/Child cannot invoke. Permanent policy unchanged.

### J20 — Panic Quiet Mode (active SOS) — FROZEN

Primary/Full enables mode in FAT-028 → when incident ACTIVE, CHD-006 shows critical-only hierarchy → entertainment/time/lock UI must not cover SOS → parents still receive full alerts → audit toggle.

---

## 4. Feedback patterns

| Event | Success feedback | Failure feedback |
|---|---|---|
| Fire | CHD-006 ACTIVE + local confirmed | Rare local persist fail → error + retry (still attempt) |
| Delivery | Per-recipient DELIVERED | DELIVERY_FAILED + fallback attempt |
| Ack | Chip ACKNOWLEDGED | Role forbidden / network → error, state unchanged |
| Escalate | ESCALATING + channel results | Partial failure listed |
| Resolve | RESOLVED + leave board | Error keeps ACTIVE |
| Cancel | Parents notified + child toast | Confirm dismiss keeps ACTIVE |
| Config save | Saved + readiness refresh | Validation / role forbidden |

---

## 5. Degraded presentation

Use explicit chips, not buried footnotes:

- `Sync pending`  
- `Push failed — trying SMS`  
- `Location unavailable`  
- `Call not available on this device`  
- `SMS not configured`  
- `Parent last seen offline`

Never use green “All good” when any critical channel is FAILED and no fallback succeeded.
