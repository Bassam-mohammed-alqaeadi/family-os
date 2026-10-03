# 18 — Degraded / Offline UX

---

## Sync states → UI

| Sync | Parent sees | Child sees |
|---|---|---|
| SYNCED | Green/neutral “Updated” | Normal remaining |
| PENDING | “Sending…” | Last known |
| OFFLINE_QUEUED | Queue badge | Last known + soft “may update later” |
| CONFLICT | Resolve / father-wins note | Last known |
| RECOVERY | Progress | Hold steady |

## Stale policy (ST-OD-009)

1. Banner: using last known  
2. Grace (non-numeric frozen) — soft warn  
3. Fail closed entertainment — CHD-021 path  
4. SOS/Chat/Quran remain  

## Device

| State | UI |
|---|---|
| SIMULATED | Honesty badge everywhere claims would overreach |
| ENFORCING | Only when proven |
| DEVICE_LOCKED | Lock banner + exempt exits |
| OFFLINE | Child offline on parent hub |
| UNSUPPORTED | iOS/Android capability honesty |

## Errors
Use `AppErrorState` + retry; never silent fail on deny reason submit.

## Notifications
In-app toast OK; do not claim push delivered.
