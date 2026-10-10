import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_invite_code_source.dart';
import 'package:family_os/foundation_gate/family_invite_code_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// SCR-FAT-009 — الانضمام برمز الدعوة (قرار المالك 2026-10-10).
///
/// The invitee — signed in with their own account — types the code the guardian shared.
/// The server checks it, creates an active membership bound to this verified account, and
/// only then does the screen say "you joined". Nothing is recorded on the phone first: the
/// phone-local acceptance this screen used before is no longer on the real journey.
///
/// The role shown afterwards is the server's (`co_guardian` → mother view); the invitee does
/// not choose it.
class AcceptMotherInviteScreen extends StatefulWidget {
  const AcceptMotherInviteScreen({
    super.key,
    this.inviteCodes,
    this.roleController,
    this.onJoined,
    this.onDecline,
  });

  /// Test seam. When null, the screen uses [AppScope]'s invite-code source.
  final FamilyInviteCodeSource? inviteCodes;

  /// Optional override; when null, uses [CurrentRole.maybeNotifierOf].
  final RoleController? roleController;

  /// Test seam — when null, a confirmed join shows a toast and goes to `/scr-fat-028`.
  final ValueChanged<InviteCodeRedeemResult>? onJoined;

  /// Test seam — when null, goes back to `/scr-shr-001`.
  final VoidCallback? onDecline;

  @override
  State<AcceptMotherInviteScreen> createState() =>
      _AcceptMotherInviteScreenState();
}

class _AcceptMotherInviteScreenState extends State<AcceptMotherInviteScreen> {
  final _codeController = TextEditingController();
  InviteCodeFailure? _failure;
  bool _formatError = false;
  bool _busy = false;
  String? _idempotencyKey;
  String? _submittedCode;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _codeController
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {
    _formatError = false;
  });

  bool get _canSubmit => _codeController.text.trim().isNotEmpty && !_busy;

  Future<void> _join() async {
    if (!_canSubmit) return;
    final normalized = FamilyInviteCodeApiClient.normalizeCode(
      _codeController.text,
    );
    if (normalized == null) {
      setState(() {
        _formatError = true;
        _failure = null;
      });
      return;
    }
    final source = widget.inviteCodes ?? AppScope.maybeOf(context)?.inviteCodes;
    if (source == null) {
      setState(() => _failure = InviteCodeFailure.unavailable);
      return;
    }
    // A retry of the same code reuses its key, so a dropped connection after the server
    // committed replays the same membership instead of reporting a spent code.
    if (_idempotencyKey == null || _submittedCode != normalized) {
      _idempotencyKey = newFoundationGateIdempotencyKey();
      _submittedCode = normalized;
    }
    setState(() {
      _busy = true;
      _failure = null;
      _formatError = false;
    });
    final result = await source.redeem(
      code: normalized,
      idempotencyKey: _idempotencyKey!,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = result.failure;
    });
    if (!result.isJoined) return;

    if (widget.onJoined != null) {
      widget.onJoined!(result);
      return;
    }
    final notifier =
        widget.roleController ?? CurrentRole.maybeNotifierOf(context);
    if (notifier != null) {
      notifier.value = result.role == 'child' ? AppRole.child : AppRole.mother;
    }
    AppToast.show(
      context,
      message: AppLocalizations.of(
        context,
      ).joinCodeJoined(result.familyDisplayName ?? ''),
    );
    context.go('/scr-fat-028');
  }

  void _decline() {
    if (widget.onDecline != null) {
      widget.onDecline!();
      return;
    }
    context.go('/scr-shr-001');
  }

  String _failureText(AppLocalizations l10n, InviteCodeFailure failure) {
    return switch (failure) {
      InviteCodeFailure.notRedeemable => l10n.joinCodeErrorNotRedeemable,
      InviteCodeFailure.alreadyMember => l10n.joinCodeErrorAlreadyMember,
      InviteCodeFailure.rateLimited => l10n.joinCodeErrorRateLimited,
      InviteCodeFailure.invalidInput => l10n.joinCodeErrorFormat,
      InviteCodeFailure.sessionInvalid ||
      InviteCodeFailure.accessDenied => l10n.joinCodeErrorSignIn,
      InviteCodeFailure.networkUnavailable => l10n.inviteCodeErrorNetwork,
      InviteCodeFailure.serviceUnavailable ||
      InviteCodeFailure.limitReached => l10n.inviteCodeErrorService,
      InviteCodeFailure.unavailable => l10n.inviteCodeErrorUnavailable,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final failure = _failure;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.input),
      borderSide: BorderSide(color: colors.border, width: 1.5),
    );

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
            Text(
              key: const Key('join_code_intro'),
              l10n.joinCodeIntro,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.joinCodeFieldLabel,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              textField: true,
              label: l10n.joinCodeFieldLabel,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  key: const Key('join_code_field'),
                  controller: _codeController,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _join(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: colors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.joinCodeFieldHint,
                    hintStyle: TextStyle(
                      color: colors.ink2.withValues(alpha: 0.45),
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    border: border,
                    enabledBorder: border,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radii.input),
                      borderSide: BorderSide(color: colors.p400, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            if (_formatError || failure != null) ...[
              const SizedBox(height: 10),
              BannerNote(
                key: Key(
                  _formatError
                      ? 'join_code_error_format'
                      : 'join_code_error_${failure!.name}',
                ),
                variant: BannerVariant.a,
                message: _formatError
                    ? l10n.joinCodeErrorFormat
                    : _failureText(l10n, failure!),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryBtn(
              key: const Key('join_code_submit'),
              label: _busy ? l10n.joinCodeJoining : l10n.joinCodeSubmit,
              onPressed: _canSubmit ? _join : null,
            ),
            const SizedBox(height: 8),
            PrimaryBtn(
              key: const Key('accept_mother_invite_decline'),
              label: l10n.acceptMotherInviteDecline,
              variant: PrimaryBtnVariant.ghost,
              onPressed: _decline,
            ),
          ],
        ),
      ),
    );
  }
}
