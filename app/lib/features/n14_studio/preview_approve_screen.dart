import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n14_studio/preview_approve_models.dart';
import 'package:family_os/features/n14_studio/preview_approve_repository.dart';

/// Widget keys for SCR-FAT-044 acceptance.
abstract final class PreviewApproveKeys {
  static const screen = Key('preview_approve_screen');
  static const loading = Key('preview_approve_loading');
  static const empty = Key('preview_approve_empty');
  static const body = Key('preview_approve_body');
  static const ruleBanner = Key('preview_approve_rule');
  static const quizCard = Key('preview_approve_quiz');
  static const lessonCard = Key('preview_approve_lesson');
  static const swapCta = Key('preview_approve_swap');
  static const editCta = Key('preview_approve_edit');
  static const deleteCta = Key('preview_approve_delete');
  static const difficultyCta = Key('preview_approve_difficulty');
  static const approveCta = Key('preview_approve_approve');
  static const rejectCta = Key('preview_approve_reject');
  static const timingNote = Key('preview_approve_timing');
  static const observerHint = Key('preview_approve_observer');
  static const childLean = Key('preview_approve_child_lean');
  static const sosCta = Key('preview_approve_sos');
  static const sosIconCta = Key('preview_approve_sos_icon');

  static Key questionRow(String id) => Key('preview_approve_q_$id');
}

/// SCR-FAT-044 — معاينة واعتماد (preview and approve).
///
/// Prototype FAT-044 · generation outputs from 043 · ADR-038 suggest/approve
/// spirit · Rule 12/23 · mother levels · mock-first · ARB · P-4 SOS ·
/// CTA → FAT-045 attribution/reward · 90-second approve-not-author rule.
class PreviewApproveScreen extends StatefulWidget {
  const PreviewApproveScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1PreviewApproveRepository].
  final PreviewApproveRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full approve like father.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<PreviewApproveScreen> createState() => _PreviewApproveScreenState();
}

class _PreviewApproveScreenState extends State<PreviewApproveScreen> {
  late PreviewApproveRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  PreviewApproveSnapshot _snap = const PreviewApproveSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full (prototype §7 — mother can create).
  bool get _canEdit {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.partner ||
          widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1PreviewApproveRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant PreviewApproveScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1PreviewApproveRepository;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
    await _sos.fire(childId: 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-FAT-018'));
  }

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  void _blockedToast(AppLocalizations l10n) {
    AppToast.show(context, message: l10n.previewApproveObserverBlocked);
  }

  void _onSwap() {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      _blockedToast(l10n);
      return;
    }
    if (_snap.questions.isEmpty) return;
    final swap = previewApproveSwapQuestionFixture();
    final rest = _snap.questions.length > 1
        ? _snap.questions.sublist(1)
        : <PreviewQuizQuestion>[];
    setState(() {
      _snap = _snap.withQuestions([swap, ...rest]);
    });
    AppToast.show(context, message: l10n.previewApproveSwapToast);
  }

  void _onEdit() {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      _blockedToast(l10n);
      return;
    }
    AppToast.show(context, message: l10n.previewApproveEditToast);
  }

  void _onDelete() {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      _blockedToast(l10n);
      return;
    }
    if (_snap.questions.isEmpty) return;
    final firstId = _snap.questions.first.id;
    setState(() {
      _snap = _snap.withoutQuestion(firstId);
    });
    AppToast.show(context, message: l10n.previewApproveDeleteToast);
  }

  void _onDifficulty() {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      _blockedToast(l10n);
      return;
    }
    final next = switch (_snap.difficulty) {
      PreviewDifficulty.normal => PreviewDifficulty.easier,
      PreviewDifficulty.easier => PreviewDifficulty.harder,
      PreviewDifficulty.harder => PreviewDifficulty.normal,
    };
    setState(() {
      _snap = _snap.withDifficulty(next);
    });
    AppToast.show(context, message: l10n.previewApproveDifficultyToast);
  }

  Future<void> _onApprove() async {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      _blockedToast(l10n);
      return;
    }
    if (!_snap.canApprove) {
      AppToast.show(context, message: l10n.previewApproveCannotApproveToast);
      return;
    }
    final snap = await _repo.approve();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(context, message: l10n.previewApproveApprovedToast);
    _go('SCR-FAT-045');
  }

  Future<void> _onReject() async {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      _blockedToast(l10n);
      return;
    }
    final snap = await _repo.reject();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(context, message: l10n.previewApproveRejectToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: PreviewApproveKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.previewApproveTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: PreviewApproveKeys.sosIconCta,
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
      body: SafeArea(child: _buildBody(context, l10n, colors)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    if (_isChild) {
      return AppEmptyState(
        key: PreviewApproveKeys.childLean,
        title: l10n.previewApproveChildLeanTitle,
        message: l10n.previewApproveChildLeanMessage,
        actionLabel: l10n.previewApproveSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: PreviewApproveKeys.childLean,
        title: l10n.previewApproveChildLeanTitle,
        message: l10n.previewApproveChildLeanMessage,
      );
    }

    if (_loading) {
      return Center(
        key: PreviewApproveKeys.loading,
        child: Semantics(
          label: l10n.previewApproveLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: PreviewApproveKeys.empty,
        title: l10n.previewApproveEmptyTitle,
        message: l10n.previewApproveEmptyMessage,
        actionLabel: l10n.previewApproveSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: PreviewApproveKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: PreviewApproveKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.previewApproveObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          BannerNote(
            key: PreviewApproveKeys.ruleBanner,
            variant: BannerVariant.t,
            leading: Icon(Icons.bolt, color: colors.tealDeep, size: 20),
            message: l10n.previewApproveRuleBanner,
          ),
          const SizedBox(height: 12),
          _QuizCard(
            snap: _snap,
            colors: colors,
            radii: radii,
            l10n: l10n,
            canEdit: _canEdit,
            onSwap: _onSwap,
            onEdit: _onEdit,
            onDelete: _onDelete,
            onDifficulty: _onDifficulty,
          ),
          if (_snap.lesson != null) ...[
            const SizedBox(height: 12),
            _LessonCard(
              lesson: _snap.lesson!,
              colors: colors,
              radii: radii,
              l10n: l10n,
            ),
          ],
          const SizedBox(height: 16),
          PrimaryBtn(
            key: PreviewApproveKeys.approveCta,
            label: l10n.previewApproveApproveCta,
            variant: PrimaryBtnVariant.mint,
            onPressed: (_canEdit && _snap.canApprove) ? _onApprove : null,
          ),
          const SizedBox(height: 10),
          PrimaryBtn(
            key: PreviewApproveKeys.rejectCta,
            label: l10n.previewApproveRejectCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: _canEdit ? _onReject : null,
          ),
          const SizedBox(height: 10),
          Text(
            key: PreviewApproveKeys.timingNote,
            l10n.previewApproveTimingNote(_snap.elapsedSeconds),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _snap.withinNinetySeconds ? colors.mintInk : colors.coral,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: PreviewApproveKeys.sosCta,
            label: l10n.previewApproveSosCta,
            variant: PrimaryBtnVariant.coral,
            onPressed: _sosBusy ? null : _openSos,
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.snap,
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.canEdit,
    required this.onSwap,
    required this.onEdit,
    required this.onDelete,
    required this.onDifficulty,
  });

  final PreviewApproveSnapshot snap;
  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final bool canEdit;
  final VoidCallback onSwap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDifficulty;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: PreviewApproveKeys.quizCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.quiz_outlined, color: colors.p600, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.previewApproveQuizTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                Tag(label: l10n.previewApproveReadyTag, variant: TagVariant.g),
              ],
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final q in snap.questions) ...[
                      _QuestionBlock(question: q, colors: colors, l10n: l10n),
                      if (q != snap.questions.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _EditChip(
                  key: PreviewApproveKeys.swapCta,
                  label: l10n.previewApproveSwapCta,
                  enabled: canEdit && snap.questions.isNotEmpty,
                  onPressed: onSwap,
                  colors: colors,
                ),
                _EditChip(
                  key: PreviewApproveKeys.editCta,
                  label: l10n.previewApproveEditCta,
                  enabled: canEdit && snap.questions.isNotEmpty,
                  onPressed: onEdit,
                  colors: colors,
                ),
                _EditChip(
                  key: PreviewApproveKeys.deleteCta,
                  label: l10n.previewApproveDeleteCta,
                  enabled: canEdit && snap.questions.isNotEmpty,
                  onPressed: onDelete,
                  colors: colors,
                ),
                _EditChip(
                  key: PreviewApproveKeys.difficultyCta,
                  label: l10n.previewApproveDifficultyCta,
                  enabled: canEdit,
                  onPressed: onDifficulty,
                  colors: colors,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.question,
    required this.colors,
    required this.l10n,
  });

  final PreviewQuizQuestion question;
  final FamilyColors colors;
  final AppLocalizations l10n;

  String _prompt() {
    return switch (question.promptKey) {
      'q1' => l10n.previewApproveQ1Prompt,
      'q2' => l10n.previewApproveQ2Prompt,
      'q3' => l10n.previewApproveQ3Prompt,
      _ => l10n.previewApproveQ1Prompt,
    };
  }

  String _optionLabel(PreviewQuizOption o) {
    return switch (o.labelKey) {
      'q1a' => l10n.previewApproveQ1OptA,
      'q1b' => l10n.previewApproveQ1OptB,
      'q1c' => l10n.previewApproveQ1OptC,
      'q2a' => l10n.previewApproveQ2OptA,
      'q2b' => l10n.previewApproveQ2OptB,
      'q2c' => l10n.previewApproveQ2OptC,
      'q3a' => l10n.previewApproveQ3OptA,
      'q3b' => l10n.previewApproveQ3OptB,
      'q3c' => l10n.previewApproveQ3OptC,
      _ => o.labelKey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: _prompt(),
      child: Column(
        key: PreviewApproveKeys.questionRow(question.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _prompt(),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: colors.ink,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final o in question.options)
                Tag(
                  label: _optionLabel(o),
                  variant: o.isCorrect ? TagVariant.p : TagVariant.a,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.colors,
    required this.radii,
    required this.l10n,
  });

  final PreviewLessonBlock lesson;
  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;

  String _lessonSummary(AppLocalizations l10n, String key) {
    return switch (key) {
      'pizza' => l10n.previewApproveLessonSummary,
      _ => l10n.previewApproveLessonSummary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: PreviewApproveKeys.lessonCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_outlined, color: colors.p600, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.previewApproveLessonTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                Tag(label: l10n.previewApproveReadyTag, variant: TagVariant.g),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _lessonSummary(l10n, lesson.summaryKey),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditChip extends StatelessWidget {
  const _EditChip({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.colors,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Ink(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
