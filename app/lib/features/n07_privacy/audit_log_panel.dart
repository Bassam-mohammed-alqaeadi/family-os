import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/web_unlock_service.dart' show AuditAppend;

/// Widget keys for SET-013 audit panel (no forget control).
abstract final class AuditLogPanelKeys {
  static const panel = Key('privacy_audit_log_panel');
  static const empty = Key('privacy_audit_log_empty');

  static Key entry(int index) => Key('privacy_audit_log_entry_$index');
}

/// Mock audit list for FAT-059 — **must not** host forget/wipe actions (R10).
///
/// Forget lives only on [PrivacyDataScreen] action row, never here.
class AuditLogPanel extends StatelessWidget {
  const AuditLogPanel({
    super.key,
    required this.audit,
  });

  final AuditAppend audit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final entries = audit.entries;

    return Semantics(
      container: true,
      label: l10n.privacyAuditPanelTitle,
      child: DecoratedBox(
        key: AuditLogPanelKeys.panel,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.privacyAuditPanelTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.privacyAuditPanelHint,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                ),
              ),
              const SizedBox(height: 10),
              if (entries.isEmpty)
                Text(
                  key: AuditLogPanelKeys.empty,
                  l10n.privacyAuditPanelEmpty,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.ink2,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                for (var i = 0; i < entries.length; i++)
                  Padding(
                    key: AuditLogPanelKeys.entry(i),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      entries[i],
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
