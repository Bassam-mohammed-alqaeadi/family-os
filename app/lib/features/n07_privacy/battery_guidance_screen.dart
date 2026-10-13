import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/foundation_gate/native_child_telemetry_bridge.dart';

/// Widget keys for the S2 battery-guidance screen (SAFETY-S2 acceptance).
abstract final class BatteryGuidanceKeys {
  static const screen = Key('s2_battery_guidance_screen');
  static const steps = Key('s2_battery_guidance_steps');
  static const openButton = Key('s2_battery_guidance_open');
  static const resultNote = Key('s2_battery_guidance_result');
}

/// S2 resilience — vendor battery-exemption guidance (guidance only).
///
/// Shows the localized steps for this vendor's settings door, then opens the
/// door through the native layer (resolve-checked there, app-details fallback).
/// The screen never claims the exemption was granted: it reports only whether a
/// settings door opened. Verification of the exemption itself belongs to the
/// protection verdict, which re-evaluates on the next heartbeat.
class BatteryGuidanceScreen extends StatefulWidget {
  const BatteryGuidanceScreen({super.key});

  @override
  State<BatteryGuidanceScreen> createState() => _BatteryGuidanceScreenState();
}

class _BatteryGuidanceScreenState extends State<BatteryGuidanceScreen> {
  late final Future<NativeBatteryGuidance> _guidance =
      NativeChildTelemetryBridge.batteryGuidance();
  bool? _openResult;
  var _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    final opened = await NativeChildTelemetryBridge.openBatterySettings();
    if (!mounted) return;
    setState(() {
      _opening = false;
      _openResult = opened;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: BatteryGuidanceKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.s2BatteryTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<NativeBatteryGuidance>(
          future: _guidance,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final guidance =
                snapshot.data ?? const NativeBatteryGuidance.unavailable();
            final opened = _openResult;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                BannerNote(
                  message: l10n.s2BatteryBody,
                  variant: BannerVariant.t,
                ),
                const SizedBox(height: 16),
                Text(
                  key: BatteryGuidanceKeys.steps,
                  _steps(l10n, guidance.stepsKey),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.8,
                    color: colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: BatteryGuidanceKeys.openButton,
                  onPressed: _opening ? null : _open,
                  child: Text(l10n.s2BatteryOpenSettings),
                ),
                if (opened != null) ...[
                  const SizedBox(height: 12),
                  BannerNote(
                    key: BatteryGuidanceKeys.resultNote,
                    message: opened
                        ? l10n.s2BatteryOpenedNote
                        : l10n.s2BatteryFallbackNote,
                    variant: opened ? BannerVariant.g : BannerVariant.a,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Vendor steps copy, keyed by the native `stepsKey` word. Unknown words fall
  /// back to the stock-Android steps rather than rendering nothing.
  String _steps(AppLocalizations l10n, String stepsKey) {
    return switch (stepsKey) {
      'oem_xiaomi' => l10n.s2BatteryOemXiaomi,
      'oem_huawei' => l10n.s2BatteryOemHuawei,
      'oem_oppo' => l10n.s2BatteryOemOppo,
      'oem_vivo' => l10n.s2BatteryOemVivo,
      'oem_samsung' => l10n.s2BatteryOemSamsung,
      _ => l10n.s2BatteryOemStock,
    };
  }
}
