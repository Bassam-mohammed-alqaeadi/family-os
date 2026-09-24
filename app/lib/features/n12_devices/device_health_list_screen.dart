import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';
import 'package:family_os/features/n12_devices/devices_ux_bridge.dart';

/// Widget keys for SCR-FAT-025 devices section / UI-012 acceptance.
abstract final class DeviceHealthListKeys {
  static const screen = Key('device_health_list_screen');
  static const devicesSection = Key('device_health_devices_section');
  static const manageEnrollment = Key('device_health_manage_enrollment');
  static Key deviceCard(String deviceId) => Key('device_health_card_$deviceId');
  static Key healthTag(String deviceId) => Key('device_health_tag_$deviceId');
  static Key manageEnrollmentFor(String childId) =>
      Key('device_health_manage_enrollment_$childId');
}

/// Devices health panel embedded on SCR-FAT-025 settings hub (UI-012).
///
/// Binds [DeviceHealthSeam.watchDevices] so a repair round-trip on FAT-026
/// updates cards green without relaunch. Not a standalone route — F-08 /
/// prototype place the list inside الإعدادات.
class DeviceHealthDevicesSection extends StatefulWidget {
  const DeviceHealthDevicesSection({
    super.key,
    this.healthSeam,
    this.onOpenDevice,
    this.onManageEnrollment,
  });

  /// Injectable — null → [stage1DeviceHealthSeam].
  final DeviceHealthSeam? healthSeam;

  /// Test / host seam — default pushes `/scr-fat-026?deviceId=…`.
  final void Function(String deviceId)? onOpenDevice;

  /// Opens child profile enrollment authority (not health controls).
  final void Function(String childId)? onManageEnrollment;

  @override
  State<DeviceHealthDevicesSection> createState() =>
      _DeviceHealthDevicesSectionState();
}

class _DeviceHealthDevicesSectionState
    extends State<DeviceHealthDevicesSection> {
  StreamSubscription<List<DeviceHealthSnapshot>>? _sub;
  String? _subscribedFamilyId;
  List<DeviceHealthSnapshot> _devices = const [];
  var _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId =
        CurrentIdentity.maybeOf(context)?.activeFamilyId.value ?? 'fam_stage1';
    if (_subscribedFamilyId == familyId && _sub != null) return;
    _subscribedFamilyId = familyId;
    _bind(familyId);
  }

  /// DEV-1 — binds the real devices seam unless a test injects one.
  Future<void> _bind(String familyId) async {
    var seam = widget.healthSeam;
    if (seam == null) {
      await Stage1DevicesRuntime.ensureOpen();
      if (!mounted) return;
      seam = Stage1DevicesRuntime.seam;
    }
    _sub?.cancel();
    _sub = seam.watchDevices(familyId: familyId).listen((list) {
      if (!mounted) return;
      setState(() {
        _devices = list;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _openDetail(String deviceId) {
    if (widget.onOpenDevice != null) {
      widget.onOpenDevice!(deviceId);
      return;
    }
    context.push('/scr-fat-026?deviceId=${Uri.encodeComponent(deviceId)}');
  }

  void _openEnrollment(String childId) {
    if (widget.onManageEnrollment != null) {
      widget.onManageEnrollment!(childId);
      return;
    }
    context.push('/scr-fat-013?childId=${Uri.encodeComponent(childId)}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final childIds = <String>{
      for (final d in _devices)
        if (d.childId.trim().isNotEmpty) d.childId,
    }.toList(growable: false);

    return DecoratedBox(
      key: DeviceHealthListKeys.devicesSection,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.deviceHealthDevicesHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                if (_devices.any((d) => d.level != DeviceHealthLevel.healthy))
                  Tag(
                    label: l10n.deviceHealthSectionAtRiskHint,
                    variant: TagVariant.a,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.deviceHealthDevicesSubtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            for (final d in _devices) ...[
              _DeviceHealthCard(
                snapshot: d,
                onTap: () => _openDetail(d.deviceId),
              ),
            ],
            if (childIds.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                key: DeviceHealthListKeys.manageEnrollment,
                l10n.deviceHealthManageEnrollmentSub,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                  height: 1.4,
                ),
              ),
              for (final childId in childIds)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    key: DeviceHealthListKeys.manageEnrollmentFor(childId),
                    onPressed: () => _openEnrollment(childId),
                    child: Text(l10n.deviceHealthManageEnrollment),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeviceHealthCard extends StatelessWidget {
  const _DeviceHealthCard({required this.snapshot, required this.onTap});

  final DeviceHealthSnapshot snapshot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final (tagLabel, tagVariant, accent) = switch (snapshot.level) {
      DeviceHealthLevel.healthy => (
        l10n.deviceHealthStatusHealthy,
        TagVariant.g,
        colors.mint,
      ),
      DeviceHealthLevel.atRisk => (
        l10n.deviceHealthStatusAtRisk,
        TagVariant.a,
        colors.amber,
      ),
      DeviceHealthLevel.offline => (
        l10n.deviceHealthStatusOffline,
        TagVariant.t,
        colors.ink2,
      ),
    };

    final meta = <String>[
      if (snapshot.lastHeartbeatAgoLabel != null)
        l10n.deviceHealthLastBeat(snapshot.lastHeartbeatAgoLabel!),
      if (snapshot.batteryPercent != null)
        l10n.deviceHealthBattery(snapshot.batteryPercent!),
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: DeviceHealthListKeys.deviceCard(snapshot.deviceId),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.displayLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.isEmpty ? snapshot.modelLabel : meta,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                    if (snapshot.offline) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.deviceHealthOfflineLastKnown,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.tealDeep,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tag(
                key: DeviceHealthListKeys.healthTag(snapshot.deviceId),
                label: tagLabel,
                variant: tagVariant,
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_left, color: colors.ink2, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
