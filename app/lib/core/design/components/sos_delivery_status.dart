import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/policy/sos_alert.dart';

/// Honest per-channel delivery list — never claims success without proof.
class SosDeliveryStatus extends StatelessWidget {
  const SosDeliveryStatus({
    super.key,
    required this.rows,
    required this.labelFor,
    this.onSurface = true,
  });

  final List<SosDeliveryRow> rows;
  final String Function(SosDeliveryRow row) labelFor;
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final fg = onSurface ? colors.surface : colors.ink;
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fg.withValues(alpha: onSurface ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  labelFor(row),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
