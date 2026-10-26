import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/i18n/clock_format.dart';
import 'package:family_os/core/i18n/numeral_format.dart';

/// The one clock renderer, tested against the only two things it may consult: the family's digits
/// and the device's hour cycle. Every screen that formatted a time by hand answered these questions
/// its own way, which is what this file exists to make impossible.
Future<void> _pump(
  WidgetTester tester, {
  required Widget Function(BuildContext) build,
  required bool twentyFour,
  Locale locale = const Locale('ar'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: twentyFour),
        child: Builder(builder: build),
      ),
      home: const SizedBox.shrink(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(AppNumerals.clearFamilyChoice);

  testWidgets('the 24-hour face writes the digits this family chose', (
    tester,
  ) async {
    const night = TimeOfDay(hour: 22, minute: 0);
    var western = '';
    var eastern = '';

    await _pump(
      tester,
      twentyFour: true,
      build: (context) {
        western = formatFamilyClock(context, night);
        return const SizedBox.shrink();
      },
    );

    AppNumerals.applyFamilyChoice(AppNumeralSystem.eastern);
    await _pump(
      tester,
      twentyFour: true,
      build: (context) {
        eastern = formatFamilyClock(context, night);
        return const SizedBox.shrink();
      },
    );

    expect(western, '22:00');
    expect(eastern, '٢٢:٠٠');
  });

  testWidgets('the 12-hour face takes its meridiem word from the catalog', (
    tester,
  ) async {
    const night = TimeOfDay(hour: 22, minute: 5);
    const noon = TimeOfDay(hour: 12, minute: 0);
    var arabicNight = '';
    var arabicNoon = '';
    var englishNoon = '';

    await _pump(
      tester,
      twentyFour: false,
      build: (context) {
        arabicNight = formatFamilyClock(context, night);
        arabicNoon = formatFamilyClock(context, noon);
        return const SizedBox.shrink();
      },
    );
    await _pump(
      tester,
      twentyFour: false,
      locale: const Locale('en'),
      build: (context) {
        englishNoon = formatFamilyClock(context, noon);
        return const SizedBox.shrink();
      },
    );

    expect(arabicNight, '10:05 م');
    expect(arabicNoon, '12:00 م');
    expect(englishNoon, '12:00 PM');
  });

  testWidgets('a single-digit hour is padded only in 24-hour faces', (
    tester,
  ) async {
    const early = TimeOfDay(hour: 7, minute: 30);
    var twentyFour = '';
    var twelve = '';

    await _pump(
      tester,
      twentyFour: true,
      build: (context) {
        twentyFour = formatFamilyClock(context, early);
        return const SizedBox.shrink();
      },
    );
    await _pump(
      tester,
      twentyFour: false,
      build: (context) {
        twelve = formatFamilyClock(context, early);
        return const SizedBox.shrink();
      },
    );

    expect(twentyFour, '07:30');
    expect(twelve, '7:30 ص');
  });

  testWidgets('an unset time is named, never invented', (tester) async {
    var unset = '';
    await _pump(
      tester,
      twentyFour: true,
      build: (context) {
        unset = formatFamilyClockOrUnset(context, null);
        return const SizedBox.shrink();
      },
    );

    expect(unset, 'لم يُحدَّد');
  });
}
