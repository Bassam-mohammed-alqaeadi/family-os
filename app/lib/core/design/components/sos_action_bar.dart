import 'package:flutter/material.dart';

/// Role-filtered SOS action row — only enabled actions appear as pressable.
class SosActionBar extends StatelessWidget {
  const SosActionBar({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          children[i],
        ],
      ],
    );
  }
}

/// Single SOS coral/surface action button (≥48dp).
class SosActionButton extends StatelessWidget {
  const SosActionButton({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
    this.filled = false,
    required this.accent,
    required this.onAccent,
  });

  final String label;
  final String semanticsLabel;
  final VoidCallback? onPressed;
  final bool filled;
  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                color: filled
                    ? onAccent
                    : onAccent.withValues(alpha: enabled ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: filled ? accent : onAccent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
