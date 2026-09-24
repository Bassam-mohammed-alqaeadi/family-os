import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/capability_honesty_badge.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/screen_camera/screen_camera_document.dart';
import 'package:family_os/core/screen_camera/screen_camera_engine.dart';

/// Widget keys for FS-004 child transparency (W-C01 / W-C02).
abstract final class ScreenCameraTransparencyKeys {
  static const card = Key('sc_transparency_card');
  static const monitorNotice = Key('sc_transparency_monitor');
  static const statusSection = Key('sc_transparency_status');
  static const cameraLine = Key('sc_transparency_camera');
  static const captureLine = Key('sc_transparency_capture');
  static const monitorLine = Key('sc_transparency_monitor_line');
  static const packageVsOsNote = Key('sc_transparency_pkg_vs_os');
  static const hidden = Key('sc_transparency_hidden');
}

/// Child-facing Screen & Camera honesty (SC-OD-10) — no admin controls.
///
/// Shows monitoring notice when configured active; always shows status lines
/// when [document] is provided. Hidden entirely when nothing configured.
class ScreenCameraTransparencyCard extends StatelessWidget {
  const ScreenCameraTransparencyCard({
    super.key,
    required this.document,
    this.cameraOsPlane = CapabilityStatus.mockRemote,
    this.capturePlane = CapabilityStatus.mockRemote,
    this.showWhenIdle = false,
  });

  final ScreenCameraDocument document;
  final CapabilityStatus cameraOsPlane;
  final CapabilityStatus capturePlane;

  /// When false (default), hide card if no prevent/monitor/protect intent.
  final bool showWhenIdle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final eval = ScreenCameraEngine.evaluate(
      document,
      cameraOsPlane: cameraOsPlane,
      capturePlane: capturePlane,
    );

    final hasIntent =
        eval.cameraOsIntent ||
        eval.capturePreventIntent ||
        eval.screenshotMonitorActive ||
        eval.protectSensitive;

    if (!hasIntent && !showWhenIdle) {
      return const SizedBox.shrink(key: ScreenCameraTransparencyKeys.hidden);
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return DecoratedBox(
      key: ScreenCameraTransparencyKeys.card,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.fs004ChildTransparencyTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            if (eval.screenshotMonitorActive) ...[
              const SizedBox(height: 10),
              BannerNote(
                key: ScreenCameraTransparencyKeys.monitorNotice,
                variant: BannerVariant.a,
                message: l10n.fs004ChildMonitorNotice,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.fs004ChildNotSecret,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Column(
              key: ScreenCameraTransparencyKeys.statusSection,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusLine(
                  key: ScreenCameraTransparencyKeys.cameraLine,
                  label: l10n.fs004StatusCameraLabel,
                  value: eval.cameraOsIntent
                      ? l10n.fs004StatusRestricted
                      : l10n.fs004StatusOff,
                  badge: CapabilityHonestyBadge(status: cameraOsPlane),
                ),
                const SizedBox(height: 6),
                _StatusLine(
                  key: ScreenCameraTransparencyKeys.captureLine,
                  label: l10n.fs004StatusCaptureLabel,
                  value: eval.capturePreventIntent
                      ? l10n.fs004StatusOnLimited
                      : l10n.fs004StatusOff,
                  badge: CapabilityHonestyBadge(status: capturePlane),
                ),
                const SizedBox(height: 6),
                _StatusLine(
                  key: ScreenCameraTransparencyKeys.monitorLine,
                  label: l10n.fs004StatusMonitorLabel,
                  value: eval.screenshotMonitorActive
                      ? l10n.fs004StatusOnSeeNotice
                      : l10n.fs004StatusOff,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              key: ScreenCameraTransparencyKeys.packageVsOsNote,
              l10n.fs004PackageVsOsNote,
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
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    super.key,
    required this.label,
    required this.value,
    this.badge,
  });

  final String label;
  final String value;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Semantics(
      container: true,
      label: '$label. $value',
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
          ),
          if (badge != null) badge!,
        ],
      ),
    );
  }
}

/// Parent preview of child transparency (W-P06).
class ScreenCameraChildPreview extends StatelessWidget {
  const ScreenCameraChildPreview({super.key, required this.monitoringActive});

  final bool monitoringActive;

  static const previewKey = Key('sc_child_preview');

  @override
  Widget build(BuildContext context) {
    if (!monitoringActive) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return DecoratedBox(
      key: previewKey,
      decoration: BoxDecoration(
        color: colors.p50,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fs004ChildPreviewHeading,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.fs004ChildMonitorNotice,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 6),
            Tag(label: l10n.fs004ChildNotSecret, variant: TagVariant.a),
          ],
        ),
      ),
    );
  }
}
