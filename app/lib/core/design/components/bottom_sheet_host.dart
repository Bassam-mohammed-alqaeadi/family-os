import 'package:flutter/material.dart';

import '../tokens.dart';

/// Modal bottom sheet shell matching prototype `.sheet`.
class BottomSheetHost {
  BottomSheetHost._();

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? semanticLabel,
  }) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: colors.ink.withValues(alpha: 0.45),
      builder: (sheetContext) {
        return Semantics(
          label: semanticLabel,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radii.sheetTop),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
                  child: builder(sheetContext),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
