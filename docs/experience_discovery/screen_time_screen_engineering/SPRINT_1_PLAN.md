# Screen Time Sprint #1 Plan (Bounded)

**Scope:** Close only 6 gaps in one bounded sprint.

## Files to modify and gap mapping

1. **CHD-020 → FAT-033 request loop**
   - `app/lib/features/n03_screen_time/child_time_request_repository.dart`
   - `app/lib/features/n03_screen_time/child_time_request_screen.dart`
   - `app/lib/features/n02_day/request_inbox_screen.dart`
   - `app/lib/core/policy/time_request_service.dart`
   - `app/lib/core/policy/time_request.dart`

2. **Approve → Temporary Grant usable effect (G-A)**
   - `app/lib/core/policy/time_request.dart`
   - `app/lib/core/policy/time_request_service.dart`
   - `app/lib/core/policy/temporary_grant_query.dart`
   - `app/lib/features/n02_day/child_day_board_screen.dart`
   - `app/lib/core/policy/screen_time_policy_query.dart`

3. **CHD-019 → WalletLedger/projection**
   - `app/lib/features/n17_child_learn/child_wallet_repository.dart`
   - `app/lib/features/n17_child_learn/child_wallet_screen.dart`

4. **FAT-034 → policy/TimeEngine inputs (conceptual seam)**
   - `app/lib/core/policy/app_access_rules.dart`
   - `app/lib/core/policy/app_access_rules_repository.dart`
   - `app/lib/features/n03_screen_time/child_apps_models.dart`
   - `app/lib/features/n03_screen_time/child_apps_repository.dart`
   - `app/lib/features/n03_screen_time/child_apps_screen.dart`

5. **5-minute child warning**
   - `app/lib/core/design/components/time_warning_banner.dart`
   - `app/lib/features/n02_day/child_day_board_screen.dart`

6. **Mother Full edit rights on FAT-032**
   - `app/lib/features/n03_screen_time/child_screen_time_screen.dart`

## Targeted tests required

- Request loop: CHD-020 submit appears in FAT-033, pending/approve/reject/expired behavior
- Grant semantics: approve creates active Temporary Grant and affects remaining
- Child feedback: rejection reason visible
- Wallet: CHD-019 reflects policy wallet balances
- App rules: rule axes map to policy seam and affect evaluation inputs
- Warning: <=5 minutes shows calm banner and actions
- Roles: Observer/Partner/Full restrictions, Mother Full can edit FAT-032

## Expected verification

1. Run targeted tests for modified screen-time files.
2. Run `python .cursor/hooks/verify_ship.py verify`.
3. Confirm compile/analyze passes in scoped verification output.
4. Write sprint report at `SPRINT_1_REPORT.md`.
