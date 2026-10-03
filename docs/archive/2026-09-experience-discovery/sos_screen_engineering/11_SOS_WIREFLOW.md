# 11 — SOS Wireflow

Textual wireflows. No implementation.

---

## Child — trigger to recovery

```
Shell FAB / CHD-021
  → CHD-005 IDLE
  → HOLDING (countdown)
  → early release? → IDLE
  → FIRING (local create)
  → CHD-006 ACTIVE (Panic Quiet critical-only)
  → [Contact] → CHD-007 / call fallback
  → [Cancel] → SosCancelConfirmation
       → confirm → FALSE_ALARM event → parents notified → CHD-004
       → dismiss → stay ACTIVE
  → parent remote RESOLVE → empty/recovery
```

---

## Parent Primary / Full — respond

```
Critical notification / shell shortcut
  → FAT-018 ACTIVE
  → ACKNOWLEDGE → ACKNOWLEDGED
  → Contact child / FAT-014 map
  → ESCALATE (VERIFIED backups) → ESCALATING
  → RESOLVE → RESOLVED (retained) → leave
  → optional Break-glass sheet → OVERRIDE_ACTIVE → expiry AUTO_REVOKE
  → Setup → FAT-028
```

---

## Observer

```
Notification → FAT-018
  → VIEW essential + delivery/location honesty
  → CONTACT child only
  → no ACK / ESCALATE / RESOLVE / SETUP / BREAK-GLASS
```

---

## Partner

```
Notification → FAT-018
  → ACK → RESPOND (contact/map) → ESCALATE → RESOLVE
  → no FAT-028 edit · no Break-glass
```

---

## Full — configure

```
Settings / FAT-018 setup
  → FAT-028
  → guardians locked
  → backups ≤5 · priority 1..5 · verify lifecycle
  → Panic Quiet toggle
  → back → FAT-018 when incident active
```

---

## Break-glass

```
FAT-018 (Primary|Full)
  → Break-glass
  → REASON/CONTEXT + capability (allowlist) + duration
  → CONFIRM
  → OVERRIDE_ACTIVE indicator
  → EXPIRY → AUTO_REVOKE → AUDIT snackbar/timeline
```

---

## Failure / recovery

```
ACTIVE + DELIVERY_FAILED(push)
  → show PARTIAL/FAILED
  → fallback SMS/CALL if AVAILABLE
  → retry → PENDING until confirm
  → offline child: local ACTIVE + sync pending → reconnect reconcile
```
