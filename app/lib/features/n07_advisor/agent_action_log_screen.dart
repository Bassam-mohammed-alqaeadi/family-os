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
import 'package:family_os/features/n07_advisor/agent_action_log_models.dart';
import 'package:family_os/features/n07_advisor/agent_action_log_repository.dart';
import 'package:family_os/features/n07_advisor/reports_ux_bridge.dart';

abstract final class AgentActionLogKeys {
  static const screen = Key('agent_action_log_screen');
  static const loading = Key('agent_action_log_loading');
  static const empty = Key('agent_action_log_empty');
  static const body = Key('agent_action_log_body');
  static const liveCard = Key('agent_action_log_live');
  static const blessCta = Key('agent_action_log_bless');
  static const undoCta = Key('agent_action_log_undo');
  static const weekly = Key('agent_action_log_weekly');
  static const childLean = Key('agent_action_log_child_lean');
  static const sosIconCta = Key('agent_action_log_sos_icon');
}

/// SCR-FAT-080 — سجل تصرفات الوكيل المفوَّض (minutes · bless/undo).
class AgentActionLogScreen extends StatefulWidget {
  const AgentActionLogScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final AgentActionLogRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<AgentActionLogScreen> createState() => _AgentActionLogScreenState();
}

class _AgentActionLogScreenState extends State<AgentActionLogScreen> {
  late AgentActionLogRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  AgentActionLogSnapshot _snap = const AgentActionLogSnapshot();

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
    _repo = widget.repository ?? Stage1ReportsRuntime.agentActionLog;
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

  String _child(AppLocalizations l10n) => switch (_snap.childLabelKey) {
    'childOne' => l10n.agentActionLogChildOne,
    _ => l10n.agentActionLogChildOne,
  };

  String _task(AppLocalizations l10n, String key) => switch (key) {
    'mathHw' => l10n.agentActionLogTaskMath,
    'room' => l10n.agentActionLogTaskRoom,
    _ => key,
  };

  String _app(AppLocalizations l10n) => switch (_snap.appTargetKey) {
    'blocksApp' => l10n.agentActionLogAppBlocks,
    _ => l10n.agentActionLogAppBlocks,
  };

  String _weeklyTitle(AppLocalizations l10n, String key) => switch (key) {
    'sleepMode' => l10n.agentActionLogWeeklySleep,
    'reviewRemind' => l10n.agentActionLogWeeklyReview,
    _ => key,
  };

  String _weeklyMeta(AppLocalizations l10n, String key) => switch (key) {
    'sleepMeta' => l10n.agentActionLogWeeklySleepMeta,
    'reviewMeta' => l10n.agentActionLogWeeklyReviewMeta,
    _ => key,
  };

  String _ruleTag(AppLocalizations l10n, String key) => switch (key) {
    'rule2' => l10n.agentActionLogRule2,
    'rule3' => l10n.agentActionLogRule3,
    _ => key,
  };

  Future<void> _bless() async {
    if (!_canAct) return;
    final snap = await _repo.bless();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(context).agentActionLogBlessToast,
    );
  }

  Future<void> _undo() async {
    if (!_canAct) return;
    final snap = await _repo.gentleUndo();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(context).agentActionLogUndoToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: AgentActionLogKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.agentActionLogTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: AgentActionLogKeys.sosIconCta,
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
        key: AgentActionLogKeys.childLean,
        title: l10n.agentActionLogChildLeanTitle,
        message: l10n.agentActionLogChildLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: AgentActionLogKeys.loading,
        child: Semantics(
          label: l10n.agentActionLogLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: AgentActionLogKeys.empty,
        title: l10n.agentActionLogEmptyTitle,
        message: l10n.agentActionLogEmptyMessage,
        actionLabel: l10n.agentActionLogEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final pending = _snap.state == AgentActionState.pending;
    final blessed = _snap.state == AgentActionState.blessed;

    return SingleChildScrollView(
      key: AgentActionLogKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_snap.hasLiveAction)
            DecoratedBox(
              key: AgentActionLogKeys.liveCard,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.mint100, colors.surface],
                ),
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(
                  color: blessed
                      ? colors.mint
                      : pending
                      ? colors.teal
                      : colors.border,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.agentActionLogLiveHeading,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.teal600,
                            ),
                          ),
                        ),
                        Tag(
                          label: blessed
                              ? l10n.agentActionLogTagBlessed
                              : pending
                              ? l10n.agentActionLogTagPending(
                                  _snap.secondsLeft ~/ 60,
                                  _snap.secondsLeft % 60,
                                )
                              : l10n.agentActionLogTagUndone,
                          variant: blessed
                              ? TagVariant.g
                              : pending
                              ? TagVariant.a
                              : TagVariant.t,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.agentActionLogGranted(
                        _snap.minutesGranted,
                        _child(l10n),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    Text(
                      l10n.agentActionLogReason(
                        _snap.taskKeys.map((k) => _task(l10n, k)).join(' + '),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                    Text(
                      l10n.agentActionLogUsage(_app(l10n)),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                    if (pending && _canAct) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryBtn(
                              key: AgentActionLogKeys.blessCta,
                              label: l10n.agentActionLogBlessCta,
                              variant: PrimaryBtnVariant.mint,
                              onPressed: _bless,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PrimaryBtn(
                              key: AgentActionLogKeys.undoCta,
                              label: l10n.agentActionLogUndoCta,
                              variant: PrimaryBtnVariant.sec,
                              onPressed: _undo,
                            ),
                          ),
                        ],
                      ),
                    ] else if (blessed) ...[
                      const SizedBox(height: 10),
                      Text(
                        l10n.agentActionLogBlessedNote,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.mintInk,
                        ),
                      ),
                    ] else if (_snap.state == AgentActionState.undone) ...[
                      const SizedBox(height: 10),
                      Text(
                        l10n.agentActionLogUndoneNote,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (_snap.weekly.isNotEmpty) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              key: AgentActionLogKeys.weekly,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.agentActionLogWeeklyHeading,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    for (final w in _snap.weekly)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _weeklyTitle(l10n, w.titleKey),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: colors.ink,
                                    ),
                                  ),
                                  Text(
                                    _weeklyMeta(l10n, w.metaKey),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.ink2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tag(
                              label: _ruleTag(l10n, w.ruleKey),
                              variant: TagVariant.g,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
