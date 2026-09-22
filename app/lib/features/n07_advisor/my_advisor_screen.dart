import 'package:flutter/material.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/ai_suggestion_repository.dart';
import 'package:family_os/core/policy/rule_consequent.dart';
import 'package:family_os/core/policy/rules_engine_rule.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';
import 'package:family_os/features/n07_advisor/rule_editor.dart';

/// Widget keys for SCR-FAT-079 / SET-022 acceptance.
abstract final class MyAdvisorKeys {
  static const servesBanner = Key('my_advisor_serves_banner');
  static const suggestionsSection = Key('my_advisor_suggestions_section');
  static const myRulesSection = Key('my_advisor_my_rules_section');
  static const suggestionsList = Key('my_advisor_suggestions_list');
  static const rulesList = Key('my_advisor_rules_list');
  static const readOnlyHint = Key('my_advisor_read_only_hint');

  static Key suggestionRow(String id) => Key('my_advisor_suggestion_$id');

  static Key approveBtn(String id) => Key('my_advisor_approve_$id');

  static Key rejectBtn(String id) => Key('my_advisor_reject_$id');

  static Key ruleRow(String id) => Key('my_advisor_rule_$id');

  static const approveForbiddenBlocked = Key(
    'my_advisor_approve_forbidden_blocked',
  );
}

/// SCR-FAT-079 — مساعدي الذكي (SET-022 ADR-038: suggestions ≠ rules).
///
/// Two labeled surfaces: advisor suggestions (approve/reject) and My rules
/// (father-authored / approved deterministic rules). Competitive: Bark —
/// AI suggests; parent decides.
class MyAdvisorScreen extends StatefulWidget {
  const MyAdvisorScreen({
    super.key,
    this.suggestions,
    this.rules,
    this.roleOverride,
  });

  /// Null → mock inbox wired to [rules] (or stage-1 rules store).
  final AiSuggestionRepository? suggestions;

  /// Null → [stage1RulesEngineRuleRepository].
  final RulesEngineRuleRepository? rules;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  @override
  MyAdvisorScreenState createState() => MyAdvisorScreenState();
}

class MyAdvisorScreenState extends State<MyAdvisorScreen> {
  late final RulesEngineRuleRepository _rules;
  late final AiSuggestionRepository _suggestions;
  var _loading = true;
  List<AiSuggestionInboxItem> _pending = const [];
  List<RulesEngineRule> _enabledRules = const [];
  String? _approveBlockedHint;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _canEdit => canApproveAdvisorRules(_role);

  @override
  void initState() {
    super.initState();
    _rules = widget.rules ?? stage1RulesEngineRuleRepository;
    _suggestions =
        widget.suggestions ??
        MockAiSuggestionRepository(rules: _rules);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    final pending = await _suggestions.listPending();
    final rules = await _rules.listEnabled();
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _enabledRules = rules;
      _loading = false;
    });
  }

  /// Father approve — creates RulesEngine rule; suggestion stays non-executable.
  /// Forbidden ADR-038(d) drafts are blocked at approve (SET-023).
  Future<void> approveSuggestion(String suggestionId) async {
    if (!_canEdit) return;
    try {
      await _suggestions.approve(suggestionId);
      if (!mounted) return;
      setState(() => _approveBlockedHint = null);
      await _load();
    } on ForbiddenRuleConsequentException {
      if (!mounted) return;
      setState(() => _approveBlockedHint = suggestionId);
    }
  }

  Future<void> rejectSuggestion(String suggestionId) async {
    if (!_canEdit) return;
    await _suggestions.reject(suggestionId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(l10n.myAdvisorTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                BannerNote(
                  key: MyAdvisorKeys.servesBanner,
                  message: l10n.myAdvisorServesBanner,
                  variant: BannerVariant.t,
                ),
                if (!_canEdit) ...[
                  const SizedBox(height: 12),
                  BannerNote(
                    key: MyAdvisorKeys.readOnlyHint,
                    message: l10n.myAdvisorReadOnlyHint,
                    variant: BannerVariant.a,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  l10n.myAdvisorSuggestionsHeading,
                  key: MyAdvisorKeys.suggestionsSection,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.myAdvisorSuggestionsHint,
                  style: TextStyle(color: colors.ink2, fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_pending.isEmpty)
                  Text(
                    l10n.myAdvisorSuggestionsEmpty,
                    style: TextStyle(color: colors.ink2, fontSize: 13.5),
                  )
                else
                  Column(
                    key: MyAdvisorKeys.suggestionsList,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in _pending) ...[
                        _SuggestionCard(
                          item: item,
                          canEdit: _canEdit,
                          approveLabel: l10n.myAdvisorApprove,
                          rejectLabel: l10n.myAdvisorReject,
                          onApprove: () => approveSuggestion(item.id),
                          onReject: () => rejectSuggestion(item.id),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                const SizedBox(height: 28),
                Text(
                  l10n.myAdvisorMyRulesHeading,
                  key: MyAdvisorKeys.myRulesSection,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.myAdvisorMyRulesHint,
                  style: TextStyle(color: colors.ink2, fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_canEdit) ...[
                  RuleEditor(
                    rules: _rules,
                    canEdit: _canEdit,
                    onSaved: _load,
                  ),
                  const SizedBox(height: 20),
                ],
                if (_approveBlockedHint != null) ...[
                  BannerNote(
                    key: MyAdvisorKeys.approveForbiddenBlocked,
                    message: l10n.ruleEditorForbiddenBlocked,
                    variant: BannerVariant.a,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_enabledRules.isEmpty)
                  Text(
                    l10n.myAdvisorMyRulesEmpty,
                    style: TextStyle(color: colors.ink2, fontSize: 13.5),
                  )
                else
                  Column(
                    key: MyAdvisorKeys.rulesList,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final rule in _enabledRules) ...[
                        _RuleCard(rule: rule),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.item,
    required this.canEdit,
    required this.approveLabel,
    required this.rejectLabel,
    required this.onApprove,
    required this.onReject,
  });

  final AiSuggestionInboxItem item;
  final bool canEdit;
  final String approveLabel;
  final String rejectLabel;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final s = item.suggestion;

    return DecoratedBox(
      key: MyAdvisorKeys.suggestionRow(s.id),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.title,
              style: TextStyle(
                color: colors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.body,
              style: TextStyle(color: colors.ink2, fontSize: 13.5),
            ),
            if (canEdit) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryBtn(
                      key: MyAdvisorKeys.approveBtn(s.id),
                      label: approveLabel,
                      onPressed: onApprove,
                      variant: PrimaryBtnVariant.teal,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryBtn(
                      key: MyAdvisorKeys.rejectBtn(s.id),
                      label: rejectLabel,
                      onPressed: onReject,
                      variant: PrimaryBtnVariant.ghost,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule});

  final RulesEngineRule rule;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return DecoratedBox(
      key: MyAdvisorKeys.ruleRow(rule.id),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              rule.title,
              style: TextStyle(
                color: colors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              rule.body,
              style: TextStyle(color: colors.ink2, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}
