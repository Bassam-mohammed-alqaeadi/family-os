import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// SCR-FAT-005 — شرح الصلاحيات (bare parent onboarding, mock-first).
///
/// Wave-1: 90s video card + WHY rows per permission + rule-3 banner.
/// Parametric / Rule 23: no default child name — «جهازه» wording only.
/// Mock video only — tap shows toast; no player / assets / system dialogs.
class PermissionsExplainerScreen extends StatelessWidget {
  const PermissionsExplainerScreen({
    super.key,
    this.onContinue,
  });

  /// Test seam — when null, navigates to `/scr-fat-006`.
  final VoidCallback? onContinue;

  void _continue(BuildContext context) {
    if (onContinue != null) {
      onContinue!();
      return;
    }
    context.go('/scr-fat-006');
  }

  void _onVideoTap(BuildContext context, AppLocalizations l10n) {
    AppToast.show(context, message: l10n.permissionsExplainerVideoToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.permissionsExplainerTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.permissionsExplainerStep,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          children: [
            Semantics(
              button: true,
              label: l10n.permissionsExplainerVideoSemantics,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('permissions_explainer_video'),
                  onTap: () => _onVideoTap(context, l10n),
                  borderRadius: BorderRadius.circular(radii.card),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: gradients.grad,
                      borderRadius: BorderRadius.circular(radii.card),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 26,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '▶️',
                            style: TextStyle(
                              fontSize: 40,
                              color: colors.surface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.permissionsExplainerVideoTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.surface,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  RowTile(
                    key: const Key('permissions_explainer_location'),
                    leading: const Text('📍', style: TextStyle(fontSize: 18)),
                    title: l10n.permissionsExplainerLocationTitle,
                    subtitle: l10n.permissionsExplainerLocationWhy,
                  ),
                  RowTile(
                    key: const Key('permissions_explainer_a11y'),
                    leading: const Text('♿', style: TextStyle(fontSize: 18)),
                    title: l10n.permissionsExplainerA11yTitle,
                    subtitle: l10n.permissionsExplainerA11yWhy,
                  ),
                  RowTile(
                    key: const Key('permissions_explainer_battery'),
                    leading: const Text('🔋', style: TextStyle(fontSize: 18)),
                    title: l10n.permissionsExplainerBatteryTitle,
                    subtitle: l10n.permissionsExplainerBatteryWhy,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BannerNote(
              key: const Key('permissions_explainer_banner'),
              message: l10n.permissionsExplainerBanner,
              variant: BannerVariant.a,
            ),
            const SizedBox(height: 14),
            PrimaryBtn(
              key: const Key('permissions_explainer_continue'),
              label: l10n.permissionsExplainerContinue,
              onPressed: () => _continue(context),
            ),
          ],
        ),
      ),
    );
  }
}
