import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Catalog host for SCR-SHR-006 — mint AppEmptyState (G-6 template).
///
/// Production hosts invoke [AppEmptyState] by event (e.g. empty child day),
/// not by navigating here. This route exists for gallery/catalog honesty.
class EmptyStateTemplateScreen extends StatelessWidget {
  const EmptyStateTemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.emptyStateTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: AppEmptyState(
          key: const Key('shr_006_catalog_empty'),
          onAction: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}
