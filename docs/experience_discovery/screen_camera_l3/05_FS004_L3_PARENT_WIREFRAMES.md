# 05 — FS-004 L3 Parent Wireframes

**Status:** UX/behavior spec — **not** Flutter  
**RTL/LTR:** Mirrored · SOS ungated  
**Master:** [12_FS004_L3_MASTER_CONTRACT.md](12_FS004_L3_MASTER_CONTRACT.md)

---

## W-P01 — SC-P-HUB

```
┌─────────────────────────────────────────┐
│ [←] Screen & Camera           [SOS]     │
├─────────────────────────────────────────┤
│ HONESTY: enforced|degraded|unsupported… │
│ Ack v… · [Mode tightening] [Queued]     │
├─────────────────────────────────────────┤
│ Prevent · Monitor · Protect  (summary)  │
│ Pending exceptions (n)                  │
├─────────────────────────────────────────┤
│ Family baseline              [Open]     │
│ Children · override · device mix        │
├─────────────────────────────────────────┤
│ [Observations] [Audit] [Devices]        │
│ Note: No microphone controls here       │
└─────────────────────────────────────────┘
```

---

## W-P02 — SC-P-FAMILY Baseline

```
┌─────────────────────────────────────────┐
│ Family baseline                         │
│ [Camera restrict default]  on/off       │
│ [Capture prevention]       on/off       │
│ [Screenshot monitoring]    on/off       │
│ [Surface protection]       on/off       │
│ Copy: child override can specialize     │
│ [Save] Primary/Full only                │
└─────────────────────────────────────────┘
```

---

## W-P03 — SC-P-CHILD Effective

```
┌─────────────────────────────────────────┐
│ {Child} · Effective: OVERRIDE|BASELINE  │
│ [Camera] [Prevention] [Monitoring]      │
│ [Protect] [Exceptions] [Devices]        │
│ Deep links: [App Control·Camera pkg]    │
│             [Screen Time] [Modes] [WF]  │
└─────────────────────────────────────────┘
```

---

## W-P04 — SC-P-CAMERA

```
┌─────────────────────────────────────────┐
│ Device camera restriction               │
│ Intent: ON                              │
│ Plane: enforced|unsupported|…           │
│                                         │
│ ⚠ This is NOT “Block Camera app”.       │
│   Package control lives in App Control. │
│   [Open App Control — Camera package]   │
│                                         │
│ Protected Family OS uses:               │
│  · QR/enrollment (explicit exception)   │
│  · Approved Studio / call when required │
│ [Manage exceptions]                     │
│ Mic: not part of this system            │
└─────────────────────────────────────────┘
```

---

## W-P05 — SC-P-PREVENT

```
┌─────────────────────────────────────────┐
│ Capture prevention                      │
│ Intent ON · Capability: degraded        │
│ “Prevents capture where the platform    │
│  can. Not a universal third-party       │
│  screenshot block.”                     │
│ Residual risk disclosed when degraded   │
└─────────────────────────────────────────┘
```

---

## W-P06 — SC-P-MONITOR

```
┌─────────────────────────────────────────┐
│ Screenshot monitoring (FS-004)          │
│ [ ] Active                              │
│ Scope / apps: [Select…]  (T-SC-05)      │
│ Preview — what child sees:              │
│ ┌─────────────────────────────────────┐ │
│ │ Family screenshot monitoring is on  │ │
│ └─────────────────────────────────────┘ │
│ Observations: only when device can      │
│ No silent surveillance · No full feed   │
│ Smart Alerts may notify — policy here   │
└─────────────────────────────────────────┘
```

---

## W-P07 — SC-P-PROTECT

```
┌─────────────────────────────────────────┐
│ Protect Family OS sensitive surfaces    │
│ Intent ON · honesty per device          │
│ Does not claim third-party app lock     │
└─────────────────────────────────────────┘
```

---

## W-P08 — SC-P-EXCEPT / D

```
┌─────────────────────────────────────────┐
│ Exception: QR camera while restricted   │
│ Underlying restrict policy: UNCHANGED   │
│ [Approve] [Deny]  Partner+ allowed      │
│ Duration TBD (T-SC-11 placeholder)      │
└─────────────────────────────────────────┘
```

---

## W-P09 — SC-P-OBS

```
┌─────────────────────────────────────────┐
│ Observations                            │
│ (empty) Monitoring off or unsupported   │
│ — or —                                  │
│ · observed capture · app · time         │
│ No planted demo events as live truth    │
└─────────────────────────────────────────┘
```

---

## W-P10 — SC-P-DEVICE / AUDIT / SOD

Device: per-device pillar honesty + ack.  
Audit: policy · monitor · exceptions · plane · real observations.  
SOD: five-way separation labels + CTAs to owners only.

---

## Sheets

| Sheet | Copy |
|---|---|
| Offline queued | Saved here — not confirmed on child |
| Unsupported | Cannot claim this control on this device |
| Package vs OS | Confirm understanding before save |
