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
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';
import 'package:family_os/features/n16_tasks/tasks_ux_bridge.dart';

/// Widget keys for SCR-FAT-054 acceptance.
abstract final class FamilyTasksKeys {
  static const screen = Key('family_tasks_screen');
  static const loading = Key('family_tasks_loading');
  static const empty = Key('family_tasks_empty');
  static const body = Key('family_tasks_body');
  static const headerRow = Key('family_tasks_header');
  static const newTaskCta = Key('family_tasks_new_task');
  static const pendingCard = Key('family_tasks_pending');
  static const pendingEmpty = Key('family_tasks_pending_empty');
  static const motherHelpCard = Key('family_tasks_mother_help');
  static const activeCard = Key('family_tasks_active');
  static const observerHint = Key('family_tasks_observer');
  static const childLean = Key('family_tasks_child_lean');
  static const sosCta = Key('family_tasks_sos');
  static const sosIconCta = Key('family_tasks_sos_icon');

  static Key pendingRow(String id) => Key('family_tasks_pending_$id');
  static Key pendingApprove(String id) => Key('family_tasks_approve_$id');
  static Key motherHelpRow(String id) => Key('family_tasks_mother_$id');
  static Key activeRow(String id) => Key('family_tasks_active_$id');
}

/// SCR-FAT-054 — المهام العائلية (family tasks).
///
/// Prototype FAT-054 · calendar wave · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · minutes-only rewards · CTA → FAT-055.
class FamilyTasksScreen extends StatefulWidget {
  const FamilyTasksScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1FamilyTasksRepository].
  final FamilyTasksRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full may approve / create.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<FamilyTasksScreen> createState() => _FamilyTasksScreenState();
}

class _FamilyTasksScreenState extends State<FamilyTasksScreen> {
  late FamilyTasksRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  FamilyTasksSnapshot _snap = const FamilyTasksSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may approve and create tasks.
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
    _repo = widget.repository ?? stage1FamilyTasksRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant FamilyTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1FamilyTasksRepository;
      _load();
    }
  }

  /// The real task board, unless a test injects a repository (Rule 25 seam).
  Future<FamilyTasksRepository> _resolveRepo() async {
    final injected = widget.repository;
    if (injected != null) return injected;
    final familyId =
        CurrentIdentity.maybeOf(context)?.activeFamilyId.value ?? '';
    await Stage1TasksRuntime.ensureOpen();
    return Stage1TasksRuntime.familyTasks(familyId: familyId);
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
    AppToast.show(context, message: l10n.familyTasksObserverBlocked);
  }

  String _childName(AppLocalizations l10n, String nameKey) {
    return switch (nameKey) {
      'childOne' => l10n.familyTasksChildOne,
      'childTwo' => l10n.familyTasksChildTwo,
      'childThree' => l10n.familyTasksChildThree,
      // A real row may name a fourth child or carry a stored value: show it
      // rather than a different child's label.
      _ => nameKey.isEmpty ? l10n.familyTasksChildOne : nameKey,
    };
  }

  String _taskTitle(AppLocalizations l10n, String titleKey) {
    return switch (titleKey) {
      'tidyRoom' => l10n.familyTasksTaskTidyRoom,
      'washDishes' => l10n.familyTasksTaskWashDishes,
      'mathStudy' => l10n.familyTasksTaskMathStudy,
      'schoolReturnList' => l10n.familyTasksTaskSchoolReturnList,
      // A father's own task title is stored verbatim; show it as written.
      _ => titleKey.isEmpty ? l10n.familyTasksTaskTidyRoom : titleKey,
    };
  }

  String _timeLine(AppLocalizations l10n, String timeKey) {
    return switch (timeKey) {
      'tenMinAgo' => l10n.familyTasksTimeTenMinAgo,
      'today' => l10n.familyTasksTimeToday,
      'yesterday' => l10n.familyTasksTimeYesterday,
      // Older rows carry their real date — never a false «اليوم».
      _ => timeKey.isEmpty ? l10n.familyTasksTimeToday : timeKey,
    };
  }

  String _proofLine(AppLocalizations l10n, String? proofKey) {
    if (proofKey == null) return '';
    return switch (proofKey) {
      'photoAttached' => l10n.familyTasksProofPhotoAttached,
      // A real attachment reference shows as stored.
      _ => proofKey,
    };
  }

  String _avatarEmoji(String avatarKey) {
    return switch (avatarKey) {
      'lion' => '🦁',
      'cat' => '🐱',
      'panda' => '🐼',
      _ => '📌',
    };
  }

  String _statusLabel(AppLocalizations l10n, FamilyTaskStatus status) {
    return switch (status) {
      FamilyTaskStatus.completed => l10n.familyTasksStatusCompleted,
      FamilyTaskStatus.pendingApproval => l10n.familyTasksStatusPendingApproval,
      FamilyTaskStatus.assigned => l10n.familyTasksStatusAssigned,
    };
  }

  TagVariant _statusVariant(FamilyTaskStatus status) {
    return switch (status) {
      FamilyTaskStatus.completed => TagVariant.g,
      FamilyTaskStatus.pendingApproval => TagVariant.a,
      FamilyTaskStatus.assigned => TagVariant.t,
    };
  }

  String _statusIcon(FamilyTaskStatus status) {
    return switch (status) {
      FamilyTaskStatus.completed => '✅',
      FamilyTaskStatus.pendingApproval => '⏳',
      FamilyTaskStatus.assigned => '📌',
    };
  }

  Future<void> _onApprove(FamilyChildTask task) async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    await _repo.approveTask(task.id);
    if (!mounted) return;
    final snap = await _repo.load();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: l10n.familyTasksApproveToast(
        _childName(l10n, task.assigneeNameKey),
        task.rewardMinutes,
      ),
    );
  }

  void _onNewTask() {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    _go('SCR-FAT-055');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: FamilyTasksKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.familyTasksTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: FamilyTasksKeys.sosIconCta,
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
    if (_isChild || !_isParent) {
      return AppEmptyState(
        key: FamilyTasksKeys.childLean,
        title: l10n.familyTasksChildLeanTitle,
        message: l10n.familyTasksChildLeanMessage,
        actionLabel: l10n.familyTasksSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: FamilyTasksKeys.loading,
        child: Semantics(
          label: l10n.familyTasksLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: FamilyTasksKeys.empty,
        title: l10n.familyTasksEmptyTitle,
        message: l10n.familyTasksEmptyMessage,
        actionLabel: l10n.familyTasksEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final pending = _snap.pendingApproval;

    return SingleChildScrollView(
      key: FamilyTasksKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: FamilyTasksKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.familyTasksObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            key: FamilyTasksKeys.headerRow,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  l10n.familyTasksSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PrimaryBtn(
                key: FamilyTasksKeys.newTaskCta,
                label: l10n.familyTasksNewTaskCta,
                fullWidth: false,
                onPressed: _onNewTask,
              ),
            ],
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            key: FamilyTasksKeys.pendingCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.mint, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.familyTasksPendingHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.mintInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (pending.isEmpty)
                    Padding(
                      key: FamilyTasksKeys.pendingEmpty,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.familyTasksPendingEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                        ),
                      ),
                    )
                  else
                    for (final task in pending)
                      _PendingRow(
                        rowKey: FamilyTasksKeys.pendingRow(task.id),
                        approveKey: FamilyTasksKeys.pendingApprove(task.id),
                        avatarEmoji: _avatarEmoji(task.avatarKey),
                        title: l10n.familyTasksPendingLine(
                          _childName(l10n, task.assigneeNameKey),
                          _taskTitle(l10n, task.titleKey),
                        ),
                        subtitle: [
                          _proofLine(l10n, task.proofKey),
                          _timeLine(l10n, task.timeKey),
                        ].where((s) => s.isNotEmpty).join(' · '),
                        approveLabel: l10n.familyTasksApproveCta(task.rewardMinutes),
                        colors: colors,
                        onApprove: () => _onApprove(task),
                      ),
                ],
              ),
            ),
          ),
          if (_snap.motherHelpTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              key: FamilyTasksKeys.motherHelpCard,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(color: colors.coral, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.familyTasksMotherHelpHeading,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final task in _snap.motherHelpTasks)
                      _MotherHelpRow(
                        rowKey: FamilyTasksKeys.motherHelpRow(task.id),
                        title: _taskTitle(l10n, task.titleKey),
                        subtitle: l10n.familyTasksMotherHelpMeta(
                          _timeLine(l10n, task.timeKey),
                        ),
                        statusLabel: task.status == MotherHelpTaskStatus.done
                            ? l10n.familyTasksMotherStatusDone
                            : l10n.familyTasksMotherStatusOpen,
                        statusVariant: task.status == MotherHelpTaskStatus.done
                            ? TagVariant.g
                            : TagVariant.t,
                        colors: colors,
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          DecoratedBox(
            key: FamilyTasksKeys.activeCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.familyTasksActiveHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final task in _snap.childTasks)
                    _ActiveRow(
                      rowKey: FamilyTasksKeys.activeRow(task.id),
                      statusIcon: _statusIcon(task.status),
                      title: l10n.familyTasksActiveLine(
                        _taskTitle(l10n, task.titleKey),
                        _childName(l10n, task.assigneeNameKey),
                      ),
                      subtitle: l10n.familyTasksRewardMeta(task.rewardMinutes),
                      statusLabel: _statusLabel(l10n, task.status),
                      statusVariant: _statusVariant(task.status),
                      colors: colors,
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

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.rowKey,
    required this.approveKey,
    required this.avatarEmoji,
    required this.title,
    required this.subtitle,
    required this.approveLabel,
    required this.colors,
    required this.onApprove,
  });

  final Key rowKey;
  final Key approveKey;
  final String avatarEmoji;
  final String title;
  final String subtitle;
  final String approveLabel;
  final FamilyColors colors;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.amber,
              borderRadius: BorderRadius.circular(19),
            ),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Center(
                child: Text(avatarEmoji, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: colors.mintInk,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          PrimaryBtn(
            key: approveKey,
            label: approveLabel,
            variant: PrimaryBtnVariant.mint,
            fullWidth: false,
            onPressed: onApprove,
          ),
        ],
      ),
    );
  }
}

class _MotherHelpRow extends StatelessWidget {
  const _MotherHelpRow({
    required this.rowKey,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusVariant,
    required this.colors,
  });

  final Key rowKey;
  final String title;
  final String subtitle;
  final String statusLabel;
  final TagVariant statusVariant;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.coral100, colors.coral],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: Text('🌸', style: TextStyle(fontSize: 14)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          Tag(label: statusLabel, variant: statusVariant),
        ],
      ),
    );
  }
}

class _ActiveRow extends StatelessWidget {
  const _ActiveRow({
    required this.rowKey,
    required this.statusIcon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusVariant,
    required this.colors,
  });

  final Key rowKey;
  final String statusIcon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final TagVariant statusVariant;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(statusIcon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          Tag(label: statusLabel, variant: statusVariant),
        ],
      ),
    );
  }
}
