import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/settings_persist_toggle.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/schedule_window.dart';
import 'package:family_os/core/policy/schedule_window_repository.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/screen_time_policy_repository.dart';

/// Optional time-picker override for widget tests.
typedef ScheduleTimePicker = Future<TimeOfDay?> Function(
  BuildContext context,
  TimeOfDay initial,
);

/// Shared Stage-1 prefs store (survives within process; Rule 25 seam).
SchedulePrefsStore stage1SchedulePrefsStore = MemorySchedulePrefsStore();

/// Shared Stage-1 policy prefs (SET-002).
ScreenTimePolicyPrefsStore stage1PolicyPrefsStore =
    MemoryScreenTimePolicyPrefsStore();

/// SCR-FAT-032 — وقت الشاشة لابن (SET-001 schedules + SET-002 caps/wallets + SET-024 overflow).
///
/// ControlFit: schedule windows + daily cap / overflow / wallets that feed
/// TimeEngine (Qustodio-style), not decorative numbers.
class ChildScreenTimeScreen extends StatefulWidget {
  const ChildScreenTimeScreen({
    super.key,
    this.childId,
    this.repository,
    this.policyRepository,
    this.syncBus,
    this.pickTime,
    this.canEditOverride,
  });

  /// Stage-1 demo child when null; real selection arrives with SET-003.
  final ChildId? childId;

  /// Rule 25 seam — null → prefs-backed memory store.
  final ScheduleWindowRepository? repository;

  /// Rule 25 seam — null → prefs-backed policy store (SET-002).
  final ScreenTimePolicyRepository? policyRepository;

  /// SET-003 mock sync bus — null → [stage1PolicySyncBus].
  final PolicySyncBus? syncBus;

  /// Test seam — when null, uses [showTimePicker].
  final ScheduleTimePicker? pickTime;

  /// Test seam — when null, father may edit; mother/child read-only.
  final bool? canEditOverride;

  @override
  State<ChildScreenTimeScreen> createState() => _ChildScreenTimeScreenState();
}

class _ChildScreenTimeScreenState extends State<ChildScreenTimeScreen> {
  late final ChildId _childId;
  late final ScheduleWindowRepository _repository;
  late final ScreenTimePolicyRepository _policyRepository;
  late final PolicySyncBus _syncBus;
  late List<ScheduleWindow> _windows;
  late ScreenTimePolicy _policy;
  late final TextEditingController _capController;
  var _loading = true;
  var _saving = false;
  PolicySyncStatus? _syncStatus;

  @override
  void initState() {
    super.initState();
    _childId = widget.childId ?? ChildId('demo-child');
    _repository = widget.repository ??
        PrefsScheduleWindowRepository(stage1SchedulePrefsStore);
    _policyRepository = widget.policyRepository ??
        PrefsScreenTimePolicyRepository(stage1PolicyPrefsStore);
    _syncBus = widget.syncBus ?? stage1PolicySyncBus;
    _windows = [
      for (final kind in ScheduleKind.values)
        ScheduleWindow(kind: kind, enabled: false),
    ];
    _policy = ScreenTimePolicy.defaults();
    _capController = TextEditingController(
      text: '${_policy.dailyCapMinutes}',
    );
    _load();
  }

  @override
  void dispose() {
    _capController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await _repository.load(_childId);
    final policy = await _policyRepository.load(_childId);
    if (!mounted) return;
    setState(() {
      _windows = loaded;
      _policy = policy;
      _capController.text = '${policy.dailyCapMinutes}';
      _loading = false;
    });
  }

  bool get _canEdit {
    if (widget.canEditOverride != null) return widget.canEditOverride!;
    final role = CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
    return role == AppRole.father;
  }

  bool get _allValid => _windows.every((w) => w.isValid);

  bool get _capValid {
    final parsed = int.tryParse(_capController.text.trim());
    return parsed != null && parsed >= 0;
  }

  bool get _canSave =>
      _canEdit && _allValid && _capValid && !_saving && !_loading;

  ScheduleWindow _window(ScheduleKind kind) =>
      _windows.firstWhere((w) => w.kind == kind);

  void _replace(ScheduleWindow next) {
    setState(() {
      _windows = [
        for (final w in _windows)
          if (w.kind == next.kind) next else w,
      ];
    });
  }

  void _onToggle(ScheduleKind kind, bool enabled) {
    if (!_canEdit) return;
    var next = _window(kind).copyWith(enabled: enabled);
    if (enabled) {
      next = ScheduleWindowDefaults.seedOnEnable(next);
    }
    _replace(next);
  }

  Future<void> _pick(
    ScheduleKind kind, {
    required bool isStart,
  }) async {
    if (!_canEdit) return;
    final current = _window(kind);
    final initial = isStart
        ? (current.start ?? const TimeOfDay(hour: 12, minute: 0))
        : (current.end ?? const TimeOfDay(hour: 13, minute: 0));

    final TimeOfDay? picked;
    if (widget.pickTime != null) {
      picked = await widget.pickTime!(context, initial);
    } else {
      if (!mounted) return;
      picked = await showTimePicker(context: context, initialTime: initial);
    }
    if (picked == null || !mounted) return;

    final next = isStart
        ? current.copyWith(start: picked)
        : current.copyWith(end: picked);
    _replace(next);
  }

  /// UI-008 — wallet overflow persist-on-toggle (Rule 24 / Ruling B).
  Future<void> _persistOverflow(bool value) async {
    if (!_canEdit) throw StateError('overflow read-only');
    final next = _policy.copyWith(allowWalletOverflow: value);
    await _policyRepository.save(_childId, next);
    final stamp = DateTime.now().toUtc();
    final status = _syncBus.publish(
      PolicySyncEvent(
        childId: _childId,
        updatedAt: stamp,
        kind: PolicySyncKind.policy,
        policy: next,
      ),
    );
    if (!mounted) return;
    setState(() {
      _policy = next;
      _syncStatus = status;
    });
  }

  void _onCapChanged(String _) {
    setState(() {}); // refresh save enablement
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final cap = int.parse(_capController.text.trim());
    setState(() => _saving = true);
    final toSave = _policy.copyWith(dailyCapMinutes: cap);
    await _repository.save(_childId, _windows);
    await _policyRepository.save(_childId, toSave);
    final stamp = DateTime.now().toUtc();
    _syncBus.publish(
      PolicySyncEvent(
        childId: _childId,
        updatedAt: stamp,
        kind: PolicySyncKind.schedule,
        schedules: List<ScheduleWindow>.from(_windows),
      ),
    );
    final status = _syncBus.publish(
      PolicySyncEvent(
        childId: _childId,
        updatedAt: stamp.add(const Duration(microseconds: 1)),
        kind: PolicySyncKind.policy,
        policy: toSave,
      ),
    );
    if (!mounted) return;
    setState(() {
      _policy = toSave;
      _saving = false;
      _syncStatus = status;
    });
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.childScreenTimeSaveToast);
  }

  String _syncStatusLabel(AppLocalizations l10n, PolicySyncStatus status) {
    return switch (status) {
      PolicySyncStatus.delivered => l10n.childScreenTimeSyncDelivered,
      PolicySyncStatus.pending => l10n.childScreenTimeSyncPending,
      PolicySyncStatus.offlineQueued => l10n.childScreenTimeSyncPending,
    };
  }

  TagVariant _syncStatusVariant(PolicySyncStatus status) {
    return switch (status) {
      PolicySyncStatus.delivered => TagVariant.g,
      PolicySyncStatus.pending ||
      PolicySyncStatus.offlineQueued =>
        TagVariant.a,
    };
  }

  String _kindLabel(AppLocalizations l10n, ScheduleKind kind) {
    return switch (kind) {
      ScheduleKind.sleep => l10n.childScreenTimeSleep,
      ScheduleKind.prayer => l10n.childScreenTimePrayer,
      ScheduleKind.study => l10n.childScreenTimeStudy,
    };
  }

  String _walletLabel(AppLocalizations l10n, String appId) {
    return switch (appId) {
      'games' => l10n.childScreenTimeWalletGames,
      'youtube' => l10n.childScreenTimeWalletYoutube,
      'quran' => l10n.childScreenTimeWalletQuran,
      _ => appId,
    };
  }

  String _formatTod(TimeOfDay? tod) {
    if (tod == null) return '--:--';
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final canEdit = _canEdit;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.childScreenTimeTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      children: [
                        Text(
                          l10n.childScreenTimeSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: colors.ink2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final kind in ScheduleKind.values) ...[
                          _ScheduleRow(
                            kind: kind,
                            window: _window(kind),
                            label: _kindLabel(l10n, kind),
                            startLabel: l10n.childScreenTimeStart,
                            endLabel: l10n.childScreenTimeEnd,
                            startText: _formatTod(_window(kind).start),
                            endText: _formatTod(_window(kind).end),
                            canEdit: canEdit,
                            colors: colors,
                            radii: radii,
                            onToggle: (v) => _onToggle(kind, v),
                            onPickStart: () => _pick(kind, isStart: true),
                            onPickEnd: () => _pick(kind, isStart: false),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (!_allValid)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              l10n.childScreenTimeValidation,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.coral,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.childScreenTimeCapsSection,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CapsSection(
                          l10n: l10n,
                          policy: _policy,
                          capController: _capController,
                          canEdit: canEdit,
                          colors: colors,
                          radii: radii,
                          walletLabel: (id) => _walletLabel(l10n, id),
                          onCapChanged: _onCapChanged,
                          onOverflowPersist: _persistOverflow,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_syncStatus != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Tag(
                                key: const Key('child_screen_time_sync_status'),
                                label: _syncStatusLabel(l10n, _syncStatus!),
                                variant: _syncStatusVariant(_syncStatus!),
                              ),
                            ),
                          ),
                        if (!canEdit)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              l10n.childScreenTimeReadOnly,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.ink2,
                              ),
                            ),
                          ),
                        PrimaryBtn(
                          key: const Key('child_screen_time_save'),
                          label: l10n.childScreenTimeSave,
                          onPressed: _canSave ? _save : null,
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

class _CapsSection extends StatelessWidget {
  const _CapsSection({
    required this.l10n,
    required this.policy,
    required this.capController,
    required this.canEdit,
    required this.colors,
    required this.radii,
    required this.walletLabel,
    required this.onCapChanged,
    required this.onOverflowPersist,
  });

  final AppLocalizations l10n;
  final ScreenTimePolicy policy;
  final TextEditingController capController;
  final bool canEdit;
  final FamilyColors colors;
  final FamilyRadii radii;
  final String Function(String appId) walletLabel;
  final ValueChanged<String> onCapChanged;
  final Future<void> Function(bool next) onOverflowPersist;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.childScreenTimeDailyCap,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              textField: true,
              label: l10n.childScreenTimeDailyCap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: TextField(
                  key: const Key('daily_cap_field'),
                  controller: capController,
                  enabled: canEdit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: onCapChanged,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colors.p50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radii.btn),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radii.btn),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingsPersistToggle(
              title: l10n.childScreenTimeAllowOverflow,
              subtitle: l10n.childScreenTimeAllowOverflowHelp,
              value: policy.allowWalletOverflow,
              enabled: canEdit,
              switchKey: const Key('allow_wallet_overflow_switch'),
              successMessage: l10n.childScreenTimeSaveToast,
              errorMessage: l10n.settingsPersistError,
              onPersist: onOverflowPersist,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.childScreenTimeWalletsHeading,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            for (final wallet in policy.wallets) ...[
              Semantics(
                label:
                    '${walletLabel(wallet.appId)} ${l10n.childScreenTimeWalletMinutes(wallet.earnedMinutes.inMinutes)}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            walletLabel(wallet.appId),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.ink,
                            ),
                          ),
                        ),
                        Text(
                          key: Key('wallet_minutes_${wallet.appId}'),
                          l10n.childScreenTimeWalletMinutes(
                            wallet.earnedMinutes.inMinutes,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.kind,
    required this.window,
    required this.label,
    required this.startLabel,
    required this.endLabel,
    required this.startText,
    required this.endText,
    required this.canEdit,
    required this.colors,
    required this.radii,
    required this.onToggle,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final ScheduleKind kind;
  final ScheduleWindow window;
  final String label;
  final String startLabel;
  final String endLabel;
  final String startText;
  final String endText;
  final bool canEdit;
  final FamilyColors colors;
  final FamilyRadii radii;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    final kindKey = kind.name;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                Semantics(
                  label: label,
                  toggled: window.enabled,
                  enabled: canEdit,
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Switch.adaptive(
                        key: Key('schedule_switch_$kindKey'),
                        value: window.enabled,
                        onChanged: canEdit ? onToggle : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (window.enabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimeChip(
                      key: Key('schedule_start_$kindKey'),
                      label: startLabel,
                      value: startText,
                      enabled: canEdit,
                      colors: colors,
                      radii: radii,
                      onTap: onPickStart,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeChip(
                      key: Key('schedule_end_$kindKey'),
                      label: endLabel,
                      value: endText,
                      enabled: canEdit,
                      colors: colors,
                      radii: radii,
                      onTap: onPickEnd,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.colors,
    required this.radii,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final FamilyColors colors;
  final FamilyRadii radii;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label $value',
      child: Material(
        color: colors.p50,
        borderRadius: BorderRadius.circular(radii.btn),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(radii.btn),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.ink2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
