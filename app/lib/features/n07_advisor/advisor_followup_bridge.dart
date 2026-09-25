import 'package:drift/drift.dart';

import 'package:family_os/core/data/ai_repository.dart';
import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/policy/advisor_repository.dart';
import 'package:family_os/core/policy/ai_stage_id.dart';
import 'package:family_os/core/policy/ai_suggestion_repository.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';
import 'package:family_os/features/n07_advisor/advisor_voice_models.dart';
import 'package:family_os/features/n07_advisor/advisor_voice_repository.dart';
import 'package:family_os/features/n07_advisor/family_advisor_hub_models.dart';
import 'package:family_os/features/n07_advisor/family_advisor_hub_repository.dart';
import 'package:family_os/features/n07_advisor/agent_action_log_models.dart';
import 'package:family_os/features/n07_advisor/agent_action_log_repository.dart';
import 'package:family_os/features/n07_advisor/family_moments_models.dart';
import 'package:family_os/features/n07_advisor/family_moments_repository.dart';
import 'package:family_os/features/n07_advisor/family_patterns_models.dart';
import 'package:family_os/features/n07_advisor/family_patterns_repository.dart';
import 'package:family_os/features/n07_advisor/individual_timeline_models.dart';
import 'package:family_os/features/n07_advisor/individual_timeline_repository.dart';
import 'package:family_os/features/n07_advisor/knowledge_maps_models.dart';
import 'package:family_os/features/n07_advisor/knowledge_maps_repository.dart';
import 'package:family_os/features/n07_advisor/mother_ai_feed_models.dart';
import 'package:family_os/features/n07_advisor/mother_ai_feed_repository.dart';
import 'package:family_os/features/n07_advisor/peer_compare_models.dart';
import 'package:family_os/features/n07_advisor/peer_compare_repository.dart';

/// WIR-01 — the advisor domain's six surfaces on the ADR-054 v6 rows:
/// `ai_suggestion` (الاقتراحات · مساعدي · لوحة العقل) · `family` (صوت المستشار ·
/// عقل عائلتي) · `ai_event` (إخطارات الذكاء للأم).
///
/// The campaign rule holds here too: a row is a fact, a missing column is a
/// declared gap, and what a screen does on the device (pressing the mic, asking
/// the advisor) never pretends to be stored family data. The adapters live with
/// the advisor because `Stage1ReportsRuntime` is this domain's one runtime.
abstract base class _AdvisorFollowupScope {
  _AdvisorFollowupScope({
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

  /// The `family` row that gates every advisor surface; an empty or unowned
  /// scope owns no family and reads nothing.
  Future<bool> familyExists(FamilyDatabase db) async {
    if (familyId.isEmpty) return false;
    final row =
        await (db.select(db.families)
              ..where((f) => f.id.equals(familyId))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// The family's children, oldest first (Rule 23 — labelled by order).
  Future<List<ChildrenData>> childrenInOrder(FamilyDatabase db) {
    if (familyId.isEmpty) return Future.value(const []);
    return (db.select(db.children)
          ..where((c) => c.familyId.equals(familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }

  /// The child a family-scoped event speaks about: the live child when the
  /// family holds that row, otherwise the first child on record.
  Future<ChildrenData?> actingChild(FamilyDatabase db) async {
    final children = await childrenInOrder(db);
    if (children.isEmpty) return null;
    for (final child in children) {
      if (child.id == childId) return child;
    }
    return children.first;
  }

  /// The alias an `ai_event` is keyed by (Rule 13/23 — never the name).
  Future<String?> actingChildAlias(FamilyDatabase db) async {
    final child = await actingChild(db);
    final alias = child?.alias.trim() ?? '';
    return alias.isEmpty ? null : alias;
  }
}

/// One stored suggestion, seen through the policy value type. The `title` is
/// the row's own `headline`; `body`, `stage` and `proposedConsequentIds` have no
/// column on `ai_suggestion`, so they stay empty/default (declared gap).
AiSuggestion _suggestionFromRow(AiSuggestionRow row) => AiSuggestion(
  id: row.id,
  title: row.headline,
  body: '',
  stage: AiStageId.suggest,
);

/// A stored decision: dismissed wins, then applied (an undone apply returns to
/// pending), otherwise it is still waiting.
AiSuggestionDecision _decisionOfRow(AiSuggestionRow row) {
  if (row.dismissedAt != null) return AiSuggestionDecision.rejected;
  if (row.appliedAt != null && row.undoneAt == null) {
    return AiSuggestionDecision.approved;
  }
  return AiSuggestionDecision.pending;
}

/// SCR-FAT-079 / SCR-FAT-011 — the father's suggestion inbox over
/// `ai_suggestion`.
///
/// The pending list is the family's own rows that are neither applied nor
/// dismissed, and a decision is a stamp on that row (ADR-042): approving writes
/// `applied_at`, rejecting writes `dismissed_at`, and both survive a reopen.
/// The rule an approval produces has no v6 table, so it is handed to the
/// screen's own rules store (declared gap: `rules_engine_rule` does not exist in
/// the contract); the row keeps no consequent list either, so the SET-023
/// forbidden-draft check sees an empty draft.
final class DriftAiSuggestionRepository extends _AdvisorFollowupScope
    implements AiSuggestionRepository {
  DriftAiSuggestionRepository(
    this._db, {
    RulesEngineRuleRepository? rules,
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  }) : _rules = rules ?? stage1RulesEngineRuleRepository;

  final FamilyDatabase _db;
  final RulesEngineRuleRepository _rules;

  @override
  Future<List<AiSuggestionInboxItem>> listInbox() async {
    if (familyId.isEmpty) return const [];
    final rows =
        await (_db.select(_db.aiSuggestions)
              ..where((t) => t.familyId.equals(familyId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    return List.unmodifiable([
      for (final row in rows)
        AiSuggestionInboxItem(
          suggestion: _suggestionFromRow(row),
          decision: _decisionOfRow(row),
        ),
    ]);
  }

  @override
  Future<List<AiSuggestionInboxItem>> listPending() async {
    final all = await listInbox();
    return List.unmodifiable([
      for (final item in all)
        if (item.decision == AiSuggestionDecision.pending) item,
    ]);
  }

  @override
  Future<void> approve(String suggestionId) async {
    final row = await _rowById(suggestionId);
    if (row == null) {
      throw StateError('Unknown suggestion: $suggestionId');
    }
    if (_decisionOfRow(row) == AiSuggestionDecision.approved) return;
    // The rules store is asked first so a forbidden draft refuses before the
    // row is stamped, exactly as the suggest-only contract says.
    await _rules.addFromApprovedSuggestion(_suggestionFromRow(row));
    await (_db.update(
      _db.aiSuggestions,
    )..where((t) => t.id.equals(suggestionId))).write(
      AiSuggestionsCompanion(
        appliedAt: Value(clock()),
        undoneAt: const Value(null),
      ),
    );
  }

  @override
  Future<void> reject(String suggestionId) async {
    final row = await _rowById(suggestionId);
    if (row == null) {
      throw StateError('Unknown suggestion: $suggestionId');
    }
    await (_db.update(
      _db.aiSuggestions,
    )..where((t) => t.id.equals(suggestionId))).write(
      AiSuggestionsCompanion(dismissedAt: Value(clock())),
    );
  }

  Future<AiSuggestionRow?> _rowById(String id) {
    return (_db.select(_db.aiSuggestions)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
  }
}

/// SCR-FAT-083 — the voice conversation with the family advisor.
///
/// What the contract can prove is only that a family exists: the `family` row
/// gates the empty state. No table keeps an advisor transcript — the `message`
/// store is the family's own encrypted thread — so the last turns are a
/// declared gap, and listening is the microphone's own device state.
final class DriftAdvisorVoiceRepository extends _AdvisorFollowupScope
    implements AdvisorVoiceRepository {
  DriftAdvisorVoiceRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  var _listening = false;

  @override
  Future<AdvisorVoiceSnapshot> load() async {
    return AdvisorVoiceSnapshot(
      hasFamily: await familyExists(_db),
      listening: _listening,
      lastTurns: const [],
    );
  }

  @override
  Future<AdvisorVoiceSnapshot> pressTalk() async {
    // Talking is the device's microphone; it writes no row.
    _listening = true;
    return load();
  }
}

/// SCR-FAT-074 — the family advisor hub.
///
/// The one family fact is the `family` row that turns the hub on; with none it
/// reads nothing. The quick chips and the capability / sovereignty rows are the
/// prototype's own navigation structure (the frozen reference is product law)
/// rather than stored family data — no v6 table keeps them — and the free-text
/// ask has no advisor backend in stage 1, so it writes nothing (declared gap).
final class DriftFamilyAdvisorHubRepository extends _AdvisorFollowupScope
    implements FamilyAdvisorHubRepository {
  DriftFamilyAdvisorHubRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  static const _suggestions = [
    AdvisorSuggestionChip(
      id: 'daySummary',
      labelKey: 'daySummary',
      sheetKey: 'daySummary',
    ),
    AdvisorSuggestionChip(
      id: 'weekly',
      labelKey: 'weeklyReport',
      navigateTo: 'SCR-FAT-073',
    ),
    AdvisorSuggestionChip(
      id: 'activity',
      labelKey: 'familyActivity',
      sheetKey: 'activity',
    ),
    AdvisorSuggestionChip(
      id: 'patterns',
      labelKey: 'patterns',
      navigateTo: 'SCR-FAT-062',
    ),
  ];

  static const _capabilities = [
    AdvisorCapabilityRow(
      id: 'voice',
      titleKey: 'voice',
      subKey: 'voiceSub',
      navigateTo: 'SCR-FAT-083',
    ),
    AdvisorCapabilityRow(
      id: 'delegate',
      titleKey: 'delegate',
      subKey: 'delegateSub',
      navigateTo: 'SCR-FAT-079',
    ),
    AdvisorCapabilityRow(
      id: 'maps',
      titleKey: 'maps',
      subKey: 'mapsSub',
      navigateTo: 'SCR-FAT-064',
    ),
    AdvisorCapabilityRow(
      id: 'motherFeed',
      titleKey: 'motherFeed',
      subKey: 'motherFeedSub',
      navigateTo: 'SCR-FAT-076',
    ),
  ];

  static const _sovereigntyRows = [
    AdvisorCapabilityRow(
      id: 'limits',
      titleKey: 'limits',
      subKey: 'limitsSub',
      navigateTo: 'SCR-FAT-029',
    ),
    AdvisorCapabilityRow(
      id: 'agentLog',
      titleKey: 'agentLog',
      subKey: 'agentLogSub',
      navigateTo: 'SCR-FAT-080',
    ),
  ];

  final FamilyDatabase _db;

  @override
  Future<FamilyAdvisorHubSnapshot> load() async {
    if (!await familyExists(_db)) return const FamilyAdvisorHubSnapshot();
    return const FamilyAdvisorHubSnapshot(
      hasFamily: true,
      suggestions: _suggestions,
      capabilities: _capabilities,
      sovereigntyRows: _sovereigntyRows,
    );
  }

  @override
  Future<void> askFreeText(String text) async {
    // The adviser's free-text answer is a gateway concern, not a local row; the
    // screen's toast is the acknowledgement (declared gap).
  }
}

/// SCR-FAT-076 — the mother's intelligence feed over `ai_event`.
///
/// Each summary is one stored event: the kind is its title token and the domain
/// its body token, with the tag following the event's own severity (a severe
/// one reads as a watch item). Sending a whisper to the father writes a real
/// `COM` / `MOTHERS_WHISPER` event keyed by the acting child's alias (Rule
/// 13/23), so it survives a reopen and never duplicates; the feed itself leaves
/// the whisper out of its own summaries.
final class DriftMotherAiFeedRepository extends _AdvisorFollowupScope
    implements MotherAiFeedRepository {
  DriftMotherAiFeedRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  static const _watchSeverity = 4;

  final FamilyDatabase _db;

  @override
  Future<MotherAiFeedSnapshot> load() async {
    if (!await familyExists(_db)) return const MotherAiFeedSnapshot();
    final events =
        await (_db.select(_db.aiEvents)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) &
                    t.kind.isNotIn([Stage1RowVocabulary.aiKindMothersWhisper]),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.occurredAt),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(20))
            .get();
    return MotherAiFeedSnapshot(
      hasFamily: true,
      whisperSent: await _whisperSent(),
      items: [
        for (final event in events)
          MotherFeedItem(
            id: event.id.toString(),
            titleKey: event.kind,
            bodyKey: event.domain,
            tagKey: event.severity >= _watchSeverity ? 'watch' : 'good',
          ),
      ],
    );
  }

  @override
  Future<MotherAiFeedSnapshot> sendWhisper() async {
    if (familyId.isEmpty) return load();
    if (await _whisperSent()) return load();
    final alias = await actingChildAlias(_db);
    // `ai_event` is keyed by an alias; with no child on record there is nothing
    // to key the whisper to, so it stays unsent rather than borrowing a name.
    if (alias == null) return load();
    await DriftAiRepository(_db).recordEvent(
      familyId: familyId,
      childAlias: alias,
      domain: Stage1RowVocabulary.aiDomainCommunication,
      kind: Stage1RowVocabulary.aiKindMothersWhisper,
      severity: 2,
      at: clock(),
    );
    return load();
  }

  Future<bool> _whisperSent() async {
    if (familyId.isEmpty) return false;
    final row =
        await (_db.select(_db.aiEvents)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) &
                    t.kind.equals(Stage1RowVocabulary.aiKindMothersWhisper),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }
}

/// SCR-FAT-029 — the brain control stage gateway over `ai_suggestion`.
///
/// The stage flags are server remote config (SET-014) and stay where they are;
/// what this adapter carries is the suggest-only payload every enabled stage
/// opens — the family's own stored suggestions. `ai_suggestion` keeps no stage
/// column, so every stored row reads as the suggest stage (declared gap); the
/// body stays empty for the same reason.
final class DriftAdvisorGateway extends _AdvisorFollowupScope
    implements AdvisorRepository {
  DriftAdvisorGateway(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<List<AiSuggestion>> suggestions({
    AiStageId stage = AiStageId.suggest,
  }) async {
    if (familyId.isEmpty) return const [];
    final rows =
        await (_db.select(_db.aiSuggestions)
              ..where((t) => t.familyId.equals(familyId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    return List.unmodifiable([
      for (final row in rows) _suggestionFromRow(row),
    ]);
  }
}

/// WIR-02A — SCR-FAT-052 فردوس الخطّ الزمني: the child's own day thread, built
/// from the rows the day actually leaves — `learn_session` sittings and the
/// `geofence_event` entrances — with the advisor's last applied `ai_suggestion`
/// as the insight. The thread's hourly copy keys have no column, so each stop
/// carries its own row's real label token and the day-relative time key.
final class DriftIndividualTimelineRepository extends _AdvisorFollowupScope
    implements IndividualTimelineRepository {
  DriftIndividualTimelineRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<IndividualTimelineSnapshot> load() async {
    if (!await familyExists(_db)) return const IndividualTimelineSnapshot();
    final children = await childrenInOrder(_db);
    if (children.isEmpty) return const IndividualTimelineSnapshot();
    var ordinal = 0;
    var child = children.first;
    for (var i = 0; i < children.length; i++) {
      if (children[i].id == childId) {
        child = children[i];
        ordinal = i;
        break;
      }
    }
    final now = clock();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final timed = <(DateTime, IndividualTimelineStop)>[];

    final sittings =
        await (_db.select(_db.learnSessions)
              ..where((t) => t.childId.equals(child.id))
              ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
            .get();
    for (final sitting in sittings) {
      final at = sitting.startedAt;
      if (at.isBefore(dayStart) || !at.isBefore(dayEnd)) continue;
      timed.add((
        at,
        IndividualTimelineStop(
          id: sitting.id,
          kind: _stopKindOf(sitting.kind),
          // The row's own content ref (else its kind) names the stop.
          titleKey: (sitting.contentRef ?? sitting.kind).trim(),
          timeKey: Stage1RowVocabulary.timeKeyFor(at, now),
        ),
      ));
    }

    final events =
        await (_db.select(_db.geofenceEvents)
              ..where(
                (e) =>
                    e.childId.equals(child.id) &
                    e.kind.equalsValue(GeofenceEventKind.enter),
              )
              ..orderBy([(e) => OrderingTerm.asc(e.occurredAt)]))
            .get();
    for (final event in events) {
      final at = event.occurredAt;
      if (at.isBefore(dayStart) || !at.isBefore(dayEnd)) continue;
      final fence =
          await (_db.select(_db.geofences)
                ..where((g) => g.id.equals(event.geofenceId)))
              .getSingleOrNull();
      timed.add((
        at,
        IndividualTimelineStop(
          id: 'geo_${event.id}',
          kind: IndividualTimelineStopKind.schoolMode,
          titleKey: (fence?.name ?? '').trim(),
          timeKey: Stage1RowVocabulary.timeKeyFor(at, now),
        ),
      ));
    }

    timed.sort((a, b) => a.$1.compareTo(b.$1));
    final stops = <IndividualTimelineStop>[];
    for (var i = 0; i < timed.length; i++) {
      final stop = timed[i].$2;
      // The prototype's «now» marker rides the last real stop of the day.
      stops.add(
        i == timed.length - 1
            ? IndividualTimelineStop(
                id: stop.id,
                kind: stop.kind,
                titleKey: stop.titleKey,
                timeKey: stop.timeKey,
                detailKey: stop.detailKey,
                isNow: true,
              )
            : stop,
      );
    }

    final suggestion =
        await (_db.select(_db.aiSuggestions)
              ..where(
                (t) => t.familyId.equals(familyId) & t.appliedAt.isNotNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.appliedAt)])
              ..limit(1))
            .getSingleOrNull();
    return IndividualTimelineSnapshot(
      nameKey: Stage1RowVocabulary.childKeyFor(ordinal),
      insight: suggestion == null
          ? null
          : IndividualTimelineInsight(
              id: suggestion.id,
              badgeKey: suggestion.actionKind,
              patternKey: suggestion.actionKind,
              suggestionKey: suggestion.headline,
              // The privacy line is copy with no column.
              privacyNoteKey: '',
            ),
      todayStops: stops,
    );
  }

  static IndividualTimelineStopKind _stopKindOf(String kind) {
    switch (kind.trim().toUpperCase()) {
      case Stage1RowVocabulary.learnKindFocus:
      case Stage1RowVocabulary.learnKindLesson:
      case Stage1RowVocabulary.learnKindQuiz:
      case Stage1RowVocabulary.learnKindHomework:
      case Stage1RowVocabulary.learnKindReview:
        return IndividualTimelineStopKind.studyComplete;
      default:
        return IndividualTimelineStopKind.studyComplete;
    }
  }
}

/// WIR-02B — SCR-FAT-053 أنماط العائلة: the patterns are the child's own open
/// `learn_skill_gap` rows (an open gap IS an education signal), their weight the
/// gap's measured share, and the children's cards carry their path's real
/// progress. Sleep/communication patterns have no rows in v6, so they simply do
/// not appear — never invented.
final class DriftFamilyPatternsRepository extends _AdvisorFollowupScope
    implements FamilyPatternsRepository {
  DriftFamilyPatternsRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<FamilyPatternsSnapshot> load() async {
    if (!await familyExists(_db)) return const FamilyPatternsSnapshot();
    final children = await childrenInOrder(_db);
    if (children.isEmpty) return const FamilyPatternsSnapshot();
    final cards = <FamilyPatternChildCard>[];
    var missed = 0;
    var total = 0;

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      // Each card carries only its own child's rows (Rule 23 keeps the label).
      final patterns = <FamilyPatternRow>[];
      final gaps =
          await (_db.select(_db.learnSkillGaps)
                ..where(
                  (g) =>
                      g.childId.equals(child.id) &
                      g.status.equals(Stage1RowVocabulary.learnOpen),
                )
                ..orderBy([(g) => OrderingTerm.desc(g.updatedAt)]))
              .get();
      for (final gap in gaps) {
        missed += gap.missed;
        total += gap.total;
        patterns.add(
          FamilyPatternRow(
            id: gap.id,
            // The row's subject is the only domain v6 can prove here.
            domain: FamilyPatternDomain.education,
            titleKey: gap.skillRef,
            // An open gap is the watch signal the row itself carries.
            tag: FamilyPatternTag.watch,
          ),
        );
      }
      final path =
          await (_db.select(_db.learningPaths)
                ..where((p) => p.childId.equals(child.id))
                ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
                ..limit(1))
              .getSingleOrNull();
      cards.add(
        FamilyPatternChildCard(
          id: child.id,
          nameKey: Stage1RowVocabulary.childKeyFor(i),
          confidencePercent: path?.progressPercent ?? 0,
          patterns: patterns,
        ),
      );
    }

    return FamilyPatternsSnapshot(
      children: cards,
      // The advisor's confidence is the measured share of the gaps' own numbers.
      advisorConfidencePercent: total == 0
          ? 0
          : (((total - missed) * 100) / total).round().clamp(0, 100),
    );
  }
}

/// WIR-02C — SCR-FAT-054 خرائط المعرفة: the maps are the child's own
/// `quran_plan` / `quran_memorization` pair and the newest `learning_path`, so
/// every card opens a real screen. The social-share balance and the dinner
/// questions have no rows in v6 and stay empty (declared), and asking for the
/// next question writes nothing.
final class DriftKnowledgeMapsRepository extends _AdvisorFollowupScope
    implements KnowledgeMapsRepository {
  DriftKnowledgeMapsRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<KnowledgeMapsSnapshot> load() async {
    if (!await familyExists(_db)) return const KnowledgeMapsSnapshot();
    final children = await childrenInOrder(_db);
    if (children.isEmpty) return const KnowledgeMapsSnapshot();
    // The screen shows one child: the acting child, else the family's first.
    var ordinal = 0;
    for (var i = 0; i < children.length; i++) {
      if (children[i].id == childId) {
        ordinal = i;
        break;
      }
    }
    final child = children[ordinal];
    final paths = <KnowledgeMapLearningPath>[];

    {
      final plan = await _planOf(child.id);
      if (plan != null) {
        final memorization =
            await (_db.select(_db.quranMemorizations)
                  ..where(
                    (m) =>
                        m.childId.equals(child.id) &
                        m.surahRef.equals(plan.surahRef),
                  )
                  ..limit(1))
                .getSingleOrNull();
        paths.add(
          KnowledgeMapLearningPath(
            id: 'quran_${plan.id}',
            kind: KnowledgeMapPathKind.quran,
            titleKey: plan.surahRef,
            subtitleKey: '${plan.fromAyah}-${plan.toAyah}',
            progressPercent: (memorization?.progress ?? 0).clamp(0, 100),
            ctaScreenId: 'SCR-CHD-025',
          ),
        );
      }
      final learningPath =
          await (_db.select(_db.learningPaths)
                ..where((p) => p.childId.equals(child.id))
                ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
                ..limit(1))
              .getSingleOrNull();
      if (learningPath != null) {
        paths.add(
          KnowledgeMapLearningPath(
            id: learningPath.id,
            kind: KnowledgeMapPathKind.math,
            titleKey: learningPath.subjectRef,
            subtitleKey: '',
            progressPercent: learningPath.progressPercent.clamp(0, 100),
            ctaScreenId: 'SCR-CHD-013',
          ),
        );
      }
    }

    // The rising tag carries the acting child's own newest measured path.
    final newest =
        await (_db.select(_db.learningPaths)
              ..where((p) => p.childId.equals(child.id))
              ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    return KnowledgeMapsSnapshot(
      childNameKey: Stage1RowVocabulary.childKeyFor(ordinal),
      masteryPercent: (newest?.progressPercent ?? 0).clamp(0, 100),
      learningPaths: paths,
      // No social-share table and no dinner-question table in v6.
      socialShares: const [],
      dinnerQuestionKeys: const [],
    );
  }

  /// Declared gap: the questions are copy with no row, so this changes nothing.
  @override
  Future<KnowledgeMapsSnapshot> nextDinnerQuestion() => load();

  Future<QuranPlan?> _planOf(String childId) async {
    final active =
        await (_db.select(_db.quranPlans)
              ..where(
                (t) => t.childId.equals(childId) & t.active.equals(true),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (active != null) return active;
    return (_db.select(_db.quranPlans)
          ..where((t) => t.childId.equals(childId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}

/// WIR-02D — SCR-FAT-055 مقارنة الأقران: the family's own child and their age
/// are real rows; the peer metrics themselves have no table in v6 (they are
/// server-side aggregates), so the list stays empty and says nothing it cannot
/// prove.
final class DriftPeerCompareRepository extends _AdvisorFollowupScope
    implements PeerCompareRepository {
  DriftPeerCompareRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<PeerCompareSnapshot> load() async {
    if (!await familyExists(_db)) return const PeerCompareSnapshot();
    final children = await childrenInOrder(_db);
    if (children.isEmpty) return const PeerCompareSnapshot();
    var ordinal = 0;
    for (var i = 0; i < children.length; i++) {
      if (children[i].id == childId) {
        ordinal = i;
        break;
      }
    }
    final child = children[ordinal];
    return PeerCompareSnapshot(
      hasFamily: true,
      childLabelKey: Stage1RowVocabulary.childKeyFor(ordinal),
      // A missing birth year reads as 0 = unknown (v6 has no such column).
      ageYears: child.birthYear == null
          ? 0
          : clock().year - child.birthYear!,
      // No peer-aggregate table exists in v6 — declared empty, never faked.
      metrics: const [],
    );
  }
}

/// WIR-02E — SCR-FAT-056 سجلّ أفعال المستشار: the live action is the family's
/// newest `ai_suggestion` and its state is read from that row's own stamps
/// (`applied_at` / `undone_at` / `dismissed_at`), so blessing writes the applied
/// stamp and a gentle undo writes the undone stamp — both survive a reopen. The
/// week's stats are the suggestions themselves, with the ledger minutes the row
/// does not carry left at zero (declared).
final class DriftAgentActionLogRepository extends _AdvisorFollowupScope
    implements AgentActionLogRepository {
  DriftAgentActionLogRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<AgentActionLogSnapshot> load() async {
    if (!await familyExists(_db)) return const AgentActionLogSnapshot();
    final now = clock();
    final live =
        await (_db.select(_db.aiSuggestions)
              ..where((t) => t.familyId.equals(familyId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    final since = now.subtract(const Duration(days: 7));
    final week =
        await (_db.select(_db.aiSuggestions)
              ..where(
                (t) =>
                    t.familyId.equals(familyId) &
                    t.createdAt.isBiggerOrEqualValue(since),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    final alias = await actingChildAlias(_db);
    return AgentActionLogSnapshot(
      hasFamily: true,
      hasLiveAction: live != null,
      // The row's own action kind is the rule it belongs to.
      ruleKey: live?.actionKind.trim() ?? '',
      childLabelKey: (live?.childAlias ?? alias ?? '').trim(),
      // No minutes/app/seconds columns on a suggestion — declared zeros.
      minutesGranted: 0,
      taskKeys: const [],
      appTargetKey: '',
      secondsLeft: 0,
      state: _stateOf(live),
      undoMsgKey: '',
      weekly: [
        for (final row in week)
          AgentWeeklyStat(
            id: row.id,
            titleKey: row.headline,
            metaKey: Stage1RowVocabulary.timeKeyFor(row.createdAt, now),
            ruleKey: row.actionKind,
          ),
      ],
    );
  }

  @override
  Future<AgentActionLogSnapshot> bless() async {
    final live = await _liveRow();
    if (live == null || live.appliedAt != null) return load();
    await (_db.update(_db.aiSuggestions)
          ..where((t) => t.id.equals(live.id)))
        .write(AiSuggestionsCompanion(appliedAt: Value(clock())));
    return load();
  }

  @override
  Future<AgentActionLogSnapshot> gentleUndo() async {
    final live = await _liveRow();
    if (live == null) return load();
    await (_db.update(_db.aiSuggestions)
          ..where((t) => t.id.equals(live.id)))
        .write(AiSuggestionsCompanion(undoneAt: Value(clock())));
    return load();
  }

  Future<AiSuggestionRow?> _liveRow() {
    return (_db.select(_db.aiSuggestions)
          ..where((t) => t.familyId.equals(familyId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  static AgentActionState _stateOf(AiSuggestionRow? row) {
    if (row == null || row.appliedAt == null) {
      return row?.dismissedAt == null
          ? AgentActionState.pending
          : AgentActionState.undone;
    }
    return row.undoneAt == null
        ? AgentActionState.blessed
        : AgentActionState.undone;
  }
}

/// WIR-02F — SCR-FAT-057 لحظات العائلة: the week's numbers are summed from the
/// rows themselves — `learn_session.minutes`, `quran_recitation.completed_ayahs`,
/// reviewed `task_submission` rows and the week's `sos_alert` rows — and each
/// star is a real child with the minutes they actually earned. The album, the
/// shared-pride flag and the reminder flag have no rows in v6 (declared): the
/// album stays empty and the three action methods write nothing rather than
/// pretend.
final class DriftFamilyMomentsRepository extends _AdvisorFollowupScope
    implements FamilyMomentsRepository {
  DriftFamilyMomentsRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  Future<FamilyMomentsSnapshot> load() async {
    if (!await familyExists(_db)) return const FamilyMomentsSnapshot();
    final children = await childrenInOrder(_db);
    if (children.isEmpty) return const FamilyMomentsSnapshot();
    final now = clock();
    final since = now.subtract(const Duration(days: 7));

    var learnMinutes = 0;
    var verses = 0;
    var tasksDone = 0;
    var worries = 0;
    final stars = <FamilyMomentStar>[];

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final sittings =
          await (_db.select(_db.learnSessions)
                ..where(
                  (t) =>
                      t.childId.equals(child.id) &
                      t.startedAt.isBiggerOrEqualValue(since),
                ))
              .get();
      for (final sitting in sittings) {
        learnMinutes += sitting.minutes;
      }
      final recitations =
          await (_db.select(_db.quranRecitations)
                ..where(
                  (r) =>
                      r.childId.equals(child.id) &
                      r.createdAt.isBiggerOrEqualValue(since),
                ))
              .get();
      for (final recitation in recitations) {
        verses += recitation.completedAyahs;
      }
      final submissions =
          await (_db.select(_db.taskSubmissions)
                ..where(
                  (s) =>
                      s.childId.equals(child.id) &
                      s.submittedAt.isBiggerOrEqualValue(since) &
                      s.reviewedAt.isNotNull(),
                ))
              .get();
      tasksDone += submissions.length;
      final earned =
          await (_db.select(_db.walletLedgerEntries)
                ..where(
                  (e) =>
                      e.childId.equals(child.id) &
                      e.deltaMinutes.isBiggerThanValue(0) &
                      e.createdAt.isBiggerOrEqualValue(since),
                ))
              .get();
      var earnedMinutes = 0;
      for (final entry in earned) {
        earnedMinutes += entry.deltaMinutes;
      }
      stars.add(
        FamilyMomentStar(
          id: child.id,
          childLabelKey: Stage1RowVocabulary.childKeyFor(i),
          // The child's own stored name — the star is about a real child.
          titleKey: child.displayName,
          subKey: '$earnedMinutes',
          emoji: _starEmoji(child.avatar),
        ),
      );
    }

    worries =
        (await (_db.select(_db.sosAlerts)
                  ..where(
                    (a) =>
                        a.familyId.equals(familyId) &
                        a.triggeredAt.isBiggerOrEqualValue(since),
                  ))
                .get())
            .length;

    return FamilyMomentsSnapshot(
      hasFamily: true,
      // The week label is copy with no column.
      weekLabelKey: '',
      learnHours: learnMinutes ~/ 60,
      versesMemorized: verses,
      tasksDone: tasksDone,
      worryAlerts: worries,
      stars: stars,
      touchHintKey: '',
      // No album table, and no row that says a card was shared or a touch sent.
      album: const [],
      prideShared: false,
      touchReminded: false,
    );
  }

  /// Declared gap — no row records a shared pride card yet.
  @override
  Future<FamilyMomentsSnapshot> sharePrideCard() => load();

  /// Declared gap — no row records a touch reminder yet.
  @override
  Future<FamilyMomentsSnapshot> remindTouch() => load();

  /// Declared gap — the album has no table to write into.
  @override
  Future<FamilyMomentsSnapshot> addMoment() => load();

  static String _starEmoji(String avatar) => switch (avatar.trim()) {
    'lion' => '🦁',
    'cat' => '🐱',
    'panda' => '🐼',
    _ => '⭐',
  };
}

