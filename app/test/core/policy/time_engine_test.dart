import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/policy/time_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final child = ChildId('k1');

  TimeContext ctx({
    bool instantLock = false,
    bool permanentlyBlocked = false,
    bool modeActive = false,
    bool appAllowedInMode = true,
    bool hasModeException = false,
    bool dailyLimitExhausted = false,
    Minutes earnedBalance = Minutes.zero,
    bool dailyCapIncludesWallet = true,
    bool allowWalletOverflow = false,
  }) {
    return TimeContext(
      childId: child,
      instantLock: instantLock,
      permanentlyBlocked: permanentlyBlocked,
      modeActive: modeActive,
      appAllowedInMode: appAllowedInMode,
      hasModeException: hasModeException,
      dailyLimitExhausted: dailyLimitExhausted,
      earnedBalance: earnedBalance,
      dailyCapIncludesWallet: dailyCapIncludesWallet,
      allowWalletOverflow: allowWalletOverflow,
    );
  }

  group('Priority ladder', () {
    test('instant lock denies above everything', () {
      final q = ctx(
        instantLock: true,
        permanentlyBlocked: true,
        modeActive: true,
        appAllowedInMode: false,
        dailyLimitExhausted: true,
        earnedBalance: Minutes(60),
        allowWalletOverflow: true,
      );
      expect(TimeEngine.resolve(q), AppAccess.deniedLock);
      expect(TimeEngine.canUse(q), isFalse);
    });

    test('permanent block after lock clears', () {
      final q = ctx(
        permanentlyBlocked: true,
        earnedBalance: Minutes(60),
        allowWalletOverflow: true,
      );
      expect(TimeEngine.resolve(q), AppAccess.deniedBlocked);
    });

    test('active mode denies when app not allowed and no exception', () {
      final q = ctx(
        modeActive: true,
        appAllowedInMode: false,
        hasModeException: false,
        earnedBalance: Minutes(30),
      );
      expect(TimeEngine.resolve(q), AppAccess.deniedMode);
    });

    test('mode exception allows past mode gate (Ruling A)', () {
      final q = ctx(
        modeActive: true,
        appAllowedInMode: false,
        hasModeException: true,
      );
      expect(TimeEngine.resolve(q), AppAccess.allowed);
    });

    test('allowed-in-mode still passes when limit remains', () {
      final q = ctx(
        modeActive: true,
        appAllowedInMode: true,
        dailyLimitExhausted: false,
      );
      expect(TimeEngine.resolve(q), AppAccess.allowed);
    });

    test('daily cap denial when exhausted and no overflow', () {
      final q = ctx(
        dailyLimitExhausted: true,
        earnedBalance: Minutes(20),
        dailyCapIncludesWallet: true,
        allowWalletOverflow: false,
      );
      expect(TimeEngine.resolve(q), AppAccess.deniedCap);
    });

    test('earned balance opens when overflow allowed', () {
      final q = ctx(
        dailyLimitExhausted: true,
        earnedBalance: Minutes(20),
        allowWalletOverflow: true,
      );
      expect(TimeEngine.resolve(q), AppAccess.allowed);
    });

    test('overflow allowed but empty wallet → deniedNoBalance', () {
      final q = ctx(
        dailyLimitExhausted: true,
        earnedBalance: Minutes.zero,
        allowWalletOverflow: true,
      );
      expect(TimeEngine.resolve(q), AppAccess.deniedNoBalance);
    });
  });

  group('Ruling A — blocked never opens via balance', () {
    test('blocked ignores large balance and overflow', () {
      final q = ctx(
        permanentlyBlocked: true,
        dailyLimitExhausted: true,
        earnedBalance: Minutes(999),
        allowWalletOverflow: true,
        dailyCapIncludesWallet: false,
      );
      expect(TimeEngine.resolve(q), AppAccess.deniedBlocked);
      expect(TimeEngine.canUse(q), isFalse);
    });

    test('mode without exception ignores balance', () {
      final q = ctx(
        modeActive: true,
        appAllowedInMode: false,
        earnedBalance: Minutes(100),
        allowWalletOverflow: true,
      );
      expect(TimeEngine.resolve(q), AppAccess.deniedMode);
    });
  });

  group('Ruling B — dailyCapIncludesWallet + allowWalletOverflow', () {
    test('defaults: cap includes wallet, overflow off → deniedCap', () {
      final q = ctx(dailyLimitExhausted: true, earnedBalance: Minutes(15));
      expect(q.dailyCapIncludesWallet, isTrue);
      expect(q.allowWalletOverflow, isFalse);
      expect(TimeEngine.resolve(q), AppAccess.deniedCap);
    });

    test('allowWalletOverflow true opens with balance', () {
      final q = ctx(
        dailyLimitExhausted: true,
        earnedBalance: Minutes(15),
        allowWalletOverflow: true,
      );
      expect(TimeEngine.canUse(q), isTrue);
    });

    test('wallet outside cap can open without overflow switch', () {
      final q = ctx(
        dailyLimitExhausted: true,
        earnedBalance: Minutes(15),
        dailyCapIncludesWallet: false,
        allowWalletOverflow: false,
      );
      expect(TimeEngine.resolve(q), AppAccess.allowed);
    });

    test('wallet outside cap still needs balance', () {
      final q = ctx(
        dailyLimitExhausted: true,
        earnedBalance: Minutes.zero,
        dailyCapIncludesWallet: false,
      );
      expect(TimeEngine.resolve(q), AppAccess.deniedNoBalance);
    });
  });

  group('Ruling D — perChild > shared > default', () {
    test('perChild wins over shared and default', () {
      expect(
        SettingSpecificity.resolve<int>(
          perChild: 30,
          shared: 60,
          defaultValue: 90,
        ),
        30,
      );
    });

    test('shared wins when perChild absent', () {
      expect(SettingSpecificity.resolve<int>(shared: 60, defaultValue: 90), 60);
    });

    test('default when neither set', () {
      expect(SettingSpecificity.resolve<bool>(defaultValue: true), isTrue);
    });

    test('resolved overflow flag feeds TimeEngine', () {
      final overflow = SettingSpecificity.resolve<bool>(
        perChild: true,
        shared: false,
        defaultValue: false,
      );
      final q = ctx(
        dailyLimitExhausted: true,
        earnedBalance: Minutes(10),
        allowWalletOverflow: overflow,
      );
      expect(TimeEngine.canUse(q), isTrue);
    });
  });

  group('Happy path', () {
    test('no restrictions → allowed', () {
      expect(TimeEngine.resolve(ctx()), AppAccess.allowed);
      expect(TimeEngine.canUse(ctx()), isTrue);
    });
  });
}
