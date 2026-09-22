import 'package:flutter/material.dart';

import '../tokens.dart';

enum TagVariant { g, t, p, a }

/// Pill tag matching prototype `.tag` variants g/t/p/a.
class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, this.variant = TagVariant.p});

  final String label;
  final TagVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final (bg, fg) = switch (variant) {
      TagVariant.g => (colors.mint100, colors.mintInk),
      TagVariant.t => (colors.teal100, colors.teal600),
      TagVariant.p => (colors.p100, colors.p700),
      TagVariant.a => (colors.amber100, colors.amberInk),
    };

    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radii.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
