import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:family_os/core/data/ai_repository.dart';
// The drift row class shares its name with the studio's note model below,
// so the library keeps its own name out of the way (`hide`).
import 'package:family_os/core/data/family_database.dart' hide FocusAdvisorNote;
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/policy/advisor_repository.dart';
import 'package:family_os/core/policy/ai_suggestion_repository.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';
import 'package:family_os/features/n03_screen_time/child_usage_report_models.dart';
import 'package:family_os/features/n03_screen_time/child_usage_report_repository.dart';
import 'package:family_os/features/n07_advisor/advisor_followup_bridge.dart';
import 'package:family_os/features/n07_advisor/agent_action_log_repository.dart';
import 'package:family_os/features/n07_advisor/advisor_voice_repository.dart';
import 'package:family_os/features/n07_advisor/family_advisor_hub_repository.dart';
import 'package:family_os/features/n07_advisor/family_moments_repository.dart';
import 'package:family_os/features/n07_advisor/family_patterns_repository.dart';
import 'package:family_os/features/n07_advisor/individual_timeline_repository.dart';
import 'package:family_os/features/n07_advisor/knowledge_maps_repository.dart';
import 'package:family_os/features/n07_advisor/mother_ai_feed_repository.dart';
import 'package:family_os/features/n07_advisor/peer_compare_repository.dart';
import 'package:family_os/features/n07_advisor/weekly_report_models.dart';
import 'package:family_os/features/n07_advisor/weekly_report_repository.dart';
import 'package:family_os/features/n14_studio/focus_report_models.dart';
import 'package:family_os/features/n14_studio/focus_report_repository.dart';

/// Stage-2 composition root for the report surfaces (ADR-054 §11).
///
/// The three reports read what the app already wrote — the wallet ledger the
/// child earns and spends, the focus sessions, the family's focus schedules and
/// the advisor's weekly note — so a report can never claim a number no row
/// supports. The bridge lives with the advisor (the reporting domain) and is
/// imported by the screen-time and studio report screens.
final class Stage1ReportsRuntime {
  Stage1ReportsRuntime._();

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

  /// SCR-FAT-069 — the child's usage summary over `wallet_ledger`.
  static ChildUsageReportRepository get usageReport =>
      DriftChildUsageReportRepository(ensureOpenSync());

  /// SCR-FAT-073 — the weekly report and its one recommendation.
  static WeeklyReportRepository get weeklyReport =>
      DriftWeeklyReportRepository(ensureOpenSync());

  /// SCR-FAT-051 — the focus week, the advisor note and the schedules.
  static FocusReportRepository get focusReport =>
      DriftFocusReportRepository(ensureOpenSync());

  /// WIR-01 — SCR-FAT-079: the father's advisor inbox over `ai_suggestion`.
  /// The screen's own rules store receives the rule an approval produces (no
  /// `rules_engine_rule` table exists in v6 — declared gap).
  static AiSuggestionRepository myAdvisor({RulesEngineRuleRepository? rules}) =>
      DriftAiSuggestionRepository(
        ensureOpenSync(),
        rules: rules ?? stage1RulesEngineRuleRepository,
      );

  /// WIR-01 — SCR-FAT-011: the same stored suggestions, on their own surface.
  static AiSuggestionRepository advisorSuggestions({
    RulesEngineRuleRepository? rules,
  }) => DriftAiSuggestionRepository(
    ensureOpenSync(),
    rules: rules ?? stage1RulesEngineRuleRepository,
  );

  /// WIR-01 — SCR-FAT-083: the voice screen, gated by the `family` row.
  static AdvisorVoiceRepository get advisorVoice =>
      DriftAdvisorVoiceRepository(ensureOpenSync());

  /// WIR-01 — SCR-FAT-074: the advisor hub over the `family` row.
  static FamilyAdvisorHubRepository get familyAdvisorHub =>
      DriftFamilyAdvisorHubRepository(ensureOpenSync());

  /// WIR-01 — SCR-FAT-076: the mother's feed over `ai_event`.
  static MotherAiFeedRepository get motherAiFeed =>
      DriftMotherAiFeedRepository(ensureOpenSync());

  /// WIR-01 — SCR-FAT-029: the brain control gateway over `ai_suggestion`.
  static AdvisorRepository get brainControl =>
      DriftAdvisorGateway(ensureOpenSync());

  /// WIR-02 — SCR-FAT-052: the child's day thread over `learn_session` +
  /// `geofence_event`.
  static IndividualTimelineRepository get individualTimeline =>
      DriftIndividualTimelineRepository(ensureOpenSync());

  /// WIR-02 — SCR-FAT-053: the family patterns over the open `learn_skill_gap`
  /// rows and each child's path.
  static FamilyPatternsRepository get familyPatterns =>
      DriftFamilyPatternsRepository(ensureOpenSync());

  /// WIR-02 — SCR-FAT-054: knowledge maps over `quran_plan` / `quran_memorization`
  /// and `learning_path`.
  static KnowledgeMapsRepository get knowledgeMaps =>
      DriftKnowledgeMapsRepository(ensureOpenSync());

  /// WIR-02 — SCR-FAT-055: the peer comparison header over `family` + `child`.
  static PeerCompareRepository get peerCompare =>
      DriftPeerCompareRepository(ensureOpenSync());

  /// WIR-02 — SCR-FAT-056: the agent action log over `ai_suggestion` stamps.
  static AgentActionLogRepository get agentActionLog =>
      DriftAgentActionLogRepository(ensureOpenSync());

  /// WIR-02 — SCR-FAT-057: family moments summed from the week's own rows.
  static FamilyMomentsRepository get familyMoments =>
      DriftFamilyMomentsRepository(ensureOpenSync());

  /// Clears this runtime only. An injected database is closed by its owner.
  static void resetForTest() => _db = null;
}

/// Shared scope + week window handling for the report adapters.
abstract base class _ReportScope {
  _ReportScope({
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

  /// The family's children, oldest first (Rule 23 — labels by order).
  Future<List<ChildrenData>> childrenInOrder(FamilyDatabase db) {
    if (familyId.isEmpty) return Future.value(const []);
    return (db.select(db.children)
          ..where((c) => c.familyId.equals(familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }

  /// The week the reports talk about starts on Saturday, the way the family
  /// calendar is read in the prototype (bars run Saturday → Friday).
  static DateTime weekStart(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final back = (today.weekday - DateTime.saturday) % 7;
    return today.subtract(Duration(days: back));
  }

  static int maskCount(int mask) {
    var count = 0;
    for (var i = 0; i < 7; i++) {
      if (mask & (1 << i) != 0) count++;
    }
    return count;
  }

  static String twoDigits(int value) => value < 10 ? '0$value' : '$value';
}

final class DriftChildUsageReportRepository
    extends _ReportScope
    implements ChildUsageReportRepository {
  DriftChildUsageReportRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<ChildUsageReportSnapshot> load() async {
    final children = await childrenInOrder(_db);
    if (children.isEmpty) return const ChildUsageReportSnapshot();

    ChildrenData? acting;
    for (final c in children) {
      if (c.id == childId) acting = c;
    }
    final child = acting ?? children.first;
    final index = children.indexOf(child);

    final rows =
        await (_db.select(_db.walletLedgerEntries)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) & t.childId.equals(child.id),
              ))
            .get();

    // Spent time is the ledger's negative side; earned (gifted) minutes are the
    // positive one — the same rows the wallet spends.
    final start = _ReportScope.weekStart(clock());
    final end = start.add(const Duration(days: 7));
    var weekSpent = 0;
    final spentByApp = <String, int>{};
    final giftedApps = <String>{};
    final spentByDay = <int, int>{};

    for (final row in rows) {
      final appId = (row.sourceRef ?? '').trim();
      if (row.deltaMinutes > 0) {
        if (appId.isNotEmpty) giftedApps.add(appId);
        continue;
      }
      final spent = -row.deltaMinutes;
      if (spent <= 0) continue;
      final at = row.createdAt;
      if (at.isBefore(start) || !at.isBefore(end)) continue;
      weekSpent += spent;
      if (appId.isNotEmpty) {
        spentByApp[appId] = (spentByApp[appId] ?? 0) + spent;
      }
      final day = at.difference(start).inDays.clamp(0, 6);
      spentByDay[day] = (spentByDay[day] ?? 0) + spent;
    }

    var busiestDay = 0;
    for (final value in spentByDay.values) {
      if (value > busiestDay) busiestDay = value;
    }
    var biggestApp = 0;
    for (final value in spentByApp.values) {
      if (value > biggestApp) biggestApp = value;
    }
    final ranked = spentByApp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ChildUsageReportSnapshot(
      childNameKey: Stage1RowVocabulary.childKeyFor(index),
      weekHours: weekSpent ~/ 60,
      weekMinutes: weekSpent % 60,
      // Bars are relative to the busiest day of the same week — never a scale
      // the rows do not carry.
      dayHeights: [
        for (var day = 0; day < 7; day++)
          busiestDay == 0
              ? 0
              : ((spentByDay[day] ?? 0) * 100 / busiestDay).round(),
      ],
      categories: [
        for (final entry in ranked)
          UsageCategoryRow(
            id: entry.key,
            // The stored app id, verbatim — the screen maps what it knows.
            labelKey: entry.key,
            hours: entry.value / 60,
            progress: biggestApp == 0 ? 0 : entry.value / biggestApp,
            giftMinutes: giftedApps.contains(entry.key),
          ),
      ],
      // Usage rows are kept thirty days (scr-FAT-069 registry line).
      retentionDays: 30,
    );
  }
}

final class DriftWeeklyReportRepository
    extends _ReportScope
    implements WeeklyReportRepository {
  DriftWeeklyReportRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.clock,
  });

  final FamilyDatabase _db;

  /// The report's own delivery choices. The contract carries no table for them
  /// yet, so they live with the repository for this slice (declared gap).
  WeeklyReportSnapshot _prefs = const WeeklyReportSnapshot();

  @override
  Future<WeeklyReportSnapshot> load() async {
    final children = await childrenInOrder(_db);
    if (children.isEmpty) return const WeeklyReportSnapshot();

    final start = _ReportScope.weekStart(clock());
    final previous = start.subtract(const Duration(days: 7));
    final rows =
        await (_db.select(_db.walletLedgerEntries)
              ..where((t) => t.familyId.equals(familyId)))
            .get();

    // The learning line is the minutes the children actually earned this week
    // against the week before — a delta the ledger can prove.
    var thisWeek = 0;
    var lastWeek = 0;
    for (final row in rows) {
      if (row.deltaMinutes <= 0) continue;
      final at = row.createdAt;
      if (!at.isBefore(start)) {
        thisWeek += row.deltaMinutes;
      } else if (!at.isBefore(previous)) {
        lastWeek += row.deltaMinutes;
      }
    }
    final deltaPercent = lastWeek == 0
        ? 0
        : (((thisWeek - lastWeek) / lastWeek) * 100).round();

    final suggestion = await _newestSuggestion();

    return WeeklyReportSnapshot(
      hasFamily: true,
      whenKey: _prefs.whenKey,
      styleKey: _prefs.styleKey,
      include: _prefs.include,
      // The recommendation is a real advisor suggestion; with none stored the
      // line stays empty instead of claiming an insight nobody wrote.
      recommendationKey: suggestion?.headline ?? '',
      learnDeltaPercent: deltaPercent,
      // The contract has no sleep table, so nothing is claimed here.
      sleepDeltaMinutes: 0,
      recommendationApplied: suggestion?.appliedAt != null,
      recommendationDeferred: suggestion?.dismissedAt != null,
    );
  }

  @override
  Future<WeeklyReportSnapshot> toggleWhen() async {
    _prefs = _prefs.copyWith(
      whenKey: _prefs.whenKey == 'fridayMorning'
          ? 'saturdayEvening'
          : 'fridayMorning',
    );
    return load();
  }

  @override
  Future<WeeklyReportSnapshot> toggleStyle() async {
    _prefs = _prefs.copyWith(
      styleKey: _prefs.styleKey == 'detailed' ? 'brief' : 'detailed',
    );
    return load();
  }

  @override
  Future<WeeklyReportSnapshot> toggleInclude(String section) async {
    final current = _prefs.include;
    _prefs = _prefs.copyWith(
      include: switch (section) {
        'screen' => current.copyWith(screen: !current.screen),
        'places' => current.copyWith(places: !current.places),
        'wins' => current.copyWith(wins: !current.wins),
        'quran' => current.copyWith(quran: !current.quran),
        'watch' => current.copyWith(watch: !current.watch),
        _ => current,
      },
    );
    return load();
  }

  @override
  Future<WeeklyReportSnapshot> applyRecommendation() async {
    await _resolve(recommendation: true);
    return load();
  }

  @override
  Future<WeeklyReportSnapshot> deferRecommendation() async {
    await _resolve(recommendation: false);
    return load();
  }

  /// Acting on the recommendation is a real decision on the advisor's own row.
  Future<void> _resolve({required bool recommendation}) async {
    final suggestion = await _newestSuggestion();
    if (suggestion == null) return;
    final ai = DriftAiRepository(_db);
    if (recommendation) {
      await ai.applySuggestion(suggestion.id, at: clock());
    } else {
      await ai.dismissSuggestion(suggestion.id, at: clock());
    }
  }

  Future<AiSuggestionRow?> _newestSuggestion() async {
    if (familyId.isEmpty) return null;
    final rows = await DriftAiRepository(
      _db,
    ).suggestionsInFamily(familyId, limit: 1);
    return rows.isEmpty ? null : rows.first;
  }
}

final class DriftFocusReportRepository
    extends _ReportScope
    implements FocusReportRepository {
  DriftFocusReportRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<FocusReportSnapshot> load() async {
    final children = await childrenInOrder(_db);
    if (children.isEmpty) return const FocusReportSnapshot();

    ChildrenData? acting;
    for (final c in children) {
      if (c.id == childId) acting = c;
    }
    final child = acting ?? children.first;
    final index = children.indexOf(child);
    final start = _ReportScope.weekStart(clock());

    // The week's focus sittings are real `learn_session` rows.
    final sessions =
        await (_db.select(_db.learnSessions)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) &
                    t.childId.equals(child.id) &
                    t.kind.equals(Stage1RowVocabulary.learnKindFocus),
              ))
            .get();
    var count = 0;
    var total = 0;
    var longest = 0;
    for (final row in sessions) {
      if (row.startedAt.isBefore(start)) continue;
      count++;
      total += row.minutes;
      if (row.minutes > longest) longest = row.minutes;
    }

    final plans =
        await (_db.select(_db.focusSchedules)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) & t.childId.equals(child.id),
              ))
            .get();
    final blocks = await (_db.select(_db.focusScheduleApps)).get();
    final appsByPlan = <String, List<String>>{};
    for (final block in blocks) {
      appsByPlan.putIfAbsent(block.scheduleId, () => []).add(block.appRef);
    }

    // The goal is the family's own plan: what its enabled schedules allow.
    var plannedMinutes = 0;
    for (final plan in plans) {
      if (!plan.enabled) continue;
      plannedMinutes +=
          (plan.endMinute - plan.startMinute) * _ReportScope.maskCount(plan.daysMask);
    }

    final note =
        await (_db.select(_db.focusAdvisorNotes)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) & t.childId.equals(child.id),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.weekStart)])
              ..limit(1))
            .getSingleOrNull();

    return FocusReportSnapshot(
      child: FocusReportChild(
        id: child.id,
        nameKey: Stage1RowVocabulary.childKeyFor(index),
      ),
      weeklySummary: FocusWeeklySummary(
        sessionsCount: count,
        totalDurationMinutes: total,
        longestSessionMinutes: longest,
        goalStatus: plannedMinutes > 0 && total >= plannedMinutes
            ? FocusReportGoalStatus.complete
            : FocusReportGoalStatus.inProgress,
      ),
      advisorNote: note == null
          ? null
          : FocusAdvisorNote(
              id: note.id,
              titleKey: note.titleRef,
              bodyKey: note.bodyRef,
              praiseSent: note.praiseSentAt != null,
              // The quote the screen shows after a send is its own copy.
              praiseQuoteKey: note.praiseSentAt == null
                  ? null
                  : 'resistDistraction',
              rewardSent: note.rewardSentAt != null,
            ),
      schedules: [
        for (final plan in plans)
          FocusScheduleItem(
            id: plan.id,
            nameKey: plan.nameRef,
            childNameKey: Stage1RowVocabulary.childKeyFor(index),
            timeKey: _windowOf(plan.startMinute, plan.endMinute),
            daysKey: _daysKeyOf(plan.daysMask),
            blockedAppKeys: appsByPlan[plan.id] ?? const [],
            enabled: plan.enabled,
          ),
      ],
    );
  }

  @override
  Future<FocusReportSnapshot> sendPraise() async {
    final child = await _actingChild();
    if (child == null) return const FocusReportSnapshot();
    final note =
        await (_db.select(_db.focusAdvisorNotes)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) & t.childId.equals(child.id),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.weekStart)])
              ..limit(1))
            .getSingleOrNull();
    if (note == null || note.praiseSentAt != null) return load();
    await (_db.update(
      _db.focusAdvisorNotes,
    )..where((t) => t.id.equals(note.id))).write(
      FocusAdvisorNotesCompanion(praiseSentAt: Value(clock())),
    );
    return load();
  }

  @override
  Future<FocusReportSnapshot> rewardSelfDiscipline() async {
    final current = await load();
    final child = current.child;
    final note = current.advisorNote;
    if (child == null || note == null || note.rewardSent) return current;
    await (_db.update(
      _db.focusAdvisorNotes,
    )..where((t) => t.id.equals(note.id))).write(
      FocusAdvisorNotesCompanion(rewardSentAt: Value(clock())),
    );
    // Minutes only (ع-١): the reward is a real ledger entry, not a tap.
    await _db
        .into(_db.walletLedgerEntries)
        .insert(
          WalletLedgerEntriesCompanion.insert(
            id: stage1RowId('ledger', clock()),
            familyId: familyId,
            childId: child.id,
            deltaMinutes: current.rewardMinutes,
            reason: Stage1RowVocabulary.walletEarned,
            sourceRef: const Value(Stage1RowVocabulary.walletSourceFocus),
          ),
        );
    return load();
  }

  @override
  Future<FocusReportSnapshot> toggleSchedule(String id, bool enabled) async {
    final child = await _actingChild();
    if (child == null) return const FocusReportSnapshot();
    await (_db.update(_db.focusSchedules)..where(
          (t) => t.id.equals(id) & t.familyId.equals(familyId),
        ))
        .write(FocusSchedulesCompanion(enabled: Value(enabled)));
    return load();
  }

  Future<ChildrenData?> _actingChild() async {
    final children = await childrenInOrder(_db);
    if (children.isEmpty) return null;
    for (final c in children) {
      if (c.id == childId) return c;
    }
    return children.first;
  }

  /// The stored window in plain clock form — the screen maps what it knows and
  /// shows the rest as it stands.
  static String _windowOf(int startMinute, int endMinute) {
    String clock(int minute) =>
        '${_ReportScope.twoDigits(minute ~/ 60)}:${_ReportScope.twoDigits(minute % 60)}';
    return '${clock(startMinute)}-${clock(endMinute)}';
  }

  /// The stored day mask as the plain list of days it covers (Sunday is 0).
  static String _daysKeyOf(int mask) {
    final days = [
      for (var day = 0; day < 7; day++)
        if (mask & (1 << day) != 0) '$day',
    ];
    return days.join(',');
  }
}
