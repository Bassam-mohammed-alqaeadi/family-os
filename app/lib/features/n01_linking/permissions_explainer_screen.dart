import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// SCR-FAT-005 — friendly, honest permission explanation before linking ends.
class PermissionsExplainerScreen extends StatelessWidget {
  const PermissionsExplainerScreen({super.key, this.onContinue});

  final VoidCallback? onContinue;

  void _continue(BuildContext context) {
    if (onContinue case final callback?) {
      callback();
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colors.bg, colors.childBg, colors.p50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Semantics(
                      button: true,
                      label: l10n.permissionsExplainerVideoSemantics,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('permissions_explainer_video'),
                          onTap: () => _onVideoTap(context, l10n),
                          borderRadius: BorderRadius.circular(radii.card + 6),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: gradients.grad,
                              borderRadius: BorderRadius.circular(radii.card + 6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 126,
                                    height: 92,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 86,
                                          height: 86,
                                          decoration: BoxDecoration(
                                            color: colors.surface.withValues(
                                              alpha: 0.18,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.family_restroom_rounded,
                                            size: 48,
                                            color: colors.surface,
                                          ),
                                        ),
                                        PositionedDirectional(
                                          end: 0,
                                          bottom: 2,
                                          child: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: colors.amber,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: colors.surface,
                                                width: 3,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.play_arrow_rounded,
                                              color: colors.ink,
                                              size: 27,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 9),
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
                    const SizedBox(height: 14),
                    _FriendlyPermissionCard(
                      key: const Key('permissions_explainer_location'),
                      icon: Icons.explore_rounded,
                      iconColor: colors.tealDeep,
                      iconBackground: colors.teal100,
                      title: l10n.permissionsExplainerLocationTitle,
                      body: l10n.permissionsExplainerLocationWhy,
                    ),
                    const SizedBox(height: 10),
                    _FriendlyPermissionCard(
                      key: const Key('permissions_explainer_a11y'),
                      icon: Icons.touch_app_rounded,
                      iconColor: colors.p700,
                      iconBackground: colors.p100,
                      title: l10n.permissionsExplainerA11yTitle,
                      body: l10n.permissionsExplainerA11yWhy,
                    ),
                    const SizedBox(height: 10),
                    _FriendlyPermissionCard(
                      key: const Key('permissions_explainer_battery'),
                      icon: Icons.battery_charging_full_rounded,
                      iconColor: colors.amberDeep,
                      iconBackground: colors.amber100,
                      title: l10n.permissionsExplainerBatteryTitle,
                      body: l10n.permissionsExplainerBatteryWhy,
                    ),
                    const SizedBox(height: 14),
                    BannerNote(
                      key: const Key('permissions_explainer_banner'),
                      message: l10n.permissionsExplainerBanner,
                      variant: BannerVariant.a,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: PrimaryBtn(
                  key: const Key('permissions_explainer_continue'),
                  label: l10n.permissionsExplainerContinue,
                  onPressed: () => _continue(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendlyPermissionCard extends StatelessWidget {
  const _FriendlyPermissionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 27),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    color: colors.ink2,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
