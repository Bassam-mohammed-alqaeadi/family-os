# 06 — FS-004 L3 Child Wireframes

**Authority:** SC-OD-10 · SC-OD-07 · SC-SF-04/15  
**Master:** [12_FS004_L3_MASTER_CONTRACT.md](12_FS004_L3_MASTER_CONTRACT.md)

---

## Hard child rules

- No configuration / admin  
- Transparency **mandatory** when monitoring active  
- No silent surveillance  
- No microphone / SOS audio UI  
- SOS / Required Chat / Quran reachable  
- Clear separation of package vs OS camera vs prevention vs monitoring  

---

## W-C01 — SC-C-TRANS Monitoring transparency

```
┌─────────────────────────────────────────┐
│ Family protection notice                │
│                                         │
│ Screenshot / capture monitoring is ON   │
│ for configured apps.                    │
│ Your family can be notified when a      │
│ capture is observed (when supported).   │
│                                         │
│ This is not a secret.                   │
│ (non-interactive — no settings)         │
│                                         │
│ [Family Chat] [Quran] [SOS]              │
└─────────────────────────────────────────┘
```

Shown persistently enough when `mon_on` (card/banner on relevant child hubs — exact chrome L3 composition).  
Hidden/updated when monitoring off (after ack).

---

## W-C02 — SC-C-STATUS

```
┌─────────────────────────────────────────┐
│ Camera & capture status                 │
│ Device camera: Restricted               │
│ Capture prevention: On (limited)        │
│ Monitoring: On — see notice             │
│                                         │
│ If Camera app blocked separately:       │
│ “Camera app blocked in App Control”     │
│ (different from device camera)          │
│                                         │
│ [Ask for temporary exception] if allowed│
└─────────────────────────────────────────┘
```

---

## W-C03 — SC-C-DENY / restriction interstitial

```
┌─────────────────────────────────────────┐
│ Camera isn't available right now        │
│ Reason: Device camera restricted        │
│      or Capture prevention              │
│      or Camera app blocked (App Control)│
│      or Mode / other (named)            │
│                                         │
│ Monitoring notice (if active)           │
│ [Ask exception] [SOS] [Chat] [Quran]     │
└─────────────────────────────────────────┘
```

CTAs only for systems that can relieve the named source.

---

## W-C04 — SC-C-REQ Exception request

```
┌─────────────────────────────────────────┐
│ Request temporary Family OS camera use  │
│ e.g. enrollment / approved workflow     │
│ Does not turn off family camera policy  │
│ [Send]                                  │
│ Offline: will send when online          │
└─────────────────────────────────────────┘
```

---

## Forbidden child patterns

| Pattern | Status |
|---|---|
| Settings for monitoring scope | Forbidden |
| Mic / ambient record UI | Forbidden |
| “Unlock with wallet” for camera OS restrict | Forbidden |
| Fake “parent watching every screen” | Forbidden |
| Admin of plane diagnostics | Forbidden |
