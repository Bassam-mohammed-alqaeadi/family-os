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

/// SCR-CHD-001 — a colorful, age-neutral child welcome.
class ChildWelcomeScreen extends StatelessWidget {
  const ChildWelcomeScreen({super.key, this.roleOverride, this.onContinue});

  final AppRole? roleOverride;
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
    if (onContinue case final callback?) {
      callback();
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
      backgroundColor: colors.childBg,
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colors.childBg, colors.teal100, colors.p50],
          ),
        ),
        child: SafeArea(
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
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(radii.card + 10),
                    border: Border.all(color: colors.teal),
                    boxShadow: [shadows.shCard],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        label: l10n.childWelcomeHeroSemantics,
                        child: SizedBox(
                          width: 180,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 142,
                                height: 142,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colors.teal100, colors.p100],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                key: ChildWelcomeKeys.hero,
                                l10n.childWelcomeHeroEmoji,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 76,
                                  color: colors.ink,
                                ),
                              ),
                              PositionedDirectional(
                                top: 4,
                                start: 4,
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: colors.amber,
                                  size: 28,
                                ),
                              ),
                              PositionedDirectional(
                                end: 0,
                                bottom: 7,
                                child: Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: colors.coral,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.surface,
                                      width: 4,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.rocket_launch_rounded,
                                    color: colors.surface,
                                    size: 23,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.childWelcomeHeadline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          color: colors.ink,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.childWelcomeBody,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
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
