import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/education/learning_result_models.dart';
import 'package:family_os/features/education/learning_result_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quiz_models.dart';
import 'package:family_os/features/n17_child_learn/child_quiz_repository.dart';

/// Widget keys for SCR-CHD-015 acceptance.
abstract final class ChildQuizKeys {
  static const screen = Key('child_quiz_screen');
  static const loading = Key('child_quiz_loading');
  static const empty = Key('child_quiz_empty');
  static const body = Key('child_quiz_body');
  static const promptCard = Key('child_quiz_prompt');
  static const optionsGrid = Key('child_quiz_options');
  static const studyGiftNote = Key('child_quiz_study_gift');
  static const parentLean = Key('child_quiz_parent_lean');
  static const sosIconCta = Key('child_quiz_sos_icon');

  static Key option(String id) => Key('child_quiz_opt_$id');
}

/// SCR-CHD-015 — الاختبار (child interactive skill quiz).
///
/// Prototype CHD-015 · RoleGuard child · minutes-only · correct→016 ·
/// wrong hints toast · P-4 SOS · Rule 12/23 · never punish mistakes.
class ChildQuizScreen extends StatefulWidget {
  const ChildQuizScreen({
    super.key,
    this.repository,
    this.results,
    this.childId,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildQuizRepository? repository;

  /// P15-EDU-006 — child correct answer → father FAT-050 activity (P12).
  final LearningResultRepository? results;
  final ChildId? childId;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildQuizScreen> createState() => _ChildQuizScreenState();
}

class _ChildQuizScreenState extends State<ChildQuizScreen> {
  late ChildQuizRepository _repo;
  late LearningResultRepository _results;
  late ChildId _childId;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _answered = false;
  var _submitting = false;
  ChildQuizSnapshot _snap = const ChildQuizSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildQuizRepository;
    _results = widget.results ?? stage1LearningResultRepository;
    _childId = widget.childId ?? ChildId('child_a');
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _answered = false;
    });
    final snap = await _repo.load();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _loading = false;
    });
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    await _sos.fire(childId: 'self');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-CHD-005'));
  }

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  String _skill(AppLocalizations l10n) {
    return switch (_snap.skillNameKey) {
      'dividingFractions' => l10n.childQuizSkillDividingFractions,
      'approvedPack' => l10n.childQuizSkillApprovedPack,
      _ => l10n.childQuizSkillDividingFractions,
    };
  }

  String _prompt(AppLocalizations l10n, String key) {
    return switch (key) {
      'halfDivQuarter' => l10n.childQuizPromptHalfDivQuarter,
      'q1' => l10n.previewApproveQ1Prompt,
      'q2' => l10n.previewApproveQ2Prompt,
      'q3' => l10n.previewApproveQ3Prompt,
      _ => l10n.childQuizPromptHalfDivQuarter,
    };
  }

  String _optionLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'opt2' => l10n.childQuizOpt2,
      'opt1over8' => l10n.childQuizOpt1over8,
      'opt1over2' => l10n.childQuizOpt1over2,
      'opt4' => l10n.childQuizOpt4,
      'q1a' => l10n.previewApproveQ1OptA,
      'q1b' => l10n.previewApproveQ1OptB,
      'q1c' => l10n.previewApproveQ1OptC,
      'q2a' => l10n.previewApproveQ2OptA,
      'q2b' => l10n.previewApproveQ2OptB,
      'q2c' => l10n.previewApproveQ2OptC,
      'q3a' => l10n.previewApproveQ3OptA,
      'q3b' => l10n.previewApproveQ3OptB,
      'q3c' => l10n.previewApproveQ3OptC,
      _ => l10n.childQuizOpt2,
    };
  }

  String _explain(AppLocalizations l10n, String key) {
    return switch (key) {
      'halfDivQuarterExplain' => l10n.childQuizExplainHalfDivQuarter,
      'approvedExplain' => l10n.childQuizExplainApproved,
      _ => l10n.childQuizExplainHalfDivQuarter,
    };
  }

  String _hint(AppLocalizations l10n, String? key) {
    return switch (key) {
      'hintNearMiss' => l10n.childQuizHintNearMiss,
      'hintFlip' => l10n.childQuizHintFlip,
      'hintMultiply' => l10n.childQuizHintMultiply,
      _ => l10n.childQuizHintFlip,
    };
  }

  Future<void> _onOption(
    ChildQuizOption option,
    ChildQuizQuestion question,
  ) async {
    if (_answered || _submitting) return;
    final l10n = AppLocalizations.of(context);
    if (option.correct) {
      setState(() {
        _answered = true;
        _submitting = true;
      });
      AppToast.show(
        context,
        message: l10n.childQuizCorrectToast(
          _explain(l10n, question.explanationKey),
          _snap.rewardMinutes,
        ),
      );
      // P12: child submit → father ResultsFollowup activity (P15-EDU-006).
      await _results.submit(
        LearningResultSubmitRequest(
          childId: _childId,
          kind: LearningResultKind.quiz,
          titleKey: 'quizSubmitted',
          rewardMinutes: Minutes(_snap.rewardMinutes),
          scoreCorrect: 1,
          scoreTotal: 1,
        ),
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      _go(_snap.successScreenId);
      return;
    }
    AppToast.show(context, message: _hint(l10n, option.wrongHintKey));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildQuizKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childQuizTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildQuizKeys.sosIconCta,
            tooltip: l10n.spineCtaSosSemantics,
            onPressed: _sosBusy ? null : _openSos,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: WidgetStatePropertyAll(Size(48, 48)),
            ),
            icon: Icon(Icons.sos, color: colors.coral),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(l10n, colors)),
    );
  }

  Widget _buildBody(AppLocalizations l10n, FamilyColors colors) {
    if (!_isChild) {
      return AppEmptyState(
        key: ChildQuizKeys.parentLean,
        title: l10n.childQuizParentLeanTitle,
        message: l10n.childQuizParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildQuizKeys.loading,
        child: Semantics(
          label: l10n.childQuizLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildQuizKeys.empty,
        title: l10n.childQuizEmptyTitle,
        message: l10n.childQuizEmptyMessage,
        actionLabel: l10n.childQuizEmptyCta,
        onAction: () => _go('SCR-CHD-012'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final q = _snap.currentQuestion!;

    return SingleChildScrollView(
      key: ChildQuizKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            key: ChildQuizKeys.promptCard,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFAF7FF), Color(0xFFF0E8FF)],
              ),
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.p500, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  Tag(
                    label: l10n.childQuizSkillTag(_skill(l10n)),
                    variant: TagVariant.p,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _prompt(l10n, q.promptKey),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.childQuizEarnHint(_snap.rewardMinutes),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.p700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            key: ChildQuizKeys.optionsGrid,
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.55,
            children: [
              for (final opt in q.options)
                _OptionTile(
                  optionKey: ChildQuizKeys.option(opt.id),
                  label: _optionLabel(l10n, opt.labelKey),
                  colors: colors,
                  radii: radii,
                  enabled: !_answered,
                  onTap: () => _onOption(opt, q),
                ),
            ],
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            key: ChildQuizKeys.studyGiftNote,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                l10n.childQuizStudyGiftNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.optionKey,
    required this.label,
    required this.colors,
    required this.radii,
    required this.enabled,
    required this.onTap,
  });

  final Key optionKey;
  final String label;
  final FamilyColors colors;
  final FamilyRadii radii;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(radii.card),
      child: InkWell(
        key: optionKey,
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(radii.card),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(color: colors.border, width: 1.5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
