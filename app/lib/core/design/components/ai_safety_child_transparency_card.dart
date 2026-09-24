import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/offline_ai_safety/offline_ai_safety.dart';

/// Widget keys for FS-007 child transparency (W-C01).
abstract final class AiSafetyChildTransparencyKeys {
  static const card = Key('ai_safety_child_card');
  static const onDeviceNote = Key('ai_safety_child_on_device');
  static const searchLine = Key('ai_safety_child_search');
  static const imageLine = Key('ai_safety_child_image');
  static const screenshotLine = Key('ai_safety_child_screenshot');
  static const hidden = Key('ai_safety_child_hidden');
}

/// Child permanent transparency card — no admin / tickets / raw previews.
class AiSafetyChildTransparencyCard extends StatelessWidget {
  const AiSafetyChildTransparencyCard({
    super.key,
    required this.transparency,
    this.showWhenAllOff = false,
  });

  final ChildSafetyTransparency transparency;

  /// When false, hide if every tool is off.
  final bool showWhenAllOff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    final anyOn = transparency.searchAnalysis != 'off' ||
        transparency.imageClassification != 'off' ||
        transparency.screenshotMonitoring != 'off';

    if (!anyOn && !showWhenAllOff) {
      return const SizedBox.shrink(key: AiSafetyChildTransparencyKeys.hidden);
    }

    return DecoratedBox(
      key: AiSafetyChildTransparencyKeys.card,
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
              l10n.fs007ChildTransparencyTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            if (transparency.namesOnDeviceOffline) ...[
              const SizedBox(height: 6),
              Text(
                key: AiSafetyChildTransparencyKeys.onDeviceNote,
                l10n.fs007ChildOnDeviceNote,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                ),
              ),
            ],
            const SizedBox(height: 10),
            _ToolLine(
              key: AiSafetyChildTransparencyKeys.searchLine,
              label: l10n.fs007ToolSearch,
              state: transparency.searchAnalysis,
            ),
            _ToolLine(
              key: AiSafetyChildTransparencyKeys.imageLine,
              label: l10n.fs007ToolImage,
              state: transparency.imageClassification,
            ),
            _ToolLine(
              key: AiSafetyChildTransparencyKeys.screenshotLine,
              label: l10n.fs007ToolScreenshot,
              state: transparency.screenshotMonitoring,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolLine extends StatelessWidget {
  const _ToolLine({
    super.key,
    required this.label,
    required this.state,
  });

  final String label;
  final String state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final stateLabel = switch (state) {
      'on_device' => l10n.fs007ToolStateOnDevice,
      'degraded' => l10n.fs007ToolStateDegraded,
      'unsupported' => l10n.fs007ToolStateUnsupported,
      _ => l10n.fs007ToolStateOff,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
          ),
          Text(
            stateLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
