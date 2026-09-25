import 'package:drift/drift.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n14_studio/community_library_models.dart';
import 'package:family_os/features/n14_studio/community_library_repository.dart';
import 'package:family_os/features/n14_studio/learning_path_models.dart';
import 'package:family_os/features/n14_studio/learning_path_repository.dart';
import 'package:family_os/features/n14_studio/quran_progress_models.dart';
import 'package:family_os/features/n14_studio/quran_progress_repository.dart';
import 'package:family_os/features/n14_studio/results_followup_models.dart';
import 'package:family_os/features/n14_studio/results_followup_repository.dart';
import 'package:family_os/features/quran/quran_ward_plan_models.dart';
import 'package:family_os/features/quran/quran_ward_plan_repository.dart';

/// DEV-6c — the studio's remaining five surfaces on the ADR-054 v6 rows:
/// `community_cache` (SCR-FAT-046) · `learning_path` / `learning_path_stop`
/// (SCR-FAT-047) · `learn_result` / `learn_skill_gap` / `learn_session` plus
/// `wallet_ledger` (SCR-FAT-050) · `quran_plan` / `quran_recitation` /
/// `learn_streak` (SCR-FAT-051) · `content_pack` staging (SCR-FAT-042).
///
/// The same rule as the other bridges: a row is a fact, a missing column is a
/// declared gap. Nothing here plants a number the family never produced.
abstract base class _FollowupScope {
  _FollowupScope({
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
    return live.isEmpty ? Stage1RowVocabulary.unattributedAccount : live;
  }

  Future<List<ChildrenData>> childrenInOrder(FamilyDatabase db) {
    if (familyId.isEmpty) return Future.value(const []);
    return (db.select(db.children)
          ..where((c) => c.familyId.equals(familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }

  /// The child the screen speaks about: the live child when the family holds
  /// that row, otherwise the first child on record — never a planted id.
  Future<ChildrenData?> actingChild(FamilyDatabase db) async {
    final children = await childrenInOrder(db);
    if (children.isEmpty) return null;
    for (final child in children) {
      if (child.id == childId) return child;
    }
    return children.first;
  }

  Future<int> ordinalOf(FamilyDatabase db, ChildrenData child) async {
    final children = await childrenInOrder(db);
    final index = children.indexWhere((c) => c.id == child.id);
    return index < 0 ? 0 : index;
  }
}

/// The ordinal words the family screens speak (`childOne` … `childThree`).
/// A family past the third child keeps the third label — the product's own
/// vocabulary is closed at three, and a missing column never becomes a name.
String _ordinalWord(int ordinal) => switch (ordinal) {
  0 => 'one',
  1 => 'two',
  _ => 'three',
};

/// `community_cache.kind` holds the pack's token; the screen knows three.
CommunityPackageKind _communityKindOf(String raw) {
  final token = raw.trim().toLowerCase();
  for (final kind in CommunityPackageKind.values) {
    if (kind.name == token) return kind;
  }
  return CommunityPackageKind.fractions;
}

/// The cache vocabulary is closed at the three Stage-1 authors; an unknown
/// token is labelled by the screen's own first author rather than dropped.
CommunityAuthorKey _communityAuthorOf(String raw) {
  final token = raw.trim();
  for (final author in CommunityAuthorKey.values) {
    if (author.name == token) return author;
  }
  return CommunityAuthorKey.fatherRiyadh;
}

/// SCR-FAT-046 — the community shelf over `community_cache`.
///
/// The cache is what the family already pulled from the community store, so
/// the shelf shows exactly the rows it holds, ordered by what the community
/// rated. Nothing in the contract says a local pack is ready to publish, so
/// the publish offer line stays empty (declared gap) instead of naming a pack
/// that never asked.
final class DriftCommunityLibraryRepository extends _FollowupScope
    implements CommunityLibraryRepository {
  DriftCommunityLibraryRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<CommunityLibrarySnapshot> load() async {
    final rows =
        await (_db.select(_db.communityCacheEntries)
              ..orderBy([
                (t) => OrderingTerm.desc(t.rating),
                (t) => OrderingTerm.desc(t.ratingCount),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    if (rows.isEmpty) return const CommunityLibrarySnapshot();
    return CommunityLibrarySnapshot(
      packages: [
        for (final row in rows)
          CommunityPackage(
            id: row.id,
            kind: _communityKindOf(row.kind),
            titleKey: row.titleRef,
            authorKey: _communityAuthorOf(row.authorRef),
            rating: row.rating,
            ratingCount: row.ratingCount,
            trusted: row.trusted,
            lessons: row.lessons,
            quizzes: row.quizzes,
          ),
      ],
      publishOffer: null,
    );
  }
}

/// SCR-FAT-047 — the child's ladder over `learning_path` + `learning_path_stop`.
///
/// The contract keeps one path model, so this screen reads the same rows the
/// staged-project surface reads: the newest path of the acting child, its own
/// progress counters, and its stops in the family's own order. A stop's reward
/// shows only when the row carries one.
final class DriftLearningPathRepository extends _FollowupScope
    implements LearningPathRepository {
  DriftLearningPathRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<LearningPathSnapshot> load() async {
    final child = await actingChild(_db);
    if (child == null) return const LearningPathSnapshot();
    final path = await _pathOf(child);
    if (path == null) return const LearningPathSnapshot();
    final stops = await _stopsOf(path.id);
    return LearningPathSnapshot(
      childNameKey: _ordinalWord(await ordinalOf(_db, child)),
      // The path row keeps the subject's own ref; the screen maps the refs it
      // knows and keeps its own copy for the rest (Rule 23).
      subjectKey: path.subjectRef,
      progressPercent: path.progressPercent,
      completedLessons: path.completedLessons,
      totalLessons: path.totalLessons,
      stops: [
        for (final stop in stops)
          LearningPathStop(
            id: stop.id,
            titleKey: stop.titleRef,
            status: _stopStatusOf(stop.status),
            kind: stop.kind == Stage1RowVocabulary.itemKindQuiz
                ? LearningStopKind.quiz
                : LearningStopKind.lesson,
            masteryPercent: stop.masteryPercent,
            subtitleKey: _stopSubtitleOf(stop),
            rewardMinutes: stop.rewardMinutes > 0 ? stop.rewardMinutes : null,
          ),
      ],
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

  /// A stop has mastered when the child's own record says so; an unlocked stop
  /// is the one the child stands on.
  LearningStopStatus _stopStatusOf(String raw) {
    final status = raw.trim();
    if (status == Stage1RowVocabulary.learnMastered ||
        status == Stage1RowVocabulary.statusDone) {
      return LearningStopStatus.mastered;
    }
    if (status == Stage1RowVocabulary.stopStatusActive) {
      return LearningStopStatus.current;
    }
    return LearningStopStatus.locked;
  }

  String _stopSubtitleOf(LearningPathStopRow stop) {
    if (_stopStatusOf(stop.status) == LearningStopStatus.mastered) {
      return 'mastered';
    }
    if (_stopStatusOf(stop.status) == LearningStopStatus.locked) {
      // The last stop of a ladder is the reward one; a locked lesson is simply
      // still ahead of the child.
      return stop.kind == Stage1RowVocabulary.itemKindQuiz ? 'reward' : 'locked';
    }
    return 'quizPending';
  }
}

/// SCR-FAT-050 — the father's follow-up over `learn_result`,
/// `learn_skill_gap`, `learn_session` and the `wallet_ledger` entries.
///
/// The mastery line is the child's newest result (the previous result on the
/// same skill is what the change compares against), the gap is the skill the
/// child has not closed yet, and an activity shows the minutes only when the
/// ledger holds an entry for it — otherwise the row simply says it came in.
final class DriftResultsFollowupRepository extends _FollowupScope
    implements ResultsFollowupRepository {
  DriftResultsFollowupRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<ResultsFollowupSnapshot> load() async {
    final child = await actingChild(_db);
    if (child == null) return const ResultsFollowupSnapshot();

    final results =
        await (_db.select(_db.learnResults)
              ..where((t) => t.childId.equals(child.id))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    final gaps =
        await (_db.select(_db.learnSkillGaps)
              ..where(
                (t) =>
                    t.childId.equals(child.id) &
                    t.status.isNotIn([
                      Stage1RowVocabulary.learnClosed,
                      Stage1RowVocabulary.learnMastered,
                    ]),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();
    final sessions =
        await (_db.select(_db.learnSessions)
              ..where(
                (t) =>
                    t.childId.equals(child.id) &
                    t.status.equals(Stage1RowVocabulary.learnDone),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
            .get();
    final entries =
        await (_db.select(_db.walletLedgerEntries)
              ..where(
                (t) =>
                    t.childId.equals(child.id) &
                    t.deltaMinutes.isBiggerThanValue(0),
              ))
            .get();

    final earnedByRef = <String, int>{};
    for (final entry in entries) {
      final ref = entry.sourceRef?.trim();
      if (ref == null || ref.isEmpty) continue;
      earnedByRef.update(
        ref,
        (value) => value + entry.deltaMinutes,
        ifAbsent: () => entry.deltaMinutes,
      );
    }

    return ResultsFollowupSnapshot(
      child: ResultsFollowupChild(
        id: child.id,
        nameKey: _ordinalWord(await ordinalOf(_db, child)),
      ),
      mastery: _masteryOf(results),
      skillGap: gaps.isEmpty
          ? null
          : ResultsFollowupSkillGap(
              id: gaps.first.id,
              titleKey: gaps.first.skillRef,
              status: gaps.first.status == Stage1RowVocabulary.learnMastered
                  ? ResultsFollowupSkillGapStatus.mastered
                  : ResultsFollowupSkillGapStatus.pending,
              missed: gaps.first.missed,
              total: gaps.first.total,
              masteryPercent: gaps.first.masteryPercent,
            ),
      activities: [
        for (final session in sessions.take(6))
          _activityOf(session, earnedByRef),
      ],
    );
  }

  ResultsFollowupMastery? _masteryOf(List<LearnResult> results) {
    if (results.isEmpty) return null;
    final latest = results.first;
    final percent =
        latest.masteryPercent ??
        _percentOf(latest.correct, latest.total);
    int? previous;
    for (final older in results.skip(1)) {
      if (older.skillRef != latest.skillRef) continue;
      previous =
          older.masteryPercent ?? _percentOf(older.correct, older.total);
      break;
    }
    return ResultsFollowupMastery(
      // The result row keeps the subject as its own ref (the screen maps the
      // refs it knows).
      subjectKey: latest.skillRef,
      percent: percent,
      previousPercent: previous,
    );
  }

  ResultsFollowupActivity _activityOf(
    LearnSession session,
    Map<String, int> earnedByRef,
  ) {
    final ref = session.contentRef?.trim() ?? '';
    final earned = ref.isEmpty ? 0 : earnedByRef[ref] ?? 0;
    return ResultsFollowupActivity(
      id: session.id,
      kind: session.kind == Stage1RowVocabulary.learnKindChallenge
          ? ResultsFollowupActivityKind.familyChallenge
          : ResultsFollowupActivityKind.homework,
      // The session names what it was about; an unnamed one keeps the screen's
      // own default copy rather than a title invented here.
      titleKey: ref,
      subtitleKey: earned > 0 ? 'earnedMinutes' : 'justSubmitted',
      statusKey: 'complete',
      minutes: earned > 0 ? earned : null,
    );
  }

  int _percentOf(int correct, int total) =>
      total <= 0 ? 0 : ((correct / total) * 100).round();
}

/// SCR-FAT-051 — the father's ward plan over `quran_plan` +
/// `quran_recitation` + `learn_streak`.
///
/// The plan row is the truth: which surah, which range, which reciter, what
/// the child earns and whether the audio is already on the device. Approving a
/// recitation moves that row's status and writes the reward as a ledger entry
/// (Rule 5 — minutes are only ever earned through the ledger). What a screen
/// cannot do on rows — playing audio, whispering, kicking off a download — is
/// device work, so it writes nothing.
final class DriftQuranProgressRepository extends _FollowupScope
    implements QuranProgressRepository {
  DriftQuranProgressRepository(
    this._db, {
    QuranWardPlanRepository? plans,
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  }) : _plans = plans ?? stage1QuranWardPlanRepository;

  final FamilyDatabase _db;
  final QuranWardPlanRepository _plans;

  /// Playback is the device's own state — it never had a row.
  var _playing = false;

  @override
  Future<QuranProgressSnapshot> load() async {
    final child = await actingChild(_db);
    if (child == null) return _emptySnapshot();
    final plan = await _planOf(child);
    if (plan == null) return _emptySnapshot();
    final recitation = await _latestRecitation(child);
    final streak =
        await (_db.select(_db.learnStreaks)
              ..where(
                (t) =>
                    t.childId.equals(child.id) &
                    t.kind.equals(Stage1RowVocabulary.learnStreakAll),
              )
              ..limit(1))
            .getSingleOrNull();

    return QuranProgressSnapshot(
      childNameKey: Stage1RowVocabulary.childKeyFor(
        await ordinalOf(_db, child),
      ),
      surahKey: plan.surahRef,
      fromAyah: plan.fromAyah,
      toAyah: plan.toAyah,
      // The child's recitation row carries the ayahs it reported — the ladder
      // here starts at the row, never at a planted number.
      completedAyahs: recitation?.completedAyahs ?? 0,
      reciterKey: plan.reciterRef,
      streakDays: streak?.currentDays ?? 0,
      rewardMinutes: plan.rewardMinutes,
      offlineReady: plan.offlineReady,
      // No column keeps a downloaded audio size, so the line stays empty and
      // the screen shows its own copy (declared gap).
      audioSizeKey: null,
      recitationStatus: _recitationStatusOf(recitation),
      playingAudio: _playing,
    );
  }

  @override
  Future<QuranProgressSnapshot> togglePlay() async {
    _playing = !_playing;
    return load();
  }

  @override
  Future<QuranProgressSnapshot> approveRecitation() async {
    final child = await actingChild(_db);
    if (child == null) return load();
    final plan = await _planOf(child);
    final recitation = await _latestRecitation(child);
    final at = clock();
    // Only a recitation that is still waiting can be approved — and only that
    // confirmation pays, so a second tap never earns twice.
    final pending =
        recitation != null && !_isApproved(recitation.status)
        ? recitation
        : null;

    if (pending != null) {
      await (_db.update(
        _db.quranRecitations,
      )..where((t) => t.id.equals(pending.id))).write(
        QuranRecitationsCompanion(
          status: const Value(Stage1RowVocabulary.recitationApproved),
          completedAyahs: Value(pending.completedAyahs),
        ),
      );
    }

    final reward = plan?.rewardMinutes ?? 0;
    if (pending != null && reward > 0) {
      // Rule 5 — the reward is a ledger entry with its reason and its source,
      // never a bare total.
      await _db
          .into(_db.walletLedgerEntries)
          .insert(
            WalletLedgerEntriesCompanion.insert(
              id: stage1RowId('quran-reward', at),
              familyId: familyId,
              childId: child.id,
              deltaMinutes: reward,
              reason: Stage1RowVocabulary.walletEarned,
              sourceRef: Value(plan?.id),
            ),
          );
    }

    _playing = false;
    return load();
  }

  @override
  Future<void> whisperEncourage() {
    // A whisper is a notification on the child's device — it writes no row.
    return Future.value();
  }

  @override
  Future<void> requestDownload() {
    // Audio download is device work; there is no queue row in the contract.
    return Future.value();
  }

  @override
  Future<QuranProgressSnapshot> cyclePlanSurah() async {
    final child = await actingChild(_db);
    if (child == null) return load();
    final plans = await _plansOf(child);
    if (plans.length < 2) return load();
    final active = await _planOf(child);
    final currentIndex = plans.indexWhere((p) => p.id == active?.id);
    final next = plans[(currentIndex < 0 ? 0 : currentIndex + 1) % plans.length];
    final at = clock();
    // One ward plan is the child's current one; the family cycling the plan
    // moves that flag, it does not duplicate the plan.
    await (_db.update(
      _db.quranPlans,
    )..where((t) => t.childId.equals(child.id))).write(
      const QuranPlansCompanion(active: Value(false)),
    );
    await (_db.update(
      _db.quranPlans,
    )..where((t) => t.id.equals(next.id))).write(
      QuranPlansCompanion(active: const Value(true), updatedAt: Value(at)),
    );
    return load();
  }

  @override
  Future<QuranWardPlan> publishPlanToChild({ChildId? childId}) async {
    final child = await actingChild(_db);
    final targetId = childId?.value ?? child?.id ?? '';
    if (targetId.isEmpty) {
      throw StateError('No child to publish a ward plan to');
    }
    final existing = child == null ? null : await _planOf(child);
    final surahRef = existing?.surahRef ?? _defaultSurahRef;
    final fromAyah = existing?.fromAyah ?? 1;
    final toAyah = existing?.toAyah ?? _defaultToAyah;
    final reciterRef = existing?.reciterRef ?? _defaultReciterRef;
    final reward = existing?.rewardMinutes ?? _defaultRewardMinutes;
    if (existing == null) {
      // Publishing to a child who has no plan row yet opens the family's first
      // ward plan as a real row, so the child's screen reads a plan and not a
      // planted snapshot.
      await _insertPlan(
        childId: targetId,
        surahRef: surahRef,
        fromAyah: fromAyah,
        toAyah: toAyah,
        reciterRef: reciterRef,
        rewardMinutes: reward,
      );
    }
    return _plans.publish(
      QuranWardPlanPublishRequest(
        childId: ChildId(targetId),
        surahKey: surahRef,
        fromAyah: fromAyah,
        toAyah: toAyah,
        reciterKey: reciterRef,
        rewardMinutes: Minutes(reward),
        ayahKey: surahRef == 'mulk' ? 'mulk16' : 'naba1',
      ),
    );
  }

  static const _defaultSurahRef = 'naba';
  static const _defaultToAyah = 40;
  static const _defaultReciterRef = 'defaultReciter';
  static const _defaultRewardMinutes = 30;

  /// No plan row yet: the reward and the offline claim stay at zero, so the
  /// screen cannot show a number the family never set.
  QuranProgressSnapshot _emptySnapshot() =>
      const QuranProgressSnapshot(rewardMinutes: 0, offlineReady: false);

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

  Future<List<QuranPlan>> _plansOf(ChildrenData child) {
    return (_db.select(_db.quranPlans)
          ..where((t) => t.childId.equals(child.id))
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<QuranRecitation?> _latestRecitation(ChildrenData child) {
    return (_db.select(_db.quranRecitations)
          ..where((t) => t.childId.equals(child.id))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> _insertPlan({
    required String childId,
    required String surahRef,
    required int fromAyah,
    required int toAyah,
    required String reciterRef,
    required int rewardMinutes,
  }) {
    final at = clock();
    return _db
        .into(_db.quranPlans)
        .insert(
          QuranPlansCompanion.insert(
            id: stage1RowId('quran-plan', at),
            familyId: familyId,
            childId: childId,
            surahRef: surahRef,
            fromAyah: fromAyah,
            toAyah: toAyah,
            reciterRef: reciterRef,
            rewardMinutes: Value(rewardMinutes),
            active: const Value(true),
          ),
        );
  }

  /// The child's own ladder says `PENDING` or `APPROVED`; anything not yet
  /// approved reads as recorded on the father's screen.
  QuranRecitationStatus _recitationStatusOf(QuranRecitation? recitation) {
    if (recitation == null) return QuranRecitationStatus.none;
    return _isApproved(recitation.status)
        ? QuranRecitationStatus.approved
        : QuranRecitationStatus.recorded;
  }

  bool _isApproved(String raw) =>
      raw.trim().toUpperCase() == Stage1RowVocabulary.recitationApproved;
}
