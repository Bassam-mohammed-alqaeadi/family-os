# 05 — SCR-FAT-028 Engineering (Emergency & Trusted Contacts)

**Screen:** SCR-FAT-028 · إعداد الطوارئ  
**Decision:** EXTEND → Emergency & Trusted Contacts  
**Widget:** `EmergencySetupScreen` · Route: `/scr-fat-028`  
**Authority:** SET-020 rung-1 · RD-04 verify · RD-05 max 5 · RD-01 Panic Quiet config · OD-08 no national number

---

## 1. Purpose

Let Primary / Mother Full configure SOS readiness: immutable family guardians, up to five prioritized **verified** backup contacts, escalation delays, and Panic Quiet Mode—without mute-SOS or emergency-service numbers.

## 2. Audience

| Role | Access |
|---|---|
| Primary | Full edit |
| Mother Full | Full edit |
| Mother Partner | Blocked / lean (no edit) |
| Mother Observer | Blocked / lean |
| Child | Blocked / lean |

## 3. Entry points

- Settings hub  
- FAT-018 empty / setup CTA (Primary/Full)  
- Onboarding / setup wizard emergency step  

## 4. Exit / navigation

- Back to settings or FAT-018  
- Start verification → sheet / pending state (same screen)  
- No navigate to national dialer config  

## 5. Information hierarchy

1. **Primary:** Protocol + SOS receipt cannot be disabled banners  
2. **Secondary:** Readiness summary (`SosReadinessCard`)  
3. **Critical status:** Per-backup verification + channel readiness  
4. **Contextual:** Rung-1 guardians locked; backup list priority 1…5  
5. **Actions:** Add / edit / remove / verify / reorder priority / Panic Quiet toggle / delay edit  

## 6. Controls

| Control | Roles | Condition | Enabled | Confirm | Event | Result |
|---|---|---|---|---|---|---|
| Parent switches | — | Rung-1 | Always ON disabled | — | — | Immutable |
| Add backup | Primary, Full | count < 5 | Disabled at 5 | No | `ContactUpserted` | New UNVERIFIED priority next |
| Edit backup | Primary, Full | Exists | Yes | No | upsert | If phone changed → re-verify |
| Remove backup | Primary, Full | Exists | Yes | Modal confirm | `ContactRemoved` | Removed |
| Set priority 1..5 | Primary, Full | Exists | Yes | No | ladder update | Reorder |
| Toggle enabled | Primary, Full | Prefer only if VERIFIED | Disabled if not VERIFIED (or enabled but engine ignores) | No | toggle | Escalation eligibility |
| Start verify | Primary, Full | UNVERIFIED/REVOKED or after phone change | Yes | Sheet | `ContactVerificationChanged` PENDING | PENDING |
| Revoke verify | Primary, Full | VERIFIED | Yes | Confirm | REVOKED | Not escalatable |
| Delay seconds | Primary, Full | Backup | Yes | No | ladder update | Timer config |
| Panic Quiet toggle | Primary, Full | — | Yes | No | `SosPanicQuietModeChanged` | Mode ON/OFF |
| Mute SOS | **Forbidden** | — | Never shown | — | — | — |
| National emergency # | **Forbidden** | — | Never shown | — | — | — |

## 7. State inventory

| State | UI |
|---|---|
| loading | Spinner |
| ready | Ladder + readiness |
| empty_backups | Guardians only; add CTA |
| at_cap | Add disabled; message max 5 |
| verification UNVERIFIED/PENDING/VERIFIED/REVOKED | Badges per `ContactVerificationState` |
| verification_failure | Inline error + retry |
| unverified_restriction | Escalate engine note: skipped |
| save_error / inline_error | Immovable parent / validation |
| offline | Queue save honesty |
| forbidden_role | Lean / RoleGuard |
| panic_quiet_on/off | Toggle state |

## 8. Role-specific UI

Edit only Primary + Full. Others: cannot open edit or see lean.

## 9. Verification flow (UI)

```
UNVERIFIED → [Start verify] → PENDING → (abstract transport success) → VERIFIED
VERIFIED → [Revoke] → REVOKED
Any phone/MSISDN change → UNVERIFIED or PENDING (must re-verify)
```

Unverified contacts **cannot** participate in trusted escalation (show restriction copy).

## 10. Empty / error / recovery

- Zero backups OK.  
- Verify fail: FAILURE class + retry.  
- Recovery: re-verify; readiness refresh.

## 11. IA placement

- ListView settings layout (not coral full-bleed)  
- Banners top  
- Cards for rung-1 and each backup  
- Sheets for verify / remove confirm  
- Inline chips for verification  

## 12. Design system

- Surface/bg tokens; BannerNote variants; Switch disabled for parents; Semantics on icon buttons ≥48dp.
