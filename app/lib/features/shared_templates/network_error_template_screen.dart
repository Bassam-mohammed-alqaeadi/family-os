import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Catalog host for SCR-SHR-005 — amber AppErrorState (G-6 template).
///
/// Production hosts invoke [AppErrorState] by event (e.g. create-family fail),
/// not by navigating here. This route exists for gallery/catalog honesty.
class NetworkErrorTemplateScreen extends StatelessWidget {
  const NetworkErrorTemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.errorNetworkTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: AppErrorState(
          key: const Key('shr_005_catalog_error'),
          kind: AppErrorKind.network,
          onRetry: () {
            // Catalog demo: dismiss if stacked; otherwise stay (honest no-op).
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}
