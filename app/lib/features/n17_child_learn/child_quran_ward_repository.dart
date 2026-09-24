import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_models.dart';
import 'package:family_os/features/quran/quran_recitation_models.dart';
import 'package:family_os/features/quran/quran_recitation_repository.dart';
import 'package:family_os/features/quran/quran_ward_plan_repository.dart';

abstract class ChildQuranWardRepository {
  Future<ChildQuranWardSnapshot> load();
  Future<ChildQuranWardSnapshot> togglePlay();
  Future<ChildQuranWardSnapshot> submitRecitation();
}

final class InMemoryChildQuranWardRepository
    implements ChildQuranWardRepository {
  InMemoryChildQuranWardRepository({
    ChildQuranWardSnapshot? seed,
    QuranWardPlanRepository? plans,
    QuranRecitationRepository? recitations,
    ChildId? childId,
  }) : _snap = seed ?? childQuranWardPrototypeFixture(),
       _plans = plans ?? stage1QuranWardPlanRepository,
       _recitations = recitations ?? stage1QuranRecitationRepository,
       _childId = childId ?? ChildId('child_a');

  ChildQuranWardSnapshot _snap;
  final QuranWardPlanRepository _plans;
  final QuranRecitationRepository _recitations;
  final ChildId _childId;
  Future<void> Function()? loadGate;

  ChildWardRecitationStatus _statusFromLive(QuranRecitationSubmission? live) {
    if (live == null) return _snap.recitationStatus;
    return switch (live.status) {
      QuranRecitationSubmitStatus.pending => ChildWardRecitationStatus.sent,
      QuranRecitationSubmitStatus.approved =>
        ChildWardRecitationStatus.approved,
    };
  }

  @override
  Future<ChildQuranWardSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final plan = await _plans.latestForChild(_childId);
    final live = await _recitations.latestForChild(_childId);
    final status = _statusFromLive(live);
    if (plan == null) {
      return ChildQuranWardSnapshot(
        hasWard: _snap.hasWard,
        surahKey: _snap.surahKey,
        fromAyah: _snap.fromAyah,
        toAyah: _snap.toAyah,
        reciterKey: _snap.reciterKey,
        rewardMinutes: _snap.rewardMinutes,
        offlineReady: _snap.offlineReady,
        giftCount: _snap.giftCount,
        ayahKey: _snap.ayahKey,
        recitationStatus: status,
        playing: _snap.playing,
      );
    }
    // P15-QUR-002: live father plan overrides local fixture fields.
    return ChildQuranWardSnapshot(
      hasWard: true,
      surahKey: plan.surahKey,
      fromAyah: plan.fromAyah,
      toAyah: plan.toAyah,
      reciterKey: plan.reciterKey,
      rewardMinutes: plan.rewardMinutes.inMinutes,
      offlineReady: _snap.offlineReady,
      giftCount: _snap.giftCount,
      ayahKey: plan.ayahKey,
      recitationStatus: status,
      playing: _snap.playing,
    );
  }

  @override
  Future<ChildQuranWardSnapshot> togglePlay() async {
    _snap = _snap.copyWith(playing: !_snap.playing);
    return load();
  }

  @override
  Future<ChildQuranWardSnapshot> submitRecitation() async {
    final current = await load();
    await _recitations.submit(
      QuranRecitationSubmitRequest(
        childId: _childId,
        surahKey: current.surahKey,
        rewardMinutes: Minutes(current.rewardMinutes),
        fromAyah: current.fromAyah,
        toAyah: current.toAyah,
      ),
    );
    _snap = _snap.copyWith(
      recitationStatus: ChildWardRecitationStatus.sent,
      playing: false,
    );
    return load();
  }

  void seed(ChildQuranWardSnapshot snap) => _snap = snap;
}

final InMemoryChildQuranWardRepository stage1ChildQuranWardRepository =
    InMemoryChildQuranWardRepository();

ChildQuranWardSnapshot childQuranWardEmptyFixture() =>
    const ChildQuranWardSnapshot();

ChildQuranWardSnapshot childQuranWardOneFixture() {
  return const ChildQuranWardSnapshot(
    hasWard: true,
    giftCount: 0,
    recitationStatus: ChildWardRecitationStatus.none,
  );
}

ChildQuranWardSnapshot childQuranWardPrototypeFixture() {
  return const ChildQuranWardSnapshot(
    hasWard: true,
    surahKey: 'mulk',
    fromAyah: 1,
    toAyah: 30,
    rewardMinutes: 30,
    giftCount: 1,
    ayahKey: 'mulk16',
    recitationStatus: ChildWardRecitationStatus.sent,
  );
}
