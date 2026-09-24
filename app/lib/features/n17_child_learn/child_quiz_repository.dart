import 'package:family_os/features/education/approved_pack_models.dart';
import 'package:family_os/features/education/approved_pack_repository.dart';
import 'package:family_os/features/n14_studio/preview_approve_models.dart';
import 'package:family_os/features/n17_child_learn/child_quiz_models.dart';

abstract class ChildQuizRepository {
  Future<ChildQuizSnapshot> load();
}

/// Merges father-approved pack when present (P15-EDU-004 · Rule 7).
final class InMemoryChildQuizRepository implements ChildQuizRepository {
  InMemoryChildQuizRepository({
    ChildQuizSnapshot? seed,
    ApprovedPackRepository? packs,
  }) : _snap = seed ?? childQuizPrototypeFixture(),
       _packs = packs ?? stage1ApprovedPackRepository;

  ChildQuizSnapshot _snap;
  final ApprovedPackRepository _packs;
  Future<void> Function()? loadGate;

  @override
  Future<ChildQuizSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final pack = await _packs.latestApproved();
    if (pack != null) {
      return _fromApprovedPack(pack);
    }
    return ChildQuizSnapshot(
      skillNameKey: _snap.skillNameKey,
      questions: List<ChildQuizQuestion>.from(_snap.questions),
      questionIndex: _snap.questionIndex,
      rewardMinutes: _snap.rewardMinutes,
      successScreenId: _snap.successScreenId,
    );
  }

  void seed(ChildQuizSnapshot snap) => _snap = snap;

  ChildQuizSnapshot _fromApprovedPack(ApprovedLearningPack pack) {
    return ChildQuizSnapshot(
      skillNameKey: 'approvedPack',
      rewardMinutes: _snap.rewardMinutes,
      successScreenId: _snap.successScreenId,
      questions: [for (final q in pack.questions) _mapQuestion(q)],
    );
  }

  ChildQuizQuestion _mapQuestion(PreviewQuizQuestion q) {
    return ChildQuizQuestion(
      id: q.id,
      promptKey: q.promptKey,
      explanationKey: 'approvedExplain',
      options: [
        for (final o in q.options)
          ChildQuizOption(
            id: o.id,
            labelKey: o.labelKey,
            correct: o.isCorrect,
            wrongHintKey: o.isCorrect ? null : 'hintRetry',
          ),
      ],
    );
  }
}

final InMemoryChildQuizRepository stage1ChildQuizRepository =
    InMemoryChildQuizRepository();

ChildQuizSnapshot childQuizEmptyFixture() => const ChildQuizSnapshot();

ChildQuizSnapshot childQuizOneFixture() {
  return const ChildQuizSnapshot(
    skillNameKey: 'dividingFractions',
    rewardMinutes: 20,
    questions: [
      ChildQuizQuestion(
        id: 'q1',
        promptKey: 'halfDivQuarter',
        explanationKey: 'halfDivQuarterExplain',
        options: [
          ChildQuizOption(id: 'a', labelKey: 'opt2', correct: true),
          ChildQuizOption(
            id: 'b',
            labelKey: 'opt1over8',
            correct: false,
            wrongHintKey: 'hintNearMiss',
          ),
          ChildQuizOption(
            id: 'c',
            labelKey: 'opt1over2',
            correct: false,
            wrongHintKey: 'hintFlip',
          ),
          ChildQuizOption(
            id: 'd',
            labelKey: 'opt4',
            correct: false,
            wrongHintKey: 'hintMultiply',
          ),
        ],
      ),
    ],
  );
}

ChildQuizSnapshot childQuizPrototypeFixture() => childQuizOneFixture();
