import 'package:flutter/material.dart';

import '../tokens.dart';

enum ProgressBarVariant { mint, pu }

/// Thin progress track matching prototype `.prog` / `.prog.pu`.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.variant = ProgressBarVariant.mint,
    this.height = 8,
    this.fillColor,
  });

  /// Progress in range 0..1.
  final double value;
  final ProgressBarVariant variant;
  final double height;

  /// When set, paints a solid fill and ignores [variant] colors/gradients.
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;
    final clamped = value.clamp(0.0, 1.0);
    final override = fillColor;

    return Semantics(
      label: 'Progress ${(clamped * 100).round()} percent',
      value: clamped.toStringAsFixed(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radii.pill),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.border),
              FractionallySizedBox(
                widthFactor: clamped,
                alignment: AlignmentDirectional.centerStart,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        override ??
                        (variant == ProgressBarVariant.mint
                            ? colors.mint
                            : null),
                    gradient:
                        override == null && variant == ProgressBarVariant.pu
                        ? gradients.grad
                        : null,
                    borderRadius: BorderRadius.circular(radii.pill),
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
