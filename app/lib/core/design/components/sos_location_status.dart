import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/policy/sos_alert.dart';

/// Location class chip — READY / ACQUIRING / STALE / UNAVAILABLE.
class SosLocationStatus extends StatelessWidget {
  const SosLocationStatus({
    super.key,
    required this.locationClass,
    required this.label,
    this.detail,
    this.onSurface = true,
  });

  final SosLocationClass locationClass;
  final String label;
  final String? detail;
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final fg = onSurface ? colors.surface : colors.ink;
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fg.withValues(alpha: onSurface ? 0.15 : 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
              if (detail != null && detail!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  detail!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
