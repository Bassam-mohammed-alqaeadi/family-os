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
import 'package:family_os/features/n07_advisor/mother_ai_feed_models.dart';
import 'package:family_os/features/n07_advisor/mother_ai_feed_repository.dart';

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
