import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/family_ui_mode.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Widget keys for SCR-CHD-003 acceptance.
abstract final class TransparencyConsentKeys {
  static const screen = Key('transparency_consent_screen');
  static const honestyBanner = Key('transparency_consent_honesty_banner');
  static const sharedCard = Key('transparency_consent_shared_card');
  static const neverCard = Key('transparency_consent_never_card');
  static const advisorCard = Key('transparency_consent_advisor_card');
  static const acceptCta = Key('transparency_consent_accept');
  static const parentLean = Key('transparency_consent_parent_lean');
}

/// SCR-CHD-003 — إقرار الشفافية (bare child onboarding, mock-first).
///
/// Prototype CHD-003 · SET-012 what-is-collected spirit · Rule 12/23 ·
/// RoleGuard child · accept → CHD-004 · age-appropriate honesty (care ≠ spy).
class TransparencyConsentScreen extends StatelessWidget {
  const TransparencyConsentScreen({
    super.key,
    this.roleOverride,
    this.onAccept,
  });

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Test seam — when null, navigates to `/scr-chd-004`.
  final VoidCallback? onAccept;

  AppRole _role(BuildContext context) =>
      roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.child;

  void _accept(BuildContext context) {
    final notifier = CurrentRole.maybeNotifierOf(context);
    if (notifier != null && notifier.value != AppRole.child) {
      notifier.value = AppRole.child;
    }
    if (onAccept != null) {
      onAccept!();
      return;
    }
    context.go('/scr-chd-004');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final role = _role(context);

    return FamilyUiModeScope(
      mode: FamilyUiMode.child,
      child: Scaffold(
        key: TransparencyConsentKeys.screen,
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.surface,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.transparencyConsentTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              Text(
                l10n.transparencyConsentSubtitle,
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
          child: role == AppRole.child
              ? _ConsentBody(
                  l10n: l10n,
                  colors: colors,
                  onAccept: () => _accept(context),
                )
              : AppEmptyState(
                  key: TransparencyConsentKeys.parentLean,
                  title: l10n.transparencyConsentParentLeanTitle,
                  message: l10n.transparencyConsentParentLeanMessage,
                ),
        ),
      ),
    );
  }
}

class _ConsentBody extends StatelessWidget {
  const _ConsentBody({
    required this.l10n,
    required this.colors,
    required this.onAccept,
  });

  final AppLocalizations l10n;
  final FamilyColors colors;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BannerNote(
                  key: TransparencyConsentKeys.honestyBanner,
                  variant: BannerVariant.t,
                  leading: Text(
                    '🤝',
                    style: TextStyle(fontSize: 18, color: colors.ink),
                  ),
                  message: l10n.transparencyConsentHonestyBanner,
                ),
                const SizedBox(height: 12),
                AppCard(
                  key: TransparencyConsentKeys.sharedCard,
                  title: l10n.transparencyConsentSharedTitle,
                  child: Column(
                    children: [
                      RowTile(
                        leading: Text(
                          '📍',
                          style: TextStyle(fontSize: 20, color: colors.ink),
                        ),
                        title: l10n.transparencyConsentSharedLocationTitle,
                        subtitle: l10n.transparencyConsentSharedLocationBody,
                        showDivider: true,
                      ),
                      RowTile(
                        leading: Text(
                          '⏱',
                          style: TextStyle(fontSize: 20, color: colors.ink),
                        ),
                        title: l10n.transparencyConsentSharedScreenTimeTitle,
                        subtitle: l10n.transparencyConsentSharedScreenTimeBody,
                        showDivider: true,
                      ),
                      RowTile(
                        leading: Text(
                          '🔋',
                          style: TextStyle(fontSize: 20, color: colors.ink),
                        ),
                        title: l10n.transparencyConsentSharedBatteryTitle,
                        subtitle: l10n.transparencyConsentSharedBatteryBody,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  key: TransparencyConsentKeys.neverCard,
                  title: l10n.transparencyConsentNeverTitle,
                  child: Column(
                    children: [
                      RowTile(
                        leading: Text(
                          '💬',
                          style: TextStyle(fontSize: 20, color: colors.ink),
                        ),
                        title: l10n.transparencyConsentNeverMessagesTitle,
                        subtitle: l10n.transparencyConsentNeverMessagesBody,
                        showDivider: true,
                      ),
                      RowTile(
                        leading: Text(
                          '📷',
                          style: TextStyle(fontSize: 20, color: colors.ink),
                        ),
                        title: l10n.transparencyConsentNeverPhotosTitle,
                        subtitle: l10n.transparencyConsentNeverPhotosBody,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  key: TransparencyConsentKeys.advisorCard,
                  title: l10n.transparencyConsentAdvisorTitle,
                  child: Text(
                    l10n.transparencyConsentAdvisorBody,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.65,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: PrimaryBtn(
            key: TransparencyConsentKeys.acceptCta,
            label: l10n.transparencyConsentAccept,
            variant: PrimaryBtnVariant.teal,
            semanticsLabel: l10n.transparencyConsentAcceptSemantics,
            onPressed: onAccept,
          ),
        ),
      ],
    );
  }
}
