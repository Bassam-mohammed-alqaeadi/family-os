import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n13_coming_soon/coming_soon_screen.dart';

/// Concrete fake ship-date patterns forbidden on FAT-075 (UI-013 AC1).
final _fakeDatePatterns = <RegExp>[
  RegExp(r'\b20\d{2}\b'),
  RegExp(r'\bQ[1-4]\b', caseSensitive: false),
  RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'),
  RegExp(
    r'\b(January|February|March|April|May|June|July|August|September|'
    r'October|November|December)\b',
    caseSensitive: false,
  ),
  RegExp(r'٢٠[٢-٩][٠-٩]'),
  RegExp(
    r'(يناير|فبراير|مارس|أبريل|ابريل|مايو|يونيو|يوليو|أغسطس|اغسطس|'
    r'سبتمبر|أكتوبر|اكتوبر|نوفمبر|ديسمبر)',
  ),
];

void main() {
  group('UI-013 SCR-FAT-075 coming soon', () {
    testWidgets('AC1: honesty banner visible; no concrete fake dates (AR)',
        (tester) async {
      await _pump(tester, locale: const Locale('ar'));

      expect(find.byKey(ComingSoonKeys.honestyBanner), findsOneWidget);
      expect(
        find.text('خارطة ما بعد الإطلاق — نبنيها بإتقان، دون وعود بتواريخ.'),
        findsOneWidget,
      );

      final texts = _allText(tester);
      for (final pattern in _fakeDatePatterns) {
        expect(
          pattern.hasMatch(texts),
          isFalse,
          reason: 'Forbidden date pattern ${pattern.pattern} in: $texts',
        );
      }
    });

    testWidgets('AC1: honesty banner visible; no concrete fake dates (EN)',
        (tester) async {
      await _pump(tester, locale: const Locale('en'));

      expect(find.byKey(ComingSoonKeys.honestyBanner), findsOneWidget);
      expect(
        find.text(
          'Post-launch roadmap — we build with care, without promising ship dates.',
        ),
        findsOneWidget,
      );

      final texts = _allText(tester);
      for (final pattern in _fakeDatePatterns) {
        expect(
          pattern.hasMatch(texts),
          isFalse,
          reason: 'Forbidden date pattern ${pattern.pattern} in: $texts',
        );
      }
    });

    testWidgets('AC2: no Switch widgets; not-settings honesty visible',
        (tester) async {
      await _pump(tester, locale: const Locale('ar'));

      expect(find.byType(Switch), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
      expect(find.byKey(ComingSoonKeys.notSettingsBanner), findsOneWidget);
      expect(
        find.text(
          'هذه ليست عناصر تحكم جاهزة. لا يمكن تشغيل أو إيقاف أي شيء هنا.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('feature rows are present with coming-soon tags; no toggles',
        (tester) async {
      await _pump(tester, locale: const Locale('ar'));

      expect(find.byKey(ComingSoonKeys.featureList), findsOneWidget);
      for (final id in ComingSoonScreen.featureIds) {
        expect(find.byKey(ComingSoonKeys.featureRow(id)), findsOneWidget);
      }
      expect(find.text('قريبًا'), findsNWidgets(8));
      expect(find.byType(Switch), findsNothing);
    });
  });
}

String _allText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final widget in tester.widgetList<Text>(find.byType(Text))) {
    final data = widget.data ?? widget.textSpan?.toPlainText() ?? '';
    buffer.writeln(data);
  }
  return buffer.toString();
}

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
}) async {
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
      home: const ComingSoonScreen(),
    ),
  );
  await tester.pumpAndSettle();
}
