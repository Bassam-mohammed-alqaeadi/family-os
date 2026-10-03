# 09 — FS-005 L3 Composition, Exception, and Grace UX

**Authority:** MODE-OD-05 · MODE-OD-07 · MODE-OD-10 · MODE-OD-11 · MODE-SF-07 · MODE-SF-18  
**Master:** [13_FS005_L3_MASTER_CONTRACT.md](13_FS005_L3_MASTER_CONTRACT.md)

---

## 1. Multi-mode composition UX

### Must show

- Active Mode **stack** (ordered list of applicable Modes)  
- **Composition result** (“stricter intersection”)  
- Per-plane tighten summary  
- Per-child effective Mode state  
- Conflict / material-change notification entry  

### Must never show

- Toggle that implies only one Mode may exist  
- Control that loosens Mode A to defeat Mode B’s tighten  
- Vacation widen surviving as target control  

### Explain sheet content

| Block | Copy intent |
|---|---|
| Stack | Names + activation channel |
| Why stricter | Intersection of overlay intents |
| What unchanged | Permanent Blocks · URL lists · geofences · ST wallets |
| Safety | SOS · Chat · Quran still on |

---

## 2. ModeException UX

| Element | Spec |
|---|---|
| Label | Always “Mode exception” / Mode overlay language |
| Separators | Buttons to App Access Exception (FS-003) and Temporary Grant (ST) if user confusion detected |
| Effect | Pierce Mode overlay only |
| End | Expire / revoke by Primary/Full |
| Child | May see resource available due to ModeException — not admin |

### Forbidden ModeException outcomes (UX guards)

Confirm sheet checklist:

- [ ] Not writing App Control package store  
- [ ] Not creating minutes  
- [ ] Not rewriting Web lists  
- [ ] Not clearing Permanent Block  
- [ ] Not mutating FS-004 permanent policy  

---

## 3. Temporary Grant interaction UX

| Surface | Behavior |
|---|---|
| Modes | Chip: “A Temporary Grant is active (Screen Time)” |
| ST grant approve | If Mode active/upcoming — require explicit parent choice path on **ST** surface |
| Modes | Must not host Grant minting |

---

## 4. Grace UX

| Rule | UX |
|---|---|
| Manual activation | **No grace UI** |
| Scheduled / location / seasonal enter | Optional grace disclosure parent+child |
| Duration | Parent-/Mode-defined; Register 2 / 0–5 = **reference only** — do not hard-code new numbers in L3 as law |
| Child | Cannot permanently disable Mode via grace |
| Prototype clear button | **Rejected** |

### Grace state machine (UX)

```
scheduled hit → grace visible → grace ends → Mode active
manual on → Mode active (no grace)
parent deactivate → Mode inactive (grace irrelevant)
```

---

## 5. Priority relative to other systems (UX copy)

When explaining deny:

| Priority hint | Label |
|---|---|
| Above Modes | Instant Lock · Permanent Block · SOS protection |
| Mode layer | Active Mode stack (stricter) |
| After Mode allow | Screen Time minutes/cap/grant |

Do not invent a separate numeric “Mode priority” editor unless L2 adds one — composition is **stricter intersection**, not a free-form priority ladder UI.
