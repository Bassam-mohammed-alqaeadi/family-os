# 05 — Time Precedence Model

**Date:** 2026-09-23  
**Do not invent CURRENT precedence** — quote code + Register. TARGET clarifies ambiguities separately.

---

## CURRENT precedence (`TimeEngine.resolve`)

Literal order in `app/lib/core/policy/time_engine.dart`:

```
1. instantLock          → deniedLock
2. permanentlyBlocked   → deniedBlocked   (wallet NEVER opens)
3. modeActive && !(appAllowedInMode || hasModeException)
                        → deniedMode
4. !dailyLimitExhausted → allowed
5. else wallet path:
     - allowWalletOverflow OR !dailyCapIncludesWallet → may open if balance > 0
     - else deniedCap
     - balance zero → deniedNoBalance
```

Register §2 summary: **Father instant lock → permanent block → active mode (+ exceptions) → daily limit → earned balance.**

Doc 33 expands device daily cap vs per-app limit as separate steps; **per-app limit is not a separate branch in current `TimeEngine`** (`CURRENT` gap vs sealed doc).

---

## CURRENT adjacent precedence

| Conflict | Winner | Evidence |
|---|---|---|
| Instant lock vs smart mode | Instant lock | Ladder step 1; Register “lock above modes” |
| Mother lock vs father unlock | Father | ADR-035 |
| Two modes same child | Stricter wins + notify father | M-B (law); code enforcement depth **UNKNOWN** |
| Per-child vs shared setting | Per-child > shared > default | `SettingSpecificity` / Ruling D |
| Web filter block vs Minutes remaining | Separate gates | No cross-engine call found |
| Pause/lock vs schedule | Lock wins | Instant lock short-circuit |
| Time expiry vs chat/Quran/SOS | Exempt surfaces win | `kTimeExpiryExemptSurfaces` |
| Device lock vs chat/Quran/SOS | Exempt | `kDeviceLockExemptSurfaces` (same triad) |

---

## CURRENT gaps / ambiguities

| Ambiguity | Status |
|---|---|
| Schedule window vs daily cap when both active | Schedules synced; hard deny path not fully unified with `TimeEngine` steps 1–5 |
| Temporary grant vs schedule | Grant not applied → conflict never resolved in code |
| Per-app limit vs device cap | Per-app limit not in engine |
| CHD-020 pending vs FAT-033 | Disconnected — no precedence |
| Overflow ON + Instant Lock | Lock still wins (clear) |
| Overflow ON + permanent block | Block still wins (clear) |
| Overflow ON + mode deny | Mode still wins without exception (clear) |

---

## TARGET precedence (proposed — eliminates contradiction)

Evaluate **top-down**; first decisive deny wins. First decisive allow still subject to lower remaining-time rules.

```
P0  SAFETY EXEMPT SURFACES
    chat | quran | sos  → always reachable for those surfaces
    (never consult entertainment ladder)

P1  INSTANT DEVICE LOCK
    → deny entertainment (and non-exempt)
    father unlock supersedes mother lock

P2  PERMANENT APP BLOCK
    → deny; Minutes / grants NEVER open

P3  ACTIVE SCHEDULE OR SMART MODE
    if surface not in allowed set AND no father exception → deny
    if two modes → stricter wins (M-B)
    grace window per Register (0–5, default 2)

P4  DEVICE DAILY ENTERTAINMENT CAP
    if usedCountable >= cap:
       if temporaryGrantRemainingToday > 0 → allow under grant rules
       else if walletMayOpenPastCap && wallet > 0 → allow (consume wallet)
       else → denyCap

P5  PER-APP / CATEGORY DAILY LIMIT
    same pattern as P4 for that app/category

P6  ALLOW
    consume: daily allotment first, then temporary grant, then wallet
    (Doc 33 order — needs Owner confirm if grant sits beside wallet)
```

**Web filter:** evaluated as **independent gate** before content load; failing filter does not spend Minutes; passing filter still requires TimeEngine allow.

---

## Temporary grant placement (`OWNER`)

Two lawful options — do not silently pick:

| Option | Meaning |
|---|---|
| **G-A** | Grant increases today’s remaining under P4 (like Family Link Bonus) |
| **G-B** | Grant deposits into app wallet and follows Ruling B overflow |

CURRENT code matches **neither** (grant is inert). See Owner decision ST-OD-004.

---

## Traceability sketch

| Requirement | Policy | Role | State | Screen | Event | Data | Future |
|---|---|---|---|---|---|---|---|
| Instant lock wins | P1 | Father / Mother Full | DEVICE_LOCK | FAT-037 | lock.engaged | DeviceLock store | OS lock API |
| Cap exhaust | P4 | Child sees | TIME_EXPIRED | CHD-021 | cap.exhausted | ScreenTimePolicy | UsageStats / Screen Time |
| Wallet open past cap | Ruling B | Father toggle | TEMPORARY_GRANT / AVAILABLE | FAT-032 | overflow.toggled | allowWalletOverflow | sync |
| SOS always | P0 | Child | AVAILABLE for SOS | CHD-005 | sos.fire | SosAlert | telecom |

See: [11_STATE_MACHINE.md](11_STATE_MACHINE.md).
