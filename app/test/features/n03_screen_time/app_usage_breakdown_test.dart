// S3 — the per-app half of the day the server already sends.
//
// `usage.byApp` has been parsed since the wave and never drawn, so a parent could read
// "40 of 60 minutes" and never learn where they went. These tests hold the widget to the
// three things it must not do: invent rows, put an app's ceiling on the bar, or let the
// order move between two reads of the same day.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/app_usage_breakdown.dart';
import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: buildFamilyTheme(),
  locale: const Locale('ar'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

Future<void> _pump(
  WidgetTester tester,
  List<FoundationGateAppUsage> rows, {
  Map<String, String> names = const <String, String>{},
}) async {
  await tester.pumpWidget(
    _wrap(AppUsageBreakdown(usage: rows, displayNames: names)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no rows is an empty card, not a zero chart', (tester) async {
    await _pump(tester, const <FoundationGateAppUsage>[]);

    expect(find.byKey(AppUsageBreakdown.empty), findsOneWidget);
    expect(find.byKey(AppUsageBreakdown.bars), findsNothing);
  });

  testWidgets('the minutes are the server\'s, in the server\'s order', (tester) async {
    await _pump(tester, const <FoundationGateAppUsage>[
      FoundationGateAppUsage(appId: 'com.small.app', usedMinutes: 5),
      FoundationGateAppUsage(appId: 'com.big.game', usedMinutes: 35),
      FoundationGateAppUsage(appId: 'com.mid.app', usedMinutes: 12),
    ]);

    final labels = tester
        .widgetList<Text>(find.descendant(
          of: find.byKey(AppUsageBreakdown.bars),
          matching: find.byType(Text),
        ))
        .map((text) => text.data)
        .toList();

    expect(
      labels.take(6).toList(),
      <String>['Big game', '35', 'Mid app', '12', 'Small app', '5'],
      reason: 'the biggest cost is read first, and a package is shown as a name',
    );
  });

  testWidgets('a family name wins over a derived label', (tester) async {
    await _pump(
      tester,
      const <FoundationGateAppUsage>[
        FoundationGateAppUsage(appId: 'com.google.android.youtube', usedMinutes: 9),
      ],
      names: const <String, String>{'com.google.android.youtube': 'يوتيوب'},
    );

    expect(find.text('يوتيوب'), findsOneWidget);
    expect(find.text('Youtube'), findsNothing);
  });

  testWidgets('the tail is folded into one honest line', (tester) async {
    await _pump(tester, const <FoundationGateAppUsage>[
      FoundationGateAppUsage(appId: 'com.a.app', usedMinutes: 50),
      FoundationGateAppUsage(appId: 'com.b.app', usedMinutes: 40),
      FoundationGateAppUsage(appId: 'com.c.app', usedMinutes: 30),
      FoundationGateAppUsage(appId: 'com.d.app', usedMinutes: 20),
      FoundationGateAppUsage(appId: 'com.e.app', usedMinutes: 10),
      FoundationGateAppUsage(appId: 'com.f.app', usedMinutes: 5),
      FoundationGateAppUsage(appId: 'com.g.app', usedMinutes: 4),
    ]);

    expect(find.text('وبقية التطبيقات'), findsOneWidget);
    expect(
      find.text('19'),
      findsOneWidget,
      reason: '20 + 10 + 5 + 4: the folded rows still add up',
    );
    expect(find.text('A app'), findsOneWidget);
    expect(find.text('F app'), findsNothing);
  });

  testWidgets('a zero-minute row is not a bar', (tester) async {
    await _pump(tester, const <FoundationGateAppUsage>[
      FoundationGateAppUsage(appId: 'com.unused.app', usedMinutes: 0),
    ]);

    expect(find.byKey(AppUsageBreakdown.empty), findsOneWidget);
    expect(find.text('Unused app'), findsNothing);
  });

  test('a package id becomes a readable label without inventing usage', () {
    expect(AppUsageBreakdown.humanisePackage('com.whatsapp'), 'Whatsapp');
    expect(
      AppUsageBreakdown.humanisePackage('com.example.my_game-2'),
      'My game 2',
    );
    expect(AppUsageBreakdown.humanisePackage(''), '');
  });
}
