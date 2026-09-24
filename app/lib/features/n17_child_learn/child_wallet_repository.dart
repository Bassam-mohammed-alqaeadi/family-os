import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:family_os/features/n03_screen_time/child_screen_time_screen.dart'
    show stage1PolicyPrefsStore;
import 'package:family_os/features/n03_screen_time/stage1_child_scope.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_models.dart';

abstract class ChildWalletRepository {
  Future<ChildWalletSnapshot> load();
}

/// Stage-1 childId for wallet surfaces (same demo child as FAT-032).
final ChildId kStage1WalletChildId = activeScopedChildId();

/// Loads per-app earned [Minutes] from [ScreenTimePolicy] / [WalletLedger].
///
/// Does **not** invent a free wallet — only AppWallet balances from policy.
final class PolicyChildWalletRepository implements ChildWalletRepository {
  PolicyChildWalletRepository({
    ScreenTimePolicyRepository? policyRepository,
    WalletLedger? walletLedger,
    ChildId? childId,
    List<ChildWalletBadge>? prestigeBadges,
  })  : _policy = policyRepository ??
            PrefsScreenTimePolicyRepository(stage1PolicyPrefsStore),
        _ledger = walletLedger,
        _childId = childId ?? activeScopedChildId(),
        _badges = prestigeBadges ?? _defaultPrestigeBadges;

  final ScreenTimePolicyRepository _policy;
  final WalletLedger? _ledger;
  final ChildId _childId;
  final List<ChildWalletBadge> _badges;

  Future<void> Function()? loadGate;

  @override
  Future<ChildWalletSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();

    final policy = await _policy.load(_childId);
    final ledger = _ledger ?? WalletLedger(_policy);

    final apps = <ChildWalletApp>[];
    var total = 0;
    for (final w in policy.wallets) {
      final balance = await ledger.balance(childId: _childId, appId: w.appId);
      final mins = balance.inMinutes;
      total += mins;
      apps.add(
        ChildWalletApp(
          id: w.appId,
          nameKey: _nameKeyFor(w.appId),
          iconKey: w.appId,
          walletMinutes: mins,
        ),
      );
    }

    return ChildWalletSnapshot(
      totalMinutes: total,
      streakDays: 0,
      recordStreakDays: 0,
      apps: apps,
      badges: List<ChildWalletBadge>.from(_badges),
      simulated: true,
    );
  }

  static String _nameKeyFor(String appId) {
    final id = appId.trim().toLowerCase();
    if (id == 'youtube' || id.startsWith('yt')) return 'youtube';
    if (id == 'games' || id == 'gaming') return 'games';
    if (id == 'social' || id == 'chat') return 'social';
    if (id == 'quran' || EducationAppIds.isEducation(id)) return 'quran';
    return id;
  }
}

final class InMemoryChildWalletRepository implements ChildWalletRepository {
  InMemoryChildWalletRepository({ChildWalletSnapshot? seed})
    : _snap = seed ?? childWalletPrototypeFixture();

  ChildWalletSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildWalletSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return ChildWalletSnapshot(
      totalMinutes: _snap.totalMinutes,
      streakDays: _snap.streakDays,
      recordStreakDays: _snap.recordStreakDays,
      apps: List<ChildWalletApp>.from(_snap.apps),
      badges: List<ChildWalletBadge>.from(_snap.badges),
      simulated: _snap.simulated,
    );
  }

  void seed(ChildWalletSnapshot snap) => _snap = snap;
}

final ChildWalletRepository stage1ChildWalletRepository =
    PolicyChildWalletRepository();

const List<ChildWalletBadge> _defaultPrestigeBadges = [
  ChildWalletBadge(id: 'b1', labelKey: 'firstWird', earned: true),
  ChildWalletBadge(id: 'b2', labelKey: 'adhkarWeek', earned: true),
  ChildWalletBadge(id: 'b3', labelKey: 'focusFive', earned: true),
  ChildWalletBadge(id: 'b4', labelKey: 'monthStreak', earned: false),
  ChildWalletBadge(id: 'b5', labelKey: 'familyHero', earned: false),
];

ChildWalletSnapshot childWalletEmptyFixture() =>
    const ChildWalletSnapshot(simulated: true);

ChildWalletSnapshot childWalletOneFixture() {
  return const ChildWalletSnapshot(
    totalMinutes: 45,
    streakDays: 3,
    recordStreakDays: 9,
    apps: [
      ChildWalletApp(
        id: 'youtube',
        nameKey: 'youtube',
        iconKey: 'yt',
        walletMinutes: 45,
      ),
    ],
    badges: [ChildWalletBadge(id: 'b1', labelKey: 'firstWird', earned: true)],
    simulated: true,
  );
}

ChildWalletSnapshot childWalletPrototypeFixture() {
  return const ChildWalletSnapshot(
    totalMinutes: 95,
    streakDays: 5,
    recordStreakDays: 9,
    apps: [
      ChildWalletApp(
        id: 'youtube',
        nameKey: 'youtube',
        iconKey: 'yt',
        walletMinutes: 40,
      ),
      ChildWalletApp(
        id: 'games',
        nameKey: 'games',
        iconKey: 'games',
        walletMinutes: 30,
      ),
      ChildWalletApp(
        id: 'social',
        nameKey: 'social',
        iconKey: 'social',
        walletMinutes: 25,
      ),
    ],
    badges: [
      ChildWalletBadge(id: 'b1', labelKey: 'firstWird', earned: true),
      ChildWalletBadge(id: 'b2', labelKey: 'adhkarWeek', earned: true),
      ChildWalletBadge(id: 'b3', labelKey: 'focusFive', earned: true),
      ChildWalletBadge(id: 'b4', labelKey: 'monthStreak', earned: false),
      ChildWalletBadge(id: 'b5', labelKey: 'familyHero', earned: false),
    ],
    simulated: true,
  );
}
