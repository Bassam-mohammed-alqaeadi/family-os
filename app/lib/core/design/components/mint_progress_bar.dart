import 'package:flutter/material.dart';

import '../tokens.dart';

/// Mint time-remaining track (prototype `.prog` mint fill on hubs).
///
/// Prefer this over [ProgressBar] when the surface needs the mint gradient
/// fill used on father/child day hubs (FAT-010 / CHD-004).
class MintProgressBar extends StatelessWidget {
  const MintProgressBar({
    super.key,
    required this.value,
    required this.semanticsLabel,
    this.height = 10,
  });

  /// Progress in range 0..1.
  final double value;

  /// Caller-supplied ARB string (Rule 12 — no hardcoded UI copy).
  final String semanticsLabel;

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;
    final clamped = value.clamp(0.0, 1.0);

    return Semantics(
      label: semanticsLabel,
      value: '${(clamped * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radii.pill),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.border.withValues(alpha: 0.55)),
              FractionallySizedBox(
                widthFactor: clamped,
                alignment: AlignmentDirectional.centerStart,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: gradients.gradMint,
                    borderRadius: BorderRadius.circular(radii.pill),
                    boxShadow: [
                      BoxShadow(
                        color: colors.mint.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
