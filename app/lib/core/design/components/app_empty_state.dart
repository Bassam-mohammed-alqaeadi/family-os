import 'package:flutter/material.dart';

import 'package:family_os/core/i18n/app_localizations.dart';

import '../tokens.dart';
import 'primary_btn.dart';

/// Shared SCR-SHR-006 empty template (Rule 15 · G-6).
///
/// Soft mint surface + friendly honesty + optional suggested action.
/// Invoked by hosts when there is no day/content data — never planted samples.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.contextName,
  });

  /// Optional overrides; defaults resolve from ARB (SHR-006).
  final String? title;
  final String? message;
  final String? actionLabel;

  /// Suggested next action. When null, CTA is omitted.
  final VoidCallback? onAction;

  /// Surface name interpolated into default message (e.g. «لوحة يومي»).
  final String? contextName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    final resolvedTitle = title ?? l10n.emptyStateTitle;
    final resolvedMessage = message ??
        l10n.emptyStateMessage(contextName ?? l10n.emptyStateDefaultContext);
    final resolvedAction = actionLabel ?? l10n.emptyStateActionCta;

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
                    color: colors.mint100,
                    borderRadius: BorderRadius.circular(radii.card),
                    border: Border.all(
                      color: colors.mint.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: colors.teal,
                          semanticLabel: resolvedTitle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          resolvedTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
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
                            color: colors.ink2,
                            height: 1.65,
                          ),
                        ),
                        if (onAction != null) ...[
                          const SizedBox(height: 22),
                          PrimaryBtn(
                            key: const Key('app_empty_action'),
                            label: resolvedAction,
                            variant: PrimaryBtnVariant.sec,
                            onPressed: onAction,
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
}
