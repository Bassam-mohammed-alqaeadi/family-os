import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/foundation_gate/onboarding_copy.dart';
import 'package:family_os/features/shared_onboarding/onboarding_form.dart';
import 'package:family_os/foundation_gate/foundation_gate_copy.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/foundation_gate/main_app_foundation_runtime.dart';

/// Widget keys for SCR-SHR-003.
abstract final class LoginKeys {
  static const email = Key('login_email');
  static const password = Key('login_password');
  static const submit = Key('login_submit');
  static const forgot = Key('login_forgot');
  static const createAccount = Key('login_create_account');
  static const notice = Key('login_notice');
  static const noticeAction = Key('login_notice_action');
  static const resetSheet = Key('login_reset_sheet');
  static const resetEmail = Key('login_reset_email');
  static const resetSend = Key('login_reset_send');
  static const resetDone = Key('login_reset_done');
}

/// SCR-SHR-003 — sign in with the real identity provider.
///
/// Every control on this screen performs a real action:
/// * e-mail + password → Firebase sign-in → family discovery → routing;
/// * "Forgot your password?" → provider password-reset e-mail;
/// * "Create an account" → SCR-SHR-002.
///
/// Without a configured [MainAppFoundationIdentitySource] the form is shown
/// disabled with an honest notice; it never simulates a session.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail});

  /// Pre-filled e-mail (e.g. coming from sign-up's "already registered").
  final String? initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _NoticeKind { none, failure, discoveryFailed, chooseFamily, unconfigured }

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  final _scroll = ScrollController();

  var _emailTouched = false;
  var _passwordTouched = false;
  var _obscure = true;
  var _submitting = false;
  var _notice = _NoticeKind.none;
  FoundationGateIdentityFailure? _failure;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail?.trim() ?? '');
    _email.addListener(_onChanged);
    _password.addListener(_onChanged);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  MainAppFoundationIdentitySource? _remoteIdentity(BuildContext context) {
    final identity = AppScope.maybeOf(context)?.identity;
    return identity is MainAppFoundationIdentitySource ? identity : null;
  }

  // ── Validation ──

  String? _emailError(OnboardingCopy copy) {
    if (!_emailTouched) return null;
    final value = _email.text.trim();
    if (value.isEmpty) return copy.emailRequired;
    if (!looksLikeEmail(value)) return copy.emailInvalid;
    return null;
  }

  String? _passwordError(OnboardingCopy copy) {
    if (!_passwordTouched) return null;
    if (_password.text.isEmpty) return copy.passwordRequired;
    return null;
  }

  bool get _formValid =>
      looksLikeEmail(_email.text) && _password.text.isNotEmpty;

  // ── Actions ──

  Future<void> _submit() async {
    if (_submitting) return;
    final remote = _remoteIdentity(context);
    if (remote == null) {
      setState(() => _notice = _NoticeKind.unconfigured);
      revealOnboardingNotice(_scroll);
      return;
    }
    setState(() {
      _emailTouched = true;
      _passwordTouched = true;
    });
    if (!_formValid) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _notice = _NoticeKind.none;
      _failure = null;
    });
    try {
      final snapshot = await remote.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      _routeAfterSignIn(remote, snapshot);
    } on Object {
      if (!mounted) return;
      setState(() {
        _notice = _NoticeKind.failure;
        _failure = FoundationGateIdentityFailure.unknown;
      });
      revealOnboardingNotice(_scroll);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _routeAfterSignIn(
    MainAppFoundationIdentitySource remote,
    IdentitySnapshot snapshot,
  ) {
    if (snapshot.isRemoteAuthoritative) {
      TextInput.finishAutofillContext();
      context.go('/scr-fat-012');
      return;
    }
    if (remote.needsFamilyCreation) {
      // Authenticated, zero families: the normal path for a new guardian.
      TextInput.finishAutofillContext();
      context.go('/scr-shr-007');
      return;
    }
    if (remote.needsFamilySelection) {
      setState(() => _notice = _NoticeKind.chooseFamily);
      revealOnboardingNotice(_scroll);
      return;
    }
    switch (remote.phase) {
      case FoundationGatePhase.serviceUnavailable:
      case FoundationGatePhase.networkUnavailable:
        if (remote.hasAuthenticatedPrincipal) {
          setState(() => _notice = _NoticeKind.discoveryFailed);
          revealOnboardingNotice(_scroll);
          return;
        }
        setState(() {
          _notice = _NoticeKind.failure;
          _failure = FoundationGateIdentityFailure.networkUnavailable;
        });
        revealOnboardingNotice(_scroll);
      case FoundationGatePhase.sessionInvalid:
        setState(() {
          _notice = _NoticeKind.failure;
          _failure = FoundationGateIdentityFailure.noSession;
        });
        revealOnboardingNotice(_scroll);
      case FoundationGatePhase.signInFailed:
        setState(() {
          _notice = _NoticeKind.failure;
          _failure =
              remote.lastIdentityFailure ??
              FoundationGateIdentityFailure.invalidCredentials;
        });
        revealOnboardingNotice(_scroll);
      default:
        setState(() {
          _notice = _NoticeKind.failure;
          _failure = remote.lastIdentityFailure;
        });
        revealOnboardingNotice(_scroll);
    }
  }

  Future<void> _retryDiscovery() async {
    final remote = _remoteIdentity(context);
    if (remote == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final snapshot = await remote.refresh();
      if (!mounted) return;
      _routeAfterSignIn(remote, snapshot);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final remote = _remoteIdentity(context);
    if (remote == null) {
      setState(() => _notice = _NoticeKind.unconfigured);
      revealOnboardingNotice(_scroll);
      return;
    }
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _PasswordResetSheet(
        initialEmail: _email.text.trim(),
        sendReset: (email) => remote.sendPasswordReset(email: email),
      ),
    );
  }

  void _goCreateAccount() => context.go('/scr-shr-002');

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final copy = OnboardingCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final configured = _remoteIdentity(context) != null;
    final busy = _submitting;

    return OnboardingScaffold(
      controller: _scroll,
      autofill: true,
      children: [
        OnboardingHeader(
          icon: Icons.lock_person_outlined,
          title: copy.signInTitle,
          subtitle: copy.signInSubtitle,
        ),
        if (!configured)
          OnboardingNotice(
            key: LoginKeys.notice,
            tone: OnboardingNoticeTone.warning,
            title: copy.notConfiguredTitle,
            message: copy.notConfiguredMessage,
          )
        else
          ..._noticeFor(copy),
        OnboardingTextField(
          fieldKey: LoginKeys.email,
          label: copy.signInEmailLabel,
          controller: _email,
          hint: 'name@example.com',
          enabled: configured && !busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError(copy),
          onChanged: (_) {
            if (!_emailTouched && looksLikeEmail(_email.text)) {
              _emailTouched = true;
            }
          },
          onSubmitted: (_) {
            setState(() => _emailTouched = true);
            _passwordFocus.requestFocus();
          },
        ),
        OnboardingTextField(
          fieldKey: LoginKeys.password,
          label: copy.signInPasswordLabel,
          controller: _password,
          focusNode: _passwordFocus,
          enabled: configured && !busy,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          errorText: _passwordError(copy),
          onChanged: (_) {
            if (!_passwordTouched && _password.text.isNotEmpty) {
              _passwordTouched = true;
            }
          },
          onSubmitted: (_) => _submit(),
          suffix: PasswordVisibilityToggle(
            obscured: _obscure,
            onToggle: () => setState(() => _obscure = !_obscure),
            showLabel: copy.showPassword,
            hideLabel: copy.hidePassword,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            key: LoginKeys.forgot,
            onPressed: configured && !busy ? _forgotPassword : null,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              copy.forgotPassword,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.p600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        OnboardingSubmitButton(
          label: copy.signInSubmit,
          busyLabel: copy.signingIn,
          busy: busy,
          onPressed: configured ? _submit : null,
          buttonKey: LoginKeys.submit,
        ),
        const SizedBox(height: 18),
        OnboardingFooterLink(
          prompt: copy.noAccountPrompt,
          linkLabel: copy.createAccountLink,
          linkKey: LoginKeys.createAccount,
          onTap: _goCreateAccount,
        ),
      ],
    );
  }

  List<Widget> _noticeFor(OnboardingCopy copy) {
    switch (_notice) {
      case _NoticeKind.none:
        return const [];
      case _NoticeKind.unconfigured:
        return [
          OnboardingNotice(
            key: LoginKeys.notice,
            tone: OnboardingNoticeTone.warning,
            title: copy.notConfiguredTitle,
            message: copy.notConfiguredMessage,
          ),
        ];
      case _NoticeKind.failure:
        final isCredentials =
            _failure == FoundationGateIdentityFailure.invalidCredentials;
        return [
          OnboardingNotice(
            key: LoginKeys.notice,
            tone: OnboardingNoticeTone.error,
            title: copy.identityFailure(_failure),
            actionLabel: isCredentials ? copy.forgotPassword : null,
            actionKey: LoginKeys.noticeAction,
            onAction: isCredentials ? _forgotPassword : null,
          ),
        ];
      case _NoticeKind.discoveryFailed:
        return [
          OnboardingNotice(
            key: LoginKeys.notice,
            tone: OnboardingNoticeTone.warning,
            title: copy.signedInDiscoveryFailedTitle,
            message: copy.signedInDiscoveryFailedMessage,
            actionLabel: copy.tryAgain,
            actionKey: LoginKeys.noticeAction,
            onAction: _submitting ? null : _retryDiscovery,
          ),
        ];
      case _NoticeKind.chooseFamily:
        return [
          OnboardingNotice(
            key: LoginKeys.notice,
            tone: OnboardingNoticeTone.info,
            title: FoundationGateCopy.of(context).chooseFamilyHint,
          ),
        ];
    }
  }
}

/// Bottom sheet: request a password-reset e-mail from the provider.
class _PasswordResetSheet extends StatefulWidget {
  const _PasswordResetSheet({
    required this.initialEmail,
    required this.sendReset,
  });

  final String initialEmail;
  final Future<FoundationGateIdentityFailure?> Function(String email) sendReset;

  @override
  State<_PasswordResetSheet> createState() => _PasswordResetSheetState();
}

enum _ResetPhase { idle, sending, sent }

class _PasswordResetSheetState extends State<_PasswordResetSheet> {
  late final TextEditingController _email;
  var _phase = _ResetPhase.idle;
  var _touched = false;
  FoundationGateIdentityFailure? _failure;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _touched = true);
    if (!looksLikeEmail(_email.text)) return;
    setState(() {
      _phase = _ResetPhase.sending;
      _failure = null;
    });
    final failure = await widget.sendReset(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _failure = failure;
      _phase = failure == null ? _ResetPhase.sent : _ResetPhase.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = OnboardingCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sending = _phase == _ResetPhase.sending;

    return Padding(
      key: LoginKeys.resetSheet,
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.p100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _phase == _ResetPhase.sent
                      ? Icons.mark_email_read_outlined
                      : Icons.lock_reset_rounded,
                  color: colors.p600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _phase == _ResetPhase.sent
                      ? copy.resetSentTitle
                      : copy.resetTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _phase == _ResetPhase.sent
                ? copy.resetSentMessage(_email.text.trim())
                : copy.resetMessage,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 16),
          if (_phase == _ResetPhase.sent)
            OnboardingSubmitButton(
              label: copy.resetDone,
              busyLabel: copy.resetDone,
              busy: false,
              onPressed: () => Navigator.of(context).pop(),
              buttonKey: LoginKeys.resetDone,
            )
          else ...[
            if (_failure != null)
              OnboardingNotice(
                tone: OnboardingNoticeTone.error,
                title: copy.identityFailure(_failure),
              ),
            OnboardingTextField(
              fieldKey: LoginKeys.resetEmail,
              label: copy.signInEmailLabel,
              controller: _email,
              hint: 'name@example.com',
              enabled: !sending,
              autofocus: widget.initialEmail.isEmpty,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              autofillHints: const [AutofillHints.email],
              errorText: !_touched
                  ? null
                  : _email.text.trim().isEmpty
                  ? copy.emailRequired
                  : looksLikeEmail(_email.text)
                  ? null
                  : copy.emailInvalid,
              onSubmitted: (_) => _send(),
            ),
            OnboardingSubmitButton(
              label: copy.resetSend,
              busyLabel: copy.resetSending,
              busy: sending,
              onPressed: _send,
              buttonKey: LoginKeys.resetSend,
            ),
            TextButton(
              onPressed: sending ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                copy.cancel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.ink2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
