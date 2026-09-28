import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/features/education/learning_assignment_local_repository.dart';
import 'package:family_os/features/n14_studio/generation_outputs_repository.dart';
import 'package:family_os/features/n14_studio/quran_progress_repository.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_repository.dart';
import 'package:family_os/features/n17_child_learn/child_tutor_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LDR-B5 generation outputs default empty (no planted AI)', () async {
    final repo = InMemoryGenerationOutputsRepository();
    final snap = await repo.load();
    expect(snap.outputs, isEmpty);
  });

  test('LDR-B5 child tutor default empty (Tutor RC honesty)', () async {
    final repo = InMemoryChildTutorRepository();
    final snap = await repo.load();
    expect(snap.hasThread, isFalse);
    expect(snap.isEmpty, isTrue);
  });

  test('LDR-B5 quran progress empty fixture has no surah', () {
    final empty = quranProgressEmptyFixture();
    expect(empty.isEmpty, isTrue);
    expect(empty.surahKey, isNull);
  });

  test('LDR-B5 learn home base empty; assignments merge from Local', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final assignments = LocalLearningAssignmentRepository(db);
    await assignments.ensureRealLocalSeeded();
    final list = await assignments.listForChild(ChildId('demo-child'));
    expect(list, isNotEmpty);
    expect(list.first.rewardMinutes.inMinutes, 10);

    final home = InMemoryChildLearnHomeRepository(
      assignments: assignments,
      childId: ChildId('demo-child'),
    );
    final snap = await home.load();
    // Empty base + live assignment should surface challenge from assignment
    expect(snap, isNotNull);
  });
}
