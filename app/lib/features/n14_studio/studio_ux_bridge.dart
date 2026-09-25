import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';
import 'package:family_os/features/n14_studio/add_from_source_repository.dart';
import 'package:family_os/features/n14_studio/attribution_reward_models.dart';
import 'package:family_os/features/n14_studio/attribution_reward_repository.dart';
import 'package:family_os/features/n14_studio/community_library_repository.dart';
import 'package:family_os/features/n14_studio/learning_path_repository.dart';
import 'package:family_os/features/n14_studio/quran_progress_repository.dart';
import 'package:family_os/features/n14_studio/results_followup_repository.dart';
import 'package:family_os/features/n14_studio/studio_followup_bridge.dart';
import 'package:family_os/features/n14_studio/create_assignment_models.dart';
import 'package:family_os/features/n14_studio/create_assignment_repository.dart';
import 'package:family_os/features/n14_studio/generation_outputs_repository.dart';
import 'package:family_os/features/n14_studio/materials_lessons_repository.dart';
import 'package:family_os/features/n14_studio/preview_approve_repository.dart';
import 'package:family_os/features/n14_studio/staged_project_repository.dart';
import 'package:family_os/features/n14_studio/studio_board_models.dart';
import 'package:family_os/features/n14_studio/studio_board_repository.dart';
import 'package:family_os/features/n14_studio/studio_content_bridge.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

/// Stage-2 composition root for the studio domain (ADR-054 §4 · §11.3).
///
/// The studio is where content is generated, approved and attributed — so its
/// rows are `content_pack` / `content_item` / `attribution_rule`, and its
/// publishing hand is the learning seam (`learn_assignment`) built in DEV-5a.
/// Scope resolves from the identity runtime at load time; tests pass ids.
final class Stage1StudioRuntime {
  Stage1StudioRuntime._();

  static FamilyDatabase? _db;

  static FamilyDatabase ensureOpenSync({FamilyDatabase? override}) {
    if (override != null) {
      _db = override;
      return override;
    }
    final existing = _db;
    if (existing != null) return existing;
    final opened = FamilyDatabase(NativeDatabase.memory());
    _db = opened;
    return opened;
  }

  static Future<void> ensureOpen({FamilyDatabase? override}) async {
    ensureOpenSync(override: override);
  }

  /// SCR-FAT-040 — the studio board over `content_pack` + `learn_skill_gap`.
  static StudioBoardRepository get board =>
      DriftStudioBoardRepository(ensureOpenSync());

  /// SCR-FAT-049 — assigning homework, a gap or a family question.
  static CreateAssignmentRepository get createAssignment =>
      DriftCreateAssignmentRepository(ensureOpenSync());

  /// SCR-FAT-045 — attributing minutes to a child's wallets.
  static AttributionRewardRepository get attribution =>
      DriftAttributionRewardRepository(ensureOpenSync());

  /// SCR-FAT-044 — the pack awaiting approval over `content_pack`.
  static PreviewApproveRepository get previewApprove =>
      DriftPreviewApproveRepository(ensureOpenSync());

  /// SCR-FAT-048 — the subject rows with their own real counts.
  static MaterialsLessonsRepository get materialsLessons =>
      DriftMaterialsLessonsRepository(ensureOpenSync());

  /// SCR-FAT-043 — the staged pack's generated outputs.
  static GenerationOutputsRepository get generationOutputs =>
      DriftGenerationOutputsRepository(ensureOpenSync());

  /// SCR-FAT-047 — the project's stages over `learning_path` + `_stop`.
  static StagedProjectRepository get stagedProject =>
      DriftStagedProjectRepository(ensureOpenSync());

  /// SCR-FAT-041 — staging a source writes the pack the studio works on.
  static AddFromSourceRepository get addFromSource =>
      DriftAddFromSourceRepository(ensureOpenSync());

  /// SCR-FAT-046 — the community shelf over `community_cache`.
  static CommunityLibraryRepository get communityLibrary =>
      DriftCommunityLibraryRepository(ensureOpenSync());

  /// SCR-FAT-047 — the child's ladder over `learning_path` + `_stop`.
  static LearningPathRepository get learningPath =>
      DriftLearningPathRepository(ensureOpenSync());

  /// SCR-FAT-050 — the father's follow-up over `learn_result` + gaps + ledger.
  static ResultsFollowupRepository get resultsFollowup =>
      DriftResultsFollowupRepository(ensureOpenSync());

  /// SCR-FAT-051 — the ward plan over `quran_plan` + `quran_recitation`.
  static QuranProgressRepository get quranProgress =>
      DriftQuranProgressRepository(ensureOpenSync());

  /// Clears this runtime only. An injected database is closed by its owner.
  static void resetForTest() => _db = null;
}

/// Shared scope handling: explicit ids win, otherwise the identity runtime
/// answers at call time, and an empty or unowned scope reads nothing.
abstract base class _StudioScope {
  _StudioScope({
    String? familyId,
    String? childId,
    DateTime Function()? clock,
  }) : _familyIdArg = familyId?.trim(),
       _childIdArg = childId?.trim(),
       clock = clock ?? DateTime.now;

  final String? _familyIdArg;
  final String? _childIdArg;
  final DateTime Function() clock;

  String get familyId =>
      (_familyIdArg ?? stage1IdentityRuntime.activeFamilyId.value).trim();

  String get childId =>
      (_childIdArg ?? stage1IdentityRuntime.activeChildId.value).trim();

  /// The family's children, oldest first — the order the screens label
  /// «الطفل الأول» by (Rule 23).
  Future<List<ChildrenData>> childrenInOrder(FamilyDatabase db) {
    if (familyId.isEmpty) return Future.value(const []);
    return (db.select(db.children)
          ..where((c) => c.familyId.equals(familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }
}

final class DriftStudioBoardRepository
    extends _StudioScope
    implements StudioBoardRepository {
  DriftStudioBoardRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<StudioBoardSnapshot> load() async {
    if (familyId.isEmpty) return const StudioBoardSnapshot();

    final packs = await (_db.select(_db.contentPacks)
          ..where((t) => t.familyId.equals(familyId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    // The «suggestions» lane is the family's outstanding skill gaps — the same
    // rows the child's review screen owns, never a planted list.
    final childIds = [for (final c in await childrenInOrder(_db)) c.id];
    final gaps = childIds.isEmpty
        ? const <LearnSkillGap>[]
        : await (_db.select(_db.learnSkillGaps)
                ..where(
                  (t) =>
                      t.status.isNotIn([Stage1RowVocabulary.learnClosed]) &
                      t.childId.isIn(childIds),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
              .get();

    return StudioBoardSnapshot(
      suggestions: [
        for (final gap in gaps)
          StudioSuggestion(id: gap.id, kind: _suggestionKindFor(gap.skillRef)),
      ],
      recent: [
        for (final pack in packs)
          StudioContentItem(
            id: pack.id,
            kind: _contentKindFor(pack.kind),
            status: _contentStatusFor(pack.status),
          ),
      ],
    );
  }

  /// The board knows two suggestion shapes; the stored subject decides which.
  static StudioSuggestionKind _suggestionKindFor(String skillRef) =>
      skillRef.toLowerCase().contains('quran')
          ? StudioSuggestionKind.quranWird
          : StudioSuggestionKind.fractions;

  static StudioContentKind _contentKindFor(String kind) {
    final key = kind.trim().toLowerCase();
    if (key.contains('flash')) return StudioContentKind.flashcards;
    if (key.contains('quran') || key.contains('wird')) {
      return StudioContentKind.quranWird;
    }
    return StudioContentKind.quiz;
  }

  /// The chip is the pack's own ladder: an approved pack is done, a staged or
  /// waiting one is in progress, everything else is still fresh.
  static StudioContentStatus _contentStatusFor(String status) {
    final key = status.trim().toUpperCase();
    if (key == Stage1RowVocabulary.packStatusApproved) {
      return StudioContentStatus.excellent;
    }
    if (key == Stage1RowVocabulary.packStatusStaged ||
        key == Stage1RowVocabulary.packStatusPending) {
      return StudioContentStatus.progress;
    }
    return StudioContentStatus.active;
  }
}

final class DriftCreateAssignmentRepository
    extends _StudioScope
    implements CreateAssignmentRepository {
  DriftCreateAssignmentRepository(
    this._db, {
    super.familyId,
    super.childId,
    String? createdByAccount,
    super.clock,
  }) : _createdByAccount = createdByAccount?.trim() ?? '';

  final FamilyDatabase _db;
  final String _createdByAccount;

  @override
  Future<CreateAssignmentSnapshot> load() async {
    final children = await childrenInOrder(_db);
    if (children.isEmpty) return const CreateAssignmentSnapshot();

    // The acting child when this family owns it, otherwise the eldest.
    ChildrenData? acting;
    for (final c in children) {
      if (c.id == childId) acting = c;
    }
    final child = acting ?? children.first;
    final gap = await _newestGap(child.id);

    return CreateAssignmentSnapshot(
      child: CreateAssignmentChild(
        id: child.id,
        nameKey: Stage1RowVocabulary.childKeyFor(children.indexOf(child)),
      ),
      skillGap: gap == null
          ? null
          : CreateAssignmentSkillGap(
              id: gap.id,
              titleKey: gap.skillRef,
              missed: gap.missed,
              total: gap.total,
              // The gap was measured on that many questions — the row's count.
              quizQuestions: gap.total,
              rewardMinutes: await _rewardFor(gap.skillRef, child.id),
            ),
    );
  }

  @override
  Future<CreateAssignmentSnapshot> assignHomework(String title) async {
    final current = await load();
    final trimmed = title.trim();
    final child = current.child;
    if (child == null || trimmed.isEmpty) return current;
    await _publish(
      childId: child.id,
      // The father's own words are the content reference, stored verbatim.
      contentRef: trimmed,
      rewardMinutes: current.homeworkRewardMinutes,
      source: LearningAssignmentSource.homework,
    );
    return current.copyWith(
      homeworkTitle: trimmed,
      lastAssignedPath: CreateAssignmentPath.homework,
    );
  }

  @override
  Future<CreateAssignmentSnapshot> assignSkillGap() async {
    final current = await load();
    final child = current.child;
    final gap = current.skillGap;
    if (child == null || gap == null) return current;
    await _publish(
      childId: child.id,
      contentRef: gap.titleKey,
      rewardMinutes: gap.rewardMinutes,
      source: LearningAssignmentSource.skillGap,
    );
    return current.copyWith(lastAssignedPath: CreateAssignmentPath.skillGap);
  }

  @override
  Future<CreateAssignmentSnapshot> assignFamilyChallenge(
    String question,
  ) async {
    final current = await load();
    final trimmed = question.trim();
    final child = current.child;
    if (child == null || trimmed.isEmpty) return current;
    await _publish(
      childId: child.id,
      contentRef: trimmed,
      rewardMinutes: current.familyRewardMinutes,
      source: LearningAssignmentSource.familyChallenge,
    );
    return current.copyWith(
      familyQuestion: trimmed,
      lastAssignedPath: CreateAssignmentPath.familyChallenge,
    );
  }

  /// The assignment lane is the one built in DEV-5a — the studio only decides
  /// *what* to assign, never a second way of writing it.
  Future<void> _publish({
    required String childId,
    required String contentRef,
    required int rewardMinutes,
    required LearningAssignmentSource source,
  }) async {
    if (!await _ownedChild(childId)) return;
    await DriftLearningAssignmentRepository(
      _db,
      familyId: familyId,
      childId: childId,
      createdByAccount: _createdByAccount,
      clock: clock,
    ).publish(
      LearningAssignmentPublishRequest(
        childId: ChildId(childId),
        titleKey: contentRef,
        rewardMinutes: Minutes(rewardMinutes),
        source: source,
      ),
    );
  }

  Future<LearnSkillGap?> _newestGap(String childId) {
    return (_db.select(_db.learnSkillGaps)
          ..where(
            (t) =>
                t.childId.equals(childId) &
                t.status.isNotIn([Stage1RowVocabulary.learnClosed]),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// A rule the family wrote for this content decides the reward; with no rule
  /// the screen's own thirty minutes stand.
  Future<int> _rewardFor(String contentRef, String childId) async {
    final row = await (_db.select(_db.attributionRules)
          ..where(
            (t) =>
                t.familyId.equals(familyId) &
                t.contentRef.equals(contentRef) &
                (t.childId.equals(childId) | t.childId.isNull()),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.minutes)])
          ..limit(1))
        .getSingleOrNull();
    return row?.minutes ?? 30;
  }

  /// Fail-closed: never publish for a child this family does not own.
  Future<bool> _ownedChild(String id) async {
    if (familyId.isEmpty || id.trim().isEmpty) return false;
    final row = await (_db.select(_db.children)
          ..where((c) => c.familyId.equals(familyId) & c.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }
}

final class DriftAttributionRewardRepository
    extends _StudioScope
    implements AttributionRewardRepository {
  DriftAttributionRewardRepository(
    this._db, {
    super.familyId,
    super.childId,
    String? createdByAccount,
    super.clock,
  }) : _createdByAccount = createdByAccount?.trim() ?? '';

  final FamilyDatabase _db;
  final String _createdByAccount;

  /// Bit 0 is the current weekday, bits 5–6 are the weekend (Friday, Saturday).
  static const int _weekendMask = (1 << 5) | (1 << 6);

  @override
  Future<AttributionRewardSnapshot> load() async {
    final children = await childrenInOrder(_db);
    if (children.isEmpty) return const AttributionRewardSnapshot();

    ChildrenData? acting;
    for (final c in children) {
      if (c.id == childId) acting = c;
    }
    final selected = acting ?? children.first;
    final rules = await _rulesFor(selected.id);
    final gap = await _newestGap(selected.id);
    final mask = rules.isEmpty ? 0 : rules.first.scheduleDayMask;

    return AttributionRewardSnapshot(
      children: [
        for (final c in children)
          AttributionChild(
            id: c.id,
            nameKey: Stage1RowVocabulary.childKeyFor(children.indexOf(c)),
            // The stored avatar is the child's own mark (Rule 23 — no names).
            emoji: c.avatar.trim(),
            // The swatch is a display choice only, cycled by the row's order.
            swatch: AttributionChildSwatch
                .values[children.indexOf(c) % AttributionChildSwatch.values.length],
          ),
      ],
      selectedChildId: selected.id,
      schedule: _scheduleFrom(mask, clock()),
      rewards: [
        for (final rule in rules)
          AttributionRewardToggle(
            id: rule.id,
            kind: _rewardKindOf(rule.kind),
            minutes: rule.minutes,
            enabled: rule.enabled,
            autoAdded: rule.autoAdded,
          ),
      ],
      masteryPercent: gap?.masteryPercent ?? 0,
      // «أُسند» is the rule row's own flag, never a session memory.
      assigned: rules.any((r) => r.assigned),
    );
  }

  @override
  Future<AttributionRewardSnapshot> assign() async {
    final current = await load();
    final child = current.selectedChild;
    if (!current.canAssign || child == null) return current;

    final now = clock();
    final mask = _maskFor(current.schedule, now);

    for (final toggle in current.rewards) {
      // The rule row keeps the father's decision (and when it applies).
      await (_db.update(_db.attributionRules)
            ..where((t) => t.id.equals(toggle.id)))
          .write(
            AttributionRulesCompanion(
              enabled: Value(toggle.enabled),
              assigned: const Value(true),
              scheduleDayMask: Value(mask),
            ),
          );
      if (!toggle.enabled || toggle.minutes <= 0) continue;
      // And the minutes land in the ledger the child's wallet already reads.
      await _db
          .into(_db.walletLedgerEntries)
          .insert(
            WalletLedgerEntriesCompanion.insert(
              id: stage1RowId('ledger', now),
              familyId: familyId,
              childId: child.id,
              deltaMinutes: toggle.minutes,
              reason: Stage1RowVocabulary.walletEarned,
              sourceRef: Value(
                toggle.kind == AttributionRewardKind.play
                    ? AttributionWalletApps.play
                    : AttributionWalletApps.education,
              ),
              createdAt: Value(now),
            ),
          );
    }

    await _publish(child.id, current.totalEnabledMinutes);

    return (await load()).withAssigned();
  }

  Future<void> _publish(String childId, int rewardMinutes) async {
    if (!await _ownedChild(childId)) return;
    await DriftLearningAssignmentRepository(
      _db,
      familyId: familyId,
      childId: childId,
      createdByAccount: _createdByAccount,
      clock: clock,
    ).publish(
      LearningAssignmentPublishRequest(
        childId: ChildId(childId),
        // The attribution host's own marker; the child's screen reads the host
        // from `request_id` and the subject from the material kind.
        titleKey: 'attribution',
        rewardMinutes: Minutes(rewardMinutes),
        source: LearningAssignmentSource.attribution,
      ),
    );
  }

  Future<List<AttributionRule>> _rulesFor(String childId) {
    return (_db.select(_db.attributionRules)
          ..where(
            (t) =>
                t.familyId.equals(familyId) &
                (t.childId.equals(childId) | t.childId.isNull()),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.kind)]))
        .get();
  }

  Future<LearnSkillGap?> _newestGap(String childId) {
    return (_db.select(_db.learnSkillGaps)
          ..where(
            (t) =>
                t.childId.equals(childId) &
                t.status.isNotIn([Stage1RowVocabulary.learnClosed]),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  static AttributionRewardKind _rewardKindOf(String kind) =>
      kind.trim().toUpperCase() == Stage1RowVocabulary.ruleKindPlay
          ? AttributionRewardKind.play
          : AttributionRewardKind.wallet;

  /// The three choices the screen offers, written as the days they mean.
  static int _maskFor(AttributionSchedule schedule, DateTime now) {
    final today = 1 << (now.weekday % 7);
    return switch (schedule) {
      AttributionSchedule.today => today,
      AttributionSchedule.weekend => _weekendMask,
      AttributionSchedule.tomorrowAfterSchool => 1 << ((now.weekday % 7 + 1) % 7),
    };
  }

  static AttributionSchedule _scheduleFrom(int mask, DateTime now) {
    if (mask == 0) return AttributionSchedule.tomorrowAfterSchool;
    if (mask == _weekendMask) return AttributionSchedule.weekend;
    if (mask == 1 << (now.weekday % 7)) return AttributionSchedule.today;
    return AttributionSchedule.tomorrowAfterSchool;
  }

  /// Fail-closed: never publish for a child this family does not own.
  Future<bool> _ownedChild(String id) async {
    if (familyId.isEmpty || id.trim().isEmpty) return false;
    final row = await (_db.select(_db.children)
          ..where((c) => c.familyId.equals(familyId) & c.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }
}
