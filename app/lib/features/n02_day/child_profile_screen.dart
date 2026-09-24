import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';

/// Widget keys for SCR-FAT-013 acceptance.
abstract final class ChildProfileKeys {
  static const screen = Key('child_profile_screen');
  static const loading = Key('child_profile_loading');
  static const missingId = Key('child_profile_missing_id');
  static const notFound = Key('child_profile_not_found');
  static const error = Key('child_profile_error');
  static const body = Key('child_profile_body');
  static const identityCard = Key('child_profile_identity');
  static const toolsGrid = Key('child_profile_tools');
  static const childLean = Key('child_profile_child_lean');
  static const deleteChild = Key('child_profile_delete_child');
  static const addDevice = Key('child_profile_add_device');
  static const maxDevicesBanner = Key('child_profile_max_devices_banner');
  static const remoteEndConfirm = Key('child_profile_remote_end_confirm');
  static const remoteEndConfirmCancel = Key(
    'child_profile_remote_end_confirm_cancel',
  );
  static const remoteEndConfirmAccept = Key(
    'child_profile_remote_end_confirm_accept',
  );
  static const primaryDeviceCard = Key('child_profile_primary_device_card');
  static const selectChild = Key('child_profile_select_child');
  static const selectChildEmpty = Key('child_profile_select_child_empty');

  static Key tool(String id) => Key('child_profile_tool_$id');
  static Key deviceCard(String id) => Key('child_profile_device_$id');
  static Key devicePrimaryToggle(String id) =>
      Key('child_profile_device_primary_$id');
  static Key enrollmentRow(String id) => Key('child_profile_enrollment_$id');
  static Key logoutToggle(String id) => Key('child_profile_logout_$id');
  static Key remoteEnd(String id) => Key('child_profile_remote_end_$id');
  static Key pairingEnroll(String id) =>
      Key('child_profile_pairing_enroll_$id');
  static Key showPairing(String id) => Key('child_profile_show_pairing_$id');
  static Key closeRevoke(String id) => Key('child_profile_close_revoke_$id');
  static Key closeLost(String id) => Key('child_profile_close_lost_$id');
  static Key closeDecommission(String id) =>
      Key('child_profile_close_decommission_$id');
  static Key reenroll(String id) => Key('child_profile_reenroll_$id');
  static Key selectChildRow(String id) => Key('child_profile_select_child_$id');
}

/// One per-child settings shortcut (real route — not a fake toggle).
@immutable
final class ChildProfileTool {
  const ChildProfileTool({
    required this.id,
    required this.emoji,
    required this.label,
    required this.routePath,
  });

  final String id;
  final String emoji;
  final String label;
  final String routePath;
}

/// SCR-FAT-013 — ملف الابن (parent child-profile hub).
///
/// Parametric [childId] (G-5 / G8). Mock-first Rule 23/25: empty/missing id →
/// honest empty; unknown id → not-found. Tool tiles navigate to existing
/// per-child settings routes (screen time, web filter, lock, …). No Firebase.
class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({
    super.key,
    this.childId,
    this.repository,
    this.managementRepository,
    this.roleOverride,
    this.onNavigateTool,
    this.onOpenLocation,
    this.onOpenDeviceHealth,
    this.onDeletedChild,
    this.onOpenPairing,
    this.onSelectChild,
  });

  /// From route `?childId=`; null/empty → child-selection state.
  final String? childId;

  /// Null → [stage1ChildProfileRepository].
  final ChildProfileRepository? repository;
  final ChildDeviceManagementRepository? managementRepository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Test seam — when null, [context.push] to tool [ChildProfileTool.routePath].
  final void Function(ChildProfileTool tool)? onNavigateTool;

  /// Test seam — location card → `/scr-fat-014`.
  final VoidCallback? onOpenLocation;

  /// Test seam — connection health → `/scr-fat-026`.
  final VoidCallback? onOpenDeviceHealth;
  final VoidCallback? onDeletedChild;

  /// Test seam — Add device / re-pair → FAT-004 (does not fake enrollment).
  final void Function({
    required String childId,
    String? deviceId,
    String? enrollmentId,
  })?
  onOpenPairing;

  /// Test seam — picker row without childId.
  final void Function(String childId)? onSelectChild;

  @override
  ChildProfileScreenState createState() => ChildProfileScreenState();
}

class ChildProfileScreenState extends State<ChildProfileScreen> {
  late final ChildProfileRepository _repo;
  late final ChildDeviceManagementRepository _managementRepo;
  var _loading = true;
  var _loadFailed = false;
  ChildProfile? _profile;
  bool _maxDevicesBlocked = false;

  AppRole get _role =>
      widget.roleOverride ??
      resolveAuthorizationContext(context, fallbackRole: AppRole.father).role;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  String? get _resolvedChildId {
    final raw = widget.childId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildProfileRepository;
    _managementRepo =
        widget.managementRepository ?? stage1ChildDeviceManagementRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant ChildProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  FamilyId? get _activeFamilyId =>
      CurrentIdentity.maybeOf(context)?.activeFamilyId;

  ChildManagementCapabilities _capabilities() {
    final familyId = _activeFamilyId;
    if (familyId == null) {
      return const ChildManagementCapabilities(
        canCreateChild: false,
        canDeleteChild: false,
        canManageDevices: false,
        canCloseNuclearEnrollment: false,
        canManageLogoutPermission: false,
        canEndChildSession: false,
        canChangePrimaryDevice: false,
      );
    }
    return _managementRepo.capabilitiesFor(familyId);
  }

  List<ManagedDeviceRecord> _devicesForCurrentChild() {
    final familyId = _activeFamilyId;
    final childId = _resolvedChildId;
    if (familyId == null || childId == null) return const [];
    return _managementRepo.listDevices(
      familyId: familyId,
      childId: ChildId(childId),
    );
  }

  Future<void> _load() async {
    final id = _resolvedChildId;
    if (id == null) {
      setState(() {
        _loading = false;
        _loadFailed = false;
        _profile = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final familyId = CurrentIdentity.maybeOf(context)?.activeFamilyId;
      final profile = await _repo.loadById(id, familyId: familyId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        _loadFailed = false;
        _maxDevicesBlocked = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _deleteChild() async {
    final familyId = _activeFamilyId;
    final childId = _resolvedChildId;
    if (familyId == null || childId == null) return;
    final l10n = AppLocalizations.of(context);
    final capabilities = _capabilities();
    if (!capabilities.canDeleteChild) {
      AppToast.show(context, message: l10n.childScreenTimeReadOnly);
      return;
    }
    final deleted = _managementRepo.deleteChild(
      familyId: familyId,
      childId: ChildId(childId),
    );
    if (!mounted) return;
    if (!deleted) {
      AppToast.show(context, message: l10n.settingsPersistError);
      return;
    }
    AppToast.show(context, message: l10n.childScreenTimeSaveToast);
    if (widget.onDeletedChild != null) {
      widget.onDeletedChild!();
      return;
    }
    context.pop();
  }

  Future<void> _addDevice() async {
    final familyId = _activeFamilyId;
    final childId = _resolvedChildId;
    if (familyId == null || childId == null) return;
    final l10n = AppLocalizations.of(context);
    final capabilities = _capabilities();
    if (!capabilities.canManageDevices) {
      AppToast.show(context, message: l10n.childScreenTimeReadOnly);
      return;
    }
    final activeCount = _devicesForCurrentChild()
        .expand((d) => d.enrollments)
        .where((e) => e.state == EnrollmentState.enrolled)
        .length;
    if (activeCount >= 3) {
      setState(() => _maxDevicesBlocked = true);
      return;
    }
    setState(() => _maxDevicesBlocked = false);
    _openPairing(childId: childId);
  }

  void _openPairing({
    required String childId,
    String? deviceId,
    String? enrollmentId,
  }) {
    if (widget.onOpenPairing != null) {
      widget.onOpenPairing!(
        childId: childId,
        deviceId: deviceId,
        enrollmentId: enrollmentId,
      );
      return;
    }
    final params = <String, String>{'childId': childId};
    if (deviceId != null && deviceId.isNotEmpty) {
      params['deviceId'] = deviceId;
    }
    if (enrollmentId != null && enrollmentId.isNotEmpty) {
      params['enrollmentId'] = enrollmentId;
    }
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    context.push('/scr-fat-004?$query');
  }

  void _selectChild(String childId) {
    if (widget.onSelectChild != null) {
      widget.onSelectChild!(childId);
      return;
    }
    context.go('/scr-fat-013?childId=${Uri.encodeComponent(childId)}');
  }

  List<ManagedChildRecord> _selectableChildren() {
    final familyId = _activeFamilyId;
    if (familyId == null) return const [];
    return _managementRepo.listChildren(familyId);
  }

  List<ChildProfileTool> _tools(AppLocalizations l10n) {
    return [
      ChildProfileTool(
        id: 'screen_time',
        emoji: '⏱',
        label: l10n.childProfileToolScreenTime,
        routePath: '/scr-fat-032',
      ),
      ChildProfileTool(
        id: 'time_requests',
        emoji: '⏳',
        label: l10n.childProfileToolTimeRequests,
        routePath: '/scr-fat-033',
      ),
      ChildProfileTool(
        id: 'web_filter',
        emoji: '🌐',
        label: l10n.childProfileToolWebFilter,
        routePath: '/scr-fat-036',
      ),
      ChildProfileTool(
        id: 'instant_lock',
        emoji: '🔒',
        label: l10n.childProfileToolInstantLock,
        routePath: '/scr-fat-037',
      ),
      ChildProfileTool(
        id: 'smart_supervision',
        emoji: '⚙️',
        label: l10n.childProfileToolSmartSupervision,
        routePath: '/scr-fat-067',
      ),
      ChildProfileTool(
        id: 'device_health',
        emoji: '📱',
        label: l10n.childProfileToolDeviceHealth,
        routePath: '/scr-fat-026',
      ),
    ];
  }

  void _goTool(ChildProfileTool tool) {
    if (widget.onNavigateTool != null) {
      widget.onNavigateTool!(tool);
      return;
    }
    final id = _resolvedChildId;
    final uri = id == null
        ? tool.routePath
        : '${tool.routePath}?childId=${Uri.encodeComponent(id)}';
    context.push(uri);
  }

  void _goLocation() {
    if (widget.onOpenLocation != null) {
      widget.onOpenLocation!();
      return;
    }
    final id = _resolvedChildId;
    final path = id == null
        ? '/scr-fat-014'
        : '/scr-fat-014?childId=${Uri.encodeComponent(id)}';
    context.push(path);
  }

  void _goDeviceHealth() {
    if (widget.onOpenDeviceHealth != null) {
      widget.onOpenDeviceHealth!();
      return;
    }
    final id = _resolvedChildId;
    final path = id == null
        ? '/scr-fat-026'
        : '/scr-fat-026?deviceId=${Uri.encodeComponent(id)}';
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final title = _profile?.displayName ?? l10n.childProfileTitle;

    return Scaffold(
      key: ChildProfileKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: !_isParent
          ? AppEmptyState(
              key: ChildProfileKeys.childLean,
              title: l10n.childProfileChildLeanTitle,
              message: l10n.childProfileChildLeanMessage,
            )
          : _resolvedChildId == null
          ? _ChildPickerBody(
              children: _selectableChildren(),
              onSelect: _selectChild,
              onAddChild: () => context.push('/scr-fat-003'),
            )
          : _loading
          ? Center(
              key: ChildProfileKeys.loading,
              child: Semantics(
                label: l10n.childProfileLoadingSemantics,
                child: const CircularProgressIndicator(),
              ),
            )
          : _loadFailed
          ? AppErrorState(
              key: ChildProfileKeys.error,
              kind: AppErrorKind.network,
              onRetry: _load,
            )
          : _profile == null
          ? AppEmptyState(
              key: ChildProfileKeys.notFound,
              title: l10n.childProfileNotFoundTitle,
              message: l10n.childProfileNotFoundMessage,
            )
          : _ProfileBody(
              profile: _profile!,
              tools: _tools(l10n),
              devices: _devicesForCurrentChild(),
              capabilities: _capabilities(),
              maxDevicesBlocked: _maxDevicesBlocked,
              onTool: _goTool,
              onOpenLocation: _goLocation,
              onOpenDeviceHealth: _goDeviceHealth,
              onDeleteChild: _deleteChild,
              onAddDevice: _addDevice,
              onSetPrimaryDevice: ({required DeviceId deviceId}) {
                final familyId = _activeFamilyId;
                final childId = _resolvedChildId;
                if (familyId == null || childId == null) return false;
                final ok = _managementRepo.setPrimaryDevice(
                  familyId: familyId,
                  childId: ChildId(childId),
                  deviceId: deviceId,
                );
                if (ok) setState(() {});
                return ok;
              },
              onCloseEnrollment:
                  ({
                    required EnrollmentId enrollmentId,
                    required EnrollmentCloseReason reason,
                  }) {
                    if (reason == EnrollmentCloseReason.revoked &&
                        GoRouter.maybeOf(context) != null) {
                      context.push(
                        '/sys3-revoke-confirm?kind=enrollment&id=${Uri.encodeComponent(enrollmentId.value)}',
                      );
                      return;
                    }
                    _managementRepo.closeEnrollment(
                      enrollmentId: enrollmentId,
                      reason: reason,
                    );
                    setState(() {});
                  },
              onShowPairing:
                  ({required EnrollmentId enrollmentId, String? deviceId}) {
                    final childId = _resolvedChildId;
                    if (childId == null) return;
                    _openPairing(
                      childId: childId,
                      deviceId: deviceId,
                      enrollmentId: enrollmentId.value,
                    );
                  },
              onReEnroll: ({required DeviceId deviceId}) {
                final childId = _resolvedChildId;
                if (childId == null) return;
                final activeCount = _devicesForCurrentChild()
                    .expand((d) => d.enrollments)
                    .where((e) => e.state == EnrollmentState.enrolled)
                    .length;
                if (activeCount >= 3) {
                  setState(() => _maxDevicesBlocked = true);
                  return;
                }
                setState(() => _maxDevicesBlocked = false);
                _openPairing(childId: childId, deviceId: deviceId.value);
              },
              onSetLogoutAllowed:
                  ({
                    required EnrollmentId enrollmentId,
                    required bool allowed,
                  }) {
                    final ok = _managementRepo.setChildLogoutPermission(
                      enrollmentId: enrollmentId,
                      allowed: allowed,
                    );
                    if (ok) setState(() {});
                    return ok;
                  },
              onRemoteEndSession: ({required EnrollmentId enrollmentId}) async {
                final childId = _resolvedChildId;
                if (GoRouter.maybeOf(context) != null) {
                  context.push(
                    '/sys3-remote-end?enrollmentId=${Uri.encodeComponent(enrollmentId.value)}'
                    '${childId == null ? '' : '&childId=${Uri.encodeComponent(childId)}'}',
                  );
                  return false;
                }
                final l10n = AppLocalizations.of(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    key: ChildProfileKeys.remoteEndConfirm,
                    title: Text(l10n.acceptMotherInviteDecline),
                    content: Text(l10n.childScreenTimeReadOnly),
                    actions: [
                      TextButton(
                        key: ChildProfileKeys.remoteEndConfirmCancel,
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.acceptMotherInviteDecline),
                      ),
                      TextButton(
                        key: ChildProfileKeys.remoteEndConfirmAccept,
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.acceptMotherInviteAccept),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return false;
                final ok = _managementRepo.remoteEndChildSession(enrollmentId);
                if (ok) setState(() {});
                return ok;
              },
            ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.tools,
    required this.devices,
    required this.capabilities,
    required this.maxDevicesBlocked,
    required this.onTool,
    required this.onOpenLocation,
    required this.onOpenDeviceHealth,
    required this.onDeleteChild,
    required this.onAddDevice,
    required this.onSetPrimaryDevice,
    required this.onCloseEnrollment,
    required this.onShowPairing,
    required this.onReEnroll,
    required this.onSetLogoutAllowed,
    required this.onRemoteEndSession,
  });

  final ChildProfile profile;
  final List<ChildProfileTool> tools;
  final List<ManagedDeviceRecord> devices;
  final ChildManagementCapabilities capabilities;
  final bool maxDevicesBlocked;
  final void Function(ChildProfileTool tool) onTool;
  final VoidCallback onOpenLocation;
  final VoidCallback onOpenDeviceHealth;
  final VoidCallback onDeleteChild;
  final VoidCallback onAddDevice;
  final bool Function({required DeviceId deviceId}) onSetPrimaryDevice;
  final void Function({
    required EnrollmentId enrollmentId,
    required EnrollmentCloseReason reason,
  })
  onCloseEnrollment;
  final void Function({required EnrollmentId enrollmentId, String? deviceId})
  onShowPairing;
  final void Function({required DeviceId deviceId}) onReEnroll;
  final bool Function({
    required EnrollmentId enrollmentId,
    required bool allowed,
  })
  onSetLogoutAllowed;
  final Future<bool> Function({required EnrollmentId enrollmentId})
  onRemoteEndSession;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;
    final ageText = l10n.addChildAgeYears(toEasternDigits(profile.ageYears));
    final statusLabel = switch (profile.health) {
      ChildListHealth.excellent => l10n.childProfileStatusOk,
      ChildListHealth.atRisk => l10n.childProfileStatusAtRisk,
    };
    final connectionLabel = switch (profile.health) {
      ChildListHealth.excellent => l10n.childrenListHealthExcellent,
      ChildListHealth.atRisk => l10n.childrenListHealthAtRisk,
    };
    final healthTag = switch (profile.health) {
      ChildListHealth.excellent => TagVariant.g,
      ChildListHealth.atRisk => TagVariant.a,
    };
    final identitySemantics = l10n.childProfileIdentitySemantics(
      profile.displayName,
      ageText,
      statusLabel,
    );

    return ListView(
      key: ChildProfileKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Semantics(
          container: true,
          label: identitySemantics,
          child: DecoratedBox(
            key: ChildProfileKeys.identityCard,
            decoration: BoxDecoration(
              gradient: gradients.grad,
              borderRadius: BorderRadius.circular(radii.card),
              boxShadow: [Theme.of(context).extension<FamilyShadows>()!.shCard],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _ProfileAvatar(
                        emoji: profile.emoji,
                        warnRing: profile.warnRing,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.childProfileNameAge(
                                profile.displayName,
                                ageText,
                              ),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          emoji: '🔋',
                          value: profile.batteryLabel,
                          label: l10n.childProfileMetricBattery,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MetricTile(
                          emoji: '📶',
                          value: connectionLabel,
                          label: l10n.childProfileMetricConnection,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MetricTile(
                          emoji: '📍',
                          value: profile.locationLabel,
                          label: l10n.childProfileMetricLocation,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MetricTile(
                          emoji: '⏱',
                          value: profile.walletLabel,
                          label: l10n.childProfileMetricWallet,
                        ),
                      ),
                    ],
                  ),
                  if (profile.todayUsedLabel.isNotEmpty &&
                      profile.todayCapLabel.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.childProfileTodayUsage(
                          profile.todayUsedLabel,
                          profile.todayCapLabel,
                        ),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          key: ChildProfileKeys.primaryDeviceCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.settingsHubRowLinkDevice,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  if (capabilities.canManageDevices)
                    TextButton(
                      key: ChildProfileKeys.addDevice,
                      onPressed: onAddDevice,
                      child: Text(l10n.childProfileAddDevice),
                    ),
                ],
              ),
              if (maxDevicesBlocked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    key: ChildProfileKeys.maxDevicesBanner,
                    l10n.childProfileMaxDevicesBlock,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.coral,
                    ),
                  ),
                ),
              if (devices.isEmpty)
                Text(
                  l10n.deviceHealthDeviceMissing,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                )
              else
                for (final device in devices)
                  _DeviceManagementCard(
                    device: device,
                    l10n: l10n,
                    colors: colors,
                    capabilities: capabilities,
                    onSetPrimary: () =>
                        onSetPrimaryDevice(deviceId: device.deviceId),
                    onCloseEnrollment: onCloseEnrollment,
                    onShowPairing: onShowPairing,
                    onReEnroll: () => onReEnroll(deviceId: device.deviceId),
                    onSetLogoutAllowed: onSetLogoutAllowed,
                    onRemoteEndSession: onRemoteEndSession,
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.childProfileToolsTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  Tag(
                    label: l10n.childProfileToolsBadge,
                    variant: TagVariant.t,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.childProfileToolsHint,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                container: true,
                label: l10n.childProfileToolsSemantics,
                child: GridView.count(
                  key: ChildProfileKeys.toolsGrid,
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.05,
                  children: [
                    for (final tool in tools)
                      _ToolTile(tool: tool, onTap: () => onTool(tool)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.childProfileLocationTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.childProfileDetailsLink,
                    child: InkWell(
                      onTap: onOpenLocation,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Text(
                          l10n.childProfileDetailsLink,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.p600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.childProfileLocationSummary(
                  profile.locationLabel,
                  profile.lastSeenLabel,
                  profile.batteryLabel,
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.childProfileConnectionTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  Tag(label: connectionLabel, variant: healthTag),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.childProfileConnectionBody(profile.lastHeartbeatLabel),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  button: true,
                  label: l10n.childProfileDeviceDetailsLink,
                  child: InkWell(
                    onTap: onOpenDeviceHealth,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Text(
                        l10n.childProfileDeviceDetailsLink,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colors.p600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (capabilities.canDeleteChild) ...[
                const SizedBox(height: 10),
                TextButton(
                  key: ChildProfileKeys.deleteChild,
                  onPressed: onDeleteChild,
                  child: Text(
                    l10n.acceptMotherInviteDecline,
                    style: TextStyle(
                      color: colors.coral,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        boxShadow: [Theme.of(context).extension<FamilyShadows>()!.shCard],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: child,
      ),
    );
  }
}

class _DeviceManagementCard extends StatelessWidget {
  const _DeviceManagementCard({
    required this.device,
    required this.l10n,
    required this.colors,
    required this.capabilities,
    required this.onSetPrimary,
    required this.onCloseEnrollment,
    required this.onShowPairing,
    required this.onReEnroll,
    required this.onSetLogoutAllowed,
    required this.onRemoteEndSession,
  });

  final ManagedDeviceRecord device;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final ChildManagementCapabilities capabilities;
  final VoidCallback onSetPrimary;
  final void Function({
    required EnrollmentId enrollmentId,
    required EnrollmentCloseReason reason,
  })
  onCloseEnrollment;
  final void Function({required EnrollmentId enrollmentId, String? deviceId})
  onShowPairing;
  final VoidCallback onReEnroll;
  final bool Function({
    required EnrollmentId enrollmentId,
    required bool allowed,
  })
  onSetLogoutAllowed;
  final Future<bool> Function({required EnrollmentId enrollmentId})
  onRemoteEndSession;

  String _stateLabel(EnrollmentState state) {
    return switch (state) {
      EnrollmentState.pairingPending => l10n.enrollmentStatePairingPending,
      EnrollmentState.enrolled => l10n.enrollmentStateEnrolled,
      EnrollmentState.revoked => l10n.enrollmentStateRevoked,
      EnrollmentState.lost => l10n.enrollmentStateLost,
      EnrollmentState.decommissioned => l10n.enrollmentStateDecommissioned,
      EnrollmentState.unenrolled => l10n.enrollmentStateUnenrolled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final active = device.activeEnrollment;
    final latest = device.enrollments.isNotEmpty
        ? device.enrollments.first
        : null;

    return Card(
      key: ChildProfileKeys.deviceCard(device.deviceId.value),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    device.deviceId.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ),
                if (device.primary)
                  Tag(label: l10n.familyMembersTagOwner, variant: TagVariant.g),
                if (!device.primary && capabilities.canChangePrimaryDevice)
                  TextButton(
                    key: ChildProfileKeys.devicePrimaryToggle(
                      device.deviceId.value,
                    ),
                    onPressed: onSetPrimary,
                    child: Text(l10n.acceptMotherInviteAccept),
                  ),
              ],
            ),
            if (active == null && capabilities.canManageDevices)
              TextButton(
                key: ChildProfileKeys.reenroll(device.deviceId.value),
                onPressed: onReEnroll,
                child: Text(l10n.linkQrRenew),
              ),
            for (final enrollment in device.enrollments) ...[
              Row(
                key: ChildProfileKeys.enrollmentRow(enrollment.id.value),
                children: [
                  Expanded(
                    child: Text(
                      '${enrollment.id.value} · ${_stateLabel(enrollment.state)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                  ),
                  if (enrollment.state == EnrollmentState.pairingPending)
                    TextButton(
                      key: ChildProfileKeys.showPairing(enrollment.id.value),
                      onPressed: () => onShowPairing(
                        enrollmentId: enrollment.id,
                        deviceId: device.deviceId.value,
                      ),
                      child: Text(l10n.enrollmentShowPairingCode),
                    ),
                ],
              ),
              if (enrollment.state == EnrollmentState.enrolled) ...[
                if (capabilities.canManageLogoutPermission)
                  SwitchListTile(
                    key: ChildProfileKeys.logoutToggle(enrollment.id.value),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.loginSubmit),
                    value: enrollment.childLogoutAllowed,
                    onChanged: (value) {
                      onSetLogoutAllowed(
                        enrollmentId: enrollment.id,
                        allowed: value,
                      );
                    },
                  ),
                if (capabilities.canEndChildSession)
                  TextButton(
                    key: ChildProfileKeys.remoteEnd(enrollment.id.value),
                    onPressed: () =>
                        onRemoteEndSession(enrollmentId: enrollment.id),
                    child: Text(l10n.acceptMotherInviteDecline),
                  ),
                if (capabilities.canCloseNuclearEnrollment)
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        key: ChildProfileKeys.closeRevoke(enrollment.id.value),
                        onPressed: () => onCloseEnrollment(
                          enrollmentId: enrollment.id,
                          reason: EnrollmentCloseReason.revoked,
                        ),
                        child: Text(l10n.enrollmentStateRevoked),
                      ),
                      TextButton(
                        key: ChildProfileKeys.closeLost(enrollment.id.value),
                        onPressed: () => onCloseEnrollment(
                          enrollmentId: enrollment.id,
                          reason: EnrollmentCloseReason.lost,
                        ),
                        child: Text(l10n.enrollmentStateLost),
                      ),
                      TextButton(
                        key: ChildProfileKeys.closeDecommission(
                          enrollment.id.value,
                        ),
                        onPressed: () => onCloseEnrollment(
                          enrollmentId: enrollment.id,
                          reason: EnrollmentCloseReason.decommissioned,
                        ),
                        child: Text(l10n.enrollmentStateDecommissioned),
                      ),
                    ],
                  ),
              ],
            ],
            if (active == null && latest != null)
              Text(
                l10n.deviceHealthOfflineLastKnown,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChildPickerBody extends StatelessWidget {
  const _ChildPickerBody({
    required this.children,
    required this.onSelect,
    required this.onAddChild,
  });

  final List<ManagedChildRecord> children;
  final void Function(String childId) onSelect;
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    if (children.isEmpty) {
      return AppEmptyState(
        key: ChildProfileKeys.selectChildEmpty,
        title: l10n.childProfileSelectChildTitle,
        message: l10n.childProfileSelectChildEmpty,
        actionLabel: l10n.childrenListAddChild,
        onAction: onAddChild,
      );
    }

    return ListView(
      key: ChildProfileKeys.selectChild,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          key: ChildProfileKeys.missingId,
          l10n.childProfileSelectChildTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.childProfileSelectChildMessage,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        for (final child in children)
          Semantics(
            button: true,
            label: l10n.childProfileSelectChildSemantics,
            child: ListTile(
              key: ChildProfileKeys.selectChildRow(child.childId.value),
              title: Text(child.childId.value),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => onSelect(child.childId.value),
            ),
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool, required this.onTap});

  final ChildProfileTool tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Semantics(
      button: true,
      label: tool.label,
      child: Material(
        color: colors.p50,
        borderRadius: BorderRadius.circular(radii.card),
        child: InkWell(
          key: ChildProfileKeys.tool(tool.id),
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.card),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tool.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  tool.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.emoji, required this.warnRing});

  final String emoji;
  final bool warnRing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final ring = warnRing ? colors.amber : Colors.white.withValues(alpha: 0.45);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
        color: Colors.white.withValues(alpha: 0.25),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
    );
  }
}
