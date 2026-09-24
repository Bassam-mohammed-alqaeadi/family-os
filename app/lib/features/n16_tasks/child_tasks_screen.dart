import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n16_tasks/child_tasks_models.dart';
import 'package:family_os/features/n16_tasks/child_tasks_repository.dart';
import 'package:family_os/features/n16_tasks/tasks_ux_bridge.dart';

/// Widget keys for SCR-CHD-022 acceptance.
abstract final class ChildTasksKeys {
  static const screen = Key('child_tasks_screen');
  static const loading = Key('child_tasks_loading');
  static const empty = Key('child_tasks_empty');
  static const body = Key('child_tasks_body');
  static const hero = Key('child_tasks_hero');
  static const list = Key('child_tasks_list');
  static const parentLean = Key('child_tasks_parent_lean');
  static const sosIconCta = Key('child_tasks_sos_icon');

  static Key row(String id) => Key('child_tasks_row_$id');
  static Key submit(String id) => Key('child_tasks_submit_$id');
}

/// SCR-CHD-022 — مهامي (child tasks + minutes rewards).
///
/// Prototype CHD-022 · RoleGuard child · minutes-only · submit proof mock ·
/// P-4 SOS · Rule 12/23.
class ChildTasksScreen extends StatefulWidget {
  const ChildTasksScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildTasksRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildTasksScreen> createState() => _ChildTasksScreenState();
}

class _ChildTasksScreenState extends State<ChildTasksScreen> {
  late ChildTasksRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _busy = false;
  ChildTasksSnapshot _snap = const ChildTasksSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildTasksRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  /// The child's own list, unless a test injects a repository.
  Future<ChildTasksRepository> _resolveRepo() async {
    final injected = widget.repository;
    if (injected != null) return injected;
    final identity = CurrentIdentity.maybeOf(context);
    final familyId = identity?.activeFamilyId.value ?? '';
    final childId = identity?.activeChildId.value;
    await Stage1TasksRuntime.ensureOpen();
    return Stage1TasksRuntime.childTasks(
      familyId: familyId,
      childId: childId,
    );
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

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  String _title(AppLocalizations l10n, String key) {
    return switch (key) {
      'tidyRoom' => l10n.childTasksTitleTidyRoom,
      'mathReview' => l10n.childTasksTitleMathReview,
      'wirdDone' => l10n.childTasksTitleWirdDone,
      // A real task keeps the title it was stored with.
      _ => key.isEmpty ? l10n.childTasksTitleTidyRoom : key,
    };
  }

  Future<void> _submit(String taskId) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final snap = await _repo.submitProof(taskId);
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _busy = false;
    });
    AppToast.show(context, message: l10n.childTasksSubmitToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildTasksKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childTasksTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildTasksKeys.sosIconCta,
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
        key: ChildTasksKeys.parentLean,
        title: l10n.childTasksParentLeanTitle,
        message: l10n.childTasksParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildTasksKeys.loading,
        child: Semantics(
          label: l10n.childTasksLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildTasksKeys.empty,
        title: l10n.childTasksEmptyTitle,
        message: l10n.childTasksEmptyMessage,
        actionLabel: l10n.childTasksEmptyCta,
        onAction: () => _go('SCR-CHD-004'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildTasksKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            key: ChildTasksKeys.hero,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colors.teal, colors.teal600]),
              borderRadius: BorderRadius.circular(radii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                children: [
                  Text(
                    l10n.childTasksHeroCaption,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.childTasksHeroHeadline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
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
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.childTasksTodayHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    key: ChildTasksKeys.list,
                    children: [
                      for (final t in _snap.tasks) ...[
                        Padding(
                          key: ChildTasksKeys.row(t.id),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _title(l10n, t.titleKey),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: colors.ink,
                                      ),
                                    ),
                                    Text(
                                      l10n.childTasksRewardLine(
                                        t.rewardMinutes,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.ink2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              switch (t.status) {
                                ChildTaskItemStatus.assigned => PrimaryBtn(
                                  key: ChildTasksKeys.submit(t.id),
                                  label: l10n.childTasksSubmitCta,
                                  fullWidth: false,
                                  onPressed: _busy ? null : () => _submit(t.id),
                                ),
                                ChildTaskItemStatus.pendingApproval => Tag(
                                  label: l10n.childTasksTagPending,
                                  variant: TagVariant.a,
                                ),
                                ChildTaskItemStatus.completed => Tag(
                                  label: l10n.childTasksTagRewarded,
                                  variant: TagVariant.g,
                                ),
                              },
                            ],
                          ),
                        ),
                      ],
                    ],
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
