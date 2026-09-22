import 'package:flutter/material.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/ai_suggestion_repository.dart';
import 'package:family_os/core/policy/rule_consequent.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';

/// Widget keys for SCR-FAT-011 acceptance.
abstract final class AdvisorSuggestionsKeys {
  static const screen = Key('advisor_suggestions_screen');
  static const servesBanner = Key('advisor_suggestions_serves_banner');
  static const loading = Key('advisor_suggestions_loading');
  static const empty = Key('advisor_suggestions_empty');
  static const error = Key('advisor_suggestions_error');
  static const list = Key('advisor_suggestions_list');
  static const readOnlyHint = Key('advisor_suggestions_read_only');
  static const privacyFooter = Key('advisor_suggestions_privacy_footer');
  static const approveConfirmDialog = Key('advisor_suggestions_approve_confirm');
  static const approveConfirmAction = Key('advisor_suggestions_approve_confirm_action');
  static const approveConfirmCancel = Key('advisor_suggestions_approve_confirm_cancel');
  static const approveForbiddenBlocked = Key(
    'advisor_suggestions_approve_forbidden_blocked',
  );

  static Key suggestionRow(String id) => Key('advisor_suggestions_row_$id');

  static Key approveBtn(String id) => Key('advisor_suggestions_approve_$id');

  static Key rejectBtn(String id) => Key('advisor_suggestions_reject_$id');
}

/// SCR-FAT-011 — اقتراحات العقل (advisor suggestions inbox).
///
/// ADR-038 / Bark: suggest only — never silent execute. Approve moves a
/// suggestion into My rules only after an explicit confirm dialog. Reject
/// dismisses. Mother/child are read-only (A-5); brain control remains
/// father-only on SCR-FAT-029 (SET-015) — this surface is not brain-gated.
class AdvisorSuggestionsScreen extends StatefulWidget {
  const AdvisorSuggestionsScreen({
    super.key,
    this.suggestions,
    this.rules,
    this.roleOverride,
  });

  /// Null → [MockAiSuggestionRepository] wired to [rules].
  final AiSuggestionRepository? suggestions;

  /// Null → [stage1RulesEngineRuleRepository].
  final RulesEngineRuleRepository? rules;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  @override
  AdvisorSuggestionsScreenState createState() =>
      AdvisorSuggestionsScreenState();
}

class AdvisorSuggestionsScreenState extends State<AdvisorSuggestionsScreen> {
  late final RulesEngineRuleRepository _rules;
  late final AiSuggestionRepository _suggestions;
  var _loading = true;
  var _loadFailed = false;
  List<AiSuggestionInboxItem> _pending = const [];
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
        widget.suggestions ?? MockAiSuggestionRepository(rules: _rules);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final pending = await _suggestions.listPending();
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _pending = const [];
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  /// Father approve — only after confirm dialog; never silent apply.
  Future<void> requestApprove(String suggestionId) async {
    if (!_canEdit) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: AdvisorSuggestionsKeys.approveConfirmDialog,
        title: Text(l10n.advisorSuggestionsApproveConfirmTitle),
        content: Text(l10n.advisorSuggestionsApproveConfirmBody),
        actions: [
          TextButton(
            key: AdvisorSuggestionsKeys.approveConfirmCancel,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.advisorSuggestionsApproveCancel),
          ),
          TextButton(
            key: AdvisorSuggestionsKeys.approveConfirmAction,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.advisorSuggestionsApproveConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _approveConfirmed(suggestionId);
  }

  Future<void> _approveConfirmed(String suggestionId) async {
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
      key: AdvisorSuggestionsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(l10n.advisorSuggestionsTitle),
      ),
      body: _buildBody(context, l10n, colors),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          key: AdvisorSuggestionsKeys.loading,
        ),
      );
    }
    if (_loadFailed) {
      return AppErrorState(
        key: AdvisorSuggestionsKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }
    if (_pending.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: BannerNote(
              key: AdvisorSuggestionsKeys.servesBanner,
              message: l10n.advisorSuggestionsServesBanner,
              variant: BannerVariant.p,
            ),
          ),
          Expanded(
            child: AppEmptyState(
              key: AdvisorSuggestionsKeys.empty,
              title: l10n.advisorSuggestionsEmptyTitle,
              message: l10n.advisorSuggestionsEmptyMessage,
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: AdvisorSuggestionsKeys.servesBanner,
            message: l10n.advisorSuggestionsServesBanner,
            variant: BannerVariant.p,
          ),
          if (!_canEdit) ...[
            const SizedBox(height: 12),
            BannerNote(
              key: AdvisorSuggestionsKeys.readOnlyHint,
              message: l10n.advisorSuggestionsReadOnlyHint,
              variant: BannerVariant.a,
            ),
          ],
          if (_approveBlockedHint != null) ...[
            const SizedBox(height: 12),
            BannerNote(
              key: AdvisorSuggestionsKeys.approveForbiddenBlocked,
              message: l10n.ruleEditorForbiddenBlocked,
              variant: BannerVariant.a,
            ),
          ],
          const SizedBox(height: 16),
          Semantics(
            container: true,
            label: l10n.advisorSuggestionsListSemantics,
            child: Column(
              key: AdvisorSuggestionsKeys.list,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in _pending) ...[
                  _SuggestionCard(
                    item: item,
                    canEdit: _canEdit,
                    sealLabel: l10n.advisorSuggestionsSeal,
                    approveLabel: l10n.advisorSuggestionsApprove,
                    rejectLabel: l10n.advisorSuggestionsReject,
                    onApprove: () => requestApprove(item.id),
                    onReject: () => rejectSuggestion(item.id),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.advisorSuggestionsPrivacyFooter,
            key: AdvisorSuggestionsKeys.privacyFooter,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.ink2, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.item,
    required this.canEdit,
    required this.sealLabel,
    required this.approveLabel,
    required this.rejectLabel,
    required this.onApprove,
    required this.onReject,
  });

  final AiSuggestionInboxItem item;
  final bool canEdit;
  final String sealLabel;
  final String approveLabel;
  final String rejectLabel;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final s = item.suggestion;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        key: AdvisorSuggestionsKeys.suggestionRow(s.id),
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
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Tag(label: sealLabel, variant: TagVariant.t),
              ),
              const SizedBox(height: 10),
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
                style: TextStyle(
                  color: colors.ink2,
                  fontSize: 13.5,
                  height: 1.65,
                ),
              ),
              if (canEdit) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryBtn(
                        key: AdvisorSuggestionsKeys.approveBtn(s.id),
                        label: approveLabel,
                        onPressed: onApprove,
                        variant: PrimaryBtnVariant.teal,
                        fullWidth: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PrimaryBtn(
                        key: AdvisorSuggestionsKeys.rejectBtn(s.id),
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
      ),
    );
  }
}
