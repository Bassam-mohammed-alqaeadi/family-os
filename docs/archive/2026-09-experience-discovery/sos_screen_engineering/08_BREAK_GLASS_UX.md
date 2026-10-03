# 08 — Break-glass UX

**Authority:** Q-SOS-RD-02A / 02B · OD-13  
**Mount:** FAT-018 bottom sheet (`SosBreakGlassSheet`) — no new Screen ID

---

## 1. Purpose

Let Primary Parent or Mother Full temporarily bypass an **allowlisted** blocking restriction so they can respond to an ACTIVE SOS—with reason, expiry, auto-revoke, and audit—without changing permanent policy.

## 2. Audience

| Role | Access |
|---|---|
| Primary | ✅ |
| Mother Full | ✅ |
| Partner / Observer / Child | ❌ Hidden |

Authorization: **RBAC only** — never inferred from device ownership.

## 3. Entry

- FAT-018 when an allowlisted capability is blocking response (e.g. cannot open communication / view context)  
- Explicit “Emergency override” control for Primary/Full  
- Not available on empty (no incident)

## 4. UI must show

1. Why override is needed (context copy)  
2. Affected capability (from allowlist enum)  
3. Duration / expiry  
4. Explicit confirmation CTA  
5. Active override indicator on FAT-018 while OVERRIDE_ACTIVE  
6. Automatic expiry countdown  
7. Audit confirmation (snackbar or inline “logged”)

## 5. Flow

```
START (tap Break-glass)
  → REASON/CONTEXT (required text or reason chips)
  → select capability (allowlist only)
  → set/confirm duration
  → CONFIRM
  → OVERRIDE_ACTIVE (banner + indicator)
  → EXPIRY timer
  → AUTO_REVOKE
  → AUDIT (immutable)
```

Early end: “End override” → AUDIT.

## 6. Allowlist (UI selectable only these)

- Child device lock / restricted shell bypass for SOS response  
- Screen-time restriction bypass for SOS response  
- Web/app restriction bypass for emergency communication/response  
- Emergency communication surface  
- Access to active SOS and location context  
- Parent SOS notification handling  

## 7. Forbidden (never offer in UI)

Permanent policy/role/billing changes; disable SOS; disable audit; delete incidents/evidence; privacy/audit bypass; permanent exceptions; unlock-everything.

## 8. Controls

| Control | Roles | Confirm | Event |
|---|---|---|---|
| Open sheet | Primary, Full | — | — |
| Confirm override | Primary, Full | Yes | `SosBreakGlassInvoked` |
| End override | Primary, Full | Optional | `SosBreakGlassEnded` |
| Auto revoke | System | — | `SosBreakGlassAutoRevoked` |

## 9. States

`sheet_open` · `reason_required` · `OVERRIDE_ACTIVE` · `expiring_soon` · `AUTO_REVOKED` · `denied_role` (should not open)

## 10. Design

- Bottom sheet, not fullscreen modal if avoidable  
- Destructive coral accents only on confirm  
- Color + text + icon for active indicator  
- ≥48dp confirm; accidental-tap resistance (hold or double-step confirm)
