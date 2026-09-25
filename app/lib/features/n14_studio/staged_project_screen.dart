import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n14_studio/staged_project_models.dart';
import 'package:family_os/features/n14_studio/staged_project_repository.dart';
import 'package:family_os/features/n14_studio/studio_ux_bridge.dart';

abstract final class StagedProjectKeys {
  static const screen = Key('staged_project_screen');
  static const loading = Key('staged_project_loading');
  static const empty = Key('staged_project_empty');
  static const body = Key('staged_project_body');
  static const hero = Key('staged_project_hero');
  static const stages = Key('staged_project_stages');
  static const confirmCta = Key('staged_project_confirm');
  static const templateCta = Key('staged_project_template');
  static const childLean = Key('staged_project_child_lean');
  static const sosIconCta = Key('staged_project_sos_icon');
}

/// SCR-FAT-084 — مشروع بمراحل (minutes rewards · confirm stage).
class StagedProjectScreen extends StatefulWidget {
  const StagedProjectScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final StagedProjectRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<StagedProjectScreen> createState() => _StagedProjectScreenState();
}

class _StagedProjectScreenState extends State<StagedProjectScreen> {
  late StagedProjectRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  StagedProjectSnapshot _snap = const StagedProjectSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;
  bool get _canAct {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel != MotherLevel.observer;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1StudioRuntime.stagedProject;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
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
    await _sos.fire(childId: 'self');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-CHD-005'));
  }

  void _go(String id) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(id);
      return;
    }
    context.push(screenPath(id));
  }

  String _title(AppLocalizations l10n) => switch (_snap.titleKey) {
    'homeGarden' => l10n.stagedProjectHomeGarden,
    _ => l10n.stagedProjectHomeGarden,
  };

  String _child(AppLocalizations l10n) => switch (_snap.childLabelKey) {
    'childOne' => l10n.stagedProjectChildOne,
    _ => l10n.stagedProjectChildOne,
  };

  String _stageTitle(AppLocalizations l10n, String key) => switch (key) {
    'research' => l10n.stagedProjectStageResearch,
    'plant' => l10n.stagedProjectStagePlant,
    'water' => l10n.stagedProjectStageWater,
    'harvest' => l10n.stagedProjectStageHarvest,
    _ => key,
  };

  String _stageSub(AppLocalizations l10n, String key) => switch (key) {
    'researchSub' => l10n.stagedProjectStageResearchSub,
    'plantSub' => l10n.stagedProjectStagePlantSub,
    'waterSub' => l10n.stagedProjectStageWaterSub,
    'harvestSub' => l10n.stagedProjectStageHarvestSub,
    _ => key,
  };

  Future<void> _confirm() async {
    if (!_canAct) return;
    final snap = await _repo.confirmActiveStage();
    if (!mounted) return;
    setState(() => _snap = snap);
    final mins = snap.stages
        .where((s) => s.status == ProjectStageStatus.done)
        .map((s) => s.rewardMinutes)
        .fold<int>(0, (a, b) => b);
    AppToast.show(
      context,
      message: AppLocalizations.of(context).stagedProjectConfirmToast(mins),
    );
  }

  Future<void> _templates() async {
    await _repo.openTemplatePicker();
    if (!mounted) return;
    AppToast.show(
      context,
      message: AppLocalizations.of(context).stagedProjectTemplateToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: StagedProjectKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.stagedProjectTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: StagedProjectKeys.sosIconCta,
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
      body: SafeArea(child: _body(l10n, colors)),
    );
  }

  Widget _body(AppLocalizations l10n, FamilyColors colors) {
    if (_isChild) {
      return AppEmptyState(
        key: StagedProjectKeys.childLean,
        title: l10n.stagedProjectChildLeanTitle,
        message: l10n.stagedProjectChildLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: StagedProjectKeys.loading,
        child: Semantics(
          label: l10n.stagedProjectLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: StagedProjectKeys.empty,
        title: l10n.stagedProjectEmptyTitle,
        message: l10n.stagedProjectEmptyMessage,
        actionLabel: l10n.stagedProjectEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final hasActive = _snap.stages.any(
      (s) => s.status == ProjectStageStatus.active,
    );

    return SingleChildScrollView(
      key: StagedProjectKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            key: StagedProjectKeys.hero,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colors.teal, colors.teal600]),
              borderRadius: BorderRadius.circular(radii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.stagedProjectHeroTitle(_child(l10n), _title(l10n)),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.stagedProjectHeroSub(
                      _snap.stageCount,
                      _snap.weeks,
                      _snap.currentStage,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _snap.progress,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: StagedProjectKeys.stages,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Column(
                children: [
                  for (final s in _snap.stages)
                    Opacity(
                      opacity: s.status == ProjectStageStatus.locked ? 0.55 : 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              s.status == ProjectStageStatus.done
                                  ? '✅'
                                  : s.status == ProjectStageStatus.active
                                  ? '🔄'
                                  : '🔒',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _stageTitle(l10n, s.titleKey),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: colors.ink,
                                    ),
                                  ),
                                  Text(
                                    _stageSub(l10n, s.subKey),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.ink2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (s.status == ProjectStageStatus.active &&
                                _canAct)
                              SizedBox(
                                width: 96,
                                child: PrimaryBtn(
                                  key: StagedProjectKeys.confirmCta,
                                  label: l10n.stagedProjectConfirmCta,
                                  variant: PrimaryBtnVariant.teal,
                                  fullWidth: false,
                                  onPressed: _confirm,
                                ),
                              )
                            else if (s.rewardMinutes > 0)
                              Tag(
                                label: l10n.stagedProjectMinutesTag(
                                  s.rewardMinutes,
                                ),
                                variant: TagVariant.g,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!hasActive) const SizedBox(height: 4),
          const SizedBox(height: 10),
          PrimaryBtn(
            key: StagedProjectKeys.templateCta,
            label: l10n.stagedProjectTemplateCta,
            variant: PrimaryBtnVariant.ghost,
            onPressed: _templates,
          ),
        ],
      ),
    );
  }
}
