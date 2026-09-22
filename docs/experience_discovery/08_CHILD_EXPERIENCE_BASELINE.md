# 08 — Child Experience Baseline (Family OS)

**Role in code:** `AppRole.child`  
**Identity:** screens are functions of `ChildId` (constitution rule 13); names only in `mock/`  
**Date:** 2026-09-23  

---

## How child mode is entered (FACT)

- SHR-007 device mode → child path → CHD-001 welcome.  
- Or in-app role switch / device user switch (SHR-008) with password mock flows.  
- Child mode lock (CHD-011) + father second key (FAT-030) — **in-app** services (`ChildModeLockService`), not Android lock task / kiosk.

---

## What the child can see / do (coded)

| Intent | Screen(s) | Behavior | Real device | Status |
|---|---|---|---|---|
| Day board | CHD-004 | Binds PolicySyncBus + SmartModeActivationBus; empty states; no planted minutes | UI only | A→H |
| Transparency | CHD-010 / CHD-003 | Shows enabled collection scopes; consent UX | No OS data collection | B/F |
| SOS | CHD-005/006 | Always reachable UI; MockSosFire; entitlement-free | No real emergency call/SMS | B/F |
| Chat / call UI | CHD-007…009 | Mock conversations; never locked by time expiry design | No realtime | C/F |
| Time expiry calm | CHD-021 | Entertainment denied via TimeEngine; chat/Quran/SOS CTAs remain | No OS app blocking | A→H |
| Time request | CHD-020 area | Repo/screen exist; **router may still be Placeholder** | — | G/F |
| Learn suite | CHD-012… | Screen files under `n17_child_learn/`; **many routes PlaceholderScreen** | — | G |
| Wallet / badges UI | child wallet screens | Minutes vocabulary; mock balances | — | F |
| Friends / media / stickers | Wave-3 CHD screens | InMemory repos + tests | — | F/G |
| QR scan pair | CHD-002 | FakeCameraPermissionSeam + repair CTA | No camera pairing server | F |

---

## What blocks the child (in-app vs real)

| Control | In-app | On physical device |
|---|---|---|
| Daily cap / wallet | TimeEngine decisions + expiry screen | **Not enforced** (H) |
| Web categories | Evaluator + block page widget | **Not a real browser/VPN filter** (H) |
| Instant lock | DeviceLock state + UI | **Not Device Admin / Lock Task** (H) |
| Smart mode | Status card tint / soft toasts | **Not Focus Mode / MDM** (H) |
| RoleGuard | Child blocked from FAT-059/060 | Navigation only |

---

## Parent action → child effect (current truth)

| Parent action | Child sees (same session) | Cross-device |
|---|---|---|
| Save schedule/cap | Mirror via PolicySyncBus | No |
| Approve time/web unlock | Decision bus / allow-list | No |
| Activate smart mode | Day board status | No |
| Toggle collection scopes | CHD-010 list updates | No |
| Lock device | Lock notify / lock UI | No OS lock |
| Fire SOS ladder config | Affects mock delivery targets | No |

---

## Child experience gaps

1. **Router placeholders** for large learn/social surface → dead ends if navigated by ID.  
2. No durable child profile beyond memory.  
3. Transparency describes collection the app does not actually perform yet.  
4. Minutes/wallet can look real while OS apps remain unrestricted.  
5. Education submit→parent results loop still open (GAP_LOG P15-EDU-006).  
6. Constitution forbids points/XP language — some registry CSV notes still say “نقاط”; code path should use Minutes (verify per screen; Rule 4).

---

## Journey sketch

`Device mode child → Welcome → QR (fake) → Transparency → Day board → (SOS always) → Chat mock → Expiry calm → Learn (often placeholder route)`
