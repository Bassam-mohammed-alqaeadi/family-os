import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n16_tasks/smart_chore_distributor_models.dart';
import 'package:family_os/features/n16_tasks/smart_chore_distributor_repository.dart';
import 'package:family_os/features/n16_tasks/tasks_ux_bridge.dart';

abstract final class SmartChoreDistributorKeys {
  static const screen = Key('smart_chore_distributor_screen');
  static const loading = Key('smart_chore_distributor_loading');
  static const empty = Key('smart_chore_distributor_empty');
  static const body = Key('smart_chore_distributor_body');
  static const proposal = Key('smart_chore_distributor_proposal');
  static const approveCta = Key('smart_chore_distributor_approve');
  static const shuffleCta = Key('smart_chore_distributor_shuffle');
  static const fairness = Key('smart_chore_distributor_fairness');
  static const observerHint = Key('smart_chore_distributor_observer');
  static const childLean = Key('smart_chore_distributor_child_lean');
  static const sosIconCta = Key('smart_chore_distributor_sos_icon');
}

/// SCR-FAT-082 — موزع المهام الذكي (ChoreAI · approve → FAT-054).
class SmartChoreDistributorScreen extends StatefulWidget {
  const SmartChoreDistributorScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final SmartChoreDistributorRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<SmartChoreDistributorScreen> createState() =>
      _SmartChoreDistributorScreenState();
}

class _SmartChoreDistributorScreenState
    extends State<SmartChoreDistributorScreen> {
  late SmartChoreDistributorRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  SmartChoreDistributorSnapshot _snap = const SmartChoreDistributorSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;
  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;
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
    _repo = widget.repository ?? stage1SmartChoreDistributorRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  /// The real chore split, unless a test injects a repository.
  Future<SmartChoreDistributorRepository> _resolveRepo() async {
    final injected = widget.repository;
    if (injected != null) return injected;
    final familyId =
        CurrentIdentity.maybeOf(context)?.activeFamilyId.value ?? '';
    await Stage1TasksRuntime.ensureOpen();
    return Stage1TasksRuntime.choreDistributor(familyId: familyId);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final resolved = await _resolveRepo();
    if (!mounted) return;
    _repo = resolved;
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

  String _child(AppLocalizations l10n, String key) => switch (key) {
    'childOne' => l10n.smartChoreChildOne,
    'childTwo' => l10n.smartChoreChildTwo,
    'childThree' => l10n.smartChoreChildThree,
    _ => key,
  };

  String _chores(AppLocalizations l10n, String key) => switch (key) {
    'dishesPlants' => l10n.smartChoreDishesPlants,
    'livingLaundry' => l10n.smartChoreLivingLaundry,
    'trashWater' => l10n.smartChoreTrashWater,
    _ => key,
  };

  String _note(AppLocalizations l10n, String key) => switch (key) {
    'examTue' => l10n.smartChoreNoteExam,
    'rotated' => l10n.smartChoreNoteRotated,
    'age8' => l10n.smartChoreNoteAge8,
    _ => key,
  };

  Future<void> _approve() async {
    if (!_canAct) return;
    final snap = await _repo.approve();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(context).smartChoreApproveToast,
    );
    _go('SCR-FAT-054');
  }

  Future<void> _shuffle() async {
    if (!_canAct) return;
    final snap = await _repo.shuffle();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(context).smartChoreShuffleToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: SmartChoreDistributorKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.smartChoreTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: SmartChoreDistributorKeys.sosIconCta,
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
        key: SmartChoreDistributorKeys.childLean,
        title: l10n.smartChoreChildLeanTitle,
        message: l10n.smartChoreChildLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: SmartChoreDistributorKeys.loading,
        child: Semantics(
          label: l10n.smartChoreLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: SmartChoreDistributorKeys.empty,
        title: l10n.smartChoreEmptyTitle,
        message: l10n.smartChoreEmptyMessage,
        actionLabel: l10n.smartChoreEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: SmartChoreDistributorKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            Text(
              key: SmartChoreDistributorKeys.observerHint,
              l10n.smartChoreObserverHint,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 10),
          ],
          DecoratedBox(
            key: SmartChoreDistributorKeys.proposal,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.teal, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.smartChoreProposalHeading,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  for (final a in _snap.assignments)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: colors.mint100,
                            child: Text(
                              String.fromCharCode(
                                _child(l10n, a.childLabelKey).runes.first,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: colors.mintInk,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_child(l10n, a.childLabelKey)}: ${_chores(l10n, a.choresKey)}',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: colors.ink,
                                  ),
                                ),
                                Text(
                                  _note(l10n, a.noteKey),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryBtn(
                          key: SmartChoreDistributorKeys.approveCta,
                          label: _snap.approved
                              ? l10n.smartChoreApprovedCta
                              : l10n.smartChoreApproveCta,
                          variant: PrimaryBtnVariant.teal,
                          onPressed: _canAct && !_snap.approved
                              ? _approve
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryBtn(
                          key: SmartChoreDistributorKeys.shuffleCta,
                          label: l10n.smartChoreShuffleCta,
                          variant: PrimaryBtnVariant.sec,
                          onPressed: _canAct ? _shuffle : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: SmartChoreDistributorKeys.fairness,
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
                  Text(
                    l10n.smartChoreFairnessHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.smartChoreFairnessBody,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
