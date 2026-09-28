import 'package:flutter/material.dart';

import '../tokens.dart';

/// Ring state for hub pulse avatars (prototype status halo).
enum StatusPulseKind { calm, attention, alert }

/// Circular emoji avatar with a status ring (FAT-010 pulse row / CHD hubs).
class StatusPulseAvatar extends StatelessWidget {
  const StatusPulseAvatar({
    super.key,
    required this.emoji,
    required this.fillColor,
    required this.semanticsLabel,
    required this.onTap,
    this.status = StatusPulseKind.calm,
    this.size = 48,
  });

  final String emoji;
  final Color fillColor;
  final String semanticsLabel;
  final VoidCallback onTap;
  final StatusPulseKind status;
  final double size;

  Color _ringColor(FamilyColors colors) => switch (status) {
    StatusPulseKind.calm => colors.mint,
    StatusPulseKind.attention => colors.amber,
    StatusPulseKind.alert => colors.coral,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final ring = _ringColor(colors);
    final inner = size - 6;

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: ring.withValues(alpha: 0.28),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Center(
                child: Ink(
                  width: inner,
                  height: inner,
                  decoration: BoxDecoration(
                    color: fillColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: TextStyle(fontSize: size * 0.32)),
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
