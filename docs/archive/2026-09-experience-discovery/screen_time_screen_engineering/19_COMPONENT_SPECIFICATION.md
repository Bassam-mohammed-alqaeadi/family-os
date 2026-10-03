# 19 — Component Specification

**Rule:** Inspect `app/lib/core/design/components/` first; reuse before inventing.  
**Tokens:** use existing only — no `tokens.dart` edits in this phase.

---

## Reuse map

| Component | Path | ST use |
|---|---|---|
| `AppCard` | components/app_card.dart | Section shells |
| `BannerNote` | banner.dart | Policy / warning / honesty |
| `Tag` | tag.dart | Chips |
| `PrimaryBtn` | primary_btn.dart | CTAs |
| `RowTile` | row_tile.dart | Lists |
| `ProgressBar` | progress_bar.dart | Remaining |
| `AppEmptyState` / `AppErrorState` | — | Empty/error |
| `AppToast` | — | Soft ack |
| `BottomSheetHost` | — | Sheets |
| `SettingsPersistToggle` | — | Overflow/countable |
| `HubGrid` | — | Overview shortcuts |
| SOS_* | — | **Do not** restyle entertainment as SOS coral |

---

## Proposed ST components (new — once each in core/design/components when implementing)

| Component | Responsibility |
|---|---|
| `ScreenTimeOverviewCard` | Hub hero: 3 remainings + active rule |
| `RemainingMinutesCard` | One labeled bucket (Daily / Grant / Wallet) |
| `ActivePolicyBanner` | Mode/schedule/lock plain-language |
| `ScheduleRuleCard` | Window row + next transition |
| `AppRuleCard` | Four axes editors/display |
| `MinutesWalletCard` | Per-app earned row |
| `TemporaryGrantCard` | Grant amount + expiry + not-earned |
| `RequestCard` | Inbox / child pending summary |
| `RequestDecisionSheet` | Approve/reject + ceiling + Ruling C hook |
| `PolicyHealthCard` | Health fields |
| `SyncStateIndicator` | Sync enum chip |
| `EnforcementStatusBadge` | SIMULATED/ENFORCING/… |
| `TimeWarningBanner` | ≤5 min calm child banner |
| `CalmExpirySurface` | CHD-021 body |
| `RoleActionGuard` | Builds role-appropriate action slots |
| `WhyUnavailableSheet` | Parent plain-language P0–P6 explanation |
| `MeteringHonestyBadge` | Verified vs Simulated usage |

---

## Semantics / targets
Every interactive ≥48dp; `Semantics` labels AR+EN via ARB; no color-only state.
