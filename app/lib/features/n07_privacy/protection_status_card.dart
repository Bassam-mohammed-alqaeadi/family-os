import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/foundation_gate/native_child_telemetry_bridge.dart';

/// Widget keys for the S2 protection card (SAFETY-S2 acceptance).
abstract final class ProtectionStatusKeys {
  static const card = Key('s2_protection_card');
  static const stateLine = Key('s2_protection_state');
  static const queuedLine = Key('s2_protection_queued');
  static const batteryButton = Key('s2_protection_battery_button');
}

/// S2 resilience — the protection verdict card for «what is collected».
///
/// Renders [NativeProtectionState.effective], which is the native verdict plus
/// the single overlay-distrust rule. Nothing here re-derives protection from
/// signals: the verdict is mirrored and shown, or an honest fallback is shown
/// when the platform side cannot answer.
///
/// The battery-guidance button appears only when the verdict names
/// `battery_restricted`. Navigation defaults to the guidance route; tests may
/// inject [onBatteryGuidance] instead of mounting a router.
class ProtectionStatusCard extends StatefulWidget {
  const ProtectionStatusCard({super.key, this.onBatteryGuidance});

  final VoidCallback? onBatteryGuidance;

  static const batteryGuidanceRoute = '/scr-chd-038';

  @override
  State<ProtectionStatusCard> createState() => _ProtectionStatusCardState();
}

class _ProtectionStatusCardState extends State<ProtectionStatusCard> {
  /// One read per mount: parent bus events rebuild often, and a fresh future
  /// per build would re-hit the channel and flicker the loader.
  late final Future<NativeProtectionState> _state =
      NativeChildTelemetryBridge.protectionState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return FutureBuilder<NativeProtectionState>(
      future: _state,
      builder: (context, snapshot) {
        final state = snapshot.data?.effective ??
            const NativeProtectionState.unavailable();
        return Column(
          key: ProtectionStatusKeys.card,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.s2ProtectionTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              BannerNote(
                key: ProtectionStatusKeys.stateLine,
                message: _stateMessage(l10n, state),
                variant: _variant(state),
              ),
            if (snapshot.connectionState != ConnectionState.waiting &&
                state.queueDepth > 0) ...[
              const SizedBox(height: 8),
              Text(
                key: ProtectionStatusKeys.queuedLine,
                '${state.queueDepth} — ${l10n.s2ProtectionQueuedNote}',
                style: TextStyle(fontSize: 12, color: colors.ink2),
              ),
            ],
            if (snapshot.connectionState != ConnectionState.waiting &&
                state.reasons.contains('battery_restricted')) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: ProtectionStatusKeys.batteryButton,
                onPressed:
                    widget.onBatteryGuidance ??
                    () => context.push(
                      ProtectionStatusCard.batteryGuidanceRoute,
                    ),
                child: Text(l10n.s2ProtectionBatteryButton),
              ),
            ],
          ],
        );
      },
    );
  }

  BannerVariant _variant(NativeProtectionState state) {
    return switch (state.state) {
      NativeProtectionVerdict.fullyProtected => BannerVariant.g,
      NativeProtectionVerdict.degraded => BannerVariant.a,
      NativeProtectionVerdict.stopped => BannerVariant.a,
      NativeProtectionVerdict.notConfigured => BannerVariant.t,
      NativeProtectionVerdict.unavailable => BannerVariant.t,
    };
  }

  String _stateMessage(AppLocalizations l10n, NativeProtectionState state) {
    return switch (state.state) {
      NativeProtectionVerdict.fullyProtected => l10n.s2ProtectionFullyProtected,
      NativeProtectionVerdict.degraded => l10n.s2ProtectionDegraded,
      NativeProtectionVerdict.stopped => l10n.s2ProtectionStopped,
      NativeProtectionVerdict.notConfigured => l10n.s2ProtectionNotConfigured,
      NativeProtectionVerdict.unavailable => l10n.s2ProtectionUnavailable,
    };
  }
}
