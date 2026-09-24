import 'dart:async';

import 'package:family_os/features/education/approved_pack_models.dart';
import 'package:family_os/features/n14_studio/preview_approve_models.dart';

/// Rule 25 seam — father approve/reject persists pack for child (P15-EDU-004).
abstract class ApprovedPackRepository {
  Future<ApprovedLearningPack?> latest();

  Future<ApprovedLearningPack?> latestApproved();

  Future<ApprovedLearningPack> approve(PreviewApproveSnapshot snap);

  Future<ApprovedLearningPack> reject();

  Stream<ApprovedLearningPack> get packs;
}

final class InMemoryApprovedPackRepository implements ApprovedPackRepository {
  InMemoryApprovedPackRepository({ApprovedLearningPack? seed}) : _latest = seed;

  ApprovedLearningPack? _latest;
  final _controller = StreamController<ApprovedLearningPack>.broadcast();
  var _seq = 0;

  @override
  Stream<ApprovedLearningPack> get packs => _controller.stream;

  @override
  Future<ApprovedLearningPack?> latest() async => _latest;

  @override
  Future<ApprovedLearningPack?> latestApproved() async {
    final pack = _latest;
    if (pack == null || !pack.isApproved) return null;
    return pack;
  }

  @override
  Future<ApprovedLearningPack> approve(PreviewApproveSnapshot snap) async {
    if (snap.questions.isEmpty) {
      throw StateError('Cannot approve an empty quiz pack');
    }
    _seq += 1;
    final pack = ApprovedLearningPack(
      id: 'pack_$_seq',
      status: ApprovedPackStatus.approved,
      quizTitleKey: snap.quizTitleKey,
      lessonTitleKey: snap.lessonTitleKey,
      questions: List<PreviewQuizQuestion>.from(snap.questions),
      lesson: snap.lesson,
      difficulty: snap.difficulty,
      updatedAt: DateTime.now().toUtc(),
    );
    _latest = pack;
    _controller.add(pack);
    return pack;
  }

  @override
  Future<ApprovedLearningPack> reject() async {
    _seq += 1;
    final pack = ApprovedLearningPack(
      id: 'pack_$_seq',
      status: ApprovedPackStatus.rejected,
      quizTitleKey: 'quiz',
      lessonTitleKey: 'lesson',
      questions: const [],
      updatedAt: DateTime.now().toUtc(),
    );
    _latest = pack;
    _controller.add(pack);
    return pack;
  }

  void seed(ApprovedLearningPack? pack) {
    _latest = pack;
  }

  void dispose() {
    _controller.close();
  }
}

/// Shared Stage-1 singleton — DI swap later (Rule 25).
final InMemoryApprovedPackRepository stage1ApprovedPackRepository =
    InMemoryApprovedPackRepository();
