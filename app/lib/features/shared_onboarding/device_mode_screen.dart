import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// SCR-SHR-007 — اختيار الوضع (شاشة عمر محايدة).
///
/// Two visually equal cards only. No mother option (security / Play age-neutral).
/// Guardian → `/scr-fat-001` without setting child role.
/// Child → [AppRole.child] then `/scr-chd-001`.
class DeviceModeScreen extends StatelessWidget {
  const DeviceModeScreen({
    super.key,
    this.onGuardian,
    this.onChild,
  });

  /// Test seam — when null, navigates to `/scr-fat-001` (role unchanged).
  final VoidCallback? onGuardian;

  /// Test seam — when null, sets child role then `/scr-chd-001`.
  final VoidCallback? onChild;

  void _pickGuardian(BuildContext context) {
    if (onGuardian != null) {
      onGuardian!();
      return;
    }
    // Do not set child role — leave CurrentRole as-is (typically father).
    context.go('/scr-fat-001');
  }

  void _pickChild(BuildContext context) {
    if (onChild != null) {
      onChild!();
      return;
    }
    final notifier = CurrentRole.maybeNotifierOf(context);
    if (notifier != null) {
      notifier.value = AppRole.child;
    }
    context.go('/scr-chd-001');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deviceModeTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.deviceModeSubtitle,
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
              label: l10n.deviceModeIntro,
              child: Text(
                l10n.deviceModeIntro,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.7,
                  color: colors.ink2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ModeChoiceCard(
              key: const Key('device_mode_guardian'),
              emoji: l10n.deviceModeGuardianEmoji,
              title: l10n.deviceModeGuardianTitle,
              body: l10n.deviceModeGuardianBody,
              semanticsLabel: l10n.deviceModeGuardianSemantics,
              onTap: () => _pickGuardian(context),
            ),
            const SizedBox(height: 12),
            _ModeChoiceCard(
              key: const Key('device_mode_child'),
              emoji: l10n.deviceModeChildEmoji,
              title: l10n.deviceModeChildTitle,
              body: l10n.deviceModeChildBody,
              semanticsLabel: l10n.deviceModeChildSemantics,
              onTap: () => _pickChild(context),
            ),
            const SizedBox(height: 16),
            BannerNote(
              key: const Key('device_mode_no_mother_banner'),
              variant: BannerVariant.p,
              leading: Text(
                l10n.deviceModeBannerLeading,
                style: TextStyle(fontSize: 14, color: colors.p700),
              ),
              message: l10n.deviceModeNoMotherBanner,
            ),
          ],
        ),
      ),
    );
  }
}

/// Equal visual card — same 2px border + padding for both choices (Play age-neutral).
class _ModeChoiceCard extends StatelessWidget {
  const _ModeChoiceCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.body,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String body;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.card),
          child: Ink(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border, width: 2),
              boxShadow: [shadows.shCard],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.6,
                            color: colors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
