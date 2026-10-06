import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/i18n/locale_controller.dart';

/// Highly visible, bidirectional locale control for the launch journey.
///
/// Locale persistence is delegated to [LocaleController], so selecting a
/// language here also controls future cold starts.
class LaunchLanguageSwitcher extends StatelessWidget {
  const LaunchLanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CurrentLocale.maybeOf(context);
    final locale = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final isArabic = locale.languageCode == 'ar';

    Future<void> select(Locale next) async {
      await controller?.setLocale(next);
    }

    return Semantics(
      container: true,
      label: isArabic
          ? l10n.languageHelpArabic
          : l10n.languageHelpEnglish,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.surface.withValues(alpha: 0.7)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageChoice(
                key: const Key('launch_language_ar'),
                label: l10n.languageHelpArabic,
                selected: isArabic,
                onTap: () => select(const Locale('ar')),
              ),
              _LanguageChoice(
                key: const Key('launch_language_en'),
                label: l10n.languageHelpEnglish,
                selected: !isArabic,
                onTap: () => select(const Locale('en')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.p700 : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? colors.surface : colors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
