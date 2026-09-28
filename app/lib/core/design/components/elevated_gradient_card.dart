import 'package:flutter/material.dart';

import '../tokens.dart';

/// Gradient surface card used on father hubs (prototype active-child / brand card).
///
/// Default fill is [FamilyGradients.grad]. Pass [gradient] for mint/teal variants.
class ElevatedGradientCard extends StatelessWidget {
  const ElevatedGradientCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticsLabel,
    this.gradient,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final LinearGradient? gradient;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;
    final fill = gradient ?? gradients.grad;

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        gradient: fill,
        borderRadius: BorderRadius.circular(radii.card),
        boxShadow: [shadows.shBrand],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return surface;
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.card),
          child: Ink(
            decoration: BoxDecoration(
              gradient: fill,
              borderRadius: BorderRadius.circular(radii.card),
              boxShadow: [shadows.shBrand],
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
