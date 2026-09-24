import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

// #region agent log
void _agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?> data = const {},
}) {
  final payload = <String, Object?>{
    'sessionId': '296a8e',
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
        'runId': 'post-fix',
      };
      final line = jsonEncode(payload);
      debugPrint('AGENT_DEBUG $line');
      try {
        File(
          r'D:\special projects\family\debug-296a8e.log',
        ).writeAsStringSync('$line\n', mode: FileMode.append);
      } catch (_) {}
      // Best-effort ingest when running on host (Windows/Chrome); ignore on device.
      try {
        HttpClient()
            .postUrl(
              Uri.parse(
                'http://127.0.0.1:7833/ingest/4add46c7-41e9-4203-afa0-61f38d854be0',
              ),
            )
            .then((req) {
              req.headers.set('Content-Type', 'application/json');
              req.headers.set('X-Debug-Session-Id', '296a8e');
              req.write(line);
              return req.close();
            })
            .then((resp) => resp.drain<void>())
            .catchError((_) {});
      } catch (_) {}
    }
// #endregion

/// SCR-SHR-003 — تسجيل الدخول (bare shared onboarding, mock-first).
///
/// No real auth / biometrics. Login → `/scr-fat-010` (placeholder OK).
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final runtime = CurrentIdentity.maybeOf(context);
    // #region agent log
    _agentDebugLog(
      hypothesisId: 'A',
      location: 'login_screen.dart:_login',
      message: 'login_pressed',
      data: {
        'hasRuntime': runtime != null,
        'sessionExpired': runtime?.session.isExpiredAt(DateTime.now().toUtc()),
        'needsFamilySelector': runtime?.needsFamilySelector,
        'hasOnLoginSuccess': widget.onLoginSuccess != null,
      },
    );
    // #endregion
    if (runtime != null &&
        runtime.session.isExpiredAt(DateTime.now().toUtc())) {
      // #region agent log
      _agentDebugLog(
        hypothesisId: 'B',
        location: 'login_screen.dart:_login',
        message: 'nav_target',
        data: {'target': '/sys3-session-expired'},
      );
      // #endregion
      context.go('/sys3-session-expired');
      return;
    }
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
      return;
    }
    if (runtime?.needsFamilySelector ?? false) {
      // #region agent log
      _agentDebugLog(
        hypothesisId: 'A',
        location: 'login_screen.dart:_login',
        message: 'nav_target',
        data: {'target': '/sys3-family-select'},
      );
      // #endregion
      context.go('/sys3-family-select');
      return;
    }
    // #region agent log
    _agentDebugLog(
      hypothesisId: 'E',
      location: 'login_screen.dart:_login',
      message: 'nav_target',
      data: {'target': '/scr-fat-010'},
    );
    // #endregion
    context.go('/scr-fat-010');
  }

  void _forgotPassword() {
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.loginForgotToast);
    try {
      // #region agent log
      _agentDebugLog(
        hypothesisId: 'C',
        location: 'login_screen.dart:_forgotPassword',
        message: 'nav_target',
        data: {'target': '/sys3-account-recovery'},
      );
      // #endregion
      context.push('/sys3-account-recovery');
    } on Object {
      // Gallery/widget hosts without GoRouter keep the existing honest toast.
    }
  }

  void _biometric() {
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.loginBiometricToast);
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
    final now = DateTime.now().toUtc();
    final sessionExpired = runtime?.session.isExpiredAt(now) ?? false;
    final sessionTag = runtime == null
        ? null
        : runtime.session.isRevoked
        ? l10n.requestInboxReject
        : sessionExpired
        ? l10n.linkQrExpired
        : l10n.dayBoardActiveTag;

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
                  decoration: _inputDecoration(
                    colors: colors,
                    radii: radii,
                    hint: l10n.loginEmailHint,
                  ),
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
                  decoration: _inputDecoration(
                    colors: colors,
                    radii: radii,
                    hint: l10n.loginPasswordHint,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Semantics(
                  button: true,
                  label: l10n.loginForgotLink,
                  child: InkWell(
                    key: const Key('login_forgot'),
                    onTap: _forgotPassword,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
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
            PrimaryBtn(
              key: const Key('login_submit'),
              label: l10n.loginSubmit,
              onPressed: _login,
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
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Semantics(
                        button: true,
                        label: l10n.loginInviteLink,
                        child: InkWell(
                          key: const Key('login_invite_link'),
                          onTap: _invite,
                          borderRadius: BorderRadius.circular(4),
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
