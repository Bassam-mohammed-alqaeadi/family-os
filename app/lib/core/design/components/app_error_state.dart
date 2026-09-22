import 'package:flutter/material.dart';

import 'package:family_os/core/i18n/app_localizations.dart';

import '../tokens.dart';
import 'primary_btn.dart';

/// SHR-005 error variants — amber composition, never coral danger red.
enum AppErrorKind {
  /// Server unreachable / generic network failure.
  network,

  /// Request timed out — distinct copy from [network].
  timeout,

  /// 4xx validation / bad request — distinct copy.
  validation,

  /// Device offline — honest “needs network” (no fake offline queue).
  offline,
}

/// Shared SCR-SHR-005 network/error template (Rule 15 · G-6).
///
/// Amber (not red) surface + friendly reason + Retry CTA with Semantics.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.kind,
    this.onRetry,
    this.title,
    this.message,
    this.retryLabel,
  });

  final AppErrorKind kind;

  /// Re-invoke the failed action. When null, Retry is disabled.
  final VoidCallback? onRetry;

  /// Optional overrides; defaults resolve from ARB via [kind].
  final String? title;
  final String? message;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    final resolvedTitle = title ?? _titleFor(l10n, kind);
    final resolvedMessage = message ?? _messageFor(l10n, kind);
    final resolvedRetry = retryLabel ?? l10n.errorRetryCta;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '$resolvedTitle. $resolvedMessage',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.amber100,
                    borderRadius: BorderRadius.circular(radii.card),
                    border: Border.all(
                      color: colors.amber.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: colors.amberDeep,
                          semanticLabel: resolvedTitle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          resolvedTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.amberDeep,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          resolvedMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: colors.amberInk,
                            height: 1.65,
                          ),
                        ),
                        if (onRetry != null) ...[
                          const SizedBox(height: 22),
                          PrimaryBtn(
                            key: const Key('app_error_retry'),
                            label: resolvedRetry,
                            variant: PrimaryBtnVariant.sec,
                            onPressed: onRetry,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _titleFor(AppLocalizations l10n, AppErrorKind kind) {
    return switch (kind) {
      AppErrorKind.network => l10n.errorNetworkTitle,
      AppErrorKind.timeout => l10n.errorTimeoutTitle,
      AppErrorKind.validation => l10n.errorValidationTitle,
      AppErrorKind.offline => l10n.errorOfflineTitle,
    };
  }

  static String _messageFor(AppLocalizations l10n, AppErrorKind kind) {
    return switch (kind) {
      AppErrorKind.network => l10n.errorNetworkMessage,
      AppErrorKind.timeout => l10n.errorTimeoutMessage,
      AppErrorKind.validation => l10n.errorValidationMessage,
      AppErrorKind.offline => l10n.errorOfflineMessage,
    };
  }
}
