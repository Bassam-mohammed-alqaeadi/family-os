# 12 — CHD-020 Time Request Engineering

**Screen:** SCR-CHD-020  
**Disposition:** WIRING FIX → same concept as FAT-033  

---

## Purpose
Child requests extra entertainment Minutes; one pending max; sees decision outcomes.

## Target loop (spec only — do not implement this phase)

```
CHD-020 → TimeRequestService.createRequest
  → FAT-033 decide → Temporary Grant → child feedback → remaining update
```

## Flow UI
`draft (REQUESTING)` → submit → `REQUEST_PENDING` → `APPROVED` | `DENIED` | `EXPIRED`

## Show
- Requested Minutes presets/custom  
- Optional reason / trade suggestion (prototype keys as labels, not currency)  
- Pending lockout (duplicate prevention)  
- Timeout hint (12h or end-of-day, family TZ)  
- Denial reason (child-visible)  
- On approve: grant amount + updated remaining (Daily vs Grant chips)  

## States / errors
formAvailable false · pending exists · offline create queued · expired  

## Never
- Separate parallel mock inbox  
- Points language  
- Hide SOS while pending  
