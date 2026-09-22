import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// SCR-FAT-007 — وضع التجربة (bare parent onboarding, mock-first).
///
/// Wave-1: amber permanent «بيانات تجريبية» strip + board preview;
/// CTA «اربط جهازًا حقيقيًا». Virtual demo child «تجريبي» is intentional
/// trial labeling (not a Rule 23 person-name default).
class TrialModeScreen extends StatelessWidget {
  const TrialModeScreen({
    super.key,
    this.onMap,
    this.onAdvisor,
    this.onLinkDevice,
  });

  /// Test seams — when null, navigates to FAT-014 / FAT-011 / FAT-004.
  final VoidCallback? onMap;
  final VoidCallback? onAdvisor;
  final VoidCallback? onLinkDevice;

  void _goMap(BuildContext context) {
    if (onMap != null) {
      onMap!();
      return;
    }
    context.go('/scr-fat-014');
  }

  void _goAdvisor(BuildContext context) {
    if (onAdvisor != null) {
      onAdvisor!();
      return;
    }
    context.go('/scr-fat-011');
  }

  void _goLink(BuildContext context) {
    if (onLinkDevice != null) {
      onLinkDevice!();
      return;
    }
    context.go('/scr-fat-004');
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
              l10n.trialModeTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.trialModeSubtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.amberDeep,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            BannerNote(
              key: const Key('trial_mode_banner'),
              message: l10n.trialModeBanner,
              variant: BannerVariant.a,
            ),
            const SizedBox(height: 12),
            Semantics(
              label: '${l10n.trialModeChildTitle}. ${l10n.trialModeChildMeta}',
              child: DecoratedBox(
                key: const Key('trial_mode_preview_card'),
                decoration: BoxDecoration(
                  gradient: gradients.grad,
                  borderRadius: BorderRadius.circular(radii.card),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          ExcludeSemantics(
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  colors.surface.withValues(alpha: 0.25),
                              child: Text(
                                l10n.trialModeAvatarLetter,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: colors.surface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.trialModeChildTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: colors.surface,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.trialModeChildMeta,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.surface
                                        .withValues(alpha: 0.85),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.trialModeRemaining,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.surface,
                              ),
                            ),
                          ),
                          Text(
                            l10n.trialModeMinutes,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.surface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              key: const Key('trial_mode_try_card'),
              title: l10n.trialModeTryTitle,
              child: Column(
                children: [
                  RowTile(
                    key: const Key('trial_mode_map_row'),
                    leading: const Text('🗺️', style: TextStyle(fontSize: 18)),
                    title: l10n.trialModeMapRow,
                    trailing: Icon(
                      Icons.chevron_left,
                      color: colors.ink2,
                      size: 22,
                    ),
                    onTap: () => _goMap(context),
                  ),
                  RowTile(
                    key: const Key('trial_mode_advisor_row'),
                    leading: const Text('🧠', style: TextStyle(fontSize: 18)),
                    title: l10n.trialModeAdvisorRow,
                    trailing: Icon(
                      Icons.chevron_left,
                      color: colors.ink2,
                      size: 22,
                    ),
                    onTap: () => _goAdvisor(context),
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryBtn(
              key: const Key('trial_mode_link_cta'),
              label: l10n.trialModeLinkCta,
              onPressed: () => _goLink(context),
            ),
          ],
        ),
      ),
    );
  }
}
