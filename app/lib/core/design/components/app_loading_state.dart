import 'package:flutter/material.dart';

import 'package:family_os/core/i18n/app_localizations.dart';

import '../tokens.dart';

/// Shared loading template (VX-B4 · FVX-G-14) — Rule 15 companion to
/// [AppEmptyState] / [AppErrorState].
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message, this.semanticsLabel});

  /// Optional status line under the spinner.
  final String? message;

  /// Override semantics; defaults to ARB loading label.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final label = semanticsLabel ?? l10n.appLoadingSemantics;
    final line = message;

    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colors.p600,
                ),
              ),
              if (line != null && line.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  line,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
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
