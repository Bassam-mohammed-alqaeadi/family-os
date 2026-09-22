import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/progress_bar.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Password strength bands matching prototype SHR-002 (length-only).
enum PasswordStrengthBand { empty, weak, good, strong }

/// Maps password length → strength band (prototype: <6 / <10 / ≥10).
PasswordStrengthBand passwordStrengthBand(String password) {
  final len = password.length;
  if (len == 0) return PasswordStrengthBand.empty;
  if (len < 6) return PasswordStrengthBand.weak;
  if (len < 10) return PasswordStrengthBand.good;
  return PasswordStrengthBand.strong;
}

/// Prototype fill width: `min(length * 9, 100)%`.
double passwordStrengthValue(String password) =>
    (password.length * 0.09).clamp(0.0, 1.0);

/// SCR-SHR-002 — إنشاء حساب (bare shared onboarding, mock-first).
///
/// No real auth. Valid form → `/scr-shr-007` (role pick; content not built here).
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key, this.onCreated});

  /// Test seam — when null, navigates to `/scr-shr-007`.
  final VoidCallback? onCreated;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _agreed = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _passwordController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _confirmController
      ..removeListener(_onFieldChanged)
      ..dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  bool get _canSubmit {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    return email.isNotEmpty &&
        password.length >= 8 &&
        password == confirm &&
        _agreed;
  }

  void _submit() {
    if (!_canSubmit) return;
    if (widget.onCreated != null) {
      widget.onCreated!();
      return;
    }
    context.go('/scr-shr-007');
  }

  Color _strengthColor(FamilyColors colors, PasswordStrengthBand band) {
    return switch (band) {
      PasswordStrengthBand.empty => colors.border,
      PasswordStrengthBand.weak => colors.amber,
      PasswordStrengthBand.good => colors.p400,
      PasswordStrengthBand.strong => colors.mint,
    };
  }

  String _strengthLabel(AppLocalizations l10n, PasswordStrengthBand band) {
    return switch (band) {
      PasswordStrengthBand.empty => '',
      PasswordStrengthBand.weak => l10n.createAccountStrengthWeak,
      PasswordStrengthBand.good => l10n.createAccountStrengthGood,
      PasswordStrengthBand.strong => l10n.createAccountStrengthStrong,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final password = _passwordController.text;
    final band = passwordStrengthBand(password);
    final strengthLabel = _strengthLabel(l10n, band);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.createAccountTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.createAccountStep,
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
            _LabeledField(
              label: l10n.createAccountEmailLabel,
              child: Semantics(
                textField: true,
                label: l10n.createAccountEmailLabel,
                child: TextField(
                  key: const Key('create_account_email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: _inputDecoration(
                    colors: colors,
                    radii: radii,
                    hint: l10n.createAccountEmailHint,
                  ),
                ),
              ),
            ),
            _LabeledField(
              label: l10n.createAccountPasswordLabel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    textField: true,
                    label: l10n.createAccountPasswordLabel,
                    child: TextField(
                      key: const Key('create_account_password'),
                      controller: _passwordController,
                      obscureText: true,
                      autocorrect: false,
                      decoration: _inputDecoration(
                        colors: colors,
                        radii: radii,
                        hint: l10n.createAccountPasswordHint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ProgressBar(
                    key: const Key('create_account_strength_bar'),
                    value: passwordStrengthValue(password),
                    height: 5,
                    fillColor: _strengthColor(colors, band),
                  ),
                  if (strengthLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        key: const Key('create_account_strength_label'),
                        strengthLabel,
                        style: TextStyle(fontSize: 12, color: colors.ink2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _LabeledField(
              label: l10n.createAccountConfirmLabel,
              child: Semantics(
                textField: true,
                label: l10n.createAccountConfirmLabel,
                child: TextField(
                  key: const Key('create_account_confirm'),
                  controller: _confirmController,
                  obscureText: true,
                  autocorrect: false,
                  decoration: _inputDecoration(
                    colors: colors,
                    radii: radii,
                    hint: l10n.createAccountConfirmHint,
                  ),
                ),
              ),
            ),
            Semantics(
              checked: _agreed,
              label: l10n.createAccountTerms,
              child: InkWell(
                key: const Key('create_account_terms'),
                onTap: () => setState(() => _agreed = !_agreed),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreed,
                          onChanged: (v) =>
                              setState(() => _agreed = v ?? false),
                          activeColor: colors.p500,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.createAccountTerms,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: colors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PrimaryBtn(
              key: const Key('create_account_submit'),
              label: l10n.createAccountSubmit,
              onPressed: _canSubmit ? _submit : null,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.createAccountNoPhoneNote,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.ink2),
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
