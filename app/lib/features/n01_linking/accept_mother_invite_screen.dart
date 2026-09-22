import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/invite_mother_screen.dart';

/// SCR-FAT-009 — قبول دعوة الأم (bare parent onboarding, mock-first).
///
/// Wave-1: family name + inviter + granted level meaning; join.
/// Mother does not choose role — enters at [grantedLevel].
/// Parametric / Rule 23: inject names via constructor; empty → ARB
/// fallbacks («ولي الأمر» / «العائلة»), never hardcoded person names.
class AcceptMotherInviteScreen extends StatelessWidget {
  const AcceptMotherInviteScreen({
    super.key,
    this.inviterName = '',
    this.familyName = '',
    this.inviteeFirstName = '',
    this.grantedLevel = MotherInviteLevel.partner,
    this.roleController,
    this.onAccept,
    this.onDecline,
  });

  /// Inviter display name (e.g. father). Empty → ARB fallback.
  final String inviterName;

  /// Family display name. Empty → ARB fallback.
  final String familyName;

  /// Optional invitee first name for welcome toast only.
  final String inviteeFirstName;

  /// Level granted by father — display only; mother cannot change.
  final MotherInviteLevel grantedLevel;

  /// Optional override; when null, uses [CurrentRole.maybeNotifierOf].
  final RoleController? roleController;

  /// Test seam — when null, sets mother role, toast, `/scr-fat-028`.
  final VoidCallback? onAccept;

  /// Test seam — when null, toast + `/scr-shr-001`.
  final VoidCallback? onDecline;

  String _resolveInviter(AppLocalizations l10n) {
    final trimmed = inviterName.trim();
    return trimmed.isEmpty ? l10n.acceptMotherInviteInviterFallback : trimmed;
  }

  String _resolveFamily(AppLocalizations l10n) {
    final trimmed = familyName.trim();
    return trimmed.isEmpty ? l10n.acceptMotherInviteFamilyFallback : trimmed;
  }

  String _levelName(AppLocalizations l10n) {
    return switch (grantedLevel) {
      MotherInviteLevel.observer => l10n.inviteMotherLevelObserverTitle,
      MotherInviteLevel.partner => l10n.inviteMotherLevelPartnerTitle,
      MotherInviteLevel.full => l10n.inviteMotherLevelFullTitle,
    };
  }

  String _levelMeaning(AppLocalizations l10n) {
    return switch (grantedLevel) {
      MotherInviteLevel.observer => l10n.acceptMotherInviteLevelObserverMeaning,
      MotherInviteLevel.partner => l10n.acceptMotherInviteLevelPartnerMeaning,
      MotherInviteLevel.full => l10n.acceptMotherInviteLevelFullMeaning,
    };
  }

  void _accept(BuildContext context) {
    if (onAccept != null) {
      onAccept!();
      return;
    }

    final l10n = AppLocalizations.of(context);
    final levelName = _levelName(l10n);
    final notifier = roleController ?? CurrentRole.maybeNotifierOf(context);
    if (notifier != null) {
      notifier.value = AppRole.mother;
    }

    final invitee = inviteeFirstName.trim();
    final message = invitee.isEmpty
        ? l10n.acceptMotherInviteWelcomeToastGeneric(levelName)
        : l10n.acceptMotherInviteWelcomeToast(invitee, levelName);
    AppToast.show(context, message: message);
    context.go('/scr-fat-028');
  }

  void _decline(BuildContext context) {
    if (onDecline != null) {
      onDecline!();
      return;
    }

    final l10n = AppLocalizations.of(context);
    final inviter = _resolveInviter(l10n);
    AppToast.show(
      context,
      message: l10n.acceptMotherInviteDeclineToast(inviter),
    );
    context.go('/scr-shr-001');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final inviter = _resolveInviter(l10n);
    final family = _resolveFamily(l10n);
    final levelName = _levelName(l10n);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.acceptMotherInviteTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.acceptMotherInviteSubtitle,
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
            const SizedBox(height: 8),
            Semantics(
              label: l10n.acceptMotherInviteHeartSemantics,
              child: Text(
                l10n.acceptMotherInviteHeart,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 50),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                key: const Key('accept_mother_invite_headline'),
                l10n.acceptMotherInviteHeadline(inviter, family),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              key: const Key('accept_mother_invite_card'),
              child: Column(
                children: [
                  RowTile(
                    key: const Key('accept_mother_invite_level_row'),
                    leading: Text(
                      l10n.acceptMotherInviteLevelEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    title: l10n.acceptMotherInviteLevelTitle(levelName),
                    subtitle: _levelMeaning(l10n),
                  ),
                  RowTile(
                    key: const Key('accept_mother_invite_rights_row'),
                    leading: Text(
                      l10n.acceptMotherInviteRightsEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    title: l10n.acceptMotherInviteRightsTitle,
                    subtitle: l10n.acceptMotherInviteRightsSubtitle,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryBtn(
              key: const Key('accept_mother_invite_accept'),
              label: l10n.acceptMotherInviteAccept,
              onPressed: () => _accept(context),
            ),
            const SizedBox(height: 8),
            PrimaryBtn(
              key: const Key('accept_mother_invite_decline'),
              label: l10n.acceptMotherInviteDecline,
              variant: PrimaryBtnVariant.ghost,
              onPressed: () => _decline(context),
            ),
          ],
        ),
      ),
    );
  }
}
