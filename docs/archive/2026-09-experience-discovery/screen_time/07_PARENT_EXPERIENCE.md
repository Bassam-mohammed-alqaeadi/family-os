# 07 — Parent Experience (Target)

**Role:** Primary / Father (OWNER)  
**Date:** 2026-09-23  
**Labels:** `CURRENT` · `TARGET`

---

## Current Father journey (honest)

1. Open child profile → FAT-032 Screen Time.
2. Edit daily cap / schedules / overflow (father-only).
3. Save → `PolicySyncBus` shows pending/delivered/offlineQueued.
4. Optionally open FAT-034 apps (mock), FAT-069 usage (fixture), FAT-033 requests (real service), FAT-037 lock, FAT-085 modes.
5. Approve request → `TimeGrant` written — **child remaining may not change**.
6. No OS enforcement feedback (“device is locking apps”).

---

## Target information flow

```
Child Profile
  → Screen Time Overview
      → Today
      → Schedule
      → App / Category Rules
      → Minutes Economy
      → Requests
      → Exceptions / Temporary Grants
      → History
      → Policy Health
```

---

## Questions the parent must answer in ≤3 seconds

| Question | Overview answer | Drill-down |
|---|---|---|
| How much time left? | Remaining countable minutes today | Today |
| Why is it left? | Cap − used + grants + overflow policy | Today / Economy |
| What is using it? | Top apps/categories (metered) | Today / History |
| What rule is active? | Mode + schedule chip | Schedule / Modes |
| What happens next? | Next window / expiry ETA / warning | Schedule |
| Is child restricted? | AVAILABLE / WARNING / EXPIRED / LOCKED | Overview badge |
| Is device enforcing? | Enforcing / Degraded / Unsupported | Policy Health |
| Is policy synced? | Synced / Queued / Stale / Conflict | Policy Health |
| Anything degraded? | Honesty badges (iOS limits, missing permission) | Policy Health |

---

## Screen intents (TARGET)

### Overview
- Child identity (ChildId-bound)
- Remaining + progress
- Active rule chip (Schedule | Mode | Lock | Cap)
- Sync + enforcement health
- Primary CTAs: Add time · Lock · Open requests

### Today
- Used vs cap
- Countable vs exempt usage separated
- Live sessions (future device)
- Bonus/grant remaining

### Schedule
- Sleep / prayer / study + smart modes entry
- Next transition time
- Conflict list (stricter-wins explanation)

### App / Category Rules
- Block / allow / limit / unlimited / countable
- New install approvals (FAT-035)
- Must persist into TimeEngine inputs

### Minutes Economy
- Per-app wallets
- Recent credits (channel, amount, source)
- Overflow switch (Ruling B)
- No points/XP language

### Requests
- Pending inbox (FAT-033 evolved)
- Ceiling indicator for mother (when viewing as co-parent context)
- Child-visible deny reason composer

### Exceptions / Temporary Grants
- Active grants with expiry
- Mode exceptions (child × app × mode)
- Freeze vs complete on mode start (Ruling C dialog)

### History
- Usage, grants, earns, locks, denials — audit-backed

### Policy Health
- Permission status (Usage Access / Screen Time entitlement)
- Last sync timestamp
- Stale policy warning
- Platform honesty (Android depth vs iOS)

---

## Error / offline recovery (TARGET)

| Situation | Parent sees | Action |
|---|---|---|
| Child offline | Queued sync badge | Retry / wait |
| Decision queued | “Will apply when online” | Flush on reconnect |
| Conflict (mother+father) | Father wins + audit (ADR-035) | Show supersession |
| Metering unavailable | Degraded enforcement honesty | Deep link to setup |
| Clock skew suspected | Policy Health warning | `OWNER` remediation |

---

## Non-goals

- Do not redesign entire app shell.
- Do not clone competitor dashboards with stat strips that hide Minutes meaning.
- Do not show SOS/paywall entanglement.

See: [16_UX_INFORMATION_ARCHITECTURE.md](16_UX_INFORMATION_ARCHITECTURE.md).
