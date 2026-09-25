import 'package:drift/drift.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/education/approved_pack_repository.dart';
import 'package:family_os/features/n14_studio/add_from_source_repository.dart';
import 'package:family_os/features/n14_studio/generation_outputs_models.dart';
import 'package:family_os/features/n14_studio/generation_outputs_repository.dart';
import 'package:family_os/features/n14_studio/materials_lessons_models.dart';
import 'package:family_os/features/n14_studio/materials_lessons_repository.dart';
import 'package:family_os/features/n14_studio/preview_approve_models.dart';
import 'package:family_os/features/n14_studio/preview_approve_repository.dart';
import 'package:family_os/features/n14_studio/staged_project_models.dart';
import 'package:family_os/features/n14_studio/staged_project_repository.dart';

/// DEV-6b — the content side of the studio (SCR-FAT-041 · 043 · 044 · 047 · 048)
/// on the ADR-054 v6 rows: `content_pack` · `content_item` ·
/// `learning_path` / `learning_path_stop` · `wallet_ledger`.
///
/// One rule runs through all of it: a row is a fact and a missing column is a
/// declared gap — never a planted number. The pack's ladder (`status`) is the
/// queue: what the family staged is what the generation and preview surfaces
/// work on, and approving or rejecting moves that row, so the studio board
/// (DEV-6a) reads the same truth the next morning.
abstract base class _PackScope {
  _PackScope({
    String? familyId,
    String? childId,
    String? accountId,
    DateTime Function()? clock,
  }) : _familyIdArg = familyId?.trim(),
       _childIdArg = childId?.trim(),
       _accountIdArg = accountId?.trim(),
       clock = clock ?? DateTime.now;

  final String? _familyIdArg;
  final String? _childIdArg;
  final String? _accountIdArg;
  final DateTime Function() clock;

  String get familyId =>
      (_familyIdArg ?? stage1IdentityRuntime.activeFamilyId.value).trim();

  String get childId =>
      (_childIdArg ?? stage1IdentityRuntime.activeChildId.value).trim();

  /// The account a write is attributed to (Rule 13/23 — never a planted id).
  String get accountId {
    final arg = _accountIdArg;
    if (arg != null && arg.isNotEmpty) return arg;
    final live = stage1IdentityRuntime.account.id.value.trim();
    return live.isEmpty
        ? Stage1RowVocabulary.unattributedAccount
        : live;
  }

  Future<List<ChildrenData>> childrenInOrder(FamilyDatabase db) {
    if (familyId.isEmpty) return Future.value(const []);
    return (db.select(db.children)
          ..where((c) => c.familyId.equals(familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }

  /// The pack the studio is working on: the family's newest staged pack, and
  /// failing that the newest draft. An approved or rejected pack has left the
  /// queue — the board shows it, not this flow.
  Future<ContentPack?> candidatePack(FamilyDatabase db) async {
    if (familyId.isEmpty) return null;
    final staged =
        await (db.select(db.contentPacks)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) &
                    t.status.equals(Stage1RowVocabulary.packStatusStaged),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    if (staged != null) return staged;
    return (db.select(db.contentPacks)
          ..where(
            (t) =>
                t.familyId.equals(familyId) &
                t.status.equals(Stage1RowVocabulary.packStatusDraft),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<ContentItem>> itemsOf(FamilyDatabase db, String packId) {
    return (db.select(db.contentItems)
          ..where((t) => t.packId.equals(packId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }
}

final class DriftPreviewApproveRepository
    extends _PackScope
    implements PreviewApproveRepository {
  DriftPreviewApproveRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
    ApprovedPackRepository? packs,
  }) : _packs = packs ?? stage1ApprovedPackRepository;

  final FamilyDatabase _db;

  /// The child's own load seam. Until the child side reads packs from rows the
  /// approval is published here too, so the session path stays alive — a
  /// declared cross-bridge gap, not a second source of truth (the row carries
  /// `status` · `approved_at` · `approved_by_account`).
  final ApprovedPackRepository _packs;

  @override
  Future<PreviewApproveSnapshot> load() async {
    final pack = await candidatePack(_db);
    if (pack == null) {
      return const PreviewApproveSnapshot(
        questions: [],
        lesson: null,
        elapsedSeconds: 0,
        ruleSeconds: 0,
      );
    }
    final items = await itemsOf(_db, pack.id);
    final questions = <PreviewQuizQuestion>[];
    PreviewLessonBlock? lesson;
    var ruleSeconds = 0;
    for (final item in items) {
      if (item.kind == Stage1RowVocabulary.itemKindQuiz) {
        questions.add(
          PreviewQuizQuestion(
            id: item.id,
            promptKey: item.titleRef,
            options: _QuizOptions.decode(item.bodyRef),
          ),
        );
        final rule = item.ruleSeconds ?? 0;
        if (rule > ruleSeconds) ruleSeconds = rule;
      } else if (item.kind == Stage1RowVocabulary.itemKindLesson) {
        lesson = PreviewLessonBlock(id: item.id, summaryKey: item.titleRef);
      }
    }
    return PreviewApproveSnapshot(
      questions: questions,
      lesson: lesson,
      difficulty: _difficultyOf(pack.difficulty),
      // No column stores the preview's own read time yet: zero says
      // «not measured», it is never a claim about the child.
      elapsedSeconds: 0,
      ruleSeconds: ruleSeconds,
      approved: pack.status == Stage1RowVocabulary.packStatusApproved,
      rejected: pack.status == Stage1RowVocabulary.packStatusRejected,
    );
  }

  @override
  Future<PreviewApproveSnapshot> approve() async {
    final pack = await candidatePack(_db);
    if (pack == null) return load();
    final snapshot = await load();
    if (!snapshot.canApprove) return snapshot;
    final at = clock();
    await _patchStatus(
      pack.id,
      Stage1RowVocabulary.packStatusApproved,
      at: at,
      approvedByAccount: accountId,
    );
    // The pack the child loads is the approved one — published on the same
    // snapshot the screen shows (P15-EDU-004 · Rule 7).
    await _packs.approve(snapshot);
    return load();
  }

  @override
  Future<PreviewApproveSnapshot> reject() async {
    final pack = await candidatePack(_db);
    if (pack == null) return load();
    await _patchStatus(
      pack.id,
      Stage1RowVocabulary.packStatusRejected,
      at: clock(),
    );
    await _packs.reject();
    return load();
  }

  Future<void> _patchStatus(
    String packId,
    String status, {
    required DateTime at,
    String? approvedByAccount,
  }) {
    final approved = status == Stage1RowVocabulary.packStatusApproved;
    return (_db.update(_db.contentPacks)..where((t) => t.id.equals(packId)))
        .write(
          ContentPacksCompanion(
            status: Value(status),
            updatedAt: Value(at),
            // A rejection clears the approval stamp — the row holds one state.
            approvedAt: Value(approved ? at : null),
            approvedByAccount: Value(approved ? approvedByAccount : null),
          ),
        );
  }
}

final class DriftMaterialsLessonsRepository
    extends _PackScope
    implements MaterialsLessonsRepository {
  DriftMaterialsLessonsRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  /// A subject row is a pack whose kind is the subject itself.
  static const subjectKinds = <String>[
    Stage1RowVocabulary.subjectKindMath,
    Stage1RowVocabulary.subjectKindQuran,
    Stage1RowVocabulary.subjectKindEnglish,
    Stage1RowVocabulary.subjectKindScience,
    Stage1RowVocabulary.subjectKindCustom,
  ];

  @override
  Future<MaterialsLessonsSnapshot> load() async {
    if (familyId.isEmpty) return const MaterialsLessonsSnapshot();
    final packs =
        await (_db.select(_db.contentPacks)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) & t.kind.isIn(subjectKinds),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return MaterialsLessonsSnapshot(
      subjects: [for (final pack in packs) await _subjectOf(pack)],
    );
  }

  @override
  Future<MaterialsSubject> addSubject() async {
    if (familyId.isEmpty) return _noSubject;
    final at = clock();
    final id = stage1RowId('subject', at);
    await _db
        .into(_db.contentPacks)
        .insert(
          ContentPacksCompanion.insert(
            id: id,
            familyId: familyId,
            kind: Stage1RowVocabulary.subjectKindCustom,
            sourceRef: Stage1RowVocabulary.sourceKindFamily,
            status: Stage1RowVocabulary.packStatusDraft,
            createdByAccount: accountId,
            createdAt: Value(at),
            updatedAt: Value(at),
          ),
        );
    return MaterialsSubject(
      id: id,
      kind: MaterialsSubjectKind.custom,
      titleKey: 'custom',
      // The family just added it — the row says so by having no lessons yet.
      subtitleKey: 'justAdded',
    );
  }

  @override
  Future<MaterialsSubject> addLesson({String? subjectId}) async {
    var target = subjectId?.trim() ?? '';
    if (target.isEmpty) {
      final subjects = (await load()).subjects;
      if (subjects.isEmpty) return addSubject();
      target = subjects.last.id;
    }
    final pack =
        await (_db.select(_db.contentPacks)
              ..where(
                (t) => t.id.equals(target) & t.familyId.equals(familyId),
              )
              ..limit(1))
            .getSingleOrNull();
    if (pack == null) return _noSubject;
    final at = clock();
    final items = await itemsOf(_db, pack.id);
    var order = 0;
    for (final item in items) {
      if (item.sortOrder >= order) order = item.sortOrder + 1;
    }
    await _db
        .into(_db.contentItems)
        .insert(
          ContentItemsCompanion.insert(
            id: stage1RowId('lesson', at),
            packId: pack.id,
            kind: Stage1RowVocabulary.itemKindLesson,
            titleRef: 'lesson',
            sortOrder: Value(order),
          ),
        );
    await (_db.update(
      _db.contentPacks,
    )..where((t) => t.id.equals(pack.id))).write(
      ContentPacksCompanion(updatedAt: Value(at)),
    );
    return _subjectOf(pack);
  }

  /// The subject a row describes: its own counts, and a path only where a real
  /// `learning_path` row exists for this child.
  Future<MaterialsSubject> _subjectOf(ContentPack pack) async {
    final items = await itemsOf(_db, pack.id);
    var lessons = 0;
    var quizzes = 0;
    var flashcards = 0;
    for (final item in items) {
      switch (item.kind) {
        case Stage1RowVocabulary.itemKindLesson:
          lessons++;
        case Stage1RowVocabulary.itemKindQuiz:
          quizzes++;
        case Stage1RowVocabulary.itemKindFlashcards:
          flashcards++;
      }
    }
    return MaterialsSubject(
      id: pack.id,
      kind: subjectKindOf(pack.kind),
      titleKey: subjectTitleKeyOf(pack.kind),
      subtitleKey: 'lessonCount',
      lessons: lessons,
      quizzes: quizzes,
      flashcards: flashcards,
      hasActivePath: await _hasPath(pack.id),
    );
  }

  Future<bool> _hasPath(String subjectRef) async {
    if (childId.isEmpty) return false;
    final row =
        await (_db.select(_db.learningPaths)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) &
                    t.childId.equals(childId) &
                    t.subjectRef.equals(subjectRef),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  static const _noSubject = MaterialsSubject(
    id: '',
    kind: MaterialsSubjectKind.custom,
    titleKey: 'custom',
    subtitleKey: 'justAdded',
  );
}

final class DriftGenerationOutputsRepository
    extends _PackScope
    implements GenerationOutputsRepository {
  DriftGenerationOutputsRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<GenerationOutputsSnapshot> load() async {
    final pack = await candidatePack(_db);
    if (pack == null) return const GenerationOutputsSnapshot(outputs: []);
    final items = await itemsOf(_db, pack.id);
    return GenerationOutputsSnapshot(
      // Which door the content came through — the pack's own ref, named by the
      // screen's copy. Never a claim about what the content contains.
      sourceKey: sourceKeyOf(pack.sourceRef),
      outputs: [
        for (final item in items)
          GenerationOutputItem(
            id: item.id,
            kind: outputKindOf(item.kind),
            // The P1 gate is a column: a phase-locked output is never chosen.
            selected: !item.phaseLocked,
            phaseLocked: item.phaseLocked,
          ),
      ],
    );
  }
}

final class DriftStagedProjectRepository
    extends _PackScope
    implements StagedProjectRepository {
  DriftStagedProjectRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<StagedProjectSnapshot> load() async {
    final path = await _projectPath();
    if (path == null) return const StagedProjectSnapshot();
    final stops = await _stopsOf(path.id);
    final children = await childrenInOrder(_db);
    var index = 0;
    for (var i = 0; i < children.length; i++) {
      if (children[i].id == path.childId) index = i;
    }
    var done = 0;
    var activeAt = 0;
    for (var i = 0; i < stops.length; i++) {
      if (stops[i].status == Stage1RowVocabulary.statusDone) done++;
      if (stops[i].status == Stage1RowVocabulary.stopStatusActive) {
        activeAt = i + 1;
      }
    }
    return StagedProjectSnapshot(
      hasProject: true,
      // The project's own ref, kept in the path row (Rule 23 — the screen maps
      // it to its own copy).
      titleKey: path.subjectRef,
      childLabelKey: Stage1RowVocabulary.childKeyFor(index),
      stageCount: stops.length,
      // No planned-duration column exists: the line is the project's own age
      // in weeks, counted from the row — never a planted plan.
      weeks: (clock().difference(path.createdAt).inDays ~/ 7) + 1,
      // The stage the family is standing on: the active one, else how many are
      // already done.
      currentStage: activeAt > 0 ? activeAt : done,
      progress: path.progressPercent / 100,
      stages: [
        for (final stop in stops)
          StagedProjectStage(
            id: stop.id,
            titleKey: stop.titleRef,
            // The contract keeps one ref per stop, so the sub-ref follows the
            // stage's own convention (`<ref>Sub`).
            subKey: '${stop.titleRef}Sub',
            status: projectStageStatusOf(stop.status),
            rewardMinutes: stop.rewardMinutes,
          ),
      ],
    );
  }

  @override
  Future<StagedProjectSnapshot> confirmActiveStage() async {
    final path = await _projectPath();
    if (path == null) return load();
    final stops = await _stopsOf(path.id);
    final at = clock();
    var done = 0;
    var completed = 0;
    var confirmed = false;
    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      if (stop.status == Stage1RowVocabulary.statusDone) done++;
      if (stop.status == Stage1RowVocabulary.stopStatusActive && !confirmed) {
        await _patchStop(
          stop.id,
          Stage1RowVocabulary.statusDone,
          masteryPercent: 100,
        );
        if (stop.rewardMinutes > 0) {
          // Minutes only (ع-١): finishing a stage pays into the ledger, and the
          // project's own id is what the entry points back at.
          await _db
              .into(_db.walletLedgerEntries)
              .insert(
                WalletLedgerEntriesCompanion.insert(
                  id: stage1RowId('ledger', at),
                  familyId: familyId,
                  childId: path.childId,
                  deltaMinutes: stop.rewardMinutes,
                  reason: Stage1RowVocabulary.walletEarned,
                  sourceRef: Value(path.id),
                ),
              );
        }
        final next = i + 1 < stops.length ? stops[i + 1] : null;
        if (next != null &&
            next.status == Stage1RowVocabulary.stopStatusLocked) {
          await _patchStop(next.id, Stage1RowVocabulary.stopStatusActive);
        }
        confirmed = true;
      }
    }
    completed = confirmed ? done + 1 : done;
    await (_db.update(
      _db.learningPaths,
    )..where((t) => t.id.equals(path.id))).write(
      LearningPathsCompanion(
        completedLessons: Value(completed),
        progressPercent: Value(
          stops.isEmpty ? 0 : ((completed / stops.length) * 100).round(),
        ),
        updatedAt: Value(at),
      ),
    );
    return load();
  }

  @override
  Future<void> openTemplatePicker() {
    // Picking a template is navigation: the row is written when the family
    // actually chooses one, so nothing is staged here.
    return Future.value();
  }

  Future<LearningPath?> _projectPath() async {
    if (familyId.isEmpty) return null;
    final query = _db.select(_db.learningPaths)
      ..where((t) => t.familyId.equals(familyId));
    if (childId.isNotEmpty) {
      query.where((t) => t.childId.equals(childId));
    }
    query
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<List<LearningPathStopRow>> _stopsOf(String pathId) {
    return (_db.select(_db.learningPathStops)
          ..where((t) => t.pathId.equals(pathId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<void> _patchStop(
    String stopId,
    String status, {
    int? masteryPercent,
  }) {
    return (_db.update(
      _db.learningPathStops,
    )..where((t) => t.id.equals(stopId))).write(
      LearningPathStopsCompanion(
        status: Value(status),
        masteryPercent: Value(masteryPercent),
      ),
    );
  }
}

final class DriftAddFromSourceRepository
    extends _PackScope
    implements AddFromSourceRepository {
  DriftAddFromSourceRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<AddFromSourceResult> addSource(AddSourceKind kind) async {
    if (familyId.isEmpty) {
      // Nothing to hang the row on: the gate stages nothing (fail-closed).
      return AddFromSourceResult(kind: kind, packId: '');
    }
    final at = clock();
    final id = stage1RowId('pack', at);
    await _db
        .into(_db.contentPacks)
        .insert(
          ContentPacksCompanion.insert(
            id: id,
            familyId: familyId,
            kind: Stage1RowVocabulary.packKindGenerated,
            sourceRef: sourceRefOf(kind),
            // Staged: it is now the pack the generation and preview surfaces
            // work on until the father approves or rejects it.
            status: Stage1RowVocabulary.packStatusStaged,
            createdByAccount: accountId,
            createdAt: Value(at),
            updatedAt: Value(at),
          ),
        );
    return AddFromSourceResult(kind: kind, packId: id);
  }
}

/// `content_pack.source_ref` for a gate on SCR-FAT-041.
String sourceRefOf(AddSourceKind kind) => switch (kind) {
  AddSourceKind.pdf => Stage1RowVocabulary.sourceKindPdf,
  AddSourceKind.assignment => Stage1RowVocabulary.sourceKindAssignment,
  AddSourceKind.camera => Stage1RowVocabulary.sourceKindCamera,
  AddSourceKind.link => Stage1RowVocabulary.sourceKindLink,
  AddSourceKind.topic => Stage1RowVocabulary.sourceKindTopic,
  AddSourceKind.voice => Stage1RowVocabulary.sourceKindVoice,
  AddSourceKind.library => Stage1RowVocabulary.sourceKindLibrary,
};

/// The ARB key the generation banner shows for a stored source ref.
String sourceKeyOf(String sourceRef) => switch (sourceRef) {
  Stage1RowVocabulary.sourceKindPdf => 'addFromSourcePdfTitle',
  Stage1RowVocabulary.sourceKindAssignment => 'addFromSourceAssignmentTitle',
  Stage1RowVocabulary.sourceKindCamera => 'addFromSourceCameraTitle',
  Stage1RowVocabulary.sourceKindLink => 'addFromSourceLinkTitle',
  Stage1RowVocabulary.sourceKindTopic => 'addFromSourceTopicTitle',
  Stage1RowVocabulary.sourceKindVoice => 'addFromSourceVoiceTitle',
  Stage1RowVocabulary.sourceKindLibrary => 'addFromSourceLibraryTitle',
  _ => kGenerationSourceFractionsKey,
};

GenerationOutputKind outputKindOf(String kind) => switch (kind) {
  Stage1RowVocabulary.itemKindHomework => GenerationOutputKind.homework,
  Stage1RowVocabulary.itemKindQuiz => GenerationOutputKind.quiz,
  Stage1RowVocabulary.itemKindFlashcards => GenerationOutputKind.flashcards,
  Stage1RowVocabulary.itemKindChallenge => GenerationOutputKind.challenge,
  Stage1RowVocabulary.itemKindReviewGame => GenerationOutputKind.reviewGame,
  _ => GenerationOutputKind.lesson,
};

MaterialsSubjectKind subjectKindOf(String kind) => switch (kind) {
  Stage1RowVocabulary.subjectKindQuran => MaterialsSubjectKind.quran,
  Stage1RowVocabulary.subjectKindEnglish => MaterialsSubjectKind.english,
  Stage1RowVocabulary.subjectKindScience => MaterialsSubjectKind.science,
  Stage1RowVocabulary.subjectKindCustom => MaterialsSubjectKind.custom,
  _ => MaterialsSubjectKind.math,
};

String subjectTitleKeyOf(String kind) => switch (kind) {
  Stage1RowVocabulary.subjectKindQuran => 'quran',
  Stage1RowVocabulary.subjectKindEnglish => 'english',
  Stage1RowVocabulary.subjectKindScience => 'science',
  Stage1RowVocabulary.subjectKindCustom => 'custom',
  _ => 'math',
};

ProjectStageStatus projectStageStatusOf(String status) => switch (status) {
  Stage1RowVocabulary.stopStatusActive => ProjectStageStatus.active,
  Stage1RowVocabulary.statusDone => ProjectStageStatus.done,
  _ => ProjectStageStatus.locked,
};

PreviewDifficulty _difficultyOf(String? stored) => switch (stored) {
  Stage1RowVocabulary.difficultyEasier => PreviewDifficulty.easier,
  Stage1RowVocabulary.difficultyHarder => PreviewDifficulty.harder,
  _ => PreviewDifficulty.normal,
};

/// A quiz item's options ride inside `content_item.body_ref` — the contract
/// keeps no options table — as `key:1;key:0`, where 1 marks the correct one.
abstract final class _QuizOptions {
  static List<PreviewQuizOption> decode(String? body) {
    final raw = body?.trim() ?? '';
    if (raw.isEmpty) return const [];
    final options = <PreviewQuizOption>[];
    for (final part in raw.split(';')) {
      final bit = part.lastIndexOf(':');
      if (bit <= 0) continue;
      final key = part.substring(0, bit).trim();
      if (key.isEmpty) continue;
      options.add(
        PreviewQuizOption(
          id: key,
          labelKey: key,
          isCorrect: part.substring(bit + 1).trim() == '1',
        ),
      );
    }
    return options;
  }
}
