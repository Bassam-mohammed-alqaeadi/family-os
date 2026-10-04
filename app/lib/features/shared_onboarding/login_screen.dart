import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/foundation_gate/foundation_gate_copy.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/foundation_gate/main_app_foundation_runtime.dart';

/// Widget keys for SCR-SHR-003.
abstract final class LoginKeys {
  static const honesty = Key('login_local_honesty');
  static const emailError = Key('login_email_error');
  static const passwordError = Key('login_password_error');
}

/// SCR-SHR-003 — تسجيل الدخول (bare shared onboarding, mock-first).
///
/// No real auth / biometrics. Login → `/scr-fat-010` (placeholder OK).
/// Fingerprint is NATIVE_CLOSED: the button explains it is not available yet
/// and never signs in or navigates.
/// Forgot password opens local recovery with honest (no email-sent) copy.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onLoginSuccess, this.onInvite});

  /// Test seam — when null, navigates to `/scr-fat-010`.
  final VoidCallback? onLoginSuccess;

  /// Test seam — when null, navigates to `/scr-fat-009`.
  final VoidCallback? onInvite;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _emailError = false;
  var _passwordError = false;
  var _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final emailOk = _emailController.text.trim().isNotEmpty;
    final passwordOk = _passwordController.text.isNotEmpty;
    setState(() {
      _emailError = !emailOk;
      _passwordError = !passwordOk;
    });
    return emailOk && passwordOk;
  }

  Future<void> _login() async {
    if (!_validate() || _submitting) {
      if (!_submitting) {
        AppToast.show(
          context,
          message: AppLocalizations.of(context).loginFieldsRequired,
        );
      }
      return;
    }
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
      return;
    }

    final appRuntime = AppScope.maybeOf(context);
    if (appRuntime != null) {
      final remoteIdentity = appRuntime.identity;
      if (remoteIdentity is! MainAppFoundationIdentitySource) {
        // A composed main route with no Firebase/API configuration must not
        // imitate a successful local account sign-in.
        AppToast.show(
          context,
          message: FoundationGateCopy.of(context).unconfigured,
        );
        return;
      }
      setState(() => _submitting = true);
      try {
        final snapshot = await remoteIdentity.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        if (!snapshot.isRemoteAuthoritative || snapshot.familyId == null) {
          AppToast.show(
            context,
            message: _signInOutcomeMessage(
              FoundationGateCopy.of(context),
              remoteIdentity.phase,
            ),
          );
          return;
        }
        context.go('/scr-fat-012');
      } on Object {
        if (mounted) {
          AppToast.show(
            context,
            message: FoundationGateCopy.of(context).signInFailure,
          );
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    // Standalone preview/test host seam: preserve the previous mock-only flow
    // only where no composed application runtime exists.
    final runtime = CurrentIdentity.maybeOf(context);
    if (runtime != null &&
        runtime.session.isExpiredAt(DateTime.now().toUtc())) {
      context.go('/sys3-session-expired');
      return;
    }
    if (runtime?.needsFamilySelector ?? false) {
      context.go('/sys3-family-select');
      return;
    }
    context.go('/scr-fat-010');
  }

  String _signInOutcomeMessage(
    FoundationGateCopy copy,
    FoundationGatePhase phase,
  ) => switch (phase) {
    FoundationGatePhase.signInFailed => copy.signInFailure,
    FoundationGatePhase.sessionInvalid => copy.signInAgain,
    FoundationGatePhase.accessDenied ||
    FoundationGatePhase.rosterAccessDenied => copy.accessDenied,
    FoundationGatePhase.serviceUnavailable => copy.serviceUnavailable,
    FoundationGatePhase.networkUnavailable => copy.networkUnavailable,
    _ => copy.noActiveFamily,
  };

  void _forgotPassword() {
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.loginForgotToast);
    try {
      context.push('/sys3-account-recovery');
    } on Object {
      // Gallery/widget hosts without GoRouter keep the existing honest toast.
    }
  }

  void _biometric() {
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.loginBiometricUnavailable);
  }

  void _invite() {
    if (widget.onInvite != null) {
      widget.onInvite!();
      return;
    }
    context.go('/scr-fat-009');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    final runtime = CurrentIdentity.maybeOf(context);
    final appRuntime = AppScope.maybeOf(context);
    final usesRemoteIdentity =
        appRuntime?.identity is MainAppFoundationIdentitySource;
    final now = DateTime.now().toUtc();
    final sessionExpired = runtime?.session.isExpiredAt(now) ?? false;
    final sessionTag = runtime == null
        ? null
        : runtime.session.isRevoked
        ? l10n.loginSessionRevoked
        : sessionExpired
        ? l10n.loginSessionExpired
        : l10n.loginSessionActive;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.loginTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.loginSubtitle,
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
            if (sessionTag != null) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Tag(
                  label: sessionTag,
                  variant: sessionExpired ? TagVariant.a : TagVariant.g,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              key: LoginKeys.honesty,
              usesRemoteIdentity
                  ? FoundationGateCopy.of(context).serverRosterCurrentSession
                  : appRuntime != null
                  ? FoundationGateCopy.of(context).unconfigured
                  : l10n.loginLocalAccountHonesty,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: l10n.loginEmailLabel,
              child: Semantics(
                textField: true,
                label: l10n.loginEmailLabel,
                child: TextField(
                  key: const Key('login_email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: (_) {
                    if (_emailError) setState(() => _emailError = false);
                  },
                  decoration: _inputDecoration(
                    colors: colors,
                    radii: radii,
                    hint: l10n.loginEmailHint,
                    errorText: _emailError ? l10n.loginFieldsRequired : null,
                  ),
                ),
              ),
            ),
            if (_emailError)
              Padding(
                key: LoginKeys.emailError,
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.loginFieldsRequired,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.coral,
                  ),
                ),
              ),
            _LabeledField(
              label: l10n.loginPasswordLabel,
              child: Semantics(
                textField: true,
                label: l10n.loginPasswordLabel,
                child: TextField(
                  key: const Key('login_password'),
                  controller: _passwordController,
                  obscureText: true,
                  autocorrect: false,
                  onChanged: (_) {
                    if (_passwordError) setState(() => _passwordError = false);
                  },
                  decoration: _inputDecoration(
                    colors: colors,
                    radii: radii,
                    hint: l10n.loginPasswordHint,
                    errorText: _passwordError ? l10n.loginFieldsRequired : null,
                  ),
                ),
              ),
            ),
            if (_passwordError)
              Padding(
                key: LoginKeys.passwordError,
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.loginFieldsRequired,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.coral,
                  ),
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Semantics(
                  button: true,
                  label: l10n.loginForgotLink,
                  child: InkWell(
                    key: const Key('login_forgot'),
                    onTap: _forgotPassword,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            l10n.loginForgotLink,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.p600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            PrimaryBtn(
              key: const Key('login_submit'),
              label: l10n.loginSubmit,
              onPressed: _submitting ? null : _login,
            ),
            const SizedBox(height: 10),
            PrimaryBtn(
              key: const Key('login_biometric'),
              label: l10n.loginBiometric,
              variant: PrimaryBtnVariant.sec,
              onPressed: _biometric,
            ),
            const SizedBox(height: 14),
            Semantics(
              container: true,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 12.5, color: colors.ink),
                  children: [
                    TextSpan(text: '${l10n.loginInvitePrompt} '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Semantics(
                        button: true,
                        label: l10n.loginInviteLink,
                        child: InkWell(
                          key: const Key('login_invite_link'),
                          onTap: _invite,
                          borderRadius: BorderRadius.circular(4),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                l10n.loginInviteLink,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: colors.p600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required FamilyColors colors,
    required FamilyRadii radii,
    required String hint,
    String? errorText,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.input),
      borderSide: BorderSide(color: colors.border, width: 1.5),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.ink2.withValues(alpha: 0.55)),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.input),
        borderSide: BorderSide(color: colors.p400, width: 1.5),
      ),
      errorText: errorText,
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
