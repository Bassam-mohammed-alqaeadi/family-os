import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Widget keys for SCR-CHD-001 acceptance.
abstract final class ChildWelcomeKeys {
  static const screen = Key('child_welcome_screen');
  static const hero = Key('child_welcome_hero');
  static const continueCta = Key('child_welcome_continue');
  static const parentLean = Key('child_welcome_parent_lean');
}

/// SCR-CHD-001 — ترحيب الابن (bare child onboarding, mock-first).
///
/// Prototype CHD-001 · age-neutral (SHR-007 spirit) · no surveillance copy ·
/// RoleGuard child · CTA → CHD-002 · Rule 12/23 · no SOS on this bare welcome.
class ChildWelcomeScreen extends StatelessWidget {
  const ChildWelcomeScreen({
    super.key,
    this.roleOverride,
    this.onContinue,
  });

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Test seam — when null, navigates to `/scr-chd-002`.
  final VoidCallback? onContinue;

  AppRole _role(BuildContext context) =>
      roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.child;

  void _continue(BuildContext context) {
    final notifier = CurrentRole.maybeNotifierOf(context);
    if (notifier != null && notifier.value != AppRole.child) {
      notifier.value = AppRole.child;
    }
    if (onContinue != null) {
      onContinue!();
      return;
    }
    context.go('/scr-chd-002');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final role = _role(context);

    return Scaffold(
      key: ChildWelcomeKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.childWelcomeTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.childWelcomeSubtitle,
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
            ? _WelcomeBody(
                l10n: l10n,
                colors: colors,
                onContinue: () => _continue(context),
              )
            : AppEmptyState(
                key: ChildWelcomeKeys.parentLean,
                title: l10n.childWelcomeParentLeanTitle,
                message: l10n.childWelcomeParentLeanMessage,
              ),
      ),
    );
  }
}

class _WelcomeBody extends StatelessWidget {
  const _WelcomeBody({
    required this.l10n,
    required this.colors,
    required this.onContinue,
  });

  final AppLocalizations l10n;
  final FamilyColors colors;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: l10n.childWelcomeHeroSemantics,
                  child: Text(
                    key: ChildWelcomeKeys.hero,
                    l10n.childWelcomeHeroEmoji,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 70, color: colors.ink),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.childWelcomeHeadline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l10n.childWelcomeBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PrimaryBtn(
            key: ChildWelcomeKeys.continueCta,
            label: l10n.childWelcomeContinue,
            variant: PrimaryBtnVariant.teal,
            semanticsLabel: l10n.childWelcomeContinueSemantics,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
