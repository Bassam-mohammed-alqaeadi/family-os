import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/policy/app_access_rules.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/time_engine.dart';

void main() {
  final child = ChildId('demo-child');
  final base = TimeContext(
    childId: child,
    dailyLimitExhausted: true,
    earnedBalance: Minutes(20),
  );
  final policy = ScreenTimePolicy(dailyCapMinutes: 60, usedMinutesToday: 60);

  test('blocked rule maps to permanentlyBlocked (wallet cannot open)', () {
    final rule = AppAccessRule(appId: 'game', blocked: true);
    final ctx = AppAccessRuleQuery.applyRule(
      base: base,
      rule: rule,
      policy: policy,
      temporaryGrantRemaining: 0,
    );
    expect(TimeEngine.resolve(ctx), AppAccess.deniedBlocked);
  });

  test('unlimited bypasses daily cap only', () {
    final rule = AppAccessRule(appId: 'game', unlimited: true);
    final ctx = AppAccessRuleQuery.applyRule(
      base: base,
      rule: rule,
      policy: policy,
      temporaryGrantRemaining: 0,
    );
    expect(ctx.dailyLimitExhausted, isFalse);
    expect(TimeEngine.resolve(ctx), AppAccess.allowed);
  });

  test('temporary grant remaining clears cap exhaustion input', () {
    final rule = AppAccessRule(appId: 'game');
    final ctx = AppAccessRuleQuery.applyRule(
      base: base,
      rule: rule,
      policy: policy,
      temporaryGrantRemaining: 10,
    );
    expect(ctx.dailyLimitExhausted, isFalse);
  });
}
