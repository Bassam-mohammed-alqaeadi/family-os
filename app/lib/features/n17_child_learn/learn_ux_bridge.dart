import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
import 'package:family_os/features/education/learning_result_models.dart';
import 'package:family_os/features/education/learning_result_repository.dart';
import 'package:family_os/features/n17_child_learn/child_daily_review_models.dart';
import 'package:family_os/features/n17_child_learn/child_daily_review_repository.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_models.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_repository.dart';
import 'package:family_os/features/n17_child_learn/child_result_models.dart';
import 'package:family_os/features/n17_child_learn/child_result_repository.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_models.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_repository.dart';

/// Stage-2 composition root for the learning domain (ADR-054 §3 · §11.2).
///
/// The same shape as `Stage1TasksRuntime`, with one difference that matters:
/// these repos resolve the acting family and child **at load time** from the
/// identity runtime, so a screen binds them with a single line and still
/// follows a scope change. Passing explicit ids keeps the tests deterministic.
final class Stage1LearnRuntime {
  Stage1LearnRuntime._();

  static FamilyDatabase? _db;

  /// Opens once, synchronously — the getters below are screen defaults and
  /// cannot await. Pass [override] to inject a database (tests own it).
  static FamilyDatabase ensureOpenSync({FamilyDatabase? override}) {
    final existing = _db;
    if (override != null) {
      _db = override;
      return override;
    }
    if (existing != null) return existing;
    final opened = FamilyDatabase(NativeDatabase.memory());
    _db = opened;
    return opened;
  }

  /// The async twin, for callers that already start from a future.
  static Future<void> ensureOpen({FamilyDatabase? override}) async {
    ensureOpenSync(override: override);
  }

  /// Only for callers that already opened the store themselves.
  static FamilyDatabase get db {
    final value = _db;
    if (value == null) {
      throw StateError('Call Stage1LearnRuntime.ensureOpenSync() first');
    }
    return value;
  }

  /// SCR-CHD-012 — the child's learning home over `learn_*` + `wallet_ledger`.
  static ChildLearnHomeRepository get learnHome =>
      DriftChildLearnHomeRepository(ensureOpenSync());

  /// SCR-CHD-019 — points and badges over `wallet_ledger` + `learn_streak`.
  static ChildWalletRepository get wallet =>
      DriftChildWalletRepository(ensureOpenSync());

  /// The daily review sitting over `learn_skill_gap` + `learn_session`.
  static ChildDailyReviewRepository get dailyReview =>
      DriftChildDailyReviewRepository(ensureOpenSync());

  /// SCR-CHD-016 — the last measured result and what it paid.
  static ChildResultRepository get result =>
      DriftChildResultRepository(ensureOpenSync());

  /// The father→child assignment lane (P15-EDU-002) over `learn_assignment`.
  static LearningAssignmentRepository get assignments =>
      DriftLearningAssignmentRepository(ensureOpenSync());

  /// Child→father results (P15-EDU-006) over `learn_session` + `learn_result`.
  static LearningResultRepository get results =>
      DriftLearningResultRepository(ensureOpenSync());

  /// The acting child, for screens that need the raw id (never a planted one).
  static ChildId activeChildId() =>
      ChildId(stage1IdentityRuntime.activeChildId.value);

  /// Clears this runtime only. An injected database is closed by its owner.
  static void resetForTest() => _db = null;
}

/// Shared scope handling for the learning adapters: explicit ids win, otherwise
/// the identity runtime answers at call time — and an empty scope reads nothing
/// (fail-closed, ADR-054 §11).
abstract base class _LearnScope {
  _LearnScope({
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

  /// Fail-closed family scope: rows are only read for a child this family owns.
  Future<bool> childInFamily(FamilyDatabase db, [String? id]) async {
    final target = (id ?? childId).trim();
    if (familyId.isEmpty || target.isEmpty) return false;
    final row = await (db.select(db.children)
          ..where((c) => c.familyId.equals(familyId) & c.id.equals(target))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }
}

/// Where an assignment sends the child: the host decides first (a family
/// challenge lives on its own screen), then the subject.
String learnCtaFor(String kindKey, String? sourceName) {
  if (sourceName == 'familyChallenge') return 'SCR-CHD-034';
  if (sourceName == 'skillGap') return 'SCR-CHD-029';
  if (kindKey == 'quran') return 'SCR-CHD-025';
  return 'SCR-CHD-013';
}

final class DriftChildLearnHomeRepository
    extends _LearnScope
    implements ChildLearnHomeRepository {
  DriftChildLearnHomeRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<ChildLearnHomeSnapshot> load() async {
    if (!await childInFamily(_db)) return const ChildLearnHomeSnapshot();

    final now = clock();
    final assignments = await _assignmentsNewestFirst();
    final progress = await _progressByRef();
    final path = await _newestPath();

    var streakDays = 0;
    for (final row in await _streakRows()) {
      if (row.currentDays > streakDays) streakDays = row.currentDays;
    }
    final badges = await _earnedBadgeCount();

    final earnedThisMonth = await _minutesThisMonth(now);
    final averageProgress = progress.isEmpty
        ? 0
        : (progress.values.reduce((a, b) => a + b) / progress.length).round();

    return ChildLearnHomeSnapshot(
      // Level and progress are read, never minted: a level is an earned badge,
      // the bar is the path's own percent (or the mean of `learn_progress`).
      level: badges,
      levelTitleKey: (badges > 0 || path != null || assignments.isNotEmpty)
          ? 'explorer'
          : null,
      minutesEarnedThisMonth: earnedThisMonth,
      levelProgressPercent: path?.progressPercent ?? averageProgress,
      streakDays: streakDays,
      freeTime: await _hasFreeTime(),
      challenge: assignments.isEmpty ? null : _challengeFrom(assignments.first),
      materials: [
        for (final a in assignments) _materialFrom(a, progress),
      ],
    );
  }

  Future<List<LearnAssignment>> _assignmentsNewestFirst() {
    return (_db.select(_db.learnAssignments)
          ..where(
            (t) => t.familyId.equals(familyId) & t.childId.equals(childId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// `learn_progress` has no subject column: the reference is the key.
  Future<Map<String, int>> _progressByRef() async {
    final rows = await (_db.select(_db.learnProgress)
          ..where((t) => t.childId.equals(childId)))
        .get();
    return {for (final row in rows) row.contentRef: row.progressPercent};
  }

  Future<LearningPath?> _newestPath() {
    return (_db.select(_db.learningPaths)
          ..where(
            (t) => t.familyId.equals(familyId) & t.childId.equals(childId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<LearnStreak>> _streakRows() {
    return (_db.select(_db.learnStreaks)
          ..where((t) => t.childId.equals(childId)))
        .get();
  }

  Future<int> _earnedBadgeCount() async {
    final rows = await (_db.select(_db.learnAchievements)
          ..where(
            (t) => t.familyId.equals(familyId) & t.childId.equals(childId),
          ))
        .get();
    return rows.length;
  }

  /// Minutes earned inside the current calendar month, from the ledger only.
  Future<int> _minutesThisMonth(DateTime now) async {
    final rows = await _ledgerRows();
    final firstOfMonth = DateTime(now.year, now.month);
    var sum = 0;
    for (final row in rows) {
      if (row.deltaMinutes <= 0) continue;
      if (row.createdAt.isBefore(firstOfMonth)) continue;
      sum += row.deltaMinutes;
    }
    return sum;
  }

  /// «وقته مجاني» — the child holds spendable minutes in the ledger.
  Future<bool> _hasFreeTime() async {
    final rows = await _ledgerRows();
    var balance = 0;
    for (final row in rows) {
      balance += row.deltaMinutes;
    }
    return balance > 0;
  }

  Future<List<WalletLedgerEntry>> _ledgerRows() {
    return (_db.select(_db.walletLedgerEntries)
          ..where(
            (t) => t.familyId.equals(familyId) & t.childId.equals(childId),
          ))
        .get();
  }

  /// The assignment carries the host that published it; the home screen's
  /// challenge line is that host, spelled in the keys it already knows.
  ChildLearnChallenge _challengeFrom(LearnAssignment a) {
    final key = switch (Stage1RowVocabulary.learnSourceOf(a.requestId)) {
      'homework' => 'assignedHomework',
      'familyChallenge' => 'assignedFamily',
      'skillGap' => 'assignedSkillGap',
      _ => 'assignedChallenge',
    };
    return ChildLearnChallenge(
      titleKey: key,
      rewardMinutes: a.rewardMinutes,
      ctaScreenId: learnCtaFor(
        a.kind.toLowerCase(),
        Stage1RowVocabulary.learnSourceOf(a.requestId),
      ),
    );
  }

  ChildLearnMaterialRow _materialFrom(
    LearnAssignment a,
    Map<String, int> progress,
  ) {
    final kindKey = a.kind.trim().toLowerCase();
    final kind = switch (kindKey) {
      'quran' => ChildLearnSubjectKind.quran,
      'english' => ChildLearnSubjectKind.english,
      'math' => ChildLearnSubjectKind.math,
      _ => ChildLearnSubjectKind.math,
    };
    final percent = progress[a.contentRef];
    return ChildLearnMaterialRow(
      id: 'mat_${a.id}',
      kind: kind,
      // The subject key and the stored reference, verbatim — the screen maps
      // the first and shows the second as it stands.
      titleKey: switch (kindKey) {
        'quran' || 'english' || 'math' => kindKey,
        _ => a.kind,
      },
      subtitleKey: a.contentRef,
      tag: percent != null
          ? ChildLearnMaterialTag.progress
          : (a.status == Stage1RowVocabulary.learnAssigned
                ? ChildLearnMaterialTag.neu
                : ChildLearnMaterialTag.chevron),
      progressPercent: percent,
      ctaScreenId: learnCtaFor(
        kindKey,
        Stage1RowVocabulary.learnSourceOf(a.requestId),
      ),
    );
  }
}

final class DriftChildWalletRepository
    extends _LearnScope
    implements ChildWalletRepository {
  DriftChildWalletRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<ChildWalletSnapshot> load() async {
    if (!await childInFamily(_db)) return const ChildWalletSnapshot();

    final ledger = await (_db.select(_db.walletLedgerEntries)
          ..where(
            (t) => t.familyId.equals(familyId) & t.childId.equals(childId),
          ))
        .get();

    // Balances are the ledger's own signed deltas, grouped by the app the
    // minutes were earned for. A wallet with no row is not invented.
    final byApp = <String, int>{};
    var total = 0;
    for (final row in ledger) {
      final appId = (row.sourceRef ?? '').trim();
      if (appId.isEmpty) continue;
      byApp[appId] = (byApp[appId] ?? 0) + row.deltaMinutes;
      total += row.deltaMinutes;
    }

    var streakDays = 0;
    var recordDays = 0;
    for (final row in await _streakRows()) {
      if (row.currentDays > streakDays) streakDays = row.currentDays;
      if (row.recordDays > recordDays) recordDays = row.recordDays;
    }

    final badges = await (_db.select(_db.learnAchievements)
          ..where(
            (t) => t.familyId.equals(familyId) & t.childId.equals(childId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.earnedAt)]))
        .get();

    return ChildWalletSnapshot(
      totalMinutes: total,
      streakDays: streakDays,
      recordStreakDays: recordDays,
      apps: [
        for (final entry in byApp.entries)
          ChildWalletApp(
            id: entry.key,
            nameKey: _nameKeyFor(entry.key),
            iconKey: entry.key,
            walletMinutes: entry.value,
          ),
      ],
      // Only a real `learn_achievement` row earns a badge — the date is the
      // fact, so nothing is ticked without one.
      badges: [
        for (final badge in badges)
          ChildWalletBadge(id: badge.id, labelKey: badge.badgeRef, earned: true),
      ],
      // Balances are real rows; enforcement on the device is not live yet.
      simulated: true,
    );
  }

  Future<List<LearnStreak>> _streakRows() {
    return (_db.select(_db.learnStreaks)
          ..where((t) => t.childId.equals(childId)))
        .get();
  }

  static String _nameKeyFor(String appId) {
    final id = appId.trim().toLowerCase();
    if (id == 'youtube' || id.startsWith('yt')) return 'youtube';
    if (id == 'games' || id == 'gaming') return 'games';
    if (id == 'social' || id == 'chat') return 'social';
    if (id == 'quran') return 'quran';
    return id;
  }
}

final class DriftChildDailyReviewRepository
    extends _LearnScope
    implements ChildDailyReviewRepository {
  DriftChildDailyReviewRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<ChildDailyReviewSnapshot> load() async {
    if (!await childInFamily(_db)) return const ChildDailyReviewSnapshot();

    // The cards are the child's outstanding `learn_skill_gap` rows — a gap is
    // a row, never a badge the screen infers.
    final gaps = await (_db.select(_db.learnSkillGaps)
          ..where(
            (t) =>
                t.childId.equals(childId) &
                t.status.isNotIn([Stage1RowVocabulary.learnClosed]),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();

    return ChildDailyReviewSnapshot(
      hasCards: gaps.isNotEmpty,
      cards: [
        for (final gap in gaps)
          ChildReviewCard(
            id: gap.id,
            // The stored skill and its own status, verbatim — never a review
            // schedule the row does not state.
            titleKey: gap.skillRef,
            metaKey: gap.status,
            strong: gap.status == Stage1RowVocabulary.learnMastered,
          ),
      ],
      // The payout policy for a review sits in `attribution_rule` (Studio);
      // stage 1 keeps the screen's own ten minutes.
      rewardMinutes: 10,
      sessionDone: await _doneToday(),
    );
  }

  @override
  Future<ChildDailyReviewSnapshot> completeSession() async {
    if (!await childInFamily(_db)) return const ChildDailyReviewSnapshot();
    final now = clock();
    await _db
        .into(_db.learnSessions)
        .insert(
          LearnSessionsCompanion.insert(
            id: stage1RowId('learn-session', now),
            familyId: familyId,
            childId: childId,
            kind: Stage1RowVocabulary.learnKindReview,
            status: Stage1RowVocabulary.learnDone,
            requestId: Stage1RowVocabulary.learnRequestIdFor('child', now),
            // The injected clock is what `_doneToday()` reads back, so the row
            // it writes has to carry that same day — not the machine's default.
            startedAt: Value(now),
          ),
        );
    return load();
  }

  /// A review is done when today's own row exists — not a flag in the screen.
  Future<bool> _doneToday() async {
    final now = clock();
    final rows = await (_db.select(_db.learnSessions)
          ..where(
            (t) =>
                t.familyId.equals(familyId) &
                t.childId.equals(childId) &
                t.kind.equals(Stage1RowVocabulary.learnKindReview),
          ))
        .get();
    for (final row in rows) {
      final at = row.startedAt;
      if (at.year == now.year && at.month == now.month && at.day == now.day) {
        return true;
      }
    }
    return false;
  }
}

final class DriftChildResultRepository
    extends _LearnScope
    implements ChildResultRepository {
  DriftChildResultRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<ChildResultSnapshot> load() async {
    if (!await childInFamily(_db)) return const ChildResultSnapshot();

    final result = await (_db.select(_db.learnResults)
          ..where((t) => t.childId.equals(childId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (result == null) return const ChildResultSnapshot();

    // What this measurement paid: the ledger entries written at the same
    // moment for the same skill.
    final ledger = await (_db.select(_db.walletLedgerEntries)
          ..where(
            (t) =>
                t.childId.equals(childId) &
                t.sourceRef.equals(result.skillRef),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    final paid = ledger
        .where(
          (r) =>
              r.createdAt
                  .difference(result.createdAt)
                  .inMinutes
                  .abs() <=
              1,
        )
        .toList();

    final gap = await (_db.select(_db.learnSkillGaps)
          ..where(
            (t) =>
                t.childId.equals(childId) &
                t.status.isNotIn([Stage1RowVocabulary.learnClosed]),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();

    final answeredAll = result.total > 0 && result.correct >= result.total;

    return ChildResultSnapshot(
      scoreCorrect: result.correct,
      scoreTotal: result.total,
      // Praise is only the screen's mastered key on a full score; otherwise the
      // screen's own encouragement stands (a wrong answer is never punished).
      praiseKey: answeredAll ? 'masteredAdd' : null,
      missedTitleKey: gap?.skillRef,
      missedBodyKey: gap?.status,
      rewards: [
        for (final row in paid)
          ChildResultRewardRow(
            id: row.id,
            titleKey: row.reason,
            tagKey: 'arrived',
            subtitleKey: '${row.deltaMinutes} min',
          ),
      ],
    );
  }
}

final class DriftLearningAssignmentRepository
    extends _LearnScope
    implements LearningAssignmentRepository {
  DriftLearningAssignmentRepository(
    this._db, {
    super.familyId,
    super.childId,
    String? createdByAccount,
    super.clock,
  }) : _createdByAccount = createdByAccount?.trim() ?? '';

  final FamilyDatabase _db;
  final String _createdByAccount;
  final _controller = StreamController<LearningAssignment>.broadcast();

  @override
  Stream<LearningAssignment> get assignments => _controller.stream;

  @override
  Future<List<LearningAssignment>> listForChild(ChildId childId) async {
    if (!await childInFamily(_db, childId.value)) return const [];
    final rows =
        await (_db.select(_db.learnAssignments)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) &
                    t.childId.equals(childId.value),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    return [for (final row in rows) _toModel(row)];
  }

  @override
  Future<LearningAssignment?> latestForChild(ChildId childId) async {
    final rows = await listForChild(childId);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<LearningAssignment> publish(
    LearningAssignmentPublishRequest request,
  ) async {
    final now = clock();
    final id = stage1RowId('assign', now);
    final owned = await childInFamily(_db, request.childId.value);
    if (owned) {
      await _db
          .into(_db.learnAssignments)
          .insert(
            LearnAssignmentsCompanion.insert(
              id: id,
              familyId: familyId,
              childId: request.childId.value,
              kind: request.materialKindKey.trim().toUpperCase(),
              contentRef: request.titleKey,
              rewardMinutes: Value(request.rewardMinutes.inMinutes),
              status: Stage1RowVocabulary.learnAssigned,
              assignedByAccount: _createdByAccount,
              requestId: Stage1RowVocabulary.learnRequestIdFor(
                request.source.name,
                now,
              ),
            ),
          );
    }
    // Fail-closed: an assignment for a child this family does not own is
    // handed back to the caller, never written.
    final model = LearningAssignment(
      id: id,
      childId: request.childId,
      titleKey: request.titleKey,
      rewardMinutes: request.rewardMinutes,
      source: request.source,
      assignedAt: now,
      // The same rule a reload applies, so read-after-write agrees.
      ctaScreenId: learnCtaFor(
        request.materialKindKey.trim().toLowerCase(),
        request.source.name,
      ),
      materialKindKey: request.materialKindKey,
    );
    if (owned) _controller.add(model);
    return model;
  }

  LearningAssignment _toModel(LearnAssignment row) {
    final sourceName = Stage1RowVocabulary.learnSourceOf(row.requestId);
    final source = LearningAssignmentSource.values.firstWhere(
      (s) => s.name == sourceName,
      orElse: () => LearningAssignmentSource.attribution,
    );
    final kindKey = row.kind.trim().toLowerCase();
    return LearningAssignment(
      id: row.id,
      childId: ChildId(row.childId),
      titleKey: row.contentRef,
      rewardMinutes: Minutes(row.rewardMinutes),
      source: source,
      assignedAt: row.createdAt,
      ctaScreenId: learnCtaFor(kindKey, source.name),
      materialKindKey: kindKey,
    );
  }

}

final class DriftLearningResultRepository
    extends _LearnScope
    implements LearningResultRepository {
  DriftLearningResultRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.clock,
  });

  final FamilyDatabase _db;
  final _controller = StreamController<LearningResultSubmission>.broadcast();

  @override
  Stream<LearningResultSubmission> get submissions => _controller.stream;

  @override
  Future<LearningResultSubmission> submit(
    LearningResultSubmitRequest request,
  ) async {
    final now = clock();
    final sessionId = stage1RowId('learn-session', now);
    final resultId = stage1RowId('learn-result', now);
    final owned = await childInFamily(_db, request.childId.value);

    // A measurement is always a sitting: the session row first, then the
    // measurement, then what it paid — three facts, no derived badge.
    if (owned) {
      await _db
          .into(_db.learnSessions)
          .insert(
            LearnSessionsCompanion.insert(
              id: sessionId,
              familyId: familyId,
              childId: request.childId.value,
              kind: _kindFor(request.kind),
              contentRef: Value(request.titleKey),
              minutes: Value(request.rewardMinutes.inMinutes),
              status: Stage1RowVocabulary.learnDone,
              requestId: Stage1RowVocabulary.learnRequestIdFor(
                request.kind.name,
                now,
              ),
            ),
          );
      await _db
          .into(_db.learnResults)
          .insert(
            LearnResultsCompanion.insert(
              id: resultId,
              sessionId: sessionId,
              childId: request.childId.value,
              skillRef: request.titleKey,
              correct: Value(request.scoreCorrect ?? 0),
              total: Value(request.scoreTotal ?? 0),
              masteryPercent: Value(_masteryPercent(request)),
            ),
          );
      if (request.rewardMinutes.inMinutes > 0) {
        await _db
            .into(_db.walletLedgerEntries)
            .insert(
              WalletLedgerEntriesCompanion.insert(
                id: stage1RowId('ledger', now),
                familyId: familyId,
                childId: request.childId.value,
                deltaMinutes: request.rewardMinutes.inMinutes,
                reason: Stage1RowVocabulary.walletEarned,
                sourceRef: Value(request.titleKey),
              ),
            );
      }
    }

    final submission = LearningResultSubmission(
      id: resultId,
      childId: request.childId,
      kind: request.kind,
      titleKey: request.titleKey,
      submittedAt: now,
      rewardMinutes: request.rewardMinutes,
      scoreCorrect: request.scoreCorrect,
      scoreTotal: request.scoreTotal,
    );
    if (owned) _controller.add(submission);
    return submission;
  }

  @override
  Future<List<LearningResultSubmission>> listRecent({int limit = 20}) async {
    if (!await childInFamily(_db)) return const [];
    final results =
        await (_db.select(_db.learnResults)
              ..where((t) => t.childId.equals(childId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(limit))
            .get();
    if (results.isEmpty) return const [];

    final sessions =
        await (_db.select(_db.learnSessions)
              ..where((t) => t.childId.equals(childId)))
            .get();
    final byId = {for (final row in sessions) row.id: row};

    return [
      for (final row in results)
        LearningResultSubmission(
          id: row.id,
          childId: ChildId(row.childId),
          kind: _kindOf(byId[row.sessionId]?.kind),
          titleKey: row.skillRef,
          submittedAt: row.createdAt,
          // What the sitting paid rides on the session row (the ledger carries
          // the same minutes as the money-of-record).
          rewardMinutes: Minutes(byId[row.sessionId]?.minutes ?? 0),
          scoreCorrect: row.correct,
          scoreTotal: row.total,
        ),
    ];
  }

  static String _kindFor(LearningResultKind kind) => switch (kind) {
    LearningResultKind.quiz => Stage1RowVocabulary.learnKindQuiz,
    LearningResultKind.homework => Stage1RowVocabulary.learnKindHomework,
    LearningResultKind.familyChallenge => Stage1RowVocabulary.learnKindChallenge,
  };

  static LearningResultKind _kindOf(String? stored) => switch (stored) {
    Stage1RowVocabulary.learnKindHomework => LearningResultKind.homework,
    Stage1RowVocabulary.learnKindChallenge =>
      LearningResultKind.familyChallenge,
    _ => LearningResultKind.quiz,
  };

  static int? _masteryPercent(LearningResultSubmitRequest request) {
    final total = request.scoreTotal ?? 0;
    if (total <= 0) return null;
    return (((request.scoreCorrect ?? 0) / total) * 100).round();
  }
}
