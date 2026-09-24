import 'dart:async';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';

/// Rule 25 seam — father publish → child Learn reflects (P15-EDU-002 · P12).
abstract class LearningAssignmentRepository {
  Future<List<LearningAssignment>> listForChild(ChildId childId);

  Future<LearningAssignment?> latestForChild(ChildId childId);

  Future<LearningAssignment> publish(LearningAssignmentPublishRequest request);

  /// Same-session parent→child notify (Family Link–style).
  Stream<LearningAssignment> get assignments;
}

final class InMemoryLearningAssignmentRepository
    implements LearningAssignmentRepository {
  InMemoryLearningAssignmentRepository({List<LearningAssignment>? seed})
    : _items = List<LearningAssignment>.from(seed ?? const []);

  final List<LearningAssignment> _items;
  final _controller = StreamController<LearningAssignment>.broadcast();
  var _seq = 0;

  @override
  Stream<LearningAssignment> get assignments => _controller.stream;

  @override
  Future<List<LearningAssignment>> listForChild(ChildId childId) async {
    return _items.where((a) => a.childId == childId).toList(growable: false);
  }

  @override
  Future<LearningAssignment?> latestForChild(ChildId childId) async {
    final forChild = await listForChild(childId);
    if (forChild.isEmpty) return null;
    return forChild.last;
  }

  @override
  Future<LearningAssignment> publish(
    LearningAssignmentPublishRequest request,
  ) async {
    _seq += 1;
    final assignment = LearningAssignment(
      id: 'assign_$_seq',
      childId: request.childId,
      titleKey: request.titleKey,
      rewardMinutes: request.rewardMinutes,
      source: request.source,
      assignedAt: DateTime.now().toUtc(),
      ctaScreenId: request.ctaScreenId,
      materialKindKey: request.materialKindKey,
    );
    _items.add(assignment);
    _controller.add(assignment);
    return assignment;
  }

  void seed(List<LearningAssignment> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  void dispose() {
    _controller.close();
  }
}

/// Shared Stage-1 singleton — DI swap later (Rule 25).
final InMemoryLearningAssignmentRepository stage1LearningAssignmentRepository =
    InMemoryLearningAssignmentRepository();

LearningAssignment learningAssignmentFixture({
  String childKey = 'child_a',
  int reward = 35,
}) {
  return LearningAssignment(
    id: 'fixture_1',
    childId: ChildId(childKey),
    titleKey: 'assignedChallenge',
    rewardMinutes: Minutes(reward),
    source: LearningAssignmentSource.attribution,
    assignedAt: DateTime.utc(2026, 9, 22),
  );
}
