import 'package:flutter/material.dart';
import 'package:family_os/core/design/tokens.dart';

/// Temporary screen for every registry route until real UI ships.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.screenId,
    required this.title,
    this.subtitle,
    super.key,
  });

  final String screenId;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(screenId, style: text.labelLarge),
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: text.titleMedium?.copyWith(color: colors.ink),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                screenId,
                style: text.bodyMedium?.copyWith(color: colors.ink2),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: text.bodySmall?.copyWith(color: colors.amberInk),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
