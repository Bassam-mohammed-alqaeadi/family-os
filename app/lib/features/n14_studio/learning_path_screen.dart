import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/progress_bar.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n14_studio/learning_path_models.dart';
import 'package:family_os/features/n14_studio/learning_path_repository.dart';

/// Widget keys for SCR-FAT-047 acceptance.
abstract final class LearningPathKeys {
  static const screen = Key('learning_path_screen');
  static const loading = Key('learning_path_loading');
  static const empty = Key('learning_path_empty');
  static const body = Key('learning_path_body');
  static const progress = Key('learning_path_progress');
  static const thread = Key('learning_path_thread');
  static const advisorBanner = Key('learning_path_advisor');
  static const materialsCta = Key('learning_path_materials');
  static const observerHint = Key('learning_path_observer');
  static const childLean = Key('learning_path_child_lean');
  static const sosCta = Key('learning_path_sos');
  static const sosIconCta = Key('learning_path_sos_icon');

  static Key stopRow(String id) => Key('learning_path_stop_$id');
}

/// SCR-FAT-047 — المسار التعليمي (learning path).
///
/// Prototype FAT-047 · studio/education wave · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · CTA → FAT-048 materials.
class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1LearningPathRepository].
  final LearningPathRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full open materials.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late LearningPathRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  LearningPathSnapshot _snap = const LearningPathSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may open materials / current stop.
  bool get _canAct {
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
    _repo = widget.repository ?? stage1LearningPathRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant LearningPathScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1LearningPathRepository;
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
    AppToast.show(context, message: l10n.learningPathObserverBlocked);
  }

  String _childName(AppLocalizations l10n) {
    return switch (_snap.childNameKey) {
      'one' => l10n.learningPathChildOne,
      'two' => l10n.learningPathChildTwo,
      'three' => l10n.learningPathChildThree,
      _ => l10n.learningPathChildOne,
    };
  }

  String _subject(AppLocalizations l10n) {
    return switch (_snap.subjectKey) {
      'fractions' => l10n.learningPathSubjectFractions,
      _ => l10n.learningPathSubjectFractions,
    };
  }

  String _stopTitle(AppLocalizations l10n, LearningPathStop stop) {
    return switch (stop.titleKey) {
      'concept' => l10n.learningPathStopConcept,
      'similar' => l10n.learningPathStopSimilar,
      'adding' => l10n.learningPathStopAdding,
      'subtract' => l10n.learningPathStopSubtract,
      'finalQuiz' => l10n.learningPathStopFinalQuiz,
      _ => l10n.learningPathStopConcept,
    };
  }

  String _stopSubtitle(AppLocalizations l10n, LearningPathStop stop) {
    return switch (stop.subtitleKey) {
      'mastered' => l10n.learningPathStopMastered(stop.masteryPercent ?? 0),
      'quizPending' => l10n.learningPathStopQuizPending,
      'locked' => l10n.learningPathStopLocked,
      'reward' => l10n.learningPathStopReward(stop.rewardMinutes ?? 0),
      _ => l10n.learningPathStopLocked,
    };
  }

  void _onMaterials() {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    _go('SCR-FAT-048');
  }

  void _onStopTap(LearningPathStop stop) {
    final l10n = AppLocalizations.of(context);
    if (stop.status == LearningStopStatus.locked) {
      AppToast.show(context, message: l10n.learningPathLockedToast);
      return;
    }
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (stop.status == LearningStopStatus.current) {
      _go('SCR-FAT-048');
      return;
    }
    AppToast.show(context, message: l10n.learningPathMasteredToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: LearningPathKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.learningPathTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: LearningPathKeys.sosIconCta,
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
        key: LearningPathKeys.childLean,
        title: l10n.learningPathChildLeanTitle,
        message: l10n.learningPathChildLeanMessage,
        actionLabel: l10n.learningPathSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: LearningPathKeys.childLean,
        title: l10n.learningPathChildLeanTitle,
        message: l10n.learningPathChildLeanMessage,
        actionLabel: l10n.learningPathSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: LearningPathKeys.loading,
        child: Semantics(
          label: l10n.learningPathLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: LearningPathKeys.empty,
        title: l10n.learningPathEmptyTitle,
        message: l10n.learningPathEmptyMessage,
        actionLabel: l10n.learningPathEmptyCta,
        onAction: () => _go('SCR-FAT-041'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final pathHeading = l10n.learningPathHeading(
      _childName(l10n),
      _subject(l10n),
    );

    return SingleChildScrollView(
      key: LearningPathKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: LearningPathKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.learningPathObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            pathHeading,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProgressBar(
                    key: LearningPathKeys.progress,
                    value: _snap.progressPercent / 100.0,
                    variant: ProgressBarVariant.pu,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.learningPathProgressLabel(
                      _snap.progressPercent,
                      _snap.completedLessons,
                      _snap.totalLessons,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    key: LearningPathKeys.thread,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final stop in _snap.stops)
                        _StopRow(
                          rowKey: LearningPathKeys.stopRow(stop.id),
                          stop: stop,
                          title: _stopTitle(l10n, stop),
                          subtitle: _stopSubtitle(l10n, stop),
                          colors: colors,
                          onTap: () => _onStopTap(stop),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          BannerNote(
            key: LearningPathKeys.advisorBanner,
            variant: BannerVariant.p,
            leading: Icon(
              Icons.psychology_outlined,
              color: colors.p700,
              size: 20,
            ),
            message: l10n.learningPathAdvisorBanner,
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            key: LearningPathKeys.materialsCta,
            label: l10n.learningPathMaterialsCta,
            onPressed: _onMaterials,
          ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.rowKey,
    required this.stop,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final Key rowKey;
  final LearningPathStop stop;
  final String title;
  final String subtitle;
  final FamilyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = stop.status == LearningStopStatus.locked;
    final current = stop.status == LearningStopStatus.current;

    final leading = switch (stop.status) {
      LearningStopStatus.mastered => '✅',
      LearningStopStatus.current => '📍',
      LearningStopStatus.locked =>
        stop.kind == LearningStopKind.quiz ? '🏆' : null,
    };
    final displayTitle = leading == null ? title : '$leading $title';

    return Opacity(
      opacity: locked ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: rowKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: current ? colors.p700 : colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
