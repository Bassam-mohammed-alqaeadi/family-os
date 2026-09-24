import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/education/approved_pack_models.dart';
import 'package:family_os/features/education/approved_pack_repository.dart';
import 'package:family_os/features/n14_studio/preview_approve_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quiz_repository.dart';

void main() {
  test('approve publishes pack; child quiz loads pack questions', () async {
    final packs = InMemoryApprovedPackRepository();
    addTearDown(packs.dispose);
    final father = InMemoryPreviewApproveRepository(packs: packs);
    final child = InMemoryChildQuizRepository(packs: packs);

    final before = await child.load();
    expect(before.skillNameKey, 'dividingFractions');
    expect(before.questions, hasLength(1));

    final approved = await father.approve();
    expect(approved.approved, isTrue);

    final pack = await packs.latestApproved();
    expect(pack, isNotNull);
    expect(pack!.status, ApprovedPackStatus.approved);
    expect(pack.questions, hasLength(2));

    final after = await child.load();
    expect(after.skillNameKey, 'approvedPack');
    expect(after.questions.map((q) => q.id), ['q1', 'q2']);
  });

  test('reject clears pack; child keeps prototype quiz', () async {
    final packs = InMemoryApprovedPackRepository();
    addTearDown(packs.dispose);
    final father = InMemoryPreviewApproveRepository(packs: packs);
    final child = InMemoryChildQuizRepository(packs: packs);

    await father.approve();
    expect(await packs.latestApproved(), isNotNull);

    final rejected = await father.reject();
    expect(rejected.rejected, isTrue);
    expect(await packs.latestApproved(), isNull);

    final quiz = await child.load();
    expect(quiz.skillNameKey, 'dividingFractions');
  });
}
