import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/web_filter_evaluator.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';
import 'package:family_os/core/policy/web_unlock_service.dart';
import 'package:family_os/core/web_filter/web_filter_enforcement.dart';
import 'package:family_os/core/web_filter/web_filter_verdict.dart';

/// Human Arabic reason for a deny (G-3 — never raw key alone).
String webFilterHumanReason(
  AppLocalizations l10n,
  String? categoryKey, {
  WebFilterDenySource? denySource,
}) {
  if (denySource == WebFilterDenySource.blocklist) {
    return l10n.webBlockReasonBlocklist;
  }
  if (denySource == WebFilterDenySource.dictionary) {
    return l10n.webBlockReasonDictionary;
  }
  return switch (categoryKey) {
    WebFilterCategories.adults => l10n.webBlockReasonAdults,
    WebFilterCategories.gambling => l10n.webBlockReasonGambling,
    WebFilterCategories.violence => l10n.webBlockReasonViolence,
    WebFilterCategories.social => l10n.webBlockReasonSocial,
    WebFilterCategories.games => l10n.webBlockReasonGames,
    WebFilterCategories.streaming => l10n.webBlockReasonStreaming,
    _ => l10n.webBlockReasonGeneric,
  };
}

/// Default SET-006 unlock CTA: create pending request + toast.
Future<void> defaultWebUnlockRequest({
  required BuildContext context,
  required WebUnlockService service,
  required ChildId childId,
  required Uri url,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await service.requestUnlock(childId, url.toString());
  if (!context.mounted) return;
  AppToast.show(
    context,
    message: result.throttled
        ? l10n.webUnlockDuplicateToast
        : l10n.webUnlockRequestedToast,
  );
}

/// Child-facing polite block page (SET-005/006).
///
/// Can be pumped without a CHD route. Father preview embeds the same widget
/// with the same [WebFilterDecisionSnapshot].
class WebBlockPage extends StatelessWidget {
  const WebBlockPage({
    super.key,
    required this.snapshot,
    this.onRequestUnlock,
    this.unlockService,
    this.childId,
    this.isPreview = false,
    this.feedback = WebFilterInterstitialFeedback.none,
  });

  /// Shared verdict from [WebFilterDecisionSnapshot.evaluate].
  final WebFilterDecisionSnapshot snapshot;

  /// SET-006 seam — when null and [unlockService]+[childId] set, uses default.
  final VoidCallback? onRequestUnlock;

  /// Stage-1 unlock service for default CTA wiring.
  final WebUnlockService? unlockService;

  /// Child identity for default unlock request.
  final ChildId? childId;

  /// When true, shows a small father-preview caption above the child UI.
  final bool isPreview;

  /// Transient unlock feedback on this interstitial only (Q-WF-15).
  final WebFilterInterstitialFeedback feedback;

  VoidCallback? _resolveUnlock(BuildContext context) {
    if (onRequestUnlock != null) return onRequestUnlock;
    final service = unlockService;
    final id = childId;
    if (service == null || id == null) return null;
    return () {
      defaultWebUnlockRequest(
        context: context,
        service: service,
        childId: id,
        url: snapshot.url,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final denied = snapshot.isDenied;
    final host = snapshot.host.isEmpty
        ? snapshot.url.toString()
        : snapshot.host;
    final reason = webFilterHumanReason(
      l10n,
      snapshot.categoryKey,
      denySource: snapshot.denySource,
    );
    final unlock = _resolveUnlock(context);
    final feedbackLabel = switch (feedback) {
      WebFilterInterstitialFeedback.none => null,
      WebFilterInterstitialFeedback.pending => l10n.webBlockFeedbackPending,
      WebFilterInterstitialFeedback.approved => l10n.webBlockFeedbackApproved,
      WebFilterInterstitialFeedback.denied => l10n.webBlockFeedbackDenied,
      WebFilterInterstitialFeedback.expired => l10n.webBlockFeedbackExpired,
    };
    final sourceLabel = snapshot.denySource == null
        ? null
        : l10n.webBlockSourceOfDeny(snapshot.denySource!.reasonClass);

    return Material(
      color: colors.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isPreview) ...[
                Text(
                  key: const Key('web_block_preview_caption'),
                  l10n.webFilterPreviewSheetTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.ink2,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      denied
                          ? Icons.shield_outlined
                          : Icons.check_circle_outline,
                      size: 56,
                      color: denied ? colors.ink2 : colors.ink,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      key: const Key('web_block_title'),
                      denied ? l10n.webBlockTitle : l10n.webBlockAllowedTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (denied) ...[
                      Text(
                        key: const Key('web_block_reason'),
                        reason,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: colors.ink2,
                        ),
                      ),
                      if (sourceLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          key: const Key('web_block_source_of_deny'),
                          sourceLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: colors.ink2,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ] else ...[
                      Text(
                        key: const Key('web_block_allowed_body'),
                        l10n.webBlockAllowedBody,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: colors.ink2,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (feedbackLabel != null) ...[
                      Text(
                        key: const Key('web_block_feedback'),
                        feedbackLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(radii.card),
                        border: Border.all(color: colors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Text(
                          key: const Key('web_block_host'),
                          host,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.ink,
                          ),
                        ),
                      ),
                    ),
                    // Hidden identity for tests — verdict parity without raw keys in UI.
                    SizedBox(
                      height: 0,
                      width: 0,
                      child: Text(
                        key: Key(
                          'web_block_verdict_'
                          '${denied ? 'deny' : 'allow'}_'
                          '${snapshot.categoryKey ?? 'none'}_'
                          'v${snapshot.policyVersion}',
                        ),
                        '',
                      ),
                    ),
                  ],
                ),
              ),
              if (denied)
                PrimaryBtn(
                  key: const Key('web_block_unlock_cta'),
                  label: l10n.webBlockUnlockCta,
                  onPressed: unlock,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
