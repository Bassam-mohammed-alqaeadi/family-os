import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';
import 'package:family_os/features/n12_devices/devices_ux_bridge.dart';

/// Widget keys for SCR-FAT-026 / UI-012 acceptance.
abstract final class DeviceHealthDetailKeys {
  static const screen = Key('device_health_detail_screen');
  static const body = Key('device_health_detail_body');
  static const healthCard = Key('device_health_detail_card');
  static const healthTag = Key('device_health_detail_tag');
  static const permissionsSection = Key('device_health_permissions');
  static const oemBanner = Key('device_health_oem_banner');
  static const oemGuide = Key('device_health_oem_guide');
  static const openSettingsNowCta = Key('device_health_open_settings_now');
  static const repairCta = Key('device_health_repair_cta');
  static const manageEnrollment = Key('device_health_detail_manage_enrollment');
  static const permanentBanner = Key('device_health_permanent_banner');
  static const offlineBanner = Key('device_health_offline_banner');
  static const sosCta = Key('device_health_detail_sos');
  static const childLean = Key('device_health_detail_child_lean');
  static Key permissionRow(DevicePermissionKind kind) =>
      Key('device_health_perm_${kind.name}');
}

/// SCR-FAT-026 — تفصيل الجهاز · أذونات + إصلاح + دليل المصنّع (UI-012).
///
/// Deny → repair / open-settings → simulated OS settings → [recheck] →
/// stream turns card green without app reinstall (AC1–AC2). Mother OK;
/// child lean; P-4 SOS ungated.
class DeviceHealthDetailScreen extends StatefulWidget {
  const DeviceHealthDetailScreen({
    super.key,
    this.deviceId,
    this.healthSeam,
    this.roleOverride,
    this.sosFire,
    this.onSos,
    this.onOpenSettingsToast = true,
  });

  /// From route `?deviceId=`; falls back to first seam device.
  final String? deviceId;

  /// Injectable — null → [stage1DeviceHealthSeam].
  final DeviceHealthSeam? healthSeam;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  final VoidCallback? onSos;

  /// Demo honesty toast when settings deep-link fires.
  final bool onOpenSettingsToast;

  /// Route helper for [gen_routes] / GoRouter.
  static DeviceHealthDetailScreen fromRoute(
    String? deviceId, {
    DeviceHealthSeam? healthSeam,
  }) {
    return DeviceHealthDetailScreen(deviceId: deviceId, healthSeam: healthSeam);
  }

  @override
  State<DeviceHealthDetailScreen> createState() =>
      _DeviceHealthDetailScreenState();
}

class _DeviceHealthDetailScreenState extends State<DeviceHealthDetailScreen> {
  DeviceHealthSeam? _seam;
  StreamSubscription<DeviceHealthSnapshot?>? _sub;
  DeviceHealthSnapshot? _snap;
  var _loading = true;
  var _sosBusy = false;
  String? _resolvedId;
  String? _familyId;
  var _bootstrapped = false;

  AppRole get _role =>
      widget.roleOverride ??
      resolveAuthorizationContext(context, fallbackRole: AppRole.father).role;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _familyId =
        CurrentIdentity.maybeOf(context)?.activeFamilyId.value ?? 'fam_stage1';
    if (_bootstrapped) return;
    _bootstrapped = true;
    _bootstrap();
  }

  /// DEV-1 — the real devices seam unless a test injects one.
  Future<void> _bootstrap() async {
    var seam = widget.healthSeam;
    if (seam == null) {
      await Stage1DevicesRuntime.ensureOpen();
      if (!mounted) return;
    }
    seam ??= Stage1DevicesRuntime.seam;
    _seam = seam;
    final id = widget.deviceId;
    if (id != null && id.isNotEmpty) {
      _resolvedId = id;
      _listen(id);
      return;
    }
    final first = await seam.watchDevices(familyId: _familyId).first;
    if (!mounted) return;
    _resolvedId = first.isEmpty ? null : first.first.deviceId;
    final resolved = _resolvedId;
    if (resolved == null) {
      setState(() => _loading = false);
      return;
    }
    _listen(resolved);
  }

  void _listen(String deviceId) {
    _sub?.cancel();
    _sub = _seam!.watchDevice(deviceId, familyId: _familyId).listen((snap) {
      if (!mounted) return;
      setState(() {
        _snap = snap;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    final fire = widget.sosFire ?? stage1SosFireService;
    final childTarget = _snap?.childId ?? 'family';
    await fire.fire(childId: childTarget);
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push('/scr-fat-018');
  }

  String _permissionLabel(AppLocalizations l10n, DevicePermissionKind kind) {
    return switch (kind) {
      DevicePermissionKind.locationAlways => l10n.deviceHealthPermLocation,
      DevicePermissionKind.accessibility => l10n.deviceHealthPermAccessibility,
      DevicePermissionKind.batteryExemption => l10n.deviceHealthPermBattery,
      DevicePermissionKind.autoStart => l10n.deviceHealthPermAutoStart,
    };
  }

  (String, TagVariant) _statusTag(
    AppLocalizations l10n,
    DevicePermissionStatus status,
  ) {
    return switch (status) {
      DevicePermissionStatus.granted => (
        l10n.deviceHealthPermGranted,
        TagVariant.g,
      ),
      DevicePermissionStatus.denied => (
        l10n.deviceHealthPermDenied,
        TagVariant.a,
      ),
      DevicePermissionStatus.permanentlyDenied => (
        l10n.deviceHealthPermOsBlocked,
        TagVariant.a,
      ),
    };
  }

  Future<void> _openOsSettings({required bool fromGuide}) async {
    final snap = _snap;
    final deviceId = _resolvedId;
    if (snap == null || deviceId == null) return;
    final kind = snap.firstRepairableKind;
    if (kind == null) return;

    final l10n = AppLocalizations.of(context);
    await _seam!.openSettings(deviceId: deviceId, kind: kind);
    if (widget.onOpenSettingsToast && mounted) {
      AppToast.show(
        context,
        message: fromGuide
            ? l10n.deviceHealthOpenSettingsNowToast
            : l10n.deviceHealthRepairRequestToast,
      );
    }
    await _seam!.recheck(deviceId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final snap = _snap;

    return Scaffold(
      key: DeviceHealthDetailKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          snap?.displayLabel ?? l10n.deviceHealthDetailTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: DeviceHealthDetailKeys.sosCta,
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
    if (!_isParent) {
      return AppEmptyState(
        key: DeviceHealthDetailKeys.childLean,
        title: l10n.deviceHealthChildLeanTitle,
        message: l10n.deviceHealthChildLeanMessage,
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final snap = _snap;
    if (snap == null) {
      return Center(
        child: Text(
          l10n.deviceHealthDeviceMissing,
          style: TextStyle(fontWeight: FontWeight.w700, color: colors.ink2),
        ),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final oem = snap.oemFamily;
    final showOemGuide = snap.hasRepairableDeny;

    return SingleChildScrollView(
      key: DeviceHealthDetailKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HealthHeader(snapshot: snap),
          if (snap.offline) ...[
            const SizedBox(height: 12),
            BannerNote(
              key: DeviceHealthDetailKeys.offlineBanner,
              message: l10n.deviceHealthOfflineLastKnown,
              variant: BannerVariant.t,
            ),
          ],
          if (oem != null && oem.isNotEmpty && showOemGuide) ...[
            const SizedBox(height: 12),
            BannerNote(
              key: DeviceHealthDetailKeys.oemBanner,
              message: l10n.deviceHealthOemBanner(oem),
              variant: BannerVariant.a,
            ),
          ],
          if (snap.permissions.any(
            (p) => p.status == DevicePermissionStatus.permanentlyDenied,
          )) ...[
            const SizedBox(height: 12),
            BannerNote(
              key: DeviceHealthDetailKeys.permanentBanner,
              message: l10n.deviceHealthPermanentExplain,
              variant: BannerVariant.a,
            ),
          ],
          if (showOemGuide) ...[
            const SizedBox(height: 14),
            DecoratedBox(
              key: DeviceHealthDetailKeys.oemGuide,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.deviceHealthGuideHeading,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _GuideStep(index: 1, label: l10n.deviceHealthGuideStep1),
                    _GuideStep(index: 2, label: l10n.deviceHealthGuideStep2),
                    _GuideStep(index: 3, label: l10n.deviceHealthGuideStep3),
                    const SizedBox(height: 12),
                    PrimaryBtn(
                      key: DeviceHealthDetailKeys.openSettingsNowCta,
                      label: l10n.deviceHealthOpenSettingsNowCta,
                      onPressed: () => _openOsSettings(fromGuide: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          DecoratedBox(
            key: DeviceHealthDetailKeys.permissionsSection,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.deviceHealthPermissionsHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final row in snap.permissions) ...[
                    _PermissionTile(
                      label: _permissionLabel(l10n, row.kind),
                      statusLabel: _statusTag(l10n, row.status).$1,
                      statusVariant: _statusTag(l10n, row.status).$2,
                      kind: row.kind,
                      osBlockedHint:
                          row.status == DevicePermissionStatus.permanentlyDenied
                          ? l10n.deviceHealthOsBlockedHint
                          : null,
                    ),
                  ],
                  if (snap.hasRepairableDeny) ...[
                    const SizedBox(height: 12),
                    PrimaryBtn(
                      key: DeviceHealthDetailKeys.repairCta,
                      label: l10n.deviceHealthRepairCta,
                      variant: PrimaryBtnVariant.sec,
                      onPressed: () => _openOsSettings(fromGuide: false),
                    ),
                  ],
                  if (snap.childId.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    PrimaryBtn(
                      key: DeviceHealthDetailKeys.manageEnrollment,
                      label: l10n.deviceHealthManageEnrollment,
                      variant: PrimaryBtnVariant.ghost,
                      onPressed: () {
                        context.push(
                          '/scr-fat-013?childId=${Uri.encodeComponent(snap.childId)}',
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.p600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthHeader extends StatelessWidget {
  const _HealthHeader({required this.snapshot});

  final DeviceHealthSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    final (tagLabel, tagVariant) = switch (snapshot.level) {
      DeviceHealthLevel.healthy => (
        l10n.deviceHealthStatusHealthy,
        TagVariant.g,
      ),
      DeviceHealthLevel.atRisk => (l10n.deviceHealthStatusAtRisk, TagVariant.a),
      DeviceHealthLevel.offline => (
        l10n.deviceHealthStatusOffline,
        TagVariant.t,
      ),
    };

    final meta = <String>[
      if (snapshot.lastHeartbeatAgoLabel != null)
        l10n.deviceHealthLastBeat(snapshot.lastHeartbeatAgoLabel!),
      if (snapshot.batteryPercent != null)
        l10n.deviceHealthBattery(snapshot.batteryPercent!),
    ].join(' · ');

    return DecoratedBox(
      key: DeviceHealthDetailKeys.healthCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        child: Column(
          children: [
            Icon(Icons.phone_android, size: 36, color: colors.ink2),
            const SizedBox(height: 8),
            Text(
              snapshot.modelLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Tag(
              key: DeviceHealthDetailKeys.healthTag,
              label: tagLabel,
              variant: tagVariant,
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                meta,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.label,
    required this.statusLabel,
    required this.statusVariant,
    required this.kind,
    this.osBlockedHint,
  });

  final String label;
  final String statusLabel;
  final TagVariant statusVariant;
  final DevicePermissionKind kind;
  final String? osBlockedHint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Padding(
      key: DeviceHealthDetailKeys.permissionRow(kind),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                if (osBlockedHint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    osBlockedHint!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tag(label: statusLabel, variant: statusVariant),
        ],
      ),
    );
  }
}
