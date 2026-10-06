import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/progress_bar.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/foundation_gate/onboarding_copy.dart';
import 'package:family_os/features/shared_onboarding/onboarding_form.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/foundation_gate/main_app_foundation_runtime.dart';

export 'package:family_os/features/shared_onboarding/onboarding_form.dart'
    show PasswordStrength, passwordStrength, passwordStrengthValue;

/// Widget keys for SCR-SHR-002.
abstract final class CreateAccountKeys {
  static const email = Key('create_account_email');
  static const password = Key('create_account_password');
  static const confirm = Key('create_account_confirm');
  static const terms = Key('create_account_terms');
  static const submit = Key('create_account_submit');
  static const strengthBar = Key('create_account_strength_bar');
  static const strengthLabel = Key('create_account_strength_label');
  static const notice = Key('create_account_notice');
  static const noticeAction = Key('create_account_notice_action');
  static const signInLink = Key('create_account_sign_in');
}

/// SCR-SHR-002 — create the guardian account with the real identity provider.
///
/// Validation is inline and live (after a field has been touched); failures
/// from the provider are shown in a persistent notice. "E-mail already in
/// use" offers a one-tap hand-off to sign-in with the e-mail pre-filled.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

enum _NoticeKind { none, failure, emailInUse, discoveryFailed, unconfigured }

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _scroll = ScrollController();

  var _emailTouched = false;
  var _passwordTouched = false;
  var _confirmTouched = false;
  var _termsTouched = false;
  var _agreed = false;
  var _obscurePassword = true;
  var _obscureConfirm = true;
  var _submitting = false;
  var _notice = _NoticeKind.none;
  FoundationGateIdentityFailure? _failure;

  @override
  void initState() {
    super.initState();
    for (final c in [_email, _password, _confirm]) {
      c.addListener(_onChanged);
    }
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus && _password.text.isNotEmpty) {
        setState(() => _passwordTouched = true);
      }
    });
    _confirmFocus.addListener(() {
      if (!_confirmFocus.hasFocus && _confirm.text.isNotEmpty) {
        setState(() => _confirmTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  MainAppFoundationIdentitySource? _remoteIdentity(BuildContext context) {
    final identity = AppScope.maybeOf(context)?.identity;
    return identity is MainAppFoundationIdentitySource ? identity : null;
  }

  // ── Validation (pure; `touched` only gates display) ──

  String? _emailProblem(OnboardingCopy copy) {
    final value = _email.text.trim();
    if (value.isEmpty) return copy.emailRequired;
    if (!looksLikeEmail(value)) return copy.emailInvalid;
    return null;
  }

  String? _passwordProblem(OnboardingCopy copy) {
    final value = _password.text;
    if (value.isEmpty) return copy.passwordRequired;
    if (value.length < 8) return copy.passwordTooShort;
    final hasLetter = RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(value);
    final hasDigit = RegExp(r'[0-9\u0660-\u0669]').hasMatch(value);
    if (!hasLetter || !hasDigit) return copy.passwordNeedsLetterAndDigit;
    return null;
  }

  String? _confirmProblem(OnboardingCopy copy) {
    final value = _confirm.text;
    if (value.isEmpty) return copy.confirmRequired;
    if (value != _password.text) return copy.confirmMismatch;
    return null;
  }

  bool _formValid(OnboardingCopy copy) =>
      _emailProblem(copy) == null &&
      _passwordProblem(copy) == null &&
      _confirmProblem(copy) == null &&
      _agreed;

  // ── Actions ──

  Future<void> _submit() async {
    if (_submitting) return;
    final copy = OnboardingCopy.of(context);
    final remote = _remoteIdentity(context);
    if (remote == null) {
      setState(() => _notice = _NoticeKind.unconfigured);
      revealOnboardingNotice(_scroll);
      return;
    }
    setState(() {
      _emailTouched = true;
      _passwordTouched = true;
      _confirmTouched = true;
      _termsTouched = true;
    });
    if (!_formValid(copy)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _notice = _NoticeKind.none;
      _failure = null;
    });
    try {
      await remote.signUp(email: _email.text.trim(), password: _password.text);
      if (!mounted) return;
      // signUp() reports provider failures through the session phase; it
      // does not throw. Never advance on a failed sign-up.
      switch (remote.phase) {
        case FoundationGatePhase.signInFailed:
          final failure = remote.lastIdentityFailure;
          setState(() {
            _failure = failure;
            _notice = failure == FoundationGateIdentityFailure.emailAlreadyInUse
                ? _NoticeKind.emailInUse
                : _NoticeKind.failure;
          });
        case FoundationGatePhase.sessionInvalid:
          setState(() {
            _failure = FoundationGateIdentityFailure.noSession;
            _notice = _NoticeKind.failure;
          });
          revealOnboardingNotice(_scroll);
        case FoundationGatePhase.accessDenied:
        case FoundationGatePhase.rosterAccessDenied:
          setState(() {
            _failure = FoundationGateIdentityFailure.unknown;
            _notice = _NoticeKind.failure;
          });
          revealOnboardingNotice(_scroll);
        case FoundationGatePhase.serviceUnavailable:
        case FoundationGatePhase.networkUnavailable:
          // The provider account exists and the user is signed in; only
          // family discovery failed. Staying here would make the natural
          // retry hit "e-mail already in use", so continue — the next screen
          // owns an honest retry against the family server.
          if (remote.hasAuthenticatedPrincipal) {
            TextInput.finishAutofillContext();
            context.go('/scr-shr-007');
          } else {
            setState(() {
              _failure = FoundationGateIdentityFailure.networkUnavailable;
              _notice = _NoticeKind.failure;
            });
            revealOnboardingNotice(_scroll);
          }
        case FoundationGatePhase.noActiveFamily:
        case FoundationGatePhase.familiesAvailable:
        case FoundationGatePhase.childrenAvailable:
        case FoundationGatePhase.noChildren:
          TextInput.finishAutofillContext();
          context.go('/scr-shr-007');
        case FoundationGatePhase.unconfigured:
        case FoundationGatePhase.signedOut:
        case FoundationGatePhase.signingIn:
        case FoundationGatePhase.loadingFamilies:
        case FoundationGatePhase.loadingRoster:
          setState(() {
            _failure = FoundationGateIdentityFailure.unknown;
            _notice = _NoticeKind.failure;
          });
          revealOnboardingNotice(_scroll);
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _failure = FoundationGateIdentityFailure.unknown;
        _notice = _NoticeKind.failure;
      });
      revealOnboardingNotice(_scroll);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goSignIn({bool carryEmail = false}) {
    final email = _email.text.trim();
    if (carryEmail && email.isNotEmpty) {
      context.go('/scr-shr-003?email=${Uri.encodeQueryComponent(email)}');
    } else {
      context.go('/scr-shr-003');
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final copy = OnboardingCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final configured = _remoteIdentity(context) != null;
    final busy = _submitting;
    final strength = passwordStrength(_password.text);

    return OnboardingScaffold(
      controller: _scroll,
      autofill: true,
      children: [
        OnboardingHeader(
          icon: Icons.person_add_alt_1_outlined,
          title: copy.signUpTitle,
          subtitle: copy.signUpSubtitle,
        ),
        if (!configured)
          OnboardingNotice(
            key: CreateAccountKeys.notice,
            tone: OnboardingNoticeTone.warning,
            title: copy.notConfiguredTitle,
            message: copy.notConfiguredMessage,
          )
        else
          ..._noticeFor(copy),
        OnboardingTextField(
          fieldKey: CreateAccountKeys.email,
          label: copy.signInEmailLabel,
          controller: _email,
          hint: 'name@example.com',
          enabled: configured && !busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: _emailTouched ? _emailProblem(copy) : null,
          onChanged: (_) {
            // Reveal validation as soon as the address becomes valid or the
            // user clearly finished typing a domain; never on the first key.
            if (!_emailTouched && _email.text.contains('.')) {
              _emailTouched = true;
            }
          },
          onSubmitted: (_) {
            setState(() => _emailTouched = true);
            _passwordFocus.requestFocus();
          },
        ),
        OnboardingTextField(
          fieldKey: CreateAccountKeys.password,
          label: copy.signInPasswordLabel,
          controller: _password,
          focusNode: _passwordFocus,
          enabled: configured && !busy,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          helperText: copy.strengthHint,
          errorText: _passwordTouched ? _passwordProblem(copy) : null,
          onChanged: (_) {
            if (!_passwordTouched && _password.text.length >= 8) {
              _passwordTouched = true;
            }
          },
          onSubmitted: (_) {
            setState(() => _passwordTouched = true);
            _confirmFocus.requestFocus();
          },
          suffix: PasswordVisibilityToggle(
            obscured: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            showLabel: copy.showPassword,
            hideLabel: copy.hidePassword,
          ),
        ),
        // Always laid out (fixed slot) so the list never reflows while the
        // user is typing; it only fills in as the password grows.
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                child: ProgressBar(
                  key: CreateAccountKeys.strengthBar,
                  value: passwordStrengthValue(strength),
                  height: 6,
                  fillColor: _strengthColor(colors, strength),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 64,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _strengthLabel(copy, strength),
                    key: CreateAccountKeys.strengthLabel,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _strengthColor(colors, strength),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        OnboardingTextField(
          fieldKey: CreateAccountKeys.confirm,
          label: copy.signUpConfirmLabel,
          controller: _confirm,
          focusNode: _confirmFocus,
          enabled: configured && !busy,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _confirmTouched ? _confirmProblem(copy) : null,
          onChanged: (_) {
            if (!_confirmTouched &&
                _confirm.text.length >= _password.text.length) {
              _confirmTouched = true;
            }
          },
          onSubmitted: (_) => _submit(),
          suffix: PasswordVisibilityToggle(
            obscured: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            showLabel: copy.showPassword,
            hideLabel: copy.hidePassword,
          ),
        ),
        _TermsRow(
          key: CreateAccountKeys.terms,
          value: _agreed,
          enabled: configured && !busy,
          label: copy.termsLabel,
          errorText: _termsTouched && !_agreed ? copy.termsRequired : null,
          onChanged: (v) => setState(() {
            _agreed = v;
            _termsTouched = true;
          }),
        ),
        const SizedBox(height: 6),
        OnboardingSubmitButton(
          label: copy.signUpSubmit,
          busyLabel: copy.creatingAccount,
          busy: busy,
          onPressed: configured ? _submit : null,
          buttonKey: CreateAccountKeys.submit,
        ),
        const SizedBox(height: 18),
        OnboardingFooterLink(
          prompt: copy.haveAccountPrompt,
          linkLabel: copy.signInLink,
          linkKey: CreateAccountKeys.signInLink,
          onTap: () => _goSignIn(),
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
            key: CreateAccountKeys.notice,
            tone: OnboardingNoticeTone.warning,
            title: copy.notConfiguredTitle,
            message: copy.notConfiguredMessage,
          ),
        ];
      case _NoticeKind.emailInUse:
        return [
          OnboardingNotice(
            key: CreateAccountKeys.notice,
            tone: OnboardingNoticeTone.info,
            title: copy.emailInUseTitle,
            message: copy.emailInUseMessage,
            actionLabel: copy.emailInUseAction,
            actionKey: CreateAccountKeys.noticeAction,
            onAction: () => _goSignIn(carryEmail: true),
          ),
        ];
      case _NoticeKind.discoveryFailed:
      case _NoticeKind.failure:
        return [
          OnboardingNotice(
            key: CreateAccountKeys.notice,
            tone: OnboardingNoticeTone.error,
            title: copy.identityFailure(_failure),
          ),
        ];
    }
  }

  Color _strengthColor(FamilyColors colors, PasswordStrength s) => switch (s) {
    PasswordStrength.empty => colors.border,
    PasswordStrength.weak => colors.coral,
    PasswordStrength.fair => colors.amber,
    PasswordStrength.good => colors.p400,
    PasswordStrength.strong => colors.mintInk,
  };

  String _strengthLabel(OnboardingCopy copy, PasswordStrength s) => switch (s) {
    PasswordStrength.empty => '',
    PasswordStrength.weak => copy.strengthWeak,
    PasswordStrength.fair => copy.strengthFair,
    PasswordStrength.good => copy.strengthGood,
    PasswordStrength.strong => copy.strengthStrong,
  };
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    super.key,
    required this.value,
    required this.enabled,
    required this.label,
    required this.onChanged,
    this.errorText,
  });

  final bool value;
  final bool enabled;
  final String label;
  final String? errorText;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          checked: value,
          label: label,
          child: InkWell(
            onTap: enabled ? () => onChanged(!value) : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: value,
                      onChanged: enabled ? (v) => onChanged(v ?? false) : null,
                      activeColor: colors.p500,
                      side: BorderSide(
                        color: errorText != null ? colors.coral : colors.ink2,
                        width: 1.6,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 38, bottom: 6),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.coral,
              ),
            ),
          ),
      ],
    );
  }
}
