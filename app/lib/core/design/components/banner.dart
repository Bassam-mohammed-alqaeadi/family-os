import 'package:flutter/material.dart';

import '../tokens.dart';

enum BannerVariant { t, p, a, g }

/// Tinted note banner matching prototype `.banner` t/p/a/g.
class BannerNote extends StatelessWidget {
  const BannerNote({
    super.key,
    required this.message,
    this.variant = BannerVariant.p,
    this.leading,
  });

  final String message;
  final BannerVariant variant;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final (bg, fg) = switch (variant) {
      BannerVariant.t => (colors.teal100, colors.tealDeep),
      BannerVariant.p => (colors.p50, colors.p700),
      BannerVariant.a => (colors.amber100, colors.amberDeep),
      BannerVariant.g => (colors.mint100, colors.mintInk),
    };

    return Semantics(
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radii.banner),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 9)],
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    height: 1.7,
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
