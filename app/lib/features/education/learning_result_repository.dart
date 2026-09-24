import 'dart:async';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/features/education/learning_result_models.dart';

/// Rule 25 seam — child submit → father results inbox (P15-EDU-006 · P12).
abstract class LearningResultRepository {
  Future<LearningResultSubmission> submit(LearningResultSubmitRequest request);

  Future<List<LearningResultSubmission>> listRecent({int limit = 20});

  Stream<LearningResultSubmission> get submissions;
}

final class InMemoryLearningResultRepository
    implements LearningResultRepository {
  InMemoryLearningResultRepository({List<LearningResultSubmission>? seed})
    : _items = List<LearningResultSubmission>.from(seed ?? const []);

  final List<LearningResultSubmission> _items;
  final _controller = StreamController<LearningResultSubmission>.broadcast();
  var _seq = 0;

  @override
  Stream<LearningResultSubmission> get submissions => _controller.stream;

  @override
  Future<List<LearningResultSubmission>> listRecent({int limit = 20}) async {
    final sorted = List<LearningResultSubmission>.from(_items)
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    if (sorted.length <= limit) return sorted;
    return sorted.sublist(0, limit);
  }

  @override
  Future<LearningResultSubmission> submit(
    LearningResultSubmitRequest request,
  ) async {
    _seq += 1;
    final row = LearningResultSubmission(
      id: 'result_$_seq',
      childId: request.childId,
      kind: request.kind,
      titleKey: request.titleKey,
      submittedAt: DateTime.now().toUtc(),
      rewardMinutes: request.rewardMinutes,
      scoreCorrect: request.scoreCorrect,
      scoreTotal: request.scoreTotal,
    );
    _items.add(row);
    _controller.add(row);
    return row;
  }

  void seed(List<LearningResultSubmission> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  void dispose() {
    _controller.close();
  }
}

/// Shared Stage-1 singleton — DI swap later (Rule 25).
final InMemoryLearningResultRepository stage1LearningResultRepository =
    InMemoryLearningResultRepository();

LearningResultSubmission learningResultFixture({
  String childKey = 'child_a',
  int reward = 20,
}) {
  return LearningResultSubmission(
    id: 'fixture_result_1',
    childId: ChildId(childKey),
    kind: LearningResultKind.quiz,
    titleKey: 'quizSubmitted',
    submittedAt: DateTime.utc(2026, 9, 23),
    rewardMinutes: Minutes(reward),
    scoreCorrect: 1,
    scoreTotal: 1,
  );
}
