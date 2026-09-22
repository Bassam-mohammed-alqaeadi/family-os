import 'package:flutter/material.dart';

import '../tokens.dart';

enum PrimaryBtnVariant { primary, teal, sec, ghost, coral, mint }

/// Full-width primary action button matching prototype `.btn` variants.
class PrimaryBtn extends StatefulWidget {
  const PrimaryBtn({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PrimaryBtnVariant.primary,
    this.fullWidth = true,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final PrimaryBtnVariant variant;
  final bool fullWidth;

  /// Screen-reader label (ARB). Defaults to [label] when null.
  final String? semanticsLabel;

  @override
  State<PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<PrimaryBtn> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;

    final style = _resolveStyle(colors, shadows, gradients);

    final announced = widget.semanticsLabel ?? widget.label;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: announced,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed && _enabled ? 0.978 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Opacity(
          opacity: _enabled ? 1 : 0.45,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              onHighlightChanged: (v) {
                if (_enabled) setState(() => _pressed = v);
              },
              borderRadius: BorderRadius.circular(radii.btn),
              child: Ink(
                width: widget.fullWidth ? double.infinity : null,
                decoration: BoxDecoration(
                  gradient: style.gradient,
                  color: style.gradient == null ? style.background : null,
                  borderRadius: BorderRadius.circular(radii.btn),
                  boxShadow: _enabled && style.shadow != null
                      ? [style.shadow!]
                      : null,
                ),
                child: ConstrainedBox(
                  // UI-015 / Rule 16 — min touch ≥48×48 even when not fullWidth.
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    minWidth: 48,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Center(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: style.fontWeight,
                          color: style.foreground,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _BtnStyle _resolveStyle(
    FamilyColors colors,
    FamilyShadows shadows,
    FamilyGradients gradients,
  ) {
    switch (widget.variant) {
      case PrimaryBtnVariant.primary:
        return _BtnStyle(
          gradient: gradients.grad,
          foreground: colors.surface,
          shadow: shadows.shBrand,
          fontWeight: FontWeight.w800,
        );
      case PrimaryBtnVariant.teal:
        return _BtnStyle(
          gradient: gradients.gradTeal,
          foreground: colors.surface,
          shadow: shadows.shTeal,
          fontWeight: FontWeight.w800,
        );
      case PrimaryBtnVariant.sec:
        return _BtnStyle(
          background: colors.p100,
          foreground: colors.p700,
          fontWeight: FontWeight.w800,
        );
      case PrimaryBtnVariant.ghost:
        return _BtnStyle(
          background: Colors.transparent,
          foreground: colors.ink2,
          fontWeight: FontWeight.w700,
        );
      case PrimaryBtnVariant.coral:
        return _BtnStyle(
          gradient: gradients.gradCoral,
          foreground: colors.surface,
          shadow: shadows.shCoral,
          fontWeight: FontWeight.w800,
        );
      case PrimaryBtnVariant.mint:
        return _BtnStyle(
          gradient: gradients.gradMint,
          foreground: colors.surface,
          shadow: shadows.shMint,
          fontWeight: FontWeight.w800,
        );
    }
  }
}

class _BtnStyle {
  const _BtnStyle({
    this.gradient,
    this.background,
    required this.foreground,
    this.shadow,
    required this.fontWeight,
  });

  final LinearGradient? gradient;
  final Color? background;
  final Color foreground;
  final BoxShadow? shadow;
  final FontWeight fontWeight;
}
