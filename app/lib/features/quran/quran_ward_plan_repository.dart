import 'dart:async';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/features/quran/quran_ward_plan_models.dart';

/// Rule 25 seam — father publish ward plan → child CHD-025 binds (P15-QUR-002).
abstract class QuranWardPlanRepository {
  Future<QuranWardPlan?> latestForChild(ChildId childId);

  Future<QuranWardPlan> publish(QuranWardPlanPublishRequest request);

  Stream<QuranWardPlan> get plans;
}

final class InMemoryQuranWardPlanRepository implements QuranWardPlanRepository {
  InMemoryQuranWardPlanRepository({List<QuranWardPlan>? seed})
    : _items = List<QuranWardPlan>.from(seed ?? const []);

  final List<QuranWardPlan> _items;
  final _controller = StreamController<QuranWardPlan>.broadcast();
  var _seq = 0;

  @override
  Stream<QuranWardPlan> get plans => _controller.stream;

  @override
  Future<QuranWardPlan?> latestForChild(ChildId childId) async {
    final forChild = _items.where((p) => p.childId == childId).toList();
    if (forChild.isEmpty) return null;
    return forChild.last;
  }

  @override
  Future<QuranWardPlan> publish(QuranWardPlanPublishRequest request) async {
    _seq += 1;
    final plan = QuranWardPlan(
      id: 'ward_plan_$_seq',
      childId: request.childId,
      surahKey: request.surahKey,
      fromAyah: request.fromAyah,
      toAyah: request.toAyah,
      reciterKey: request.reciterKey,
      rewardMinutes: request.rewardMinutes,
      publishedAt: DateTime.now().toUtc(),
      ayahKey: request.ayahKey,
    );
    _items.add(plan);
    _controller.add(plan);
    return plan;
  }

  void seed(List<QuranWardPlan> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  void dispose() {
    _controller.close();
  }
}

/// Shared Stage-1 singleton — DI swap later (Rule 25).
final InMemoryQuranWardPlanRepository stage1QuranWardPlanRepository =
    InMemoryQuranWardPlanRepository();

QuranWardPlan quranWardPlanFixture({
  String childKey = 'child_a',
  String surahKey = 'naba',
  int reward = 30,
}) {
  return QuranWardPlan(
    id: 'fixture_ward_1',
    childId: ChildId(childKey),
    surahKey: surahKey,
    fromAyah: 1,
    toAyah: 40,
    reciterKey: 'defaultReciter',
    rewardMinutes: Minutes(reward),
    publishedAt: DateTime.utc(2026, 9, 23),
    ayahKey: surahKey == 'mulk' ? 'mulk16' : 'naba1',
  );
}
