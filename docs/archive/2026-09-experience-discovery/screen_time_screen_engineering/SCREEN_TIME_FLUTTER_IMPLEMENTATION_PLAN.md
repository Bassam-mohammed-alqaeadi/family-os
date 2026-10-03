# SCREEN TIME — Flutter Implementation Plan

**Date:** 2026-09-23  
**Authority:** `screen_time_final/13_*` + `screen_time_screen_engineering/23_*`  
**Phase:** Flutter slice only — no backend / OS enforcement  

---

## Current dependency graph

```
FAT-032 ──► ScreenTimePolicyRepository + SchedulePrefs + PolicySyncBus
FAT-033 ──► TimeRequestService ──► TimeGrant (inert) ✗ remaining
CHD-020 ──► InMemoryChildTimeRequestRepository ✗ (disconnected)
CHD-019 ──► InMemoryChildWalletRepository ✗ (fixtures)
FAT-034 ──► ChildAppsRepository mock ✗ TimeEngine
FAT-045 ──► WalletLedger.earn ──► AppWallet ✓
CHD-004 ──► PolicySyncBus.remainingMinutes (cap−used only)
CHD-021 ──► TimeExpirySurface + TimeEngine ✓ exempt
```

---

## Target dependency graph

```
CHD-020 ──► TimeRequestService.createRequest (1 pending)
FAT-033 ──► approve ──► TimeGrant (G-A remaining + expiresAt)
         └─✗ WalletLedger
RemainingProjection = max(0,cap−used) + Σ activeGrant.remaining
CHD-004 / mirror / FAT-032 Today ──► RemainingProjection (3 labeled buckets)
CHD-019 ──► WalletLedger / ScreenTimePolicy.wallets
FAT-034 ──► AppRules store ──► ScreenTimePolicyQuery / TimeContext.permanentlyBlocked + unlimited/countable/limit
```

---

## Files to create

| File | Why |
|---|---|
| `app/lib/core/policy/temporary_grant_query.dart` | Sum active grant remaining; expiry check |
| `app/lib/core/policy/screen_time_remaining.dart` | 3-bucket projection (daily/grant/wallet) |
| `app/lib/core/policy/app_access_rules.dart` (+ repo prefs) | FAT-034 axes → TimeContext inputs |
| `app/lib/core/design/components/screen_time_*.dart` (subset) | Overview/Remaining/Grant/Request/Health/Warning/Enforcement badges — reuse AppCard/Tag/BannerNote |
| `app/test/core/policy/time_request_service_test.dart` | G-A + pending rules |
| `app/test/core/policy/temporary_grant_query_test.dart` | Expiry / remaining |
| `app/test/features/n03_screen_time/request_loop_integration_test.dart` | CHD-020→FAT-033 |

## Files to modify (core — additive only)

| File | Change | Contract |
|---|---|---|
| `time_request.dart` | Extend `TimeGrant` with remaining/expiresAt/status; request expired status | ST-OD-004/007 |
| `time_request_service.dart` | 1 pending; timeout; activate G-A on approve; no WalletLedger | loops 1–2 |
| `time_request_repository.dart` | Persist new grant fields | — |
| `policy_sync_bus.dart` | Mirror remaining uses 3-bucket / grant-aware | ST-ADD-004 |
| `screen_time_policy_query.dart` | Cap exhaustion accounts for grant remaining; app rules | P4/P5 |
| ARB en/ar + localizations | Minutes labels; remove نقاط on touched screens | E-1 |

## Files to modify (features)

| File | Change |
|---|---|
| `child_time_request_*` | Adapter → TimeRequestService |
| `request_inbox_screen.dart` | CurrentRole; remaining context; Ruling C sheet; grant result |
| `child_wallet_*` | Read WalletLedger / policy wallets |
| `child_apps_*` | Persist axes → AppAccessRules |
| `child_screen_time_screen.dart` | Hub IA; Mother Full edit; 3 buckets; health; nav |
| `child_day_board_screen.dart` | WARNING ≤5; grant chip; CTAs |
| `time_expiry_screen.dart` | Ensure Request/Quran/Chat/SOS; calm |
| `child_usage_report_*` | Simulated badge |
| Instant lock / smart modes screens | Honesty badges; link from hub only |
| Router | Pass role/motherLevel where needed |

## Tests required

Request loop · Grants G-A · Economy CHD-019 · App rules block>wallet · Warning/expiry · Roles · Precedence smoke · Honesty SIMULATED · verify_ship

## Risks

| Risk | Mitigation |
|---|---|
| Rule 21 core/policy touch | Additive only; Owner task authorizes Screen Time slice |
| Breaking existing FAT-033 tests | Extend asserts; keep reject/ceiling |
| Double remaining inflation | Grant only via approve; never earn path |
| Fixture CHD-019 tests | Retarget to ledger seeds |

## Rollback

Revert feature adapters first; TimeGrant new fields default-compatible in fromJson; feature flags not needed if prefs keys versioned.

## Out of scope (deferred)

OS metering/blocking · FCM · multi-device transport · free wallet · numeric stale TTL · System #3
