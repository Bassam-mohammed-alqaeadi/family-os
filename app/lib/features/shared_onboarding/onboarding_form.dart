import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';

/// Shared building blocks for the four real onboarding screens
/// (sign-in, sign-up, create family, add child).
///
/// The goal is one consistent, calm form language: a hero header, labelled
/// fields with inline validation under the field, one inline notice area for
/// server outcomes (never a disappearing toast for something the user must
/// act on), and a submit button that shows its own progress.

// ── Validation helpers ──────────────────────────────────────────────────────

final RegExp _emailPattern = RegExp(
  r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$",
);

/// Pragmatic e-mail syntax check (RFC-lite: local@domain.tld).
bool looksLikeEmail(String value) => _emailPattern.hasMatch(value.trim());

/// Password strength bands used by the sign-up meter.
enum PasswordStrength { empty, weak, fair, good, strong }

/// Scores a password on length plus character-class variety. Length is the
/// dominant factor (NIST-style); variety only lifts the band.
PasswordStrength passwordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.empty;
  var score = 0;
  final length = password.length;
  if (length >= 8) score++;
  if (length >= 12) score++;
  if (length >= 16) score++;
  var classes = 0;
  if (RegExp(r'[a-z]').hasMatch(password)) classes++;
  if (RegExp(r'[A-Z]').hasMatch(password)) classes++;
  if (RegExp(r'[0-9]').hasMatch(password)) classes++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) classes++;
  if (classes >= 2) score++;
  if (classes >= 3) score++;
  if (length < 8) return PasswordStrength.weak;
  return switch (score) {
    <= 1 => PasswordStrength.weak,
    2 => PasswordStrength.fair,
    3 => PasswordStrength.good,
    _ => PasswordStrength.strong,
  };
}

/// Meter fill for [passwordStrength] (0..1).
double passwordStrengthValue(PasswordStrength strength) => switch (strength) {
  PasswordStrength.empty => 0,
  PasswordStrength.weak => 0.25,
  PasswordStrength.fair => 0.5,
  PasswordStrength.good => 0.75,
  PasswordStrength.strong => 1,
};

// ── Header ──────────────────────────────────────────────────────────────────

/// Hero header: tinted icon badge, title, one-line supporting copy.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.step,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Optional progress pill, e.g. "2 / 3".
  final String? step;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.p100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: colors.p600, size: 28),
              ),
              const Spacer(),
              if (step != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    step!,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.ink2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fields ──────────────────────────────────────────────────────────────────

/// Labelled text field with the error rendered inline under the field.
class OnboardingTextField extends StatelessWidget {
  const OnboardingTextField({
    super.key,
    required this.label,
    required this.controller,
    this.fieldKey,
    this.hint,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.suffix,
    this.maxLength,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final Key? fieldKey;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final int? maxLength;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final hasError = errorText != null;

    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.input),
          borderSide: BorderSide(color: color, width: width),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            textField: true,
            label: label,
            child: TextField(
              key: fieldKey,
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: autofocus,
              obscureText: obscureText,
              autocorrect: !obscureText,
              enableSuggestions: !obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              textCapitalization: textCapitalization,
              maxLength: maxLength,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              style: TextStyle(fontSize: 15, color: colors.ink),
              buildCounter: maxLength == null
                  ? null
                  : (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => Text(
                      '$currentLength / $maxLength',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: currentLength >= (maxLength ?? 0)
                            ? colors.coral
                            : colors.ink2,
                      ),
                    ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: colors.ink2.withValues(alpha: 0.5)),
                helperText: hasError ? null : helperText,
                helperMaxLines: 2,
                helperStyle: TextStyle(fontSize: 12, color: colors.ink2),
                errorText: errorText,
                errorMaxLines: 3,
                errorStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.coral,
                ),
                filled: true,
                fillColor: enabled
                    ? colors.surface
                    : colors.surface.withValues(alpha: 0.6),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: border(colors.border),
                enabledBorder: border(colors.border),
                disabledBorder: border(colors.border),
                focusedBorder: border(colors.p400, 2),
                errorBorder: border(colors.coral),
                focusedErrorBorder: border(colors.coral, 2),
                suffixIcon: suffix,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Eye toggle for password fields (≥48 dp tap target, labelled).
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onToggle,
    required this.showLabel,
    required this.hideLabel,
  });

  final bool obscured;
  final VoidCallback onToggle;
  final String showLabel;
  final String hideLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return IconButton(
      tooltip: obscured ? showLabel : hideLabel,
      onPressed: onToggle,
      iconSize: 22,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: colors.ink2,
      ),
    );
  }
}

// ── Notices ─────────────────────────────────────────────────────────────────

enum OnboardingNoticeTone { info, success, warning, error }

/// Inline, persistent notice for server outcomes. Optional action button.
class OnboardingNotice extends StatelessWidget {
  const OnboardingNotice({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final OnboardingNoticeTone tone;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final (Color bg, Color fg, IconData icon) = switch (tone) {
      OnboardingNoticeTone.info => (
        colors.p50,
        colors.p700,
        Icons.info_outline_rounded,
      ),
      OnboardingNoticeTone.success => (
        colors.mint100,
        colors.mintInk,
        Icons.check_circle_outline_rounded,
      ),
      OnboardingNoticeTone.warning => (
        colors.amber100,
        colors.amberInk,
        Icons.warning_amber_rounded,
      ),
      OnboardingNoticeTone.error => (
        colors.coral100,
        colors.coral,
        Icons.error_outline_rounded,
      ),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radii.banner),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          message!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.tonal(
                  key: actionKey,
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: fg,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 44),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Submit ──────────────────────────────────────────────────────────────────

/// Primary submit button that renders an inline spinner while busy. While
/// busy it is not tappable, which is the double-submit guard at the UI layer.
class OnboardingSubmitButton extends StatelessWidget {
  const OnboardingSubmitButton({
    super.key,
    required this.label,
    required this.busyLabel,
    required this.busy,
    required this.onPressed,
    this.buttonKey,
  });

  final String label;
  final String busyLabel;
  final bool busy;
  final VoidCallback? onPressed;

  /// Key applied to the rendered control (idle button or busy indicator).
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    if (!busy) {
      return PrimaryBtn(key: buttonKey, label: label, onPressed: onPressed);
    }
    return Semantics(
      key: buttonKey,
      button: true,
      enabled: false,
      label: busyLabel,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: colors.p500.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(radii.btn),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              busyLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Prompt + link" footer line, e.g. "New here? Create an account".
class OnboardingFooterLink extends StatelessWidget {
  const OnboardingFooterLink({
    super.key,
    required this.prompt,
    required this.linkLabel,
    required this.onTap,
    this.linkKey,
  });

  final String prompt;
  final String linkLabel;
  final VoidCallback onTap;
  final Key? linkKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
          ),
        ),
        TextButton(
          key: linkKey,
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            linkLabel,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: colors.p600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Standard scaffold for onboarding: app bar with back affordance only when
/// the router can pop, bounded content width on tablets, keyboard-safe list.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.children,
    this.appBarTitle,
    this.controller,
  });

  final List<Widget> children;
  final String? appBarTitle;

  /// Optional controller so screens can bring an inline notice into view.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: appBarTitle == null
            ? null
            : Text(
                appBarTitle!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.ink2,
                ),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              controller: controller,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrolls an onboarding list back to its top so a freshly shown notice is
/// visible. Safe to call before the first layout.
void revealOnboardingNotice(ScrollController controller) {
  if (!controller.hasClients) return;
  controller.animateTo(
    0,
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
  );
}
