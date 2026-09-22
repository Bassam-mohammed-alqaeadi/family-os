import 'package:flutter/material.dart';

import '../tokens.dart';
import 'family_ui_mode.dart';

/// Surface card matching prototype `.card` (radius follows [FamilyUiMode]).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.linkLabel,
    this.onLinkTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
  });

  final Widget child;
  final String? title;
  final String? linkLabel;
  final VoidCallback? onLinkTap;

  /// Optional surface override (e.g. soft [FamilyColors.p50]).
  final Color? backgroundColor;

  /// Optional border override (e.g. teal accent card).
  final Color? borderColor;

  /// Border stroke width when [borderColor] is set; default 1.
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final mode = FamilyUiModeScope.of(context);
    final radius = mode == FamilyUiMode.child ? radii.cardChild : radii.card;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? colors.border.withValues(alpha: 0.85),
          width: borderWidth ?? 1,
        ),
        boxShadow: [shadows.shCard],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || (linkLabel != null && onLinkTap != null)) ...[
              Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.ink,
                          height: 1.3,
                        ),
                      ),
                    ),
                  if (linkLabel != null && onLinkTap != null)
                    Semantics(
                      button: true,
                      label: linkLabel,
                      child: InkWell(
                        onTap: onLinkTap,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 48,
                            minWidth: 48,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              linkLabel!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.p600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
