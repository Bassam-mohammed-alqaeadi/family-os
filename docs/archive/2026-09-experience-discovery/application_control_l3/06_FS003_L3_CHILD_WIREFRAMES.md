# 06 — FS-003 L3 Child Wireframes

**Status:** UX/behavior specification — **not** Flutter code  
**Authority:** APP-OD-17 · APP-SF-04 · APP-SF-08  
**Master:** [11_FS003_L3_MASTER_CONTRACT.md](11_FS003_L3_MASTER_CONTRACT.md)

---

## Hard child rules

- No admin / lists / policy / inventory management  
- Deny/pending + disclosure + Exception Request only  
- **SOS / Required Family Chat / Quran remain reachable and cannot be denied by App Control**  
- Source-of-deny must be honest  
- Exception Request ≠ ST minutes request (separate CTAs / copy)  
- No full surveillance UI  

---

## W-C01 — AC-C-DENY Interstitial

```
┌─────────────────────────────────────────┐
│                                         │
│         This app isn't available        │
│                                         │
│ Reason: {source-of-deny plain language} │
│  · Family blocked this app              │
│  · Waiting for parent approval (new)    │
│  · Temporary lock                       │
│  · And/or Web Filter / Time / Mode …    │
│                                         │
│ Family protection is active             │
│ (non-interactive disclosure)            │
│                                         │
│ [Ask for temporary access]  ← if allowed│
│ [Request more time] → Screen Time only  │
│   when sod includes time exhaustion     │
│                                         │
│ [Family Chat]  [Quran]  [SOS]            │
│  (always reachable when required)       │
└─────────────────────────────────────────┘
```

| Condition | Exception CTA |
|---|---|
| Permanent Block / pending unknown / Lock Now | Show Exception Request if enabled |
| Protected surface | Never shown as deny for SOS/Chat/Quran |
| Only WF deny (app allowed) | Prefer WF unlock path — not App Exception |
| Only ST cap | Prefer ST minutes request — not App Exception |
| Both AC + WF | Show sources; CTAs only for systems that can relieve |

---

## W-C02 — AC-C-REQ Exception Request

```
┌─────────────────────────────────────────┐
│ [←]  Ask for temporary access           │
├─────────────────────────────────────────┤
│ App: {label}                            │
│ This asks for a short exception.        │
│ It does not remove a permanent block.   │
│ It is not extra Minutes.                │
│                                         │
│ Optional note: [____________]           │
│ [Send request]                          │
│                                         │
│ Offline: “Will send when online”        │
└─────────────────────────────────────────┘
```

Success → back to deny with status `request pending`.  
Forbidden: duration picker for child (parent decides; T-APP-06).

---

## W-C03 — Disclosure strip (AC-C-DISC)

May be embedded in W-C01:

`Family app protection is active` — non-interactive; no settings affordance.

---

## W-C04 — Exception active (optional transient)

If child opens app during active Exception: normal app use subject to ST/Modes/WF; no admin chrome.  
On expiry: return to W-C01 with reason exception ended / block resumed.

---

## W-C05 — Forbidden child patterns

| Pattern | Status |
|---|---|
| Settings hub for App Control | Forbidden |
| List of all blocked apps as admin | Forbidden |
| Approve own install | Forbidden |
| Toggle Unlimited | Forbidden |
| “Unlock with wallet” for Permanent Block | Forbidden |
| Fake “parent approved on cloud” without local state | Forbidden |
