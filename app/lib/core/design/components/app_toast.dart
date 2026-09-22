import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens.dart';

/// Transient feedback toast matching prototype `.toast`.
class AppToast {
  AppToast._();

  static const Duration duration = Duration(milliseconds: 2500);

  static OverlayEntry? _current;
  static Timer? _timer;

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final overlay = Overlay.of(context);

    dismiss();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 96,
          child: Material(
            color: Colors.transparent,
            child: Semantics(
              liveRegion: true,
              label: message,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.toastBg,
                  borderRadius: BorderRadius.circular(radii.banner),
                  boxShadow: [shadows.shFloat],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: colors.surface,
                            height: 1.6,
                          ),
                        ),
                      ),
                      if (actionLabel != null && onAction != null)
                        Semantics(
                          button: true,
                          label: actionLabel,
                          child: InkWell(
                            onTap: () {
                              dismiss();
                              onAction();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 48,
                                minWidth: 48,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Text(
                                  actionLabel,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: colors.toastAction,
                                  ),
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
        );
      },
    );

    _current = entry;
    overlay.insert(entry);

    _timer = Timer(duration, dismiss);
  }
}
