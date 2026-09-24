# 02 — FAT-032 Screen Time Engineering

**Screen:** SCR-FAT-032 · وقت الشاشة لابن  
**Widget:** `ChildScreenTimeScreen`  
**Disposition:** EXTEND into **Screen Time Overview hub**  
**Authority:** Product freeze + this pack

---

## 1–4. Purpose / role / entry / exit

| | Spec |
|---|---|
| **Purpose** | Parent hub: answer remaining / why / active rule / next / restricted / enforcement honesty / sync / degradation in ≤3s |
| **Roles** | Primary full · Mother Full operational edit · Partner/Observer read (+ Partner jumps to Requests) |
| **Entry** | Child Profile · Quick Action · deep links from requests/lock |
| **Exit** | Back to profile · → FAT-033/034/037/069/085 · sheets for Add Time / Exceptions |

---

## 5. Information hierarchy

1. **Hero status strip:** remaining (3 quantities) · active rule chip · restriction badge  
2. **Honesty strip:** EnforcementStatusBadge · SyncStateIndicator · stale/conflict if any  
3. **Primary action row:** Add Time · Lock · Requests  
4. **Section list:** Today · Schedule · Apps/Rules · Minutes · Exceptions · History · Policy Health  

---

## 6–7. Actions

| Primary | Secondary |
|---|---|
| Add Time (Temporary Grant sheet) | Open Today detail |
| Lock → FAT-037 | Edit cap / overflow (Primary, Mother Full) |
| Requests → FAT-033 | Open Schedule / Apps / Economy / Health |

---

## 8. Permission behavior

| Role | Behavior |
|---|---|
| Primary | Full edit + ownership |
| Mother Full | Edit caps, schedules, overflow; Add Time ≤ ceiling; Lock; no anti-tamper / ceiling-rule ownership / father-block unlock |
| Partner | Read Overview; primary CTA = Requests; Add Time only if product routes grant via inbox/ceiling (prefer FAT-033); no cap/schedule/overflow edit |
| Observer | Read-only; CTAs explain “view only” |

Use `RoleActionGuard` — intent-shaped layouts, not greyed clones.

---

## 9–10. Policy I/O

**Inputs:** `ScreenTimePolicy` (cap, used, overflow, wallets) · schedules · active mode · lock · sync · grants · requests count · enforcement class  

**Outputs (on edit):** updated cap/schedules/overflow → sync publish · Temporary Grant create · navigate lock  

---

## 11. Events

`screen_time.overview_opened` · `policy.cap_updated` · `policy.overflow_toggled` · `schedule.updated` · `temporary_grant.created` · `nav.lock` · `nav.requests`

---

## 12. Data dependencies

ChildId · policy repo · schedule repo · PolicySyncBus · TimeRequest pending count · DeviceLock state · grant remaining · role + MotherLevel

---

## 13–15. States / errors / offline

| States | loading · ready · editing · saving · error · offline_queued |
| Errors | save fail · permission denied · conflict |
| Offline | Allow local edit queue; show OFFLINE_QUEUED; never claim device delivered |

---

## 16–18. Sync / enforcement / audit

- Sync chip always visible on hub.  
- Default Stage-1: **SIMULATED**.  
- Overflow/cap edits by Mother Full → audit + Primary-visible marker.

---

## 19–20. A11y / RTL

Semantics on all CTAs; ≥48dp; RTL mirrored action row; status not color-only (icon+text); Arabic calm copy.

---

## Section contracts (mounted in hub)

### Today
Daily Remaining · Temporary Grant Remaining · Earned Wallet (sum or top apps) — **separate**. Countable vs exempt usage split. Metering honesty badge.

### Schedule / Routines
Sleep · prayer · study · link Smart Modes. Active rule · next transition · conflict + stricter-wins. Grant does **not** look like schedule override.

### Apps/Rules
→ FAT-034 summary + “Manage”.

### Minutes Economy
→ parent economy view / CHD-019 conceptual mirror for parent.

### Exceptions
Active Temporary Grants (expiry) · ModeExceptions · Ruling C pending.

### Policy Health
→ [17_POLICY_HEALTH_UX.md](17_POLICY_HEALTH_UX.md)

### History
Usage (honest) · grants · earns · locks · denials.
