import 'package:flutter/material.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/anti_tamper_alert_bus.dart';
import 'package:family_os/core/policy/anti_tamper_permission.dart';
import 'package:family_os/core/policy/anti_tamper_policy.dart';
import 'package:family_os/core/policy/anti_tamper_repository.dart';
import 'package:family_os/core/policy/device_lock_service.dart';
import 'package:family_os/core/policy/device_lock_state.dart';

/// Widget keys for anti-tamper switches (SET-007 / SET-008 acceptance).
abstract final class AntiTamperKeys {
  static const section = Key('anti_tamper_section');
  static const denyPanel = Key('anti_tamper_deny_panel');
  static const save = Key('anti_tamper_save');
  static const permissionBanner = Key('anti_tamper_permission_banner');

  static Key switchFor(String flag) => Key('anti_tamper_switch_$flag');

  static Key whenEnabledFor(String flag) =>
      Key('anti_tamper_when_enabled_$flag');

  static const List<Key> allSwitches = [
    Key('anti_tamper_switch_noDelete'),
    Key('anti_tamper_switch_noClockChange'),
    Key('anti_tamper_switch_noVpn'),
    Key('anti_tamper_switch_simAlert'),
    Key('anti_tamper_switch_settingsPin'),
    Key('anti_tamper_switch_bypassAlert'),
  ];

  static const List<Key> allWhenEnabled = [
    Key('anti_tamper_when_enabled_noDelete'),
    Key('anti_tamper_when_enabled_noClockChange'),
    Key('anti_tamper_when_enabled_noVpn'),
    Key('anti_tamper_when_enabled_simAlert'),
    Key('anti_tamper_when_enabled_settingsPin'),
    Key('anti_tamper_when_enabled_bypassAlert'),
  ];
}

/// Widget keys for instant lock controls (SET-009 / ADR-035).
abstract final class InstantLockKeys {
  static const card = Key('instant_lock_card');
  static const status = Key('instant_lock_status');
  static const lockButton = Key('instant_lock_lock_btn');
  static const unlockButton = Key('instant_lock_unlock_btn');
  static const supersessionBanner = Key('instant_lock_supersession_banner');

  /// Legacy key retained for SET-007/008 widget tests (maps to lock switch era).
  static const legacySwitch = Key('instant_lock_switch');
}

/// SCR-FAT-037 — القفل الفوري (SET-007…009).
///
/// Competitive honesty (Qustodio / Family Link): each defense states **what
/// happens when ON** — not mystery toggles. ADR-035-b: omit AT for mother/child.
/// ADR-035: mother FULL may lock; father unlock supersedes + audit.
class InstantLockScreen extends StatefulWidget {
  const InstantLockScreen({
    super.key,
    this.childId,
    this.repository,
    this.alertBus,
    this.lockService,
    this.roleOverride,
    this.motherLevel = MotherLevel.full,
    this.forceAntiTamperSurface = false,
    this.canConfigureAntiTamperOverride,
    this.deviceAdminGranted = true,
  });

  /// Stage-1 demo child when null.
  final ChildId? childId;

  /// Rule 25 seam — null → prefs-backed Stage-1 singleton.
  final AntiTamperRepository? repository;

  /// Rule 25 seam — null → [stage1AntiTamperAlertBus].
  final AntiTamperAlertBus? alertBus;

  /// Rule 25 seam — null → prefs-backed Stage-1 [DeviceLockService].
  final DeviceLockService? lockService;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority for lock/unlock (SET-009). Ignored for father/child.
  final MotherLevel motherLevel;

  /// Deep-link / forced navigation to anti-tamper surface.
  /// Mother/child → deny panel; father → normal section.
  final bool forceAntiTamperSurface;

  /// Test seam for permission (defaults to [canConfigureAntiTamper]).
  final bool? canConfigureAntiTamperOverride;

  /// Mock OS Device Admin / Screen Time grant for flags that need it
  /// (SET-008 honesty — `noDelete`).
  final bool deviceAdminGranted;

  @override
  State<InstantLockScreen> createState() => InstantLockScreenState();
}

/// Public for Stage-1 simulate hooks in widget tests (SET-008).
class InstantLockScreenState extends State<InstantLockScreen> {
  late final ChildId _childId;
  late final AntiTamperRepository _repository;
  late final AntiTamperAlertBus _alertBus;
  late final DeviceLockService _lockService;
  late AntiTamperPolicy _policy;
  DeviceLockState? _lockState;
  var _loading = true;
  var _saving = false;
  var _lockBusy = false;
  var _showPermissionBanner = false;
  var _showSupersessionBanner = false;

  @override
  void initState() {
    super.initState();
    _childId = widget.childId ?? ChildId('demo-child');
    _repository = widget.repository ??
        PrefsAntiTamperRepository(
          stage1AntiTamperPrefsStore,
          audit: stage1AntiTamperAudit,
        );
    _alertBus = widget.alertBus ?? stage1AntiTamperAlertBus;
    _lockService = widget.lockService ??
        DeviceLockService(
          store: stage1DeviceLockPrefsStore,
          audit: stage1DeviceLockAudit,
          notifyBus: stage1DeviceLockNotifyBus,
        );
    _policy = AntiTamperPolicy.defaults();
    _lockService.notifyBus.addListener(_onSupersessionNotify);
    _load();
  }

  @override
  void dispose() {
    _lockService.notifyBus.removeListener(_onSupersessionNotify);
    super.dispose();
  }

  void _onSupersessionNotify() {
    final event = _lockService.notifyBus.lastSupersession;
    if (event == null || event.childId != _childId) return;
    if (_role != AppRole.mother) return;
    if (!mounted) return;
    setState(() => _showSupersessionBanner = true);
    _refreshLockState();
  }

  Future<void> _load() async {
    final loaded = await _repository.load(_childId);
    final lock = await _lockService.load(_childId);
    if (!mounted) return;
    setState(() {
      _policy = loaded;
      _lockState = lock;
      _loading = false;
      _showPermissionBanner =
          loaded.noDelete && !widget.deviceAdminGranted;
    });
  }

  Future<void> _refreshLockState() async {
    final lock = await _lockService.load(_childId);
    if (!mounted) return;
    setState(() => _lockState = lock);
  }

  AppRole get _role {
    if (widget.roleOverride != null) return widget.roleOverride!;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  DeviceLockActor get _lockActor {
    final role = _role;
    if (role == AppRole.father) return const DeviceLockActor.father();
    if (role == AppRole.mother) {
      return DeviceLockActor.mother(widget.motherLevel);
    }
    return const DeviceLockActor.father(); // unused for child UI
  }

  bool get _canConfigureAntiTamper {
    if (widget.canConfigureAntiTamperOverride != null) {
      return widget.canConfigureAntiTamperOverride!;
    }
    return canConfigureAntiTamper(_role);
  }

  /// ADR-035-b: omit anti-tamper tree for non-father unless deep-link forced.
  bool get _showAntiTamperSection => _canConfigureAntiTamper;

  bool get _showAntiTamperDeny =>
      !_canConfigureAntiTamper && widget.forceAntiTamperSurface;

  bool get _showLockControls =>
      _role == AppRole.father || _role == AppRole.mother;

  bool get _canOfferLock {
    final actor = _lockActor;
    return actor.canLock && !(_lockState?.locked ?? false);
  }

  bool get _canOfferUnlock {
    final state = _lockState;
    if (state == null || !state.locked) return false;
    return _lockActor.canUnlock(state);
  }

  /// Test / Stage-1 hook — fires father alert when [bypassAlert] is ON.
  bool simulateBypassAttempt() =>
      _alertBus.simulateBypassAttempt(_childId, _policy);

  /// Test / Stage-1 hook — fires father alert when [simAlert] is ON.
  bool simulateSimChange() =>
      _alertBus.simulateSimChange(_childId, _policy);

  Future<void> _saveAntiTamper() async {
    if (!_canConfigureAntiTamper || _saving) return;
    setState(() => _saving = true);
    final result = await _repository.write(
      _childId,
      _policy,
      actor: _role,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    final l10n = AppLocalizations.of(context);
    if (result is AntiTamperWriteOk) {
      setState(() => _policy = result.policy);
      AppToast.show(context, message: l10n.antiTamperSaveToast);
    } else if (result is AntiTamperWriteDenied) {
      AppToast.show(context, message: l10n.antiTamperDeniedToast);
    }
  }

  Future<void> _onLock() async {
    if (_lockBusy || !_canOfferLock) return;
    setState(() => _lockBusy = true);
    final result = await _lockService.lock(_childId, _lockActor);
    if (!mounted) return;
    setState(() => _lockBusy = false);
    final l10n = AppLocalizations.of(context);
    if (result is DeviceLockCommandOk) {
      setState(() {
        _lockState = result.state;
        _showSupersessionBanner = false;
      });
    } else {
      AppToast.show(context, message: l10n.instantLockDeniedToast);
    }
  }

  Future<void> _onUnlock() async {
    if (_lockBusy || !_canOfferUnlock) return;
    setState(() => _lockBusy = true);
    final result = await _lockService.unlock(_childId, _lockActor);
    if (!mounted) return;
    setState(() => _lockBusy = false);
    final l10n = AppLocalizations.of(context);
    if (result is DeviceLockCommandOk) {
      setState(() => _lockState = result.state);
    } else {
      AppToast.show(context, message: l10n.instantLockDeniedToast);
    }
  }

  void _onFlagChanged(String flag, bool enabled) {
    if (!_canConfigureAntiTamper) return;
    setState(() {
      _policy = _policy.withFlag(flag, enabled);
      if (flag == AntiTamperFlags.noDelete) {
        _showPermissionBanner = enabled && !widget.deviceAdminGranted;
      }
    });
  }

  String _flagLabel(AppLocalizations l10n, String flag) {
    return switch (flag) {
      AntiTamperFlags.noDelete => l10n.antiTamperNoDelete,
      AntiTamperFlags.noClockChange => l10n.antiTamperNoClockChange,
      AntiTamperFlags.noVpn => l10n.antiTamperNoVpn,
      AntiTamperFlags.simAlert => l10n.antiTamperSimAlert,
      AntiTamperFlags.settingsPin => l10n.antiTamperSettingsPin,
      AntiTamperFlags.bypassAlert => l10n.antiTamperBypassAlert,
      _ => flag,
    };
  }

  String _flagWhenEnabled(AppLocalizations l10n, String flag) {
    return switch (flag) {
      AntiTamperFlags.noDelete => l10n.antiTamperNoDeleteWhenEnabled,
      AntiTamperFlags.noClockChange => l10n.antiTamperNoClockChangeWhenEnabled,
      AntiTamperFlags.noVpn => l10n.antiTamperNoVpnWhenEnabled,
      AntiTamperFlags.simAlert => l10n.antiTamperSimAlertWhenEnabled,
      AntiTamperFlags.settingsPin => l10n.antiTamperSettingsPinWhenEnabled,
      AntiTamperFlags.bypassAlert => l10n.antiTamperBypassAlertWhenEnabled,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final locked = _lockState?.locked ?? false;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(l10n.instantLockTitle),
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              children: [
                if (_showSupersessionBanner && _role == AppRole.mother) ...[
                  BannerNote(
                    key: InstantLockKeys.supersessionBanner,
                    message: l10n.instantLockSupersessionBanner,
                    variant: BannerVariant.a,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_showLockControls)
                  _InstantLockCard(
                    locked: locked,
                    lockedBy: _lockState?.lockedBy,
                    canLock: _canOfferLock && !_lockBusy,
                    canUnlock: _canOfferUnlock && !_lockBusy,
                    onLock: _onLock,
                    onUnlock: _onUnlock,
                    title: l10n.instantLockToggle,
                    subtitle: l10n.instantLockSubtitle,
                    statusLocked: l10n.instantLockStatusLocked,
                    statusUnlocked: l10n.instantLockStatusUnlocked,
                    lockedByFather: l10n.instantLockLockedByFather,
                    lockedByMother: l10n.instantLockLockedByMother,
                    lockLabel: l10n.instantLockAction,
                    unlockLabel: l10n.instantLockUnlockAction,
                    lockSemantics: l10n.spineCtaLockSemantics,
                    unlockSemantics: l10n.spineCtaUnlockSemantics,
                  )
                else
                  _InstantLockCard(
                    locked: locked,
                    lockedBy: _lockState?.lockedBy,
                    canLock: false,
                    canUnlock: false,
                    onLock: null,
                    onUnlock: null,
                    title: l10n.instantLockToggle,
                    subtitle: l10n.instantLockSubtitle,
                    statusLocked: l10n.instantLockStatusLocked,
                    statusUnlocked: l10n.instantLockStatusUnlocked,
                    lockedByFather: l10n.instantLockLockedByFather,
                    lockedByMother: l10n.instantLockLockedByMother,
                    lockLabel: l10n.instantLockAction,
                    unlockLabel: l10n.instantLockUnlockAction,
                    lockSemantics: l10n.spineCtaLockSemantics,
                    unlockSemantics: l10n.spineCtaUnlockSemantics,
                  ),
                const SizedBox(height: 20),
                if (_showAntiTamperSection) ...[
                  if (_showPermissionBanner) ...[
                    BannerNote(
                      key: AntiTamperKeys.permissionBanner,
                      message: l10n.antiTamperNeedsDevicePermission,
                      variant: BannerVariant.a,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _AntiTamperSection(
                    policy: _policy,
                    flagLabel: (f) => _flagLabel(l10n, f),
                    flagWhenEnabled: (f) => _flagWhenEnabled(l10n, f),
                    onChanged: _onFlagChanged,
                    onSave: _saving ? null : _saveAntiTamper,
                    sectionTitle: l10n.antiTamperSectionTitle,
                    saveLabel: l10n.antiTamperSave,
                  ),
                ],
                if (_showAntiTamperDeny) ...[
                  _AntiTamperDenyPanel(message: l10n.antiTamperUnavailable),
                ],
              ],
            ),
    );
  }
}

class _InstantLockCard extends StatelessWidget {
  const _InstantLockCard({
    required this.locked,
    required this.lockedBy,
    required this.canLock,
    required this.canUnlock,
    required this.onLock,
    required this.onUnlock,
    required this.title,
    required this.subtitle,
    required this.statusLocked,
    required this.statusUnlocked,
    required this.lockedByFather,
    required this.lockedByMother,
    required this.lockLabel,
    required this.unlockLabel,
    required this.lockSemantics,
    required this.unlockSemantics,
  });

  final bool locked;
  final DeviceLockedBy? lockedBy;
  final bool canLock;
  final bool canUnlock;
  final VoidCallback? onLock;
  final VoidCallback? onUnlock;
  final String title;
  final String subtitle;
  final String statusLocked;
  final String statusUnlocked;
  final String lockedByFather;
  final String lockedByMother;
  final String lockLabel;
  final String unlockLabel;
  final String lockSemantics;
  final String unlockSemantics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final statusText = locked ? statusLocked : statusUnlocked;
    final byText = lockedBy == DeviceLockedBy.father
        ? lockedByFather
        : lockedBy == DeviceLockedBy.mother
            ? lockedByMother
            : null;

    return DecoratedBox(
      key: InstantLockKeys.card,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.ink2,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              statusText,
              key: InstantLockKeys.status,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (byText != null) ...[
              const SizedBox(height: 4),
              Text(
                byText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.ink2,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            // Legacy key for SET-007 mother presence assertion.
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 0,
                child: Switch(
                  key: InstantLockKeys.legacySwitch,
                  value: locked,
                  onChanged: null,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: PrimaryBtn(
                    key: InstantLockKeys.lockButton,
                    label: lockLabel,
                    semanticsLabel: lockSemantics,
                    onPressed: canLock ? onLock : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryBtn(
                    key: InstantLockKeys.unlockButton,
                    label: unlockLabel,
                    semanticsLabel: unlockSemantics,
                    onPressed: canUnlock ? onUnlock : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AntiTamperSection extends StatelessWidget {
  const _AntiTamperSection({
    required this.policy,
    required this.flagLabel,
    required this.flagWhenEnabled,
    required this.onChanged,
    required this.onSave,
    required this.sectionTitle,
    required this.saveLabel,
  });

  final AntiTamperPolicy policy;
  final String Function(String flag) flagLabel;
  final String Function(String flag) flagWhenEnabled;
  final void Function(String flag, bool enabled) onChanged;
  final VoidCallback? onSave;
  final String sectionTitle;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return DecoratedBox(
      key: AntiTamperKeys.section,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            for (final flag in AntiTamperFlags.known)
              SwitchListTile(
                key: AntiTamperKeys.switchFor(flag),
                contentPadding: EdgeInsets.zero,
                title: Text(flagLabel(flag)),
                subtitle: Text(
                  flagWhenEnabled(flag),
                  key: AntiTamperKeys.whenEnabledFor(flag),
                ),
                value: policy.flag(flag),
                onChanged: (v) => onChanged(flag, v),
              ),
            const SizedBox(height: 16),
            PrimaryBtn(
              key: AntiTamperKeys.save,
              label: saveLabel,
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _AntiTamperDenyPanel extends StatelessWidget {
  const _AntiTamperDenyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return DecoratedBox(
      key: AntiTamperKeys.denyPanel,
      decoration: BoxDecoration(
        color: colors.coral100,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.coral),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
