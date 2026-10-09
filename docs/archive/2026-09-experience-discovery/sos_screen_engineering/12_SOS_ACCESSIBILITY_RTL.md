# 12 — SOS Accessibility & RTL

**Authority:** Constitution Rule 12/16 · Arabic-first product

---

## 1. RTL / Arabic-first

- Default layout Directionality RTL for `ar`.  
- ARB keys for all user strings (no hardcoded UI literals).  
- Mirrored action bars and sheets; countdown numerals acceptable as Western digits if product-standard, but labels Arabic.

## 2. Typography & emergency readability

- Use existing design typography tokens; weight 700/800 for SOS headlines.  
- High contrast on coral: surface-on-coral text.  
- Do not rely on small caption-only status.

## 3. Touch targets

- All interactive SOS controls ≥ **48×48 dp**.  
- Hold button remains large (~190dp Stage-1).  
- Break-glass confirm resistant to accidental taps (two-step: reason + confirm).

## 4. Color is not the only signal

Every status uses **text and/or icon + color**:

- Location / delivery / lifecycle chips include text class names.  
- Break-glass active: banner text + icon + optional countdown.

## 5. Screen reader

| Control | Semantics requirement |
|---|---|
| Hold | button + hold instruction label |
| Cancel / Confirm safe | button labels |
| Acknowledge / Escalate / Resolve | distinct labels |
| Break-glass | states purpose + capability |
| Map | label location honesty |
| Delivery rows | recipient + channel + class |

Live regions: CHD-006 / FAT-018 headlines while ACTIVE.

## 6. Haptic / audio cues

- Haptic on hold start/complete if platform allows.  
- **No** custom SOS audio recording/broadcast.  
- System critical notification sound is OS-owned (not in-app mic).

## 7. Reduce motion

- Disable pulse animations when `disableAnimations`; keep countdown text.
