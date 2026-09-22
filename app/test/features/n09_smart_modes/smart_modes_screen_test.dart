import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/smart_mode_prefs.dart';
import 'package:family_os/core/policy/smart_mode_prefs_repository.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/features/n09_smart_modes/smart_modes_screen.dart';

void main() {
  testWidgets('SET-018 lists built-in modes including school', (tester) async {
    final repo = InMemorySmartModePrefsRepository();
    await _pump(tester, repository: repo);

    expect(find.byKey(SmartModesKeys.modesList), findsOneWidget);
    for (final id in BuiltInModeId.values) {
      expect(find.byKey(SmartModesKeys.modeTile(id)), findsOneWidget);
    }
    expect(find.text('المدرسة'), findsOneWidget);
    // Host banner may mention the tombstone by id; must never offer a route CTA.
    expect(find.byTooltip('SCR-FAT-039'), findsNothing);
    expect(find.text('/scr-fat-039'), findsNothing);
  });

  testWidgets('SET-018 school schedule editable + activate persists', (
    tester,
  ) async {
    final repo = InMemorySmartModePrefsRepository();
    var pickCount = 0;

    await _pump(
      tester,
      repository: repo,
      pickTime: (context, initial) async {
        pickCount++;
        if (pickCount == 1) {
          return const TimeOfDay(hour: 8, minute: 30);
        }
        return const TimeOfDay(hour: 14, minute: 0);
      },
    );

    // Default school times from prefs.
    expect(find.byKey(SmartModesKeys.schoolStart), findsOneWidget);
    expect(find.byKey(SmartModesKeys.schoolEnd), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('13:45'), findsOneWidget);

    await tester.tap(find.byKey(SmartModesKeys.schoolStart));
    await tester.pumpAndSettle();
    expect(find.text('08:30'), findsOneWidget);

    await tester.tap(find.byKey(SmartModesKeys.schoolEnd));
    await tester.pumpAndSettle();
    expect(find.text('14:00'), findsOneWidget);

    await tester.tap(find.byKey(SmartModesKeys.modeSwitch(BuiltInModeId.school)));
    await tester.pumpAndSettle();

    final sw = tester.widget<Switch>(
      find.byKey(SmartModesKeys.modeSwitch(BuiltInModeId.school)),
    );
    expect(sw.value, isTrue);

    final saved = await repo.load(SmartModePrefs.defaultChildId);
    final school = saved.row(BuiltInModeId.school);
    expect(school.active, isTrue);
    expect(school.scheduleStart, const TimeOfDay(hour: 8, minute: 30));
    expect(school.scheduleEnd, const TimeOfDay(hour: 14, minute: 0));
  });

  test('SET-018 PrefsSmartModePrefsRepository round-trips school row', () async {
    final store = MemorySmartModePrefsStore();
    final repo = PrefsSmartModePrefsRepository(store);
    final prefs = SmartModePrefs.defaults().withRow(
      const SmartModeRow(
        modeId: BuiltInModeId.school,
        active: true,
        scheduleStart: TimeOfDay(hour: 7, minute: 15),
        scheduleEnd: TimeOfDay(hour: 13, minute: 0),
      ),
    );
    await repo.save(prefs);
    final loaded = await repo.load(SmartModePrefs.defaultChildId);
    expect(loaded.row(BuiltInModeId.school).active, isTrue);
    expect(
      loaded.row(BuiltInModeId.school).scheduleStart,
      const TimeOfDay(hour: 7, minute: 15),
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required SmartModePrefsRepository repository,
  SmartModeTimePicker? pickTime,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SmartModesScreen(
        repository: repository,
        pickTime: pickTime,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
