# Screen Time Sprint #1 Report (Bounded)

Date: 2026-09-23
Scope: bounded implementation sprint for six Screen Time closures only.

## Gaps closed in this sprint

1. **CHD-020 -> FAT-033 request loop**
   - Child submit is wired to `TimeRequestService.createRequest`.
   - Pending request appears in parent inbox flow.
   - Duplicate pending prevention enforced.
   - Child decision feedback path (approve/reject/expired) is wired.

2. **Approve -> Temporary Grant usable effect (G-A)**
   - Approval produces active child-wide Temporary Grant.
   - Grant contributes to child effective remaining display.
   - Grant is distinct from wallet earnings.
   - Ceiling/role protections and duplicate decision protections remain enforced.

3. **CHD-019 wallet projection**
   - Child wallet view reads policy/wallet projection seam (not fixture-only).
   - Minutes attribution display path preserved.

4. **FAT-034 app-rule wiring**
   - App access rule model/query seam wired for block/allow/limit/countable/unlimited axes.
   - Rule mapping tests cover policy-evaluation inputs conceptually.

5. **<=5 minute warning (S-3)**
   - Child warning state and protected-action CTA surface are wired and tested.

6. **Mother Full edit capability (FAT-032)**
   - Mother Full edit permissions for caps/schedules/overflow are enabled through role seam.
   - Observer/Partner restrictions remain covered by tests.

## Files changed (sprint-focused)

- `app/lib/core/policy/time_request.dart`
- `app/lib/core/policy/time_request_service.dart`
- `app/lib/core/policy/temporary_grant_query.dart`
- `app/lib/core/policy/policy_sync_bus.dart`
- `app/lib/core/policy/screen_time_policy_query.dart`
- `app/lib/core/policy/app_access_rules.dart`
- `app/lib/features/n03_screen_time/child_time_request_repository.dart`
- `app/lib/features/n03_screen_time/child_time_request_screen.dart`
- `app/lib/features/n02_day/request_inbox_screen.dart`
- `app/lib/features/n02_day/child_day_board_screen.dart`
- `app/lib/features/n03_screen_time/child_screen_time_screen.dart`
- `app/lib/features/n17_child_learn/child_wallet_repository.dart`
- `app/lib/features/n17_child_learn/child_wallet_screen.dart`
- `app/lib/features/n03_screen_time/child_apps_models.dart`
- `app/lib/features/n03_screen_time/child_apps_repository.dart`
- `app/lib/features/n03_screen_time/child_apps_screen.dart`
- `app/test/core/policy/time_request_service_test.dart`
- `app/test/core/policy/app_access_rules_query_test.dart`
- `app/test/features/n03_screen_time/child_time_request_screen_test.dart`
- `app/test/features/n02_day/ui_006_request_inbox_test.dart`
- `app/test/features/n02_day/ui_005_child_day_board_test.dart`
- `app/test/features/n03_screen_time/child_screen_time_screen_test.dart`
- `app/test/features/n03_screen_time/child_time_mirror_test.dart`
- `app/test/features/n17_child_learn/child_wallet_screen_test.dart`

## Targeted tests run

Passed targeted sprint tests:

- `test/core/policy/time_request_service_test.dart`
- `test/core/policy/app_access_rules_query_test.dart`
- `test/features/n03_screen_time/child_time_request_screen_test.dart`
- `test/features/n17_child_learn/child_wallet_screen_test.dart`
- `test/features/n03_screen_time/child_screen_time_screen_test.dart`
- `test/features/n02_day/ui_005_child_day_board_test.dart`
- `test/features/n02_day/ui_006_request_inbox_test.dart`
- `test/features/n03_screen_time/new_app_approval_screen_test.dart`
- `test/features/n03_screen_time/child_time_mirror_test.dart`

## Ship verification

- `python .cursor/hooks/verify_ship.py verify` was executed.
- Earlier run failed with four tests.
  - Two **in-scope Screen Time** regressions in `child_time_mirror_test` were fixed in this sprint.
  - Two **out-of-scope SOS** failures remained:
    - `test/core/policy/sos_break_glass_test.dart: SosBreakGlass Primary can start; Partner denied`
    - `test/core/policy/sos_break_glass_test.dart: SosBreakGlass expiry clears active without mutating ladder policy`
- Final verify rerun result:
  - analyze: pass
  - tests: `FAILED (1164 passed / 2 failed)`
  - remaining failures are the two SOS tests above (outside this bounded Screen Time sprint scope).

## Known limitations / deferred items

- No backend/APIs/Firebase/FCM implemented.
- No Android/iOS enforcement integrations implemented.
- No OS-level metering/blocking or real cross-device transport implemented.
- Sprint intentionally stopped after the six bounded closures.

## Remaining Screen Time gaps (outside Sprint #1 scope)

- Remaining Screen Time contract surfaces not included in bounded sprint.
- Full-system validation pass (beyond targeted sprint tests).
- Backend/device-enforcement phases remain deferred by contract.
