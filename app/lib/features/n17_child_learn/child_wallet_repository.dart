import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/features/n03_screen_time/stage1_child_scope.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_models.dart';
import 'package:family_os/foundation_gate/child_minutes_balance_client.dart';

abstract class ChildWalletRepository {
  Future<ChildWalletSnapshot> load();
}

/// Stage-1 childId for wallet surfaces (same demo child as FAT-032).
final ChildId kStage1WalletChildId = activeScopedChildId();

/// CHD-019 — the child's wallet, read from the server. Nothing is computed on the device.
final class ServerChildWalletRepository implements ChildWalletRepository {
  ServerChildWalletRepository({required ChildMinutesBalanceClient client})
    : _client = client;

  final ChildMinutesBalanceClient _client;

  Future<void> Function()? loadGate;

  @override
  Future<ChildWalletSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();

    final balance = await _client.read();
    return ChildWalletSnapshot(
      totalMinutes: balance.total,
      // No server source for streaks or badges yet: they stay empty until real activity
      // provides them (owner ruling 2026-10-15). Never a fabricated number.
      streakDays: 0,
      recordStreakDays: 0,
      apps: [
        for (final app in balance.apps)
          ChildWalletApp(
            id: app.appId,
            nameKey: _nameKeyFor(app.appId),
            iconKey: app.appId,
            walletMinutes: app.minutes,
          ),
      ],
      badges: const [],
      simulated: false,
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
    : _snap = seed ?? childWalletEmptyFixture();

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
    ServerChildWalletRepository(
      client: ChildMinutesBalanceClient(
        transport: NativeChildMinutesBalanceTransport(),
      ),
    );

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
