import 'dart:async';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/features/quran/quran_recitation_models.dart';

/// Rule 25 seam — child submit → father FAT-072 pending (P15-QUR-003 · P12).
abstract class QuranRecitationRepository {
  Future<QuranRecitationSubmission> submit(
    QuranRecitationSubmitRequest request,
  );

  Future<QuranRecitationSubmission?> latestForChild(ChildId childId);

  Future<QuranRecitationSubmission?> latestPending();

  Future<QuranRecitationSubmission> approve(String id);

  Stream<QuranRecitationSubmission> get submissions;
}

final class InMemoryQuranRecitationRepository
    implements QuranRecitationRepository {
  InMemoryQuranRecitationRepository({List<QuranRecitationSubmission>? seed})
    : _items = List<QuranRecitationSubmission>.from(seed ?? const []);

  final List<QuranRecitationSubmission> _items;
  final _controller = StreamController<QuranRecitationSubmission>.broadcast();
  var _seq = 0;

  @override
  Stream<QuranRecitationSubmission> get submissions => _controller.stream;

  @override
  Future<QuranRecitationSubmission?> latestForChild(ChildId childId) async {
    final forChild = _items.where((s) => s.childId == childId).toList();
    if (forChild.isEmpty) return null;
    return forChild.last;
  }

  @override
  Future<QuranRecitationSubmission?> latestPending() async {
    for (var i = _items.length - 1; i >= 0; i--) {
      if (_items[i].status == QuranRecitationSubmitStatus.pending) {
        return _items[i];
      }
    }
    return null;
  }

  @override
  Future<QuranRecitationSubmission> submit(
    QuranRecitationSubmitRequest request,
  ) async {
    _seq += 1;
    final row = QuranRecitationSubmission(
      id: 'recitation_$_seq',
      childId: request.childId,
      surahKey: request.surahKey,
      status: QuranRecitationSubmitStatus.pending,
      rewardMinutes: request.rewardMinutes,
      submittedAt: DateTime.now().toUtc(),
      fromAyah: request.fromAyah,
      toAyah: request.toAyah,
    );
    _items.add(row);
    _controller.add(row);
    return row;
  }

  @override
  Future<QuranRecitationSubmission> approve(String id) async {
    final i = _items.indexWhere((s) => s.id == id);
    if (i < 0) {
      throw StateError('Unknown recitation id: $id');
    }
    final updated = _items[i].copyWith(
      status: QuranRecitationSubmitStatus.approved,
    );
    _items[i] = updated;
    _controller.add(updated);
    return updated;
  }

  void seed(List<QuranRecitationSubmission> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  void dispose() {
    _controller.close();
  }
}

/// Shared Stage-1 singleton — DI swap later (Rule 25).
final InMemoryQuranRecitationRepository stage1QuranRecitationRepository =
    InMemoryQuranRecitationRepository();

QuranRecitationSubmission quranRecitationFixture({
  String childKey = 'child_a',
  String surahKey = 'naba',
  int reward = 30,
  QuranRecitationSubmitStatus status = QuranRecitationSubmitStatus.pending,
}) {
  return QuranRecitationSubmission(
    id: 'fixture_recitation_1',
    childId: ChildId(childKey),
    surahKey: surahKey,
    status: status,
    rewardMinutes: Minutes(reward),
    submittedAt: DateTime.utc(2026, 9, 23),
  );
}
