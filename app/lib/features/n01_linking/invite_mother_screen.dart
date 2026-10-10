import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_invite_code_source.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// SCR-FAT-008 — دعوة الأم، برمز يصدره الخادم (قرار المالك 2026-10-10).
///
/// The guardian asks the server for a single-use code, sees it once, copies it and shares
/// it however the family talks. The invitee redeems it from their own account on
/// SCR-FAT-009; the server binds the membership to that verified account. Nothing here is
/// stored on the phone: a code exists only because the server issued it, and the phone-local
/// invite storage this screen used before is no longer on the real journey.
///
/// The prototype's mother permission levels are not stored by the server yet, so this screen
/// does not offer a choice it cannot keep — the honesty banner says so.
class InviteMotherScreen extends StatefulWidget {
  const InviteMotherScreen({super.key, this.inviteCodes, this.onDone});

  /// Test seam. When null, the screen uses [AppScope]'s invite-code source.
  final FamilyInviteCodeSource? inviteCodes;

  /// Test seam — when null, "done" navigates to `/scr-fat-027` (family members).
  final VoidCallback? onDone;

  @override
  State<InviteMotherScreen> createState() => _InviteMotherScreenState();
}

class _InviteMotherScreenState extends State<InviteMotherScreen> {
  IssuedInviteCode? _issued;
  InviteCodeFailure? _failure;
  bool _busy = false;
  bool _revoked = false;
  String? _issueKey;

  FamilyInviteCodeSource? get _source =>
      widget.inviteCodes ?? AppScope.maybeOf(context)?.inviteCodes;

  Future<void> _issue() async {
    if (_busy) return;
    final source = _source;
    final identity = AppScope.maybeOf(context)?.identity.value;
    final familyId = identity?.familyId;
    if (source == null || familyId == null) {
      setState(() => _failure = InviteCodeFailure.unavailable);
      return;
    }
    // One key per attempt: the server never replays an issued code, so a retry after a
    // refusal must be a new request rather than a replay the server would refuse.
    _issueKey = newFoundationGateIdempotencyKey();
    setState(() {
      _busy = true;
      _failure = null;
      _revoked = false;
    });
    final result = await source.issue(
      familyId: familyId,
      role: 'co_guardian',
      idempotencyKey: _issueKey!,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _issued = result.invite;
      _failure = result.failure;
    });
  }

  Future<void> _revoke() async {
    final issued = _issued;
    final source = _source;
    final familyId = AppScope.maybeOf(context)?.identity.value.familyId;
    if (_busy || issued == null || source == null || familyId == null) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await source.revoke(
      familyId: familyId,
      inviteId: issued.inviteId,
      idempotencyKey: newFoundationGateIdempotencyKey(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.isRevoked) {
        // The code is dead on the server; the phone forgets it too.
        _issued = null;
        _revoked = true;
      } else {
        _failure = result.failure;
      }
    });
    if (result.isRevoked) {
      AppToast.show(
        context,
        message: AppLocalizations.of(context).inviteCodeRevoked,
      );
    }
  }

  Future<void> _copy() async {
    final issued = _issued;
    if (issued == null) return;
    await Clipboard.setData(ClipboardData(text: issued.code));
    if (!mounted) return;
    AppToast.show(
      context,
      message: AppLocalizations.of(context).inviteCodeCopied,
    );
  }

  void _done() {
    if (widget.onDone != null) {
      widget.onDone!();
      return;
    }
    context.go('/scr-fat-027');
  }

  String _failureText(AppLocalizations l10n, InviteCodeFailure failure) {
    return switch (failure) {
      InviteCodeFailure.limitReached => l10n.inviteCodeErrorLimit,
      InviteCodeFailure.accessDenied => l10n.inviteCodeErrorDenied,
      InviteCodeFailure.networkUnavailable => l10n.inviteCodeErrorNetwork,
      InviteCodeFailure.sessionInvalid => l10n.loginSessionExpired,
      InviteCodeFailure.serviceUnavailable ||
      InviteCodeFailure.rateLimited ||
      InviteCodeFailure.invalidInput ||
      InviteCodeFailure.notRedeemable ||
      InviteCodeFailure.alreadyMember => l10n.inviteCodeErrorService,
      InviteCodeFailure.unavailable => l10n.inviteCodeErrorUnavailable,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final issued = _issued;
    final failure = _failure;
    final localeName = Localizations.localeOf(context).toString();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.inviteMotherTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          children: [
            Text(
              key: const Key('invite_mother_intro'),
              l10n.inviteCodeIntro,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 14),
            if (issued != null)
              AppCard(
                key: const Key('invite_code_card'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.inviteCodeValueLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.ink2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: SelectableText(
                        key: const Key('invite_code_value'),
                        issued.code,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: colors.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      key: const Key('invite_code_expiry'),
                      l10n.inviteCodeExpiry(
                        DateFormat.MMMd(
                          localeName,
                        ).add_jm().format(issued.expiresAt.toLocal()),
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryBtn(
                      key: const Key('invite_code_copy'),
                      label: l10n.inviteCodeCopy,
                      onPressed: _busy ? null : _copy,
                    ),
                    const SizedBox(height: 8),
                    PrimaryBtn(
                      key: const Key('invite_code_revoke'),
                      label: l10n.inviteCodeRevoke,
                      variant: PrimaryBtnVariant.ghost,
                      onPressed: _busy ? null : _revoke,
                    ),
                  ],
                ),
              )
            else
              PrimaryBtn(
                key: const Key('invite_code_issue'),
                label: _busy ? l10n.inviteCodeIssuing : l10n.inviteCodeIssue,
                onPressed: _busy ? null : _issue,
              ),
            if (failure != null) ...[
              const SizedBox(height: 10),
              BannerNote(
                key: Key('invite_code_error_${failure.name}'),
                variant: BannerVariant.a,
                message: _failureText(l10n, failure),
              ),
            ],
            if (_revoked) ...[
              const SizedBox(height: 10),
              Text(
                key: const Key('invite_code_revoked'),
                l10n.inviteCodeRevoked,
                style: TextStyle(fontSize: 12.5, color: colors.ink2),
              ),
            ],
            const SizedBox(height: 14),
            BannerNote(
              key: const Key('invite_code_honesty'),
              variant: BannerVariant.t,
              message: l10n.inviteCodeHonesty,
            ),
            const SizedBox(height: 16),
            PrimaryBtn(
              key: const Key('invite_code_done'),
              label: l10n.inviteCodeDone,
              variant: PrimaryBtnVariant.ghost,
              onPressed: _done,
            ),
          ],
        ),
      ),
    );
  }
}
