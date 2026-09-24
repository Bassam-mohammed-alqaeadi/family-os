import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/policy/sos_alert.dart';

/// SOS lifecycle status banner (incident state honesty).
class SosStatusBanner extends StatelessWidget {
  const SosStatusBanner({
    super.key,
    required this.status,
    required this.label,
    this.onSurface = true,
  });

  final SosAlertStatus status;
  final String label;
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final fg = onSurface ? colors.surface : colors.ink;
    return Semantics(
      liveRegion: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fg.withValues(alpha: onSurface ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
