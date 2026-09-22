import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/rule_consequent.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';

/// Widget keys for SET-023 RuleEditor (SCR-FAT-079).
abstract final class RuleEditorKeys {
  static const section = Key('rule_editor_section');
  static const picker = Key('rule_editor_consequent_picker');
  static const saveBtn = Key('rule_editor_save');
  static const forbiddenBlockedHint = Key('rule_editor_forbidden_blocked');

  static Key option(RuleConsequent c) => Key('rule_editor_option_${c.id}');

  /// Forbidden ids must never appear — tests use find.byKey + findsNothing.
  static Key forbiddenOption(String forbiddenId) =>
      Key('rule_editor_option_$forbiddenId');
}

/// Father-only rule consequent picker — allow-list only (ADR-038(d) / SET-023).
///
/// Picker never lists ANTI_TAMPER / BLOCK_OVERRIDE / DELEGATION_EDIT.
class RuleEditor extends StatefulWidget {
  const RuleEditor({
    super.key,
    required this.rules,
    required this.canEdit,
    this.onSaved,
  });

  final RulesEngineRuleRepository rules;
  final bool canEdit;
  final VoidCallback? onSaved;

  @override
  State<RuleEditor> createState() => RuleEditorState();
}

class RuleEditorState extends State<RuleEditor> {
  RuleConsequent _selected = RuleConsequent.notifyFather;
  var _saving = false;
  String? _error;

  RuleConsequent get selected => _selected;

  /// Exposed for tests — attempts to select a forbidden id (always no-op / error).
  Future<void> trySelectForbiddenForTest(String forbiddenId) async {
    if (!isForbiddenRuleConsequentId(forbiddenId)) return;
    setState(() {
      _error = 'forbidden';
    });
  }

  Future<void> saveDraft() async {
    if (!widget.canEdit || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.rules.save(
        title: 'Rule',
        body: _selected.id,
        consequentIds: [_selected.id],
      );
      widget.onSaved?.call();
    } on ForbiddenRuleConsequentException {
      setState(() => _error = 'forbidden');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    if (!widget.canEdit) {
      return const SizedBox.shrink();
    }

    return Column(
      key: RuleEditorKeys.section,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.ruleEditorHeading,
          style: TextStyle(
            color: colors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.ruleEditorHint,
          style: TextStyle(color: colors.ink2, fontSize: 13),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          key: RuleEditorKeys.picker,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              for (final c in RuleConsequent.values)
                ListTile(
                  key: RuleEditorKeys.option(c),
                  enabled: !_saving,
                  selected: _selected == c,
                  selectedTileColor: colors.teal100,
                  title: Text(
                    _labelFor(l10n, c),
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: _selected == c
                      ? Icon(Icons.check_circle, color: colors.teal, size: 22)
                      : Icon(
                          Icons.circle_outlined,
                          color: colors.ink2,
                          size: 22,
                        ),
                  onTap: _saving
                      ? null
                      : () {
                          setState(() {
                            _selected = c;
                            _error = null;
                          });
                        },
                ),
              // Explicitly omit ForbiddenRuleConsequentIds — no tiles for them.
            ],
          ),
        ),
        if (_error == 'forbidden') ...[
          const SizedBox(height: 8),
          Text(
            key: RuleEditorKeys.forbiddenBlockedHint,
            l10n.ruleEditorForbiddenBlocked,
            style: TextStyle(color: colors.coral, fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
        PrimaryBtn(
          key: RuleEditorKeys.saveBtn,
          label: l10n.ruleEditorSave,
          onPressed: _saving ? null : saveDraft,
          variant: PrimaryBtnVariant.teal,
          fullWidth: true,
        ),
      ],
    );
  }

  String _labelFor(AppLocalizations l10n, RuleConsequent c) {
    return switch (c) {
      RuleConsequent.notifyFather => l10n.ruleConsequentNotifyFather,
      RuleConsequent.grantMinutes => l10n.ruleConsequentGrantMinutes,
      RuleConsequent.softLock => l10n.ruleConsequentSoftLock,
    };
  }
}
