import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/earning_channel.dart';
import 'package:family_os/core/policy/policy_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('E-1 Minutes-only currency', () {
    test('PolicyEngine APIs deal only in Minutes', () {
      final reward = Minutes(20);
      final deposited = PolicyEngine.depositOnApproval(reward: reward);
      expect(deposited, isA<Minutes>());
      expect(deposited, reward);
    });
  });

  group('E-2 father sets reward — no invented defaults', () {
    test('child receives exactly fatherSetReward', () {
      final fatherSet = Minutes(42);
      final result = PolicyEngine.rewardForAssignee(
        assignee: AppRole.child,
        fatherSetReward: fatherSet,
      );
      expect(result, fatherSet);
      expect(result, isNot(Minutes(10))); // no system default
    });

    test('zero fatherSetReward is preserved for child', () {
      expect(
        PolicyEngine.rewardForAssignee(
          assignee: AppRole.child,
          fatherSetReward: Minutes.zero,
        ),
        Minutes.zero,
      );
    });
  });

  group('E-3 five protected earning channels', () {
    test('catalog has exactly five channels', () {
      expect(EarningChannel.values, hasLength(5));
      expect(EarningChannel.values.toSet(), {
        EarningChannel.quranPortion,
        EarningChannel.athkar,
        EarningChannel.learningChallenge,
        EarningChannel.familyTaskChild,
        EarningChannel.conditionalAppUnlock,
      });
    });
  });

  group('E-4 mother tasks carry no minutes', () {
    test('mother assignee returns null (no minutes path)', () {
      expect(
        PolicyEngine.rewardForAssignee(
          assignee: AppRole.mother,
          fatherSetReward: Minutes(30),
        ),
        isNull,
      );
    });

    test('father assignee returns null (not an earning role)', () {
      expect(
        PolicyEngine.rewardForAssignee(
          assignee: AppRole.father,
          fatherSetReward: Minutes(30),
        ),
        isNull,
      );
    });

    test('child assignee returns fatherSetReward', () {
      expect(
        PolicyEngine.rewardForAssignee(
          assignee: AppRole.child,
          fatherSetReward: Minutes(30),
        ),
        Minutes(30),
      );
    });
  });

  group('E-5 instant approval deposit', () {
    test('deposit equals reward exactly', () {
      final reward = Minutes(15);
      expect(PolicyEngine.depositOnApproval(reward: reward), reward);
    });

    test('deposit of zero is zero', () {
      expect(
        PolicyEngine.depositOnApproval(reward: Minutes.zero),
        Minutes.zero,
      );
    });
  });

  group('ChildId', () {
    test('wraps opaque key', () {
      final id = ChildId('k1');
      expect(id.value, 'k1');
      expect(id, ChildId('k1'));
      expect(id, isNot(ChildId('k2')));
    });

    test('rejects empty', () {
      expect(() => ChildId(''), throwsArgumentError);
      expect(() => ChildId('   '), throwsArgumentError);
    });
  });
}
