import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/sos_final/sos_readiness.dart';

/// One readiness row for FAT-028 honesty checklist.
@immutable
final class SosReadinessUiRow {
  const SosReadinessUiRow({
    required this.id,
    required this.label,
    required this.klass,
    this.detail = '',
  });

  final String id;
  final String label;
  final SosReadinessClass klass;
  final String detail;
}

/// FAT-028 readiness / honesty card (capability class presentation).
class SosReadinessCard extends StatelessWidget {
  const SosReadinessCard({
    super.key,
    required this.title,
    required this.body,
    this.rows = const [],
    this.claimsReady = false,
  });

  final String title;
  final String body;
  final List<SosReadinessUiRow> rows;
  final bool claimsReady;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                Icon(
                  claimsReady ? Icons.check_circle : Icons.info_outline,
                  size: 18,
                  color: claimsReady ? colors.mint : colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: TextStyle(fontSize: 12, height: 1.45, color: colors.ink2),
            ),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final row in rows) ...[
                _ReadinessLine(row: row, colors: colors),
                const SizedBox(height: 6),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadinessLine extends StatelessWidget {
  const _ReadinessLine({required this.row, required this.colors});

  final SosReadinessUiRow row;
  final FamilyColors colors;

  Color get _klassColor => switch (row.klass) {
    SosReadinessClass.available => colors.mint,
    SosReadinessClass.degraded => colors.amber,
    SosReadinessClass.unavailable => colors.coral,
    SosReadinessClass.notConfigured => colors.ink2,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: Key('sos_readiness_dot_${row.id}'),
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: _klassColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
              if (row.detail.isNotEmpty)
                Text(
                  row.detail,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.ink2,
                    height: 1.35,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
