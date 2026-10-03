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
import 'package:family_os/core/i18n/notebook_studio_i18n.dart';
import 'package:family_os/core/identity/sos_sender.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n14_studio/generation_outputs_models.dart';
import 'package:family_os/features/n14_studio/generation_outputs_repository.dart';

/// Widget keys for SCR-FAT-043 acceptance.
abstract final class GenerationOutputsKeys {
  static const screen = Key('generation_outputs_screen');
  static const loading = Key('generation_outputs_loading');
  static const empty = Key('generation_outputs_empty');
  static const body = Key('generation_outputs_body');
  static const sourceBanner = Key('generation_outputs_source');
  static const listCard = Key('generation_outputs_list');
  static const sourcesCard = Key('generation_outputs_sources_card');
  static const flexibilityCard = Key('generation_outputs_flexibility_card');
  static const religiousLock = Key('generation_outputs_religious_lock');
  static const generateCta = Key('generation_outputs_generate');
  static const observerHint = Key('generation_outputs_observer');
  static const childLean = Key('generation_outputs_child_lean');
  static const sosCta = Key('generation_outputs_sos');
  static const sosIconCta = Key('generation_outputs_sos_icon');

  static Key outputRow(String id) => Key('generation_outputs_row_$id');
  static Key outputSwitch(String id) => Key('generation_outputs_swt_$id');
  static Key sourceSwitch(String id) => Key('generation_outputs_src_swt_$id');
  static Key depthChip(String name) => Key('generation_outputs_depth_$name');
  static Key toneChip(String name) => Key('generation_outputs_tone_$name');
}

/// SCR-FAT-043 — مخرجات التوليد (generation outputs + NotebookLM Studio).
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

  /// Rule 25 seam — null → [stage1GenerationOutputsRepository].
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
    _repo = widget.repository ?? stage1GenerationOutputsRepository;
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
      _repo = widget.repository ?? stage1GenerationOutputsRepository;
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
    await parentSosSenderOf(context).fireThrough(_sos);
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

  void _onSourceToggle(NotebookSourceItem src, bool value) {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      AppToast.show(context, message: l10n.generationOutputsObserverBlocked);
      return;
    }
    setState(() {
      _snap = _snap.withSourceToggled(src.id, value);
    });
  }

  void _onDepthSelected(NotebookDepthLevel depth) {
    if (!_canEdit) return;
    setState(() {
      _snap = _snap.withFlexibility(_snap.flexibility.copyWith(depth: depth));
    });
  }

  void _onToneSelected(NotebookToneStyle tone) {
    if (!_canEdit) return;
    setState(() {
      _snap = _snap.withFlexibility(_snap.flexibility.copyWith(tone: tone));
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
            leading: Icon(
              Icons.menu_book_outlined,
              color: colors.mintInk,
              size: 20,
            ),
            message: _sourceLabel(l10n, _snap.source),
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
          _SourcesGroundingCard(
            key: GenerationOutputsKeys.sourcesCard,
            sources: _snap.sources,
            activeCount: _snap.activeSourceCount,
            enabled: _canEdit,
            colors: colors,
            radii: radii,
            l10n: l10n,
            onToggle: _onSourceToggle,
          ),
          const SizedBox(height: 12),
          _FlexibilityEngineCard(
            key: GenerationOutputsKeys.flexibilityCard,
            config: _snap.flexibility,
            enabled: _canEdit,
            colors: colors,
            radii: radii,
            l10n: l10n,
            onDepthSelected: _onDepthSelected,
            onToneSelected: _onToneSelected,
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

  String _sourceLabel(AppLocalizations l10n, GenerationSourceLabel source) {
    return switch (source) {
      GenerationSourceLabel.fractionsPage47 =>
        l10n.generationOutputsSourceFractions,
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
      GenerationOutputKind.studyGuideFaq =>
        l10n.generationOutputsStudyGuideFaqTitle,
      GenerationOutputKind.audioOverview =>
        l10n.generationOutputsAudioOverviewTitle,
      GenerationOutputKind.conceptMindMap =>
        l10n.generationOutputsConceptMindMapTitle,
      GenerationOutputKind.timeline => l10n.generationOutputsTimelineTitle,
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
      GenerationOutputKind.studyGuideFaq =>
        l10n.generationOutputsStudyGuideFaqSub,
      GenerationOutputKind.audioOverview =>
        l10n.generationOutputsAudioOverviewSub,
      GenerationOutputKind.conceptMindMap =>
        l10n.generationOutputsConceptMindMapSub,
      GenerationOutputKind.timeline => l10n.generationOutputsTimelineSub,
    };
  }
}

class _SourcesGroundingCard extends StatelessWidget {
  const _SourcesGroundingCard({
    super.key,
    required this.sources,
    required this.activeCount,
    required this.enabled,
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.onToggle,
  });

  final List<NotebookSourceItem> sources;
  final int activeCount;
  final bool enabled;
  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final void Function(NotebookSourceItem src, bool value) onToggle;

  String _title(NotebookSourceKey key) => switch (key) {
    NotebookSourceKey.cameraPage47 => l10n.notebookSourceCameraPage47,
    NotebookSourceKey.teacherPdf => l10n.notebookSourceTeacherPdf,
    NotebookSourceKey.fatherVoice => l10n.notebookSourceFatherVoice,
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.library_books_outlined,
                  color: colors.tealDeep,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.notebookSourcesHeading,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                Tag(
                  label: l10n.notebookSourcesActiveCount(
                    activeCount,
                    sources.length,
                  ),
                  variant: TagVariant.g,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final src in sources)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title(src.sourceKey),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.notebookSourcePassagesBadge(src.passageCount),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      key: GenerationOutputsKeys.sourceSwitch(src.id),
                      value: src.includedInGrounding,
                      onChanged: enabled ? (v) => onToggle(src, v) : null,
                      activeThumbColor: colors.mint,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FlexibilityEngineCard extends StatelessWidget {
  const _FlexibilityEngineCard({
    super.key,
    required this.config,
    required this.enabled,
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.onDepthSelected,
    required this.onToneSelected,
  });

  final NotebookFlexibilityConfig config;
  final bool enabled;
  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final ValueChanged<NotebookDepthLevel> onDepthSelected;
  final ValueChanged<NotebookToneStyle> onToneSelected;

  String _depthText(NotebookDepthLevel d) => switch (d) {
    NotebookDepthLevel.quickBriefing => l10n.notebookDepthQuick,
    NotebookDepthLevel.standardLesson => l10n.notebookDepthStandard,
    NotebookDepthLevel.examCrunch => l10n.notebookDepthExam,
  };

  String _toneText(NotebookToneStyle t) => switch (t) {
    NotebookToneStyle.simpleFusha => l10n.notebookToneFusha,
    NotebookToneStyle.gulfWarm => l10n.notebookToneGulf,
    NotebookToneStyle.bilingualStem => l10n.notebookToneBilingual,
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
                Icon(Icons.tune_outlined, color: colors.p600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.notebookFlexibilityTitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.notebookDepthLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in NotebookDepthLevel.values)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    child: ChoiceChip(
                      key: GenerationOutputsKeys.depthChip(d.name),
                      label: Text(_depthText(d)),
                      selected: config.depth == d,
                      onSelected: enabled ? (_) => onDepthSelected(d) : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.notebookToneLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in NotebookToneStyle.values)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    child: ChoiceChip(
                      key: GenerationOutputsKeys.toneChip(t.name),
                      label: Text(_toneText(t)),
                      selected: config.tone == t,
                      onSelected: enabled ? (_) => onToneSelected(t) : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notebookStrictGroundingLabel,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: colors.mintInk,
              ),
            ),
          ],
        ),
      ),
    );
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
    GenerationOutputKind.studyGuideFaq => Icons.fact_check_outlined,
    GenerationOutputKind.audioOverview => Icons.podcasts_outlined,
    GenerationOutputKind.conceptMindMap => Icons.account_tree_outlined,
    GenerationOutputKind.timeline => Icons.timeline_outlined,
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
