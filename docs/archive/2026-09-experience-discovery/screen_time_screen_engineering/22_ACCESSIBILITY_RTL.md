# 22 — Accessibility & RTL

**No `tokens.dart` changes.** Use existing FamilyColors / radii / type.

---

## Arabic-first RTL

- All ST screens respect `Directionality` RTL for AR.  
- Action rows mirror (Requests / Lock / Add Time).  
- Progress bars fill correctly in RTL.  
- Sheets grab handles and confirm buttons follow platform RTL.  
- Numbers: Minutes remain locale-aware numerals per app i18n rules.

---

## Touch & semantics

- Interactive ≥48×48dp.  
- Every button/toggle/row: `Semantics` / ARB labels.  
- `RoleActionGuard` exposes “unavailable for your role” as text, not only disabled color.  
- Status chips: icon + text (not color-only).  

---

## Safety hierarchy

- SOS / Chat / Quran CTAs never buried under entertainment chrome.  
- On WARNING/EXPIRED, SOS is explicit on-screen in addition to shell FAB.  
- Do not reuse SOS coral for entertainment lock (preserve emergency language).  

---

## Calm child copy

- No shame / punishment tone at expiry.  
- Denial reasons plain language.  
- Avoid implementation jargon for child; parent WhyUnavailable may use plain precedence (“Locked by parent”, “Bedtime schedule”, “Daily time finished”).  

---

## Screen reader order (child WARNING)

1. Warning message  
2. Remaining Minutes  
3. Request More  
4. Quran  
5. Chat  
6. SOS  

---

## Mother role messaging

Observer/Partner/Full differences announced via banners + semantics, not invisible missing controls alone.
