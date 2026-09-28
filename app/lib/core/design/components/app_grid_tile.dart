import 'package:flutter/material.dart';

import '../tokens.dart';

/// Icon + label tile for apps / tools grids (prototype `.tcard` density).
///
/// Shared chrome for FAT-034 app grid and FAT-013 tools grid — KEEP+REFINE.
class AppGridTile extends StatelessWidget {
  const AppGridTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticsLabel,
    this.badgeLabel,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  /// Defaults to [label] when null.
  final String? semanticsLabel;

  /// Optional corner chip (e.g. lock / wallet hint) — ARB string only.
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final a11y = semanticsLabel ?? label;

    return Semantics(
      button: true,
      label: a11y,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.tcard),
          child: Ink(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.tcard),
              border: Border.all(color: colors.border),
              boxShadow: [shadows.shCard],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 6,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          icon,
                          style: TextStyle(fontSize: 26, color: colors.ink),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                      ],
                    ),
                    if (badgeLabel != null && badgeLabel!.isNotEmpty)
                      PositionedDirectional(
                        top: -4,
                        end: -2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.amber100,
                            borderRadius: BorderRadius.circular(radii.pill),
                            border: Border.all(color: colors.amber),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text(
                              badgeLabel!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: colors.amberDeep,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
