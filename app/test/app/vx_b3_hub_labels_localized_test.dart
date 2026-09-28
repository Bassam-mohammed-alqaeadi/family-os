import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/family_shell.dart';
import 'package:family_os/app/shell_config.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// VX-B3 · D1 — hub tab labels resolve from ARB (AR + EN).
void main() {
  Future<AppLocalizations> l10nFor(WidgetTester tester, Locale locale) async {
    late AppLocalizations out;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFamilyTheme(),
        home: Builder(
          builder: (context) {
            out = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return out;
  }

  testWidgets('parent hub keys resolve Arabic labels', (tester) async {
    final l10n = await l10nFor(tester, const Locale('ar'));
    for (final tab in parentShellTabs) {
      final label = shellTabLabel(l10n, tab.arbLabelKey);
      expect(label, isNot(equals(tab.arbLabelKey)));
      expect(label.trim(), isNotEmpty);
    }
    expect(l10n.tabParentToday, 'اليوم');
  });

  testWidgets('parent hub keys resolve English labels', (tester) async {
    final l10n = await l10nFor(tester, const Locale('en'));
    for (final tab in parentShellTabs) {
      final label = shellTabLabel(l10n, tab.arbLabelKey);
      expect(label, isNot(equals(tab.arbLabelKey)));
      expect(RegExp(r'[A-Za-z]').hasMatch(label), isTrue);
    }
    expect(l10n.tabParentToday, 'Today');
  });

  testWidgets('child hub keys resolve Arabic + English', (tester) async {
    final ar = await l10nFor(tester, const Locale('ar'));
    final en = await l10nFor(tester, const Locale('en'));
    for (final tab in childShellTabs) {
      expect(shellTabLabel(ar, tab.arbLabelKey), isNot(equals(tab.arbLabelKey)));
      expect(shellTabLabel(en, tab.arbLabelKey), isNot(equals(tab.arbLabelKey)));
    }
    expect(ar.tabChildMyDay, 'يومي');
    expect(en.tabChildMyDay, 'My day');
  });
}
