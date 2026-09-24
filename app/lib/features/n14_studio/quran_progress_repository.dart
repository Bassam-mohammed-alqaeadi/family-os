import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:family_os/features/n03_screen_time/child_screen_time_screen.dart'
    show stage1PolicyPrefsStore;
import 'package:family_os/features/n14_studio/quran_progress_models.dart';
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
  }) : _snap = seed ?? quranProgressPrototypeFixture(),
       _plans = plans ?? stage1QuranWardPlanRepository,
       _recitations = recitations ?? stage1QuranRecitationRepository,
       _wallet =
           wallet ??
           WalletLedger(
             PrefsScreenTimePolicyRepository(stage1PolicyPrefsStore),
           ),
       _childId = childId ?? ChildId('child_a');

  QuranProgressSnapshot _snap;
  final QuranWardPlanRepository _plans;
  final QuranRecitationRepository _recitations;
  final WalletLedger _wallet;
  final ChildId _childId;
  Future<void> Function()? loadGate;
  var whisperCount = 0;
  var downloadCount = 0;

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
      );
    }
    if (latest?.status == QuranRecitationSubmitStatus.approved) {
      return _snap.copyWith(
        surahKey: latest!.surahKey,
        recitationStatus: QuranRecitationStatus.approved,
      );
    }
    return _snap.copyWith();
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
      await _wallet.earn(
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
  }

  @override
  Future<void> requestDownload() async {
    downloadCount++;
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
