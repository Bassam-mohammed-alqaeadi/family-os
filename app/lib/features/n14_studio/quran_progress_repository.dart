import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/active_child_resolver.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';
import 'package:family_os/features/n14_studio/quran_progress_models.dart';
import 'package:family_os/features/quran/quran_local_bridge.dart';
import 'package:family_os/features/quran/quran_recitation_models.dart';
import 'package:family_os/features/quran/quran_recitation_repository.dart';
import 'package:family_os/features/quran/quran_ward_plan_models.dart';
import 'package:family_os/features/quran/quran_ward_plan_repository.dart';

/// Play-wallet app id for Quran ward rewards (minutes-only · ع-١).
abstract final class QuranWalletApps {
  static const play = 'play';
}

abstract class QuranProgressRepository {
  Future<QuranProgressSnapshot> load();
  Future<QuranProgressSnapshot> togglePlay();
  Future<QuranProgressSnapshot> approveRecitation();
  Future<void> whisperEncourage();
  Future<void> requestDownload();

  /// P15-QUR-002 — cycle plan fields then ready to publish (ControlFit edit).
  Future<QuranProgressSnapshot> cyclePlanSurah();

  /// P15-QUR-002 — publish current ward plan → child CHD-025 (P12).
  Future<QuranWardPlan> publishPlanToChild({ChildId? childId});
}

final class InMemoryQuranProgressRepository implements QuranProgressRepository {
  InMemoryQuranProgressRepository({
    QuranProgressSnapshot? seed,
    QuranWardPlanRepository? plans,
    QuranRecitationRepository? recitations,
    WalletLedger? wallet,
    ChildId? childId,
    QuranLocalBridge? bridge,
  }) : _snap = seed ?? quranProgressEmptyFixture(),
       _plans = plans ?? stage1QuranWardPlanRepository,
       _recitations = recitations ?? stage1QuranRecitationRepository,
       _injectedWallet = wallet,
       _explicitChildId = childId,
       _bridgeOverride = bridge;

  QuranProgressSnapshot _snap;
  final QuranWardPlanRepository _plans;
  final QuranRecitationRepository _recitations;
  final WalletLedger? _injectedWallet;
  WalletLedger? _resolvedWallet;
  final ChildId? _explicitChildId;

  /// Null explicit id → family context's selected child at call time.
  ChildId get _childId => resolveActiveChildId(explicit: _explicitChildId);
  final QuranLocalBridge? _bridgeOverride;
  Future<void> Function()? loadGate;
  var whisperCount = 0;
  var downloadCount = 0;

  QuranLocalBridge get _bridge => _bridgeOverride ?? stage1QuranLocalBridge;

  Future<WalletLedger> _wallet() async {
    final injected = _injectedWallet;
    if (injected != null) return injected;
    return _resolvedWallet ??= WalletLedger(
      await ScreenTimeLocalPersistence.openPolicyRepository(),
    );
  }

  @override
  Future<QuranProgressSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    // P15-QUR-003: live child submit drives recitation card.
    final pending = await _recitations.latestPending();
    final latest = await _recitations.latestForChild(_childId);
    if (pending != null) {
      return _snap.copyWith(
        surahKey: pending.surahKey,
        fromAyah: pending.fromAyah,
        toAyah: pending.toAyah,
        rewardMinutes: pending.rewardMinutes.inMinutes,
        recitationStatus: QuranRecitationStatus.recorded,
        offlineReady: _bridge.offlineReady,
      );
    }
    if (latest?.status == QuranRecitationSubmitStatus.approved) {
      return _snap.copyWith(
        surahKey: latest!.surahKey,
        recitationStatus: QuranRecitationStatus.approved,
        offlineReady: _bridge.offlineReady,
      );
    }
    return _snap.copyWith(offlineReady: _bridge.offlineReady);
  }

  @override
  Future<QuranProgressSnapshot> togglePlay() async {
    _snap = _snap.copyWith(playingAudio: !_snap.playingAudio);
    return load();
  }

  @override
  Future<QuranProgressSnapshot> approveRecitation() async {
    final pending = await _recitations.latestPending();
    final reward = pending?.rewardMinutes ?? Minutes(_snap.rewardMinutes);
    if (pending != null) {
      await _recitations.approve(pending.id);
    }
    // Rule 5 — earn only through WalletLedger / PolicyEngine.
    if (reward.inMinutes > 0) {
      final wallet = await _wallet();
      await wallet.earn(
        childId: pending?.childId ?? _childId,
        appId: QuranWalletApps.play,
        assignee: AppRole.child,
        fatherSetReward: reward,
      );
    }
    final next = (_snap.completedAyahs + 5).clamp(0, _snap.toAyah);
    _snap = _snap.copyWith(
      completedAyahs: next,
      rewardMinutes: reward.inMinutes,
      recitationStatus: QuranRecitationStatus.approved,
      playingAudio: false,
    );
    return load();
  }

  @override
  Future<void> whisperEncourage() async {
    whisperCount++;
    // P15-QUR-007 — Local encourage for child ward (not remote delivery).
    _bridge.enqueueWhisper();
  }

  @override
  Future<void> requestDownload() async {
    downloadCount++;
    // P15-QUR-004 — Local offline-ready flag only (licensed audio REMOTE CLOSED).
    _bridge.markOfflineReady();
    _snap = _snap.copyWith(offlineReady: true);
  }

  @override
  Future<QuranProgressSnapshot> cyclePlanSurah() async {
    final nextSurah = _snap.surahKey == 'mulk' ? 'naba' : 'mulk';
    final toAyah = nextSurah == 'mulk' ? 30 : 40;
    _snap = _snap.copyWith(
      surahKey: nextSurah,
      fromAyah: 1,
      toAyah: toAyah,
      completedAyahs: _snap.completedAyahs.clamp(0, toAyah),
    );
    return _snap.copyWith();
  }

  @override
  Future<QuranWardPlan> publishPlanToChild({ChildId? childId}) async {
    final id = childId ?? _childId;
    final surah = _snap.surahKey ?? 'naba';
    return _plans.publish(
      QuranWardPlanPublishRequest(
        childId: id,
        surahKey: surah,
        fromAyah: _snap.fromAyah,
        toAyah: _snap.toAyah,
        reciterKey: _snap.reciterKey ?? 'defaultReciter',
        rewardMinutes: Minutes(_snap.rewardMinutes),
        ayahKey: surah == 'mulk' ? 'mulk16' : 'naba1',
      ),
    );
  }

  void seed(QuranProgressSnapshot snap) => _snap = snap;
}

final InMemoryQuranProgressRepository stage1QuranProgressRepository =
    InMemoryQuranProgressRepository();

QuranProgressSnapshot quranProgressEmptyFixture() =>
    const QuranProgressSnapshot();

QuranProgressSnapshot quranProgressOneFixture() {
  return const QuranProgressSnapshot(
    childNameKey: 'childOne',
    surahKey: 'naba',
    fromAyah: 1,
    toAyah: 40,
    completedAyahs: 12,
    reciterKey: 'defaultReciter',
    streakDays: 3,
    rewardMinutes: 30,
    offlineReady: true,
    audioSizeKey: 'size184',
    recitationStatus: QuranRecitationStatus.none,
  );
}

QuranProgressSnapshot quranProgressPrototypeFixture() {
  return const QuranProgressSnapshot(
    childNameKey: 'childOne',
    surahKey: 'naba',
    fromAyah: 1,
    toAyah: 40,
    completedAyahs: 27,
    reciterKey: 'defaultReciter',
    streakDays: 5,
    rewardMinutes: 30,
    offlineReady: true,
    audioSizeKey: 'size184',
    recitationStatus: QuranRecitationStatus.recorded,
  );
}
