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
import 'package:family_os/features/n14_studio/generation_outputs_models.dart';
import 'package:family_os/features/n14_studio/generation_outputs_repository.dart';
import 'package:family_os/features/n14_studio/studio_ux_bridge.dart';

/// Widget keys for SCR-FAT-043 acceptance.
abstract final class GenerationOutputsKeys {
  static const screen = Key('generation_outputs_screen');
  static const loading = Key('generation_outputs_loading');
  static const empty = Key('generation_outputs_empty');
  static const body = Key('generation_outputs_body');
  static const sourceBanner = Key('generation_outputs_source');
  static const listCard = Key('generation_outputs_list');
  static const religiousLock = Key('generation_outputs_religious_lock');
  static const generateCta = Key('generation_outputs_generate');
  static const observerHint = Key('generation_outputs_observer');
  static const childLean = Key('generation_outputs_child_lean');
  static const sosCta = Key('generation_outputs_sos');
  static const sosIconCta = Key('generation_outputs_sos_icon');

  static Key outputRow(String id) => Key('generation_outputs_row_$id');
  static Key outputSwitch(String id) => Key('generation_outputs_swt_$id');
}

/// SCR-FAT-043 — مخرجات التوليد (generation outputs).
///
/// Prototype FAT-043 · S-EDU-054…060 · S-AIC-021 · Rule 12/23 · mother
/// levels · mock-first · ARB · P-4 SOS · generate → FAT-044 · religious
/// auto-generation lock (no exception).
class GenerationOutputsScreen extends StatefulWidget {
  const GenerationOutputsScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [Stage1StudioRuntime.generationOutputs].
  final GenerationOutputsRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full generate like father.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<GenerationOutputsScreen> createState() =>
      _GenerationOutputsScreenState();
}

class _GenerationOutputsScreenState extends State<GenerationOutputsScreen> {
  late GenerationOutputsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _generating = false;
  GenerationOutputsSnapshot _snap = const GenerationOutputsSnapshot();

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
    _repo = widget.repository ?? Stage1StudioRuntime.generationOutputs;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant GenerationOutputsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? Stage1StudioRuntime.generationOutputs;
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

  void _onToggle(GenerationOutputItem item, bool value) {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      AppToast.show(context, message: l10n.generationOutputsObserverBlocked);
      return;
    }
    if (item.phaseLocked) {
      AppToast.show(context, message: l10n.generationOutputsPhaseLockedToast);
      return;
    }
    setState(() {
      _snap = _snap.withToggled(item.id, value);
    });
  }

  Future<void> _onGenerate() async {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      AppToast.show(context, message: l10n.generationOutputsObserverBlocked);
      return;
    }
    if (_snap.selectedCount == 0) {
      AppToast.show(context, message: l10n.generationOutputsNoneSelectedToast);
      return;
    }
    if (_generating) return;
    setState(() => _generating = true);
    AppToast.show(context, message: l10n.generationOutputsGeneratingToast);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _generating = false);
    _go('SCR-FAT-044');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: GenerationOutputsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.generationOutputsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: GenerationOutputsKeys.sosIconCta,
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
        key: GenerationOutputsKeys.childLean,
        title: l10n.generationOutputsChildLeanTitle,
        message: l10n.generationOutputsChildLeanMessage,
        actionLabel: l10n.generationOutputsSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: GenerationOutputsKeys.childLean,
        title: l10n.generationOutputsChildLeanTitle,
        message: l10n.generationOutputsChildLeanMessage,
      );
    }

    if (_loading) {
      return Center(
        key: GenerationOutputsKeys.loading,
        child: Semantics(
          label: l10n.generationOutputsLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: GenerationOutputsKeys.empty,
        title: l10n.generationOutputsEmptyTitle,
        message: l10n.generationOutputsEmptyMessage,
        actionLabel: l10n.generationOutputsSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: GenerationOutputsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: GenerationOutputsKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.generationOutputsObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          BannerNote(
            key: GenerationOutputsKeys.sourceBanner,
            variant: BannerVariant.g,
            leading: Icon(Icons.menu_book_outlined, color: colors.mintInk, size: 20),
            message: _sourceLabel(l10n, _snap.sourceKey),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            key: GenerationOutputsKeys.listCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.generationOutputsHeading,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final item in _snap.outputs)
                    _OutputRow(
                      item: item,
                      enabled: _canEdit,
                      colors: colors,
                      title: _kindTitle(l10n, item.kind),
                      subtitle: _kindSubtitle(l10n, item.kind),
                      phaseTag: item.phaseLocked
                          ? l10n.generationOutputsPhaseTag
                          : null,
                      onChanged: (v) => _onToggle(item, v),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ReligiousLockBanner(
            key: GenerationOutputsKeys.religiousLock,
            message: l10n.generationOutputsReligiousLock,
            colors: colors,
            radii: radii,
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            key: GenerationOutputsKeys.generateCta,
            label: l10n.generationOutputsGenerateCta(_snap.selectedCount),
            onPressed: (_canEdit && !_generating) ? _onGenerate : null,
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: GenerationOutputsKeys.sosCta,
            label: l10n.generationOutputsSosCta,
            variant: PrimaryBtnVariant.coral,
            onPressed: _sosBusy ? null : _openSos,
          ),
        ],
      ),
    );
  }

  /// The stored ref is the source; the banner names the door it came through
  /// (the staged pack's own `source_ref`, never a claim about its content).
  String _sourceLabel(AppLocalizations l10n, String sourceKey) {
    return switch (sourceKey) {
      kGenerationSourceFractionsKey => l10n.generationOutputsSourceFractions,
      'addFromSourcePdfTitle' => l10n.addFromSourcePdfTitle,
      'addFromSourceAssignmentTitle' => l10n.addFromSourceAssignmentTitle,
      'addFromSourceCameraTitle' => l10n.addFromSourceCameraTitle,
      'addFromSourceLinkTitle' => l10n.addFromSourceLinkTitle,
      'addFromSourceTopicTitle' => l10n.addFromSourceTopicTitle,
      'addFromSourceVoiceTitle' => l10n.addFromSourceVoiceTitle,
      'addFromSourceLibraryTitle' => l10n.addFromSourceLibraryTitle,
      _ => '',
    };
  }

  String _kindTitle(AppLocalizations l10n, GenerationOutputKind kind) {
    return switch (kind) {
      GenerationOutputKind.lesson => l10n.generationOutputsLessonTitle,
      GenerationOutputKind.homework => l10n.generationOutputsHomeworkTitle,
      GenerationOutputKind.quiz => l10n.generationOutputsQuizTitle,
      GenerationOutputKind.flashcards => l10n.generationOutputsFlashcardsTitle,
      GenerationOutputKind.challenge => l10n.generationOutputsChallengeTitle,
      GenerationOutputKind.reviewGame => l10n.generationOutputsReviewGameTitle,
    };
  }

  String _kindSubtitle(AppLocalizations l10n, GenerationOutputKind kind) {
    return switch (kind) {
      GenerationOutputKind.lesson => l10n.generationOutputsLessonSub,
      GenerationOutputKind.homework => l10n.generationOutputsHomeworkSub,
      GenerationOutputKind.quiz => l10n.generationOutputsQuizSub,
      GenerationOutputKind.flashcards => l10n.generationOutputsFlashcardsSub,
      GenerationOutputKind.challenge => l10n.generationOutputsChallengeSub,
      GenerationOutputKind.reviewGame => l10n.generationOutputsReviewGameSub,
    };
  }
}

class _ReligiousLockBanner extends StatelessWidget {
  const _ReligiousLockBanner({
    super.key,
    required this.message,
    required this.colors,
    required this.radii,
  });

  final String message;
  final FamilyColors colors;
  final FamilyRadii radii;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.coral100,
          borderRadius: BorderRadius.circular(radii.banner),
          border: Border.all(color: colors.coral.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.block, color: colors.coral, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.coral,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutputRow extends StatelessWidget {
  const _OutputRow({
    required this.item,
    required this.enabled,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.onChanged,
    this.phaseTag,
  });

  final GenerationOutputItem item;
  final bool enabled;
  final FamilyColors colors;
  final String title;
  final String subtitle;
  final String? phaseTag;
  final ValueChanged<bool> onChanged;

  IconData get _icon => switch (item.kind) {
    GenerationOutputKind.lesson => Icons.menu_book_outlined,
    GenerationOutputKind.homework => Icons.assignment_outlined,
    GenerationOutputKind.quiz => Icons.quiz_outlined,
    GenerationOutputKind.flashcards => Icons.style_outlined,
    GenerationOutputKind.challenge => Icons.emoji_events_outlined,
    GenerationOutputKind.reviewGame => Icons.sports_esports_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final switchOn = item.selected && !item.phaseLocked;
    return Semantics(
      container: true,
      label: '$title. $subtitle',
      child: Padding(
        key: GenerationOutputsKeys.outputRow(item.id),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(_icon, color: colors.p600, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                      ),
                      if (phaseTag != null) ...[
                        const SizedBox(width: 6),
                        Tag(label: phaseTag!, variant: TagVariant.a),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              key: GenerationOutputsKeys.outputSwitch(item.id),
              value: switchOn,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: colors.mint,
            ),
          ],
        ),
      ),
    );
  }
}
