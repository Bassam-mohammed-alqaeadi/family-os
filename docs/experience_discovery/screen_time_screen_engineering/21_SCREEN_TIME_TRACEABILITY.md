# 21 — Screen Time Traceability

**Template:** Requirement → Policy → Role → State → Screen → Component → Event → Data → Future backend/device

---

| Requirement | Policy | Role | State | Screen | Component | Event | Data | Future |
|---|---|---|---|---|---|---|---|---|
| See remaining ≤3s | ST-OD-001/004; 3 buckets | Parent all read | TIME AVAILABLE/WARNING/EXPIRED | FAT-032 | ScreenTimeOverviewCard · RemainingMinutesCard | overview_opened | ScreenTimePolicy · grants · wallets | Shared meter sync |
| Edit cap | Child-level cap | Primary · Full | POLICY_ACTIVE | FAT-032 | SettingsPersistToggle / steppers | cap_updated | policy repo | API policy |
| Edit overflow | Ruling B · ST-OD-012 | Primary · Full | — | FAT-032 | toggle + audit hint | overflow_toggled | policy | audit store |
| Schedule/modes | P3 · M-B | Primary · Full | active schedule | FAT-032 · FAT-085 | ScheduleRuleCard · ActivePolicyBanner | mode.activated | schedules · modes | OS Focus optional |
| App axes | ST-OD-010 · P2/P5 | Primary · Full | — | FAT-034 | AppRuleCard | app_rule.updated | app rules | device inventory |
| New install | — | Primary · Full | — | FAT-035 | AppRuleCard | app_pending.resolved | pending apps | package listener |
| Request extra | ST-OD-006/007 · G-A | Child; Partner+ decide | REQUEST_* | CHD-020 · FAT-033 | RequestCard · RequestDecisionSheet | time_request.* · temporary_grant.* | TimeRequestService | FCM |
| Grant ≠ wallet | ST-OD-004 | — | TEMPORARY_GRANT facet | FAT-032 · CHD-004 | TemporaryGrantCard | grant.activated | TimeGrant | — |
| Ruling C | Ruling C | Approver | — | FAT-033 sheet | RequestDecisionSheet | grant.onModeStart | grant meta | — |
| Warning 5m | S-3 | Child | WARNING | CHD-004 | TimeWarningBanner | time.warning | remaining | DeviceActivity |
| Calm expiry | S-4 · Rule 11 | Child | EXPIRED | CHD-021 | CalmExpirySurface | cap.exhausted | — | OS block |
| SOS always | P0 · SOS freeze | Child | any | CHD-004/021 · CHD-005 | SOS CTA / shell | sos.fire | SosFire | telecom |
| Wallet view | ST-OD-002/003 | Child | — | CHD-019 | MinutesWalletCard | wallet.viewed | WalletLedger | ledger API |
| Instant lock | P1 · ADR-035 | Primary · Full | DEVICE_LOCKED | FAT-037 | ActivePolicyBanner | lock.engaged | DeviceLock | OS lock |
| Anti-tamper | P-6 · 035-b | Primary only | TAMPER_SUSPECT | FAT-038 | list + honesty | tamper.signal | signals | Device Admin |
| Usage report | Honesty | Parents read | SIMULATED/verified | FAT-069 | MeteringHonestyBadge | usage.viewed | usage repo | UsageStats |
| Policy Health | ST-OD-009 | Parents | POLICY_* · SYNC_* · Device | FAT-032 | PolicyHealthCard · badges | health.viewed | sync · perms | entitlements |
| Why blocked | P0–P6 | Parent | RESTRICTED/BLOCKED/… | FAT-032/034 | WhyUnavailableSheet | explain.opened | TimeEngine ctx | — |
| No points | E-1 | All | — | CHD-019 · copy | — | — | ARB | — |
| Shared multi-device budget | ST-OD-001 | Parent | — | Policy Health | note | — | child meter | cross-device |
| Fail closed stale | ST-OD-009 | Child entertainment | POLICY_STALE→EXPIRED | CHD-021 | CalmExpirySurface | policy.fail_closed | mirror | — |

---

## Coverage check

Core screens · Father · Observer · Partner · Full · Child · 3 budgets · grant≠wallet · grant≠exception · SOS · no XP · warning · calm expiry · request loop · roles · precedence · health · offline · simulated vs enforcing — **mapped**.
