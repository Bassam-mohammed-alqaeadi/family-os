import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/policy/capability_level.dart';
import 'package:family_os/core/policy/platform_capability_table.dart';

/// SET-017 / Rule 16 — capability honesty control (unavailable ≠ green ON).
///
/// Visual contract:
/// - [CapabilityLevel.unavailable]: Switch.value false, onChanged null,
///   muted tokens (ink2/border), honesty Tag — never mint selected-on.
/// - [CapabilityLevel.reportsOnly]: limited copy + amber Tag, not fully on.
/// - [CapabilityLevel.full]: interactive Switch; ON uses mint track/thumb.
class CapabilityHonestyTile extends StatelessWidget {
  const CapabilityHonestyTile({
    super.key,
    required this.label,
    required this.desired,
    required this.capability,
    required this.unavailableLabel,
    required this.limitedLabel,
    required this.onChanged,
    this.limitedHint,
    this.switchKey,
    this.badgeKey,
  });

  final String label;
  final bool desired;
  final CapabilityLevel capability;
  final String unavailableLabel;
  final String limitedLabel;

  /// Extra limited-state copy under the label (reportsOnly only).
  final String? limitedHint;
  final ValueChanged<bool> onChanged;
  final Key? switchKey;
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final interactive = switchInteractive(capability);
    final looksOn = switchLooksOn(desired: desired, capability: capability);

    final Tag? badge = switch (capability) {
      CapabilityLevel.unavailable => Tag(
          key: badgeKey,
          label: unavailableLabel,
          variant: TagVariant.a,
        ),
      CapabilityLevel.reportsOnly => Tag(
          key: badgeKey,
          label: limitedLabel,
          variant: TagVariant.a,
        ),
      CapabilityLevel.full => null,
    };

    final semanticsLabel = switch (capability) {
      CapabilityLevel.unavailable => '$label. $unavailableLabel',
      CapabilityLevel.reportsOnly => '$label. $limitedLabel',
      CapabilityLevel.full => label,
    };

    final labelColor = switch (capability) {
      CapabilityLevel.unavailable => colors.ink2,
      CapabilityLevel.reportsOnly => colors.amberDeep,
      CapabilityLevel.full => colors.ink,
    };

    return Semantics(
      container: true,
      enabled: interactive,
      label: semanticsLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radii.card),
          border: Border.all(
            color: capability == CapabilityLevel.reportsOnly
                ? colors.amber.withValues(alpha: 0.45)
                : colors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: labelColor,
                      ),
                    ),
                    if (capability == CapabilityLevel.reportsOnly &&
                        limitedHint != null &&
                        limitedHint!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        limitedHint!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.amberInk,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (badge != null) ...[
                      const SizedBox(height: 6),
                      badge,
                    ],
                  ],
                ),
              ),
              Switch(
                key: switchKey,
                value: looksOn,
                onChanged: interactive ? onChanged : null,
                // Rule 14 tokens only — ON = mint; off/disabled = muted ink2.
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colors.mint;
                  }
                  return colors.ink2;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colors.mint100;
                  }
                  return colors.border;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
