import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/capability_honesty_badge.dart';
import 'package:family_os/core/design/components/screen_camera_transparency_card.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/screen_camera/screen_camera_document.dart';

/// Widget keys for FS-004 parent policy panel (KEEP/REFINE host).
abstract final class ScreenCameraParentPanelKeys {
  static const panel = Key('sc_parent_panel');
  static const honestyRow = Key('sc_parent_honesty');
  static const cameraSwitch = Key('sc_parent_camera');
  static const captureSwitch = Key('sc_parent_capture');
  static const monitorSwitch = Key('sc_parent_monitor');
  static const protectSwitch = Key('sc_parent_protect');
  static const packageNote = Key('sc_parent_package_note');
  static const micNote = Key('sc_parent_mic_note');
}

/// Compact Prevent / Monitor / Protect panel bound to [ScreenCameraDocument].
///
/// Hosted on FAT-065 (entry) — not a second policy store. Planes stay honest.
class ScreenCameraParentPanel extends StatelessWidget {
  const ScreenCameraParentPanel({
    super.key,
    required this.document,
    required this.canConfigure,
    this.cameraOsPlane = CapabilityStatus.mockRemote,
    this.capturePlane = CapabilityStatus.mockRemote,
    this.onCameraOsChanged,
    this.onCaptureChanged,
    this.onMonitorChanged,
    this.onProtectChanged,
  });

  final ScreenCameraDocument document;
  final bool canConfigure;
  final CapabilityStatus cameraOsPlane;
  final CapabilityStatus capturePlane;
  final ValueChanged<bool>? onCameraOsChanged;
  final ValueChanged<bool>? onCaptureChanged;
  final ValueChanged<bool>? onMonitorChanged;
  final ValueChanged<bool>? onProtectChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return DecoratedBox(
      key: ScreenCameraParentPanelKeys.panel,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                l10n.fs004ParentPanelTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                key: ScreenCameraParentPanelKeys.honestyRow,
                children: [
                  Expanded(
                    child: Text(
                      l10n.fs004PlanesHonestyHint,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                  ),
                  CapabilityHonestyBadge(status: cameraOsPlane),
                  const SizedBox(width: 6),
                  CapabilityHonestyBadge(status: capturePlane),
                ],
              ),
            ),
            SwitchListTile(
              key: ScreenCameraParentPanelKeys.cameraSwitch,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              title: Text(
                l10n.fs004PreventCameraOs,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text(
                l10n.fs004PreventCameraOsSub,
                style: TextStyle(fontSize: 12, color: colors.ink2),
              ),
              value: document.preventCameraOs,
              onChanged: canConfigure ? onCameraOsChanged : null,
            ),
            SwitchListTile(
              key: ScreenCameraParentPanelKeys.captureSwitch,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              title: Text(
                l10n.fs004PreventCapture,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text(
                l10n.fs004PreventCaptureSub,
                style: TextStyle(fontSize: 12, color: colors.ink2),
              ),
              value: document.preventCapture,
              onChanged: canConfigure ? onCaptureChanged : null,
            ),
            SwitchListTile(
              key: ScreenCameraParentPanelKeys.monitorSwitch,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              title: Text(
                l10n.fs004MonitorScreenshots,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text(
                l10n.fs004MonitorScreenshotsSub,
                style: TextStyle(fontSize: 12, color: colors.ink2),
              ),
              value: document.monitorScreenshots,
              onChanged: canConfigure ? onMonitorChanged : null,
            ),
            SwitchListTile(
              key: ScreenCameraParentPanelKeys.protectSwitch,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              title: Text(
                l10n.fs004ProtectSurfaces,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text(
                l10n.fs004ProtectSurfacesSub,
                style: TextStyle(fontSize: 12, color: colors.ink2),
              ),
              value: document.protectSensitiveSurfaces,
              onChanged: canConfigure ? onProtectChanged : null,
            ),
            if (document.monitorScreenshots) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ScreenCameraChildPreview(
                  monitoringActive: document.monitorScreenshots,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: BannerNote(
                key: ScreenCameraParentPanelKeys.packageNote,
                variant: BannerVariant.t,
                message: l10n.fs004PackageVsOsNote,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                key: ScreenCameraParentPanelKeys.micNote,
                l10n.fs004MicOutOfScope,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
