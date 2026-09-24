import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/offline_ai_safety/offline_ai_safety.dart';

/// Widget keys for FS-007 parent ticket review (W-P05).
abstract final class AiSafetyTicketReviewKeys {
  static const panel = Key('ai_safety_ticket_panel');
  static const ownershipBanner = Key('ai_safety_ticket_ownership');
  static const empty = Key('ai_safety_ticket_empty');
  static const list = Key('ai_safety_ticket_list');
  static const detail = Key('ai_safety_ticket_detail');
  static const preview = Key('ai_safety_ticket_preview');
  static const previewUnavailable = Key('ai_safety_ticket_preview_na');
  static const resolve = Key('ai_safety_ticket_resolve');
  static const dismissFp = Key('ai_safety_ticket_dismiss_fp');
  static const suggest = Key('ai_safety_ticket_suggest');
  static const noExecutorNote = Key('ai_safety_ticket_no_executor');

  static Key ticketRow(String id) => Key('ai_safety_ticket_row_$id');
}

/// Parent review panel — metadata + redacted preview; never policy executor.
class AiSafetyTicketReviewPanel extends StatelessWidget {
  const AiSafetyTicketReviewPanel({
    super.key,
    required this.tickets,
    required this.signalsById,
    required this.canReview,
    this.selectedTicketId,
    this.onSelect,
    this.onResolve,
    this.onDismissFp,
    this.onSuggestWebFilter,
  });

  final List<SafetyTicket> tickets;
  final Map<String, SafetySignal> signalsById;
  final bool canReview;
  final String? selectedTicketId;
  final ValueChanged<String>? onSelect;
  final ValueChanged<String>? onResolve;
  final ValueChanged<String>? onDismissFp;
  final ValueChanged<String>? onSuggestWebFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final open = tickets.where((t) => t.isOpen).toList();
    SafetyTicket? selected;
    if (open.isNotEmpty) {
      if (selectedTicketId != null) {
        for (final t in open) {
          if (t.id == selectedTicketId) {
            selected = t;
            break;
          }
        }
      }
      selected ??= open.first;
    }

    return DecoratedBox(
      key: AiSafetyTicketReviewKeys.panel,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.fs007TicketPanelTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              key: AiSafetyTicketReviewKeys.ownershipBanner,
              l10n.fs007SuggestOnlyBanner,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              key: AiSafetyTicketReviewKeys.noExecutorNote,
              l10n.fs007NotPolicyExecutor,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: colors.amberDeep,
              ),
            ),
            const SizedBox(height: 10),
            if (open.isEmpty)
              Text(
                key: AiSafetyTicketReviewKeys.empty,
                l10n.fs007TicketEmpty,
                style: TextStyle(fontSize: 13, color: colors.ink2),
              )
            else ...[
              Column(
                key: AiSafetyTicketReviewKeys.list,
                children: [
                  for (final t in open)
                    ListTile(
                      key: AiSafetyTicketReviewKeys.ticketRow(t.id),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        _categoryLabel(
                          l10n,
                          signalsById[t.signalId]?.category,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        _metaLine(l10n, signalsById[t.signalId]),
                        style: TextStyle(fontSize: 11.5, color: colors.ink2),
                      ),
                      trailing: selectedTicketId == t.id
                          ? Icon(Icons.check_circle, color: colors.tealDeep)
                          : null,
                      onTap: canReview && onSelect != null
                          ? () => onSelect!(t.id)
                          : null,
                    ),
                ],
              ),
              if (selected != null) ...[
                const SizedBox(height: 8),
                _TicketDetail(
                  ticket: selected,
                  signal: signalsById[selected.signalId],
                  canReview: canReview,
                  onResolve: onResolve,
                  onDismissFp: onDismissFp,
                  onSuggestWebFilter: onSuggestWebFilter,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static String _categoryLabel(AppLocalizations l10n, SafetyCategory? c) {
    if (c == null) return l10n.fs007CategoryUncategorized;
    return switch (c) {
      SafetyCategory.sexualContent => l10n.fs007CategorySexual,
      SafetyCategory.sensitiveVisual => l10n.fs007CategorySensitiveVisual,
      SafetyCategory.violenceOrThreat => l10n.fs007CategoryViolence,
      SafetyCategory.selfHarmSignal => l10n.fs007CategorySelfHarm,
      SafetyCategory.predatoryOrGroomingSignal => l10n.fs007CategoryPredatory,
      SafetyCategory.substanceOrGambling => l10n.fs007CategorySubstance,
      SafetyCategory.suspiciousLanguage => l10n.fs007CategorySuspicious,
      SafetyCategory.uncategorizedConcern => l10n.fs007CategoryUncategorized,
    };
  }

  static String _certaintyLabel(AppLocalizations l10n, SafetyCertainty? c) {
    if (c == null) return l10n.fs007CertaintyUnknown;
    return switch (c) {
      SafetyCertainty.unknown => l10n.fs007CertaintyUnknown,
      SafetyCertainty.preliminary => l10n.fs007CertaintyPreliminary,
      SafetyCertainty.analysis => l10n.fs007CertaintyAnalysis,
      SafetyCertainty.confirmed => l10n.fs007CertaintyConfirmed,
    };
  }

  static String _severityLabel(AppLocalizations l10n, SafetySeverity? s) {
    if (s == null) return l10n.fs007SeverityLow;
    return switch (s) {
      SafetySeverity.low => l10n.fs007SeverityLow,
      SafetySeverity.elevated => l10n.fs007SeverityElevated,
      SafetySeverity.high => l10n.fs007SeverityHigh,
    };
  }

  static String _metaLine(AppLocalizations l10n, SafetySignal? s) {
    if (s == null) return l10n.fs007TicketMetaMissing;
    return '${_certaintyLabel(l10n, s.certainty)} · '
        '${_severityLabel(l10n, s.severity)} · '
        '${s.provenance.wireName} · v${s.modelVersion}';
  }
}

class _TicketDetail extends StatelessWidget {
  const _TicketDetail({
    required this.ticket,
    required this.signal,
    required this.canReview,
    this.onResolve,
    this.onDismissFp,
    this.onSuggestWebFilter,
  });

  final SafetyTicket ticket;
  final SafetySignal? signal;
  final bool canReview;
  final ValueChanged<String>? onResolve;
  final ValueChanged<String>? onDismissFp;
  final ValueChanged<String>? onSuggestWebFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final preview = ticket.redactedPreview ?? signal?.redactedPreview;

    return DecoratedBox(
      key: AiSafetyTicketReviewKeys.detail,
      decoration: BoxDecoration(
        color: colors.p50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.fs007TicketDetailHeading,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Tag(
                  label: AiSafetyTicketReviewPanel._certaintyLabel(
                    l10n,
                    signal?.certainty,
                  ),
                ),
                Tag(
                  label: AiSafetyTicketReviewPanel._severityLabel(
                    l10n,
                    signal?.severity,
                  ),
                ),
                if (signal != null)
                  Tag(label: signal!.provenance.wireName),
              ],
            ),
            const SizedBox(height: 8),
            if (preview == null || preview.isEmpty)
              Text(
                key: AiSafetyTicketReviewKeys.previewUnavailable,
                l10n.fs007PreviewUnavailable,
                style: TextStyle(fontSize: 12.5, color: colors.ink2),
              )
            else
              Text(
                key: AiSafetyTicketReviewKeys.preview,
                preview,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: colors.ink,
                ),
              ),
            if (canReview) ...[
              const SizedBox(height: 10),
              PrimaryBtn(
                key: AiSafetyTicketReviewKeys.resolve,
                label: l10n.fs007ActionResolve,
                onPressed: onResolve == null
                    ? null
                    : () => onResolve!(ticket.id),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: AiSafetyTicketReviewKeys.dismissFp,
                onPressed: onDismissFp == null
                    ? null
                    : () => onDismissFp!(ticket.id),
                child: Text(l10n.fs007ActionDismissFp),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: AiSafetyTicketReviewKeys.suggest,
                onPressed: onSuggestWebFilter == null
                    ? null
                    : () => onSuggestWebFilter!(ticket.id),
                child: Text(l10n.fs007ActionSuggestWf),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
