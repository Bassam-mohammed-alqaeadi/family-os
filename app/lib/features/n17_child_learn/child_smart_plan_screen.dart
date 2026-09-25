import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_smart_plan_models.dart';
import 'package:family_os/features/n17_child_learn/child_smart_plan_repository.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

abstract final class ChildSmartPlanKeys {
  static const screen = Key('child_smart_plan_screen');
  static const loading = Key('child_smart_plan_loading');
  static const empty = Key('child_smart_plan_empty');
  static const body = Key('child_smart_plan_body');
  static const gapCard = Key('child_smart_plan_gap');
  static const projectCard = Key('child_smart_plan_project');
  static const pathCard = Key('child_smart_plan_path');
  static const startCta = Key('child_smart_plan_start');
  static const projectCta = Key('child_smart_plan_project_cta');
  static const parentLean = Key('child_smart_plan_parent_lean');
  static const sosIconCta = Key('child_smart_plan_sos_icon');
}

/// SCR-CHD-028 — خطتي الذكية.
class ChildSmartPlanScreen extends StatefulWidget {
  const ChildSmartPlanScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildSmartPlanRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildSmartPlanScreen> createState() => _ChildSmartPlanScreenState();
}

class _ChildSmartPlanScreenState extends State<ChildSmartPlanScreen> {
  late ChildSmartPlanRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildSmartPlanSnapshot _snap = const ChildSmartPlanSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1LearnRuntime.smartPlan;
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

  String _gap(AppLocalizations l10n) => switch (_snap.gapKey) {
    'times7' => l10n.childSmartPlanGapTimes7,
    _ => l10n.childSmartPlanGapTimes7,
  };

  String _project(AppLocalizations l10n) => switch (_snap.projectKey) {
    'homeGarden' => l10n.childSmartPlanProjectGarden,
    _ => l10n.childSmartPlanProjectGarden,
  };

  String _stage(AppLocalizations l10n) => switch (_snap.projectStageKey) {
    'stage2' => l10n.childSmartPlanStage2,
    _ => l10n.childSmartPlanStage2,
  };

  Future<void> _startPlan() async {
    final snap = await _repo.startRepairPlan();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childSmartPlanStartToast,
    );
  }

  Future<void> _completeProject() async {
    final snap = await _repo.completeProjectStage();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childSmartPlanProjectToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildSmartPlanKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childSmartPlanTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildSmartPlanKeys.sosIconCta,
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
    if (!_isChild) {
      return AppEmptyState(
        key: ChildSmartPlanKeys.parentLean,
        title: l10n.childSmartPlanParentLeanTitle,
        message: l10n.childSmartPlanParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildSmartPlanKeys.loading,
        child: Semantics(
          label: l10n.childSmartPlanLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildSmartPlanKeys.empty,
        title: l10n.childSmartPlanEmptyTitle,
        message: l10n.childSmartPlanEmptyMessage,
        actionLabel: l10n.childSmartPlanEmptyCta,
        onAction: () => _go('SCR-CHD-012'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildSmartPlanKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            key: ChildSmartPlanKeys.gapCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.teal, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.childSmartPlanGapHeading,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _gap(l10n),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryBtn(
                    key: ChildSmartPlanKeys.startCta,
                    label: _snap.planStarted
                        ? l10n.childSmartPlanStartedCta
                        : l10n.childSmartPlanStartCta,
                    variant: PrimaryBtnVariant.teal,
                    onPressed: _snap.planStarted ? null : _startPlan,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: ChildSmartPlanKeys.projectCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.teal, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.childSmartPlanProjectHeading(_project(l10n)),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.childSmartPlanProjectStage(_stage(l10n)),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryBtn(
                    key: ChildSmartPlanKeys.projectCta,
                    label: _snap.projectDone
                        ? l10n.childSmartPlanProjectDoneCta
                        : l10n.childSmartPlanProjectCta,
                    variant: PrimaryBtnVariant.teal,
                    onPressed: _snap.projectDone ? null : _completeProject,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: ChildSmartPlanKeys.pathCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.childSmartPlanPathHeading,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < _snap.pathTotal; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < _snap.pathDone
                                    ? colors.mint
                                    : i == _snap.pathDone
                                    ? colors.teal
                                    : colors.border,
                              ),
                              child: Center(
                                child: Text(
                                  i < _snap.pathDone ? '✓' : '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: i <= _snap.pathDone
                                        ? Colors.white
                                        : colors.ink2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.childSmartPlanPathCaption,
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
          const SizedBox(height: 10),
          Text(
            l10n.childSmartPlanExerciseHint,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
