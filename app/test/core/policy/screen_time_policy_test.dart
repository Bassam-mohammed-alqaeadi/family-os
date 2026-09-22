import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/screen_time_policy_query.dart';
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/core/policy/time_engine.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final child = ChildId('c1');

  group('ScreenTimePolicy defaults & S-1', () {
    test('allowWalletOverflow defaults false (Ruling B)', () {
      final policy = ScreenTimePolicy.defaults();
      expect(policy.allowWalletOverflow, isFalse);
    });

    test('education app cannot be marked countable=true', () {
      final quran = AppWallet(
        appId: 'quran',
        earnedMinutes: Minutes(10),
        countable: true,
      );
      expect(quran.countable, isFalse);

      final edu = AppWallet(
        appId: 'edu_math',
        earnedMinutes: Minutes(5),
        countable: true,
      );
      expect(edu.countable, isFalse);
      expect(EducationAppIds.isEducation('quran'), isTrue);
      expect(EducationAppIds.isEducation('edu_science'), isTrue);
      expect(EducationAppIds.isEducation('games'), isFalse);
    });
  });

  group('PrefsScreenTimePolicyRepository restart', () {
    test('cap + wallets persist across new repo instance', () async {
      final shared = <String, String>{};
      final store = MemoryScreenTimePolicyPrefsStore(shared);
      final repo1 = PrefsScreenTimePolicyRepository(store);

      final policy = ScreenTimePolicy(
        dailyCapMinutes: 90,
        allowWalletOverflow: true,
        usedMinutesToday: 30,
        wallets: [
          AppWallet(appId: 'games', earnedMinutes: Minutes(15)),
          AppWallet(appId: 'youtube', earnedMinutes: Minutes(5)),
          AppWallet(appId: 'quran', earnedMinutes: Minutes(20)),
        ],
      );
      await repo1.save(child, policy);

      final repo2 = PrefsScreenTimePolicyRepository(
        MemoryScreenTimePolicyPrefsStore(shared),
      );
      final loaded = await repo2.load(child);
      expect(loaded.dailyCapMinutes, 90);
      expect(loaded.allowWalletOverflow, isTrue);
      expect(loaded.usedMinutesToday, 30);
      expect(loaded.walletFor('games')!.earnedMinutes, Minutes(15));
      expect(loaded.walletFor('quran')!.countable, isFalse);
    });
  });

  group('InMemoryScreenTimePolicyRepository Rule 25', () {
    test('InMemory alternate compiles and round-trips', () async {
      final repo = InMemoryScreenTimePolicyRepository();
      await repo.save(
        child,
        ScreenTimePolicy(
          dailyCapMinutes: 60,
          wallets: [
            AppWallet(appId: 'games', earnedMinutes: Minutes(8)),
          ],
        ),
      );
      final loaded = await repo.load(child);
      expect(loaded.dailyCapMinutes, 60);
      expect(loaded.walletFor('games')!.earnedMinutes, Minutes(8));
      expect(loaded.allowWalletOverflow, isFalse);
    });
  });

  group('WalletLedger Rule 5', () {
    test('earn deposits via PolicyEngine for child only', () async {
      final repo = InMemoryScreenTimePolicyRepository();
      final ledger = WalletLedger(repo);

      final deposited = await ledger.earn(
        childId: child,
        appId: 'games',
        assignee: AppRole.child,
        fatherSetReward: Minutes(12),
      );
      expect(deposited, Minutes(12));
      expect(await ledger.balance(childId: child, appId: 'games'), Minutes(12));

      final mother = await ledger.earn(
        childId: child,
        appId: 'games',
        assignee: AppRole.mother,
        fatherSetReward: Minutes(50),
      );
      expect(mother, Minutes.zero);
      expect(await ledger.balance(childId: child, appId: 'games'), Minutes(12));
    });
  });

  group('ScreenTimePolicyQuery → TimeEngine', () {
    test('permanentlyBlocked + wallet balance → deniedBlocked (Ruling A)', () {
      final policy = ScreenTimePolicy(
        dailyCapMinutes: 60,
        allowWalletOverflow: true,
        usedMinutesToday: 60,
        wallets: [
          AppWallet(appId: 'games', earnedMinutes: Minutes(99)),
        ],
      );
      final ctx = ScreenTimePolicyQuery.timeContextFromPolicy(
        base: TimeContext(
          childId: child,
          permanentlyBlocked: true,
        ),
        policy: policy,
        appId: 'games',
      );
      expect(ctx.earnedBalance, Minutes(99));
      expect(TimeEngine.resolve(ctx), AppAccess.deniedBlocked);
    });

    test('cap exhausted + overflow false + zero wallet → deniedCap', () {
      final policy = ScreenTimePolicy(
        dailyCapMinutes: 60,
        allowWalletOverflow: false,
        usedMinutesToday: 60,
        wallets: [
          AppWallet(appId: 'games', earnedMinutes: Minutes.zero),
        ],
      );
      final ctx = ScreenTimePolicyQuery.timeContextFromPolicy(
        base: TimeContext(childId: child),
        policy: policy,
        appId: 'games',
      );
      expect(ctx.dailyLimitExhausted, isTrue);
      expect(TimeEngine.resolve(ctx), AppAccess.deniedCap);
    });

    test('cap exhausted + overflow true + wallet >0 → allowed', () {
      final policy = ScreenTimePolicy(
        dailyCapMinutes: 60,
        allowWalletOverflow: true,
        usedMinutesToday: 90,
        wallets: [
          AppWallet(appId: 'games', earnedMinutes: Minutes(20)),
        ],
      );
      final ctx = ScreenTimePolicyQuery.timeContextFromPolicy(
        base: TimeContext(childId: child),
        policy: policy,
        appId: 'games',
      );
      expect(TimeEngine.resolve(ctx), AppAccess.allowed);
    });

    test('education app does not exhaust daily cap', () {
      final policy = ScreenTimePolicy(
        dailyCapMinutes: 30,
        allowWalletOverflow: false,
        usedMinutesToday: 30,
        wallets: [
          AppWallet(appId: 'quran', earnedMinutes: Minutes.zero),
        ],
      );
      final ctx = ScreenTimePolicyQuery.timeContextFromPolicy(
        base: TimeContext(childId: child),
        policy: policy,
        appId: 'quran',
      );
      expect(ctx.dailyLimitExhausted, isFalse);
      expect(TimeEngine.resolve(ctx), AppAccess.allowed);
    });
  });

  /// SET-024 — Ruling B wallet overflow (formal gap closure).
  ///
  /// Clamp semantics (documented): WalletLedger deposits are **not** clamped
  /// when overflow is off. TimeEngine returns [AppAccess.deniedCap] so earned
  /// minutes cannot open an app past the daily cap until overflow is ON.
  group('SET-024 Ruling B — wallet overflow acceptance', () {
    test('1. default false on new child policy', () {
      expect(ScreenTimePolicy.defaults().allowWalletOverflow, isFalse);
      expect(ScreenTimePolicy().allowWalletOverflow, isFalse);
    });

    test(
      '2. overflow OFF + cap exhausted + wallet >0 → deniedCap '
      '(cannot exceed daily cap; access deny, not deposit clamp)',
      () {
        final policy = ScreenTimePolicy(
          dailyCapMinutes: 60,
          allowWalletOverflow: false,
          usedMinutesToday: 60,
          wallets: [
            AppWallet(appId: 'games', earnedMinutes: Minutes(25)),
          ],
        );
        final ctx = ScreenTimePolicyQuery.timeContextFromPolicy(
          base: TimeContext(childId: child),
          policy: policy,
          appId: 'games',
        );
        expect(ctx.allowWalletOverflow, isFalse);
        expect(ctx.earnedBalance, Minutes(25));
        expect(ctx.dailyLimitExhausted, isTrue);
        expect(TimeEngine.resolve(ctx), AppAccess.deniedCap);
        expect(TimeEngine.canUse(ctx), isFalse);
      },
    );

    test('3. overflow ON + cap exhausted + wallet >0 → allowed via TimeEngine',
        () {
      final policy = ScreenTimePolicy(
        dailyCapMinutes: 60,
        allowWalletOverflow: true,
        usedMinutesToday: 90,
        wallets: [
          AppWallet(appId: 'games', earnedMinutes: Minutes(20)),
        ],
      );
      final ctx = ScreenTimePolicyQuery.timeContextFromPolicy(
        base: TimeContext(childId: child),
        policy: policy,
        appId: 'games',
      );
      expect(TimeEngine.resolve(ctx), AppAccess.allowed);
      expect(TimeEngine.canUse(ctx), isTrue);
    });

    test(
      '4. Ruling A: permanentlyBlocked + overflow ON + wallet → deniedBlocked',
      () {
        final policy = ScreenTimePolicy(
          dailyCapMinutes: 60,
          allowWalletOverflow: true,
          usedMinutesToday: 60,
          wallets: [
            AppWallet(appId: 'games', earnedMinutes: Minutes(99)),
          ],
        );
        final ctx = ScreenTimePolicyQuery.timeContextFromPolicy(
          base: TimeContext(childId: child, permanentlyBlocked: true),
          policy: policy,
          appId: 'games',
        );
        expect(ctx.allowWalletOverflow, isTrue);
        expect(TimeEngine.resolve(ctx), AppAccess.deniedBlocked);
      },
    );

    test(
      'earn may deposit past remaining cap; overflow OFF still denies use',
      () async {
        final repo = InMemoryScreenTimePolicyRepository({
          child.value: ScreenTimePolicy(
            dailyCapMinutes: 30,
            allowWalletOverflow: false,
            usedMinutesToday: 30,
            wallets: [
              AppWallet(appId: 'games', earnedMinutes: Minutes.zero),
            ],
          ),
        });
        final ledger = WalletLedger(repo);
        final deposited = await ledger.earn(
          childId: child,
          appId: 'games',
          assignee: AppRole.child,
          fatherSetReward: Minutes(40),
        );
        expect(deposited, Minutes(40));
        expect(await ledger.balance(childId: child, appId: 'games'), Minutes(40));

        final policy = await repo.load(child);
        final ctx = ScreenTimePolicyQuery.timeContextFromPolicy(
          base: TimeContext(childId: child),
          policy: policy,
          appId: 'games',
        );
        expect(TimeEngine.resolve(ctx), AppAccess.deniedCap);
      },
    );
  });
}
