import 'package:drift/drift.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n17_child_learn/child_flashcards_models.dart';
import 'package:family_os/features/n17_child_learn/child_flashcards_repository.dart';
import 'package:family_os/features/n17_child_learn/child_lesson_models.dart';
import 'package:family_os/features/n17_child_learn/child_lesson_repository.dart';
import 'package:family_os/features/n17_child_learn/child_memorization_models.dart';
import 'package:family_os/features/n17_child_learn/child_memorization_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_models.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_repository.dart';
import 'package:family_os/features/n17_child_learn/child_smart_plan_models.dart';
import 'package:family_os/features/n17_child_learn/child_smart_plan_repository.dart';
import 'package:family_os/features/n17_child_learn/child_smart_tilawah_models.dart';
import 'package:family_os/features/n17_child_learn/child_smart_tilawah_repository.dart';

/// DEV-6d — the child's own learning surfaces on the ADR-054 v6 rows:
/// `learning_path` / `learning_path_stop` (الدرس · الخطّة الذكية) ·
/// `content_pack` / `content_item` (البطاقات) · `quran_plan` /
/// `quran_recitation` / `quran_memorization` / `learn_achievement`
/// (الحفظ · التلاوة · الورد) · `learn_skill_gap` / `learn_session` /
/// `learn_assignment` / `wallet_ledger`.
///
/// The rule is the campaign's rule: a row is a fact, a missing column is a
/// declared gap, and what a screen does on the device (playback, listening,
/// flipping a card) never pretends to be stored data.
abstract base class _LearnFollowupScope {
  _LearnFollowupScope({
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

  String get accountId {
    final arg = _accountIdArg;
    if (arg != null && arg.isNotEmpty) return arg;
    final live = stage1IdentityRuntime.account.id.value.trim();
    return live.isEmpty ? Stage1RowVocabulary.unattributedAccount : live;
  }

  Future<List<ChildrenData>> childrenInOrder(FamilyDatabase db) {
    if (familyId.isEmpty) return Future.value(const []);
    return (db.select(db.children)
          ..where((c) => c.familyId.equals(familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }

  /// The child whose screen this is: the live child when the family holds
  /// that row, otherwise the first child on record — never a planted id.
  Future<ChildrenData?> actingChild(FamilyDatabase db) async {
    final children = await childrenInOrder(db);
    if (children.isEmpty) return null;
    for (final child in children) {
      if (child.id == childId) return child;
    }
    return children.first;
  }

  /// The day key every child-side row speaks (`yyyy-mm-dd`, UTC).
  String dayKey(DateTime at) {
    final month = at.month.toString().padLeft(2, '0');
    final day = at.day.toString().padLeft(2, '0');
    return '${at.year}-$month-$day';
  }
}

/// SCR-CHD-013 — the lesson the child is standing on.
///
/// The lesson is the path's own active stop: the row names it, the path holds
/// the progress counters, and the pizza slices are those counters (one slice
/// per lesson) rather than a planted shape. The hook and the body are editorial
/// copy with no column, so the screen keeps its own.
final class DriftChildLessonRepository extends _LearnFollowupScope
    implements ChildLessonRepository {
  DriftChildLessonRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<ChildLessonSnapshot> load() async {
    final child = await actingChild(_db);
    if (child == null) return const ChildLessonSnapshot();
    final path = await _pathOf(child);
    if (path == null) return const ChildLessonSnapshot();
    final stops = await _stopsOf(path.id);
    final active = _activeStop(stops);
    return ChildLessonSnapshot(
      titleKey: active?.titleRef ?? path.subjectRef,
      progressPercent: path.progressPercent,
      pizzaFilled: [
        for (var i = 0; i < path.totalLessons; i++)
          i < path.completedLessons,
      ],
      rewardMinutes: active?.rewardMinutes ?? 0,
    );
  }

  Future<LearningPath?> _pathOf(ChildrenData child) {
    return (_db.select(_db.learningPaths)
          ..where(
            (t) => t.familyId.equals(familyId) & t.childId.equals(child.id),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
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

  LearningPathStopRow? _activeStop(List<LearningPathStopRow> stops) {
    for (final stop in stops) {
      if (stop.status == Stage1RowVocabulary.stopStatusActive) return stop;
    }
    for (final stop in stops) {
      if (stop.status != Stage1RowVocabulary.statusDone &&
          stop.status != Stage1RowVocabulary.learnMastered) {
        return stop;
      }
    }
    return null;
  }
}

/// SCR-CHD-014 — the flashcards of the pack the child is working on.
///
/// The cards are the pack's own `content_item` rows of kind `FLASHCARDS`,
/// ordered as the family left them; flipping and marking are the sitting's own
/// state (the contract keeps no per-card row), while the quiz reward is the
/// assignment's real number when an assignment names the pack.
final class DriftChildFlashcardsRepository extends _LearnFollowupScope
    implements ChildFlashcardsRepository {
  DriftChildFlashcardsRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  var _index = 0;
  var _flipped = false;

  @override
  Future<ChildFlashcardsSnapshot> load() async {
    final child = await actingChild(_db);
    if (child == null) return const ChildFlashcardsSnapshot();
    final pack = await _packOf(child);
    if (pack == null) return const ChildFlashcardsSnapshot();
    final items = await _itemsOf(pack.id);
    if (items.isEmpty) return const ChildFlashcardsSnapshot();
    if (_index >= items.length) _index = items.length - 1;
    final rangeReward = await _assignmentReward(child, pack.sourceRef);
    return ChildFlashcardsSnapshot(
      // The pack's own door ref (a real token the screen maps), and the pack's
      // kind as the source line.
      lessonTitleKey: pack.sourceRef,
      sourceNameKey: pack.kind,
      cards: [
        for (final item in items)
          ChildFlashcard(
            id: item.id,
            questionKey: item.titleRef,
            answerKey: item.bodyRef ?? '',
            // No column keeps a flashcard hint — the screen's own copy shows.
            hintKey: '',
          ),
      ],
      currentIndex: _index,
      flipped: _flipped,
      quizRewardMinutes: rangeReward ?? 50,
    );
  }

  @override
  Future<ChildFlashcardsSnapshot> flip() async {
    _flipped = !_flipped;
    return load();
  }

  @override
  Future<ChildFlashcardsSnapshot> next() async {
    final snap = await load();
    _advance(snap, 1);
    return load();
  }

  @override
  Future<ChildFlashcardsSnapshot> previous() async {
    final snap = await load();
    _advance(snap, -1);
    return load();
  }

  @override
  Future<ChildFlashcardsSnapshot> markKnown() async {
    // Knowing a card is the sitting's own judgement — the contract keeps no
    // per-card row, so the mark moves the sitting on and stores nothing.
    final snap = await load();
    _advance(snap, 1);
    return load();
  }

  @override
  Future<ChildFlashcardsSnapshot> markReview() async {
    final snap = await load();
    _advance(snap, 1);
    return load();
  }

  void _advance(ChildFlashcardsSnapshot snap, int step) {
    if (snap.cards.isEmpty) return;
    _index = (_index + step).clamp(0, snap.cards.length - 1);
    _flipped = false;
  }

  /// The pack the child should be on: the one their own assignment names, and
  /// failing that the family's newest approved flashcard pack.
  Future<ContentPack?> _packOf(ChildrenData child) async {
    final assignedRef = await _latestAssignedRef(child);
    final packs =
        await (_db.select(_db.contentPacks)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) &
                    t.kind.equals(Stage1RowVocabulary.packKindFlashcards) &
                    t.status.equals(Stage1RowVocabulary.packStatusApproved),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();
    for (final pack in packs) {
      if (assignedRef != null && pack.sourceRef == assignedRef) return pack;
    }
    return packs.isEmpty ? null : packs.first;
  }

  Future<String?> _latestAssignedRef(ChildrenData child) async {
    final row =
        await (_db.select(_db.learnAssignments)
              ..where((t) => t.childId.equals(child.id))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.contentRef;
  }

  Future<List<ContentItem>> _itemsOf(String packId) {
    return (_db.select(_db.contentItems)
          ..where(
            (t) =>
                t.packId.equals(packId) &
                t.kind.equals(Stage1RowVocabulary.itemKindFlashcards),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<int?> _assignmentReward(ChildrenData child, String ref) async {
    if (ref.trim().isEmpty) return null;
    final row =
        await (_db.select(_db.learnAssignments)
              ..where(
                (t) => t.childId.equals(child.id) & t.contentRef.equals(ref),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.rewardMinutes;
  }
}

/// SCR-CHD-020 — the child's smart plan over the real rows.
///
/// The gap is the child's own newest open `learn_skill_gap`; the project is the
/// same `learning_path` the other surfaces read (one path model, seen from the
/// child's side), so the stage keys and counters are the rows themselves.
/// Starting the repair plan sits a review session (`learn_session`) that names
/// the gap — the row is the proof the plan started, and the daily-review card
/// reads the same rows. Completing a project stage closes the stop, opens the
/// next, updates the path and pays the stop's minutes through `wallet_ledger`.
final class DriftChildSmartPlanRepository extends _LearnFollowupScope
    implements ChildSmartPlanRepository {
  DriftChildSmartPlanRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<ChildSmartPlanSnapshot> load() async {
    final child = await actingChild(_db);
    if (child == null) return const ChildSmartPlanSnapshot();
    final gap = await _openGap(child);
    final path = await _pathOf(child);
    final stops = path == null
        ? <LearningPathStopRow>[]
        : await _stopsOf(path.id);
    final active = _activeStop(stops);
    final started = gap != null && await _sittingOf(child, gap.skillRef) != null;
    return ChildSmartPlanSnapshot(
      hasPlan: gap != null || path != null,
      // Empty refs when the row is missing — the screen keeps its own copy for
      // the keys it does not know, and nothing is planted here.
      gapKey: gap?.skillRef ?? '',
      projectKey: path?.subjectRef ?? '',
      projectStageKey: active?.titleRef ?? '',
      projectDone: stops.isNotEmpty && active == null,
      pathDone: path?.completedLessons ?? 0,
      pathTotal: path?.totalLessons ?? 0,
      planStarted: started,
    );
  }

  @override
  Future<ChildSmartPlanSnapshot> startRepairPlan() async {
    final child = await actingChild(_db);
    if (child == null) return load();
    final gap = await _openGap(child);
    if (gap == null) return load();
    if (await _sittingOf(child, gap.skillRef) != null) return load();
    final at = clock();
    await _db
        .into(_db.learnSessions)
        .insert(
          LearnSessionsCompanion.insert(
            id: stage1RowId('learn-session', at),
            familyId: familyId,
            childId: child.id,
            kind: Stage1RowVocabulary.learnKindReview,
            contentRef: Value(gap.skillRef),
            startedAt: Value(at),
            endedAt: Value(at),
            status: Stage1RowVocabulary.learnDone,
            requestId: gap.skillRef,
            createdAt: Value(at),
          ),
        );
    return load();
  }

  @override
  Future<ChildSmartPlanSnapshot> completeProjectStage() async {
    final child = await actingChild(_db);
    if (child == null) return load();
    final path = await _pathOf(child);
    if (path == null) return load();
    final stops = await _stopsOf(path.id);
    final active = _activeStop(stops);
    if (active == null) return load();
    final at = clock();

    await (_db.update(
      _db.learningPathStops,
    )..where((t) => t.id.equals(active.id))).write(
      LearningPathStopsCompanion(
        status: const Value(Stage1RowVocabulary.statusDone),
        masteryPercent: Value(active.masteryPercent ?? 100),
      ),
    );

    final next = _firstLockedAfter(stops, active);
    if (next != null) {
      await (_db.update(
        _db.learningPathStops,
      )..where((t) => t.id.equals(next.id))).write(
        const LearningPathStopsCompanion(
          status: Value(Stage1RowVocabulary.stopStatusActive),
        ),
      );
    }

    var done = 0;
    for (final stop in stops) {
      if (stop.id == active.id ||
          stop.status == Stage1RowVocabulary.statusDone ||
          stop.status == Stage1RowVocabulary.learnMastered) {
        done++;
      }
    }
    await (_db.update(
      _db.learningPaths,
    )..where((t) => t.id.equals(path.id))).write(
      LearningPathsCompanion(
        completedLessons: Value(done),
        progressPercent: Value(
          stops.isEmpty ? 0 : ((done / stops.length) * 100).round(),
        ),
        updatedAt: Value(at),
      ),
    );

    if (active.rewardMinutes > 0) {
      // ع-١ — minutes only, and only through the ledger with its reason.
      await _db
          .into(_db.walletLedgerEntries)
          .insert(
            WalletLedgerEntriesCompanion.insert(
              id: stage1RowId('ledger', at),
              familyId: familyId,
              childId: child.id,
              deltaMinutes: active.rewardMinutes,
              reason: Stage1RowVocabulary.walletEarned,
              sourceRef: Value(active.titleRef),
              createdAt: Value(at),
            ),
          );
    }
    return load();
  }

  Future<LearnSkillGap?> _openGap(ChildrenData child) {
    return (_db.select(_db.learnSkillGaps)
          ..where(
            (t) =>
                t.childId.equals(child.id) &
                t.status.isNotIn([
                  Stage1RowVocabulary.learnClosed,
                  Stage1RowVocabulary.learnMastered,
                ]),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<LearnSession?> _sittingOf(ChildrenData child, String ref) {
    if (ref.trim().isEmpty) return Future.value(null);
    return (_db.select(_db.learnSessions)
          ..where(
            (t) =>
                t.childId.equals(child.id) &
                t.kind.equals(Stage1RowVocabulary.learnKindReview) &
                t.requestId.equals(ref),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<LearningPath?> _pathOf(ChildrenData child) {
    return (_db.select(_db.learningPaths)
          ..where(
            (t) => t.familyId.equals(familyId) & t.childId.equals(child.id),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
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

  LearningPathStopRow? _activeStop(List<LearningPathStopRow> stops) {
    for (final stop in stops) {
      if (stop.status == Stage1RowVocabulary.stopStatusActive) return stop;
    }
    for (final stop in stops) {
      if (stop.status != Stage1RowVocabulary.statusDone &&
          stop.status != Stage1RowVocabulary.learnMastered) {
        return stop;
      }
    }
    return null;
  }

  LearningPathStopRow? _firstLockedAfter(
    List<LearningPathStopRow> stops,
    LearningPathStopRow current,
  ) {
    var seen = false;
    for (final stop in stops) {
      if (stop.id == current.id) {
        seen = true;
        continue;
      }
      if (seen && stop.status == Stage1RowVocabulary.stopStatusLocked) {
        return stop;
      }
    }
    return null;
  }
}

/// SCR-CHD-026 — memorisation over `quran_memorization` +
/// `learn_achievement` + `quran_recitation`.
///
/// Each memorisation row is one surah with its own percent (stored whole, read
/// as a fraction); a badge exists only when its `learn_achievement` row does;
/// a review is one recitation row, due when its `due_day` is empty or today.
final class DriftChildMemorizationRepository extends _LearnFollowupScope
    implements ChildMemorizationRepository {
  DriftChildMemorizationRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<ChildMemorizationSnapshot> load() async {
    final child = await actingChild(_db);
    if (child == null) return const ChildMemorizationSnapshot();
    final surahs =
        await (_db.select(_db.quranMemorizations)
              ..where((t) => t.childId.equals(child.id))
              ..orderBy([
                (t) => OrderingTerm.desc(t.progress),
                (t) => OrderingTerm.asc(t.surahRef),
              ]))
            .get();
    final badges =
        await (_db.select(_db.learnAchievements)
              ..where((t) => t.childId.equals(child.id))
              ..orderBy([(t) => OrderingTerm.desc(t.earnedAt)]))
            .get();
    final reviews =
        await (_db.select(_db.quranRecitations)
              ..where((t) => t.childId.equals(child.id))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    final today = dayKey(clock());
    // A recitation row carries its plan, not its surah — the plan names it.
    final plans =
        await (_db.select(_db.quranPlans)
              ..where((t) => t.childId.equals(child.id)))
            .get();
    final surahByPlan = {for (final plan in plans) plan.id: plan.surahRef};
    var extraAyahs = 0;
    for (final surah in surahs) {
      extraAyahs += surah.extraAyahs;
    }
    return ChildMemorizationSnapshot(
      hasProgress: surahs.isNotEmpty,
      surahCount: surahs.length,
      extraAyahs: extraAyahs,
      surahs: [
        for (final surah in surahs)
          ChildMemSurah(
            id: surah.id,
            nameKey: surah.surahRef,
            progress: (surah.progress / 100).clamp(0, 1).toDouble(),
          ),
      ],
      badges: [
        for (final badge in badges)
          ChildMemBadge(
            id: badge.id,
            labelKey: badge.badgeRef,
            // A row exists because the badge was earned.
            earned: true,
          ),
      ],
      reviews: [
        for (final review in reviews.take(5))
          ChildMemReview(
            id: review.id,
            titleKey: surahByPlan[review.planId] ?? review.kind,
            metaKey: review.status,
            dueToday: review.dueDay == null || review.dueDay == today,
          ),
      ],
    );
  }

  @override
  Future<void> startReview(String id) async {
    final child = await actingChild(_db);
    if (child == null) return;
    final recitation =
        await (_db.select(_db.quranRecitations)
              ..where((t) => t.childId.equals(child.id) & t.id.equals(id))
              ..limit(1))
            .getSingleOrNull();
    var contentRef = id;
    if (recitation != null) {
      final plan =
          await (_db.select(_db.quranPlans)
                ..where((t) => t.id.equals(recitation.planId))
                ..limit(1))
              .getSingleOrNull();
      if (plan != null) contentRef = plan.surahRef;
    }
    final at = clock();
    await _db
        .into(_db.learnSessions)
        .insert(
          LearnSessionsCompanion.insert(
            id: stage1RowId('learn-session', at),
            familyId: familyId,
            childId: child.id,
            kind: Stage1RowVocabulary.learnKindReview,
            contentRef: Value(contentRef),
            startedAt: Value(at),
            endedAt: Value(at),
            status: Stage1RowVocabulary.learnDone,
            requestId: id,
            createdAt: Value(at),
          ),
        );
  }
}

/// SCR-CHD-028 — smart tilawah over the child's own ward plan.
///
/// The session is the plan row: which surah, from which ayah. Listening and
/// playing the reciter are the device's work (no column, no row), and the
/// tajweed tip and the praise line are editorial copy the contract does not
/// store — the screen keeps its own.
final class DriftChildSmartTilawahRepository extends _LearnFollowupScope
    implements ChildSmartTilawahRepository {
  DriftChildSmartTilawahRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  var _listening = false;
  var _sheikhPlayed = false;

  @override
  Future<ChildSmartTilawahSnapshot> load() async {
    final child = await actingChild(_db);
    if (child == null) return const ChildSmartTilawahSnapshot();
    final plan = await _planOf(child);
    if (plan == null) return const ChildSmartTilawahSnapshot();
    return ChildSmartTilawahSnapshot(
      hasSession: true,
      surahKey: plan.surahRef,
      ayahNumber: plan.fromAyah,
      ayahKey: '${plan.surahRef}${plan.fromAyah}',
      listening: _listening,
      sheikhPlayed: _sheikhPlayed,
    );
  }

  @override
  Future<ChildSmartTilawahSnapshot> startListening() async {
    _listening = true;
    return load();
  }

  @override
  Future<ChildSmartTilawahSnapshot> playSheikh() async {
    _sheikhPlayed = true;
    return load();
  }

  Future<QuranPlan?> _planOf(ChildrenData child) async {
    final active =
        await (_db.select(_db.quranPlans)
              ..where(
                (t) => t.childId.equals(child.id) & t.active.equals(true),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (active != null) return active;
    return (_db.select(_db.quranPlans)
          ..where((t) => t.childId.equals(child.id))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}

/// SCR-CHD-025 — the child's ward over `quran_plan` + `quran_recitation`.
///
/// Submitting a recitation writes the child's own `quran_recitation` row
/// (`PENDING`, covering the plan's range) — that is the row the father's screen
/// approves. The gifts counter is the positive `wallet_ledger` entries the
/// child actually received, and playback stays on the device.
final class DriftChildQuranWardRepository extends _LearnFollowupScope
    implements ChildQuranWardRepository {
  DriftChildQuranWardRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  var _playing = false;

  @override
  Future<ChildQuranWardSnapshot> load() async {
    final child = await actingChild(_db);
    if (child == null) return const ChildQuranWardSnapshot();
    final plan = await _planOf(child);
    if (plan == null) return const ChildQuranWardSnapshot();
    final recitation =
        await (_db.select(_db.quranRecitations)
              ..where((t) => t.childId.equals(child.id))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    final gifts =
        await (_db.select(_db.walletLedgerEntries)
              ..where(
                (t) =>
                    t.childId.equals(child.id) &
                    t.deltaMinutes.isBiggerThanValue(0),
              ))
            .get();
    return ChildQuranWardSnapshot(
      hasWard: true,
      surahKey: plan.surahRef,
      fromAyah: plan.fromAyah,
      toAyah: plan.toAyah,
      reciterKey: plan.reciterRef,
      rewardMinutes: plan.rewardMinutes,
      offlineReady: plan.offlineReady,
      giftCount: gifts.length,
      ayahKey: '${plan.surahRef}${plan.fromAyah}',
      recitationStatus: _statusOf(recitation),
      playing: _playing,
    );
  }

  @override
  Future<ChildQuranWardSnapshot> togglePlay() async {
    _playing = !_playing;
    return load();
  }

  @override
  Future<ChildQuranWardSnapshot> submitRecitation() async {
    final child = await actingChild(_db);
    if (child == null) return load();
    final plan = await _planOf(child);
    if (plan == null) return load();
    final at = clock();
    await _db
        .into(_db.quranRecitations)
        .insert(
          QuranRecitationsCompanion.insert(
            id: stage1RowId('recitation', at),
            planId: plan.id,
            childId: child.id,
            day: dayKey(at),
            kind: Stage1RowVocabulary.learnKindReview,
            status: Stage1RowVocabulary.recitationPending,
            // The child just recited the plan's own range — that is the fact
            // the row carries, not a timer the screen does not have.
            completedAyahs: Value(plan.toAyah - plan.fromAyah + 1),
            createdAt: Value(at),
          ),
        );
    _playing = false;
    return load();
  }

  ChildWardRecitationStatus _statusOf(QuranRecitation? recitation) {
    if (recitation == null) return ChildWardRecitationStatus.none;
    final approved =
        recitation.status.trim().toUpperCase() ==
        Stage1RowVocabulary.recitationApproved;
    return approved
        ? ChildWardRecitationStatus.approved
        : ChildWardRecitationStatus.sent;
  }

  Future<QuranPlan?> _planOf(ChildrenData child) async {
    final active =
        await (_db.select(_db.quranPlans)
              ..where(
                (t) => t.childId.equals(child.id) & t.active.equals(true),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (active != null) return active;
    return (_db.select(_db.quranPlans)
          ..where((t) => t.childId.equals(child.id))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}
