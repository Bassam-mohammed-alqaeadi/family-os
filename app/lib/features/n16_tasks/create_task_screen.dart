import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n16_tasks/create_task_models.dart';
import 'package:family_os/features/n16_tasks/create_task_repository.dart';
import 'package:family_os/features/n16_tasks/tasks_ux_bridge.dart';

/// Widget keys for SCR-FAT-055 acceptance.
abstract final class CreateTaskKeys {
  static const screen = Key('create_task_screen');
  static const loading = Key('create_task_loading');
  static const empty = Key('create_task_empty');
  static const body = Key('create_task_body');
  static const titleField = Key('create_task_title_field');
  static const assigneeSection = Key('create_task_assignee');
  static const motherHelpBanner = Key('create_task_mother_help');
  static const rewardCard = Key('create_task_reward');
  static const courageSection = Key('create_task_courage');
  static const playtimeSection = Key('create_task_playtime');
  static const submitCta = Key('create_task_submit');
  static const observerHint = Key('create_task_observer');
  static const childLean = Key('create_task_child_lean');
  static const sosIconCta = Key('create_task_sos_icon');

  static Key courageChip(int minutes) => Key('create_task_courage_$minutes');
  static Key playtimeChip(int minutes) => Key('create_task_playtime_$minutes');
}

/// SCR-FAT-055 — إنشاء مهمة بمكافأة (create task with reward).
///
/// Prototype FAT-055 · tasks wave · Rule 12/23 · mother levels · mock-first ·
/// ARB · P-4 SOS · minutes-only (ع-١) · CTA → FAT-054 family tasks.
class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1CreateTaskRepository].
  final CreateTaskRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full may submit.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  late CreateTaskRepository _repo;
  late final SosFireService _sos;
  late final TextEditingController _titleCtrl;
  var _sosBusy = false;
  var _loading = true;
  var _submitBusy = false;
  CreateTaskSnapshot _snap = const CreateTaskSnapshot();
  CreateTaskDraft _draft = const CreateTaskDraft();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may submit (prototype §7).
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
    _repo = widget.repository ?? stage1CreateTaskRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    _titleCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CreateTaskScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1CreateTaskRepository;
      _load();
    }
  }

  /// The real create-task flow, unless a test injects a repository.
  Future<CreateTaskRepository> _resolveRepo() async {
    final injected = widget.repository;
    if (injected != null) return injected;
    final identity = CurrentIdentity.maybeOf(context);
    final familyId = identity?.activeFamilyId.value ?? '';
    final accountId = identity?.account.id.value;
    await Stage1TasksRuntime.ensureOpen();
    return Stage1TasksRuntime.createTask(
      familyId: familyId,
      createdByAccount: accountId,
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final resolved = await _resolveRepo();
    if (!mounted) return;
    _repo = resolved;
    final snap = await _repo.load();
    if (!mounted) return;
    _titleCtrl.text = snap.draft.title;
    setState(() {
      _snap = snap;
      _draft = snap.draft;
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
    AppToast.show(context, message: l10n.createTaskObserverBlocked);
  }

  String _assigneeLabel(AppLocalizations l10n, String nameKey) {
    return switch (nameKey) {
      'childOne' => l10n.createTaskAssigneeChildOne,
      'childTwo' => l10n.createTaskAssigneeChildTwo,
      'childThree' => l10n.createTaskAssigneeChildThree,
      'mother' => l10n.createTaskAssigneeMother,
      // A fourth child (childFour …) keeps its ordinal label.
      _ => nameKey.isEmpty ? l10n.createTaskAssigneeChildOne : nameKey,
    };
  }

  Future<void> _onSubmit() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (_submitBusy) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      AppToast.show(context, message: l10n.createTaskTitleEmptyToast);
      return;
    }
    setState(() => _submitBusy = true);
    final draft = _draft.copyWith(title: title);
    final snap = await _repo.submitTask(draft);
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _draft = snap.draft;
      _submitBusy = false;
    });
    AppToast.show(
      context,
      message: l10n.createTaskSubmittedToast(
        title,
        _assigneeLabel(l10n, draft.assigneeNameKey),
      ),
    );
    _go('SCR-FAT-054');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: CreateTaskKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.createTaskTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: CreateTaskKeys.sosIconCta,
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
        key: CreateTaskKeys.childLean,
        title: l10n.createTaskChildLeanTitle,
        message: l10n.createTaskChildLeanMessage,
        actionLabel: l10n.createTaskSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: CreateTaskKeys.loading,
        child: Semantics(
          label: l10n.createTaskLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: CreateTaskKeys.empty,
        title: l10n.createTaskEmptyTitle,
        message: l10n.createTaskEmptyMessage,
        actionLabel: l10n.createTaskEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final showReward = !_draft.isMotherAssignee;

    return SingleChildScrollView(
      key: CreateTaskKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: CreateTaskKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.createTaskObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            l10n.createTaskTaskTitleLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: CreateTaskKeys.titleField,
            controller: _titleCtrl,
            minLines: 1,
            maxLines: 2,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
            decoration: InputDecoration(
              hintText: l10n.createTaskTaskTitleHint,
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.createTaskAssigneeLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: CreateTaskKeys.assigneeSection,
            initialValue: _draft.assigneeNameKey,
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
            ),
            // The family's real children, by ordinal — five children give five
            // rows, and Rule 23 still holds (ordinals, never names).
            items: [
              for (var i = 0; i < _snap.children.length; i++)
                Stage1RowVocabulary.childKeyFor(i),
              'mother',
            ].map((key) {
              return DropdownMenuItem(
                value: key,
                child: Text(_assigneeLabel(l10n, key)),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _draft = _draft.copyWith(assigneeNameKey: v));
            },
          ),
          const SizedBox(height: 10),
          if (_draft.isMotherAssignee) ...[
            BannerNote(
              key: CreateTaskKeys.motherHelpBanner,
              variant: BannerVariant.t,
              message: l10n.createTaskMotherHelpBanner,
            ),
            const SizedBox(height: 10),
          ],
          if (showReward)
            _RewardCard(
              colors: colors,
              radii: radii,
              l10n: l10n,
              draft: _draft,
              onCourageChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(courageMinutes: v)),
              onPlaytimeChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(playtimeMinutes: v)),
            ),
          if (showReward) const SizedBox(height: 12),
          PrimaryBtn(
            key: CreateTaskKeys.submitCta,
            label: l10n.createTaskSubmitCta,
            onPressed: _submitBusy ? null : _onSubmit,
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.draft,
    required this.onCourageChanged,
    required this.onPlaytimeChanged,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final CreateTaskDraft draft;
  final ValueChanged<CreateTaskCourageMinutes> onCourageChanged;
  final ValueChanged<CreateTaskPlaytimeMinutes> onPlaytimeChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: CreateTaskKeys.rewardCard,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.mint100.withValues(alpha: 0.45), colors.mint100],
        ),
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.mint, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.createTaskRewardTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.mintInk,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.createTaskCourageLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              key: CreateTaskKeys.courageSection,
              spacing: 6,
              runSpacing: 6,
              children: CreateTaskCourageMinutes.values.map((option) {
                final minutes = option.value;
                return _MinuteChip(
                  key: CreateTaskKeys.courageChip(minutes),
                  label: l10n.createTaskMinutesLabel(minutes),
                  selected: draft.courageMinutes == option,
                  colors: colors,
                  onTap: () => onCourageChanged(option),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.createTaskPlaytimeLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              key: CreateTaskKeys.playtimeSection,
              spacing: 6,
              runSpacing: 6,
              children: CreateTaskPlaytimeMinutes.values.map((option) {
                final minutes = option.value;
                return _MinuteChip(
                  key: CreateTaskKeys.playtimeChip(minutes),
                  label: l10n.createTaskMinutesLabel(minutes),
                  selected: draft.playtimeMinutes == option,
                  colors: colors,
                  onTap: () => onPlaytimeChanged(option),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinuteChip extends StatelessWidget {
  const _MinuteChip({
    super.key,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final FamilyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.mint : colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? colors.mintInk : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? colors.mintInk : colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
