# 01 — Screen Time Screen Architecture

**Status:** SCREEN ENGINEERING SPEC (docs only)  
**Authority:** [`../screen_time_final/13_SCREEN_TIME_FINAL_MASTER_CONTRACT.md`](../screen_time_final/13_SCREEN_TIME_FINAL_MASTER_CONTRACT.md)  
**Entry:** [23_SCREEN_TIME_SCREEN_ENGINEERING_MASTER.md](23_SCREEN_TIME_SCREEN_ENGINEERING_MASTER.md)

**Hard rules:** No app code · no `core/policy/` · no `tokens.dart` · no backend/OS · no points/XP · SOS always available · product freeze authoritative.

---

## 1. Primary screens

| Screen ID | Title | Disposition | Stage-1 widget | Route |
|---|---|---|---|---|
| SCR-FAT-032 | Screen Time (child) | **EXTEND** → hub | `ChildScreenTimeScreen` | `/scr-fat-032` |
| SCR-FAT-033 | Request Inbox | **EXTEND** | `RequestInboxScreen` | `/scr-fat-033` |
| SCR-FAT-034 | Child Apps | **WIRING FIX** + **EXTEND** | `ChildAppsScreen` | `/scr-fat-034` |
| SCR-FAT-035 | New App Approval | **EXTEND** | `NewAppApprovalScreen` | `/scr-fat-035` |
| SCR-FAT-037 | Instant Lock | **EXTEND** | `InstantLockScreen` | `/scr-fat-037` |
| SCR-FAT-038 | Anti-Tamper | **KEEP**/honesty | anti-tamper list | `/scr-fat-038` |
| SCR-FAT-069 | Usage Report | **EXTEND** honesty | `ChildUsageReportScreen` | `/scr-fat-069` |
| SCR-FAT-085 | Smart Modes | **EXTEND** (not 2nd home) | `SmartModesScreen` | `/scr-fat-085` |
| SCR-CHD-004 | Day Board | **EXTEND** | `ChildDayBoardScreen` | day board route |
| SCR-CHD-019 | Minutes Wallet | **WIRING FIX** | `ChildWalletScreen` | `/scr-chd-019` |
| SCR-CHD-020 | Time Request | **WIRING FIX** | `ChildTimeRequestScreen` | `/scr-chd-020` |
| SCR-CHD-021 | Time Expiry | **EXTEND** | `TimeExpiryScreen` | `/scr-chd-021` |

No new Screen IDs. Hub sections mount **inside** FAT-032 (or sheets) — not duplicate homes.

---

## 2. Supporting surfaces (link-only)

| Surface | Use | Engineering |
|---|---|---|
| Child Profile | Entry to FAT-032 | Keep G-5 spirit |
| FAT-031 Mother level | Ceiling / role context | Link; no redesign |
| FAT-036 Web Filter | Independent gate | Link as adjacent; not Minutes tab |
| FAT-045 Attribution | Earn source → wallets | Deep-link into Economy history |
| CHD-005 SOS | From WARNING/EXPIRED | Keep CTA |
| CHD-008 Chat | Exempt | Keep |
| CHD-018 Focus | Edu / non-countable | Link; ST-OD-011 suggest≠auto |
| CHD-007 contact parent | Optional from expiry | Reuse |
| Audit (FAT-060) | Grant/overflow/lock visibility | Append-only; no ST redesign |
| PolicySyncBus / DecisionBus | Conceptual data | Spec only |

---

## 3. Frozen parent IA (single hub)

```
Child Profile
  → Screen Time Overview (FAT-032)
      → Today
      → Schedule / Routines (+ entry FAT-085)
      → App / Category Rules (FAT-034)
      → Minutes Economy
      → Requests (FAT-033)
      → Exceptions / Temporary Grants
      → History
      → Policy Health
```

Quick Actions on Overview: **Add Time** · **Lock** (→ FAT-037) · **Requests**.

---

## 4. Frozen child IA

```
Day Board (CHD-004)
  → Remaining Time (inline)
  → Request More (CHD-020)
  → Minutes Wallet (CHD-019)
  → Expiry (CHD-021) when EXPIRED
```

Protected exits always: Quran · Chat · SOS.

---

## 5. Orthogonal state machines (display)

Do **not** collapse.

| Machine | States (engineering) |
|---|---|
| Policy | ACTIVE · STALE · CONFLICT · DEGRADED · DEFAULT |
| Time Balance (primary UX) | AVAILABLE · WARNING · EXPIRED |
| Time Balance (access facets) | TEMPORARY_GRANT · WALLET_ONLY · OVERFLOW_BLOCKED — explain *why* open/closed; quantities always separate |
| Device | ENFORCING · SIMULATED · RESTRICTED · BLOCKED · DEVICE_LOCKED · OFFLINE · UNSUPPORTED |
| Sync | SYNCED · PENDING · OFFLINE_QUEUED · SYNCING · CONFLICT · RECOVERY |
| Request | NONE · REQUESTING · REQUEST_PENDING · APPROVED · DENIED · EXPIRED · QUEUED_OFFLINE |

**No `LOW_TIME`** (product freeze). WARNING = ≤5 minutes.

---

## 6. Existing shared components to reuse

| Existing | Reuse for |
|---|---|
| `AppCard` | Section containers |
| `BannerNote` | Active policy / honesty / warning |
| `Tag` | Status chips (sync, enforcement, role) |
| `PrimaryBtn` | Primary CTAs (≥48dp) |
| `RowTile` | App rules, request rows, wallet rows |
| `ProgressBar` | Remaining progress |
| `AppEmptyState` / `AppErrorState` | Empty/error |
| `AppToast` | Soft ack (not push claim) |
| `BottomSheetHost` | Decision sheets, Ruling C, Add Time |
| `SettingsPersistToggle` | Overflow / countable toggles (Mother Full+) |
| `HubGrid` | Overview section shortcuts if needed |
| SOS components | **Do not reuse coral SOS chrome** for entertainment expiry |

New ST components listed in [19_COMPONENT_SPECIFICATION.md](19_COMPONENT_SPECIFICATION.md).

---

## 7. Honesty classes

Every enforcement/metering claim chip:

`SIMULATED` · `ENFORCING` · `UNSUPPORTED` · `DEGRADED`

Never show fixture usage as “verified device usage” without explicit badge.
