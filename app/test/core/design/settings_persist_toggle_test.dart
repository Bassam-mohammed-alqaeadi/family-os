import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/family_ui_mode.dart';
import 'package:family_os/core/design/components/settings_persist_toggle.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FamilyUiModeScope(
        mode: FamilyUiMode.parent,
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(AppToast.dismiss);

  group('SettingsPersistToggle UI-008', () {
    testWidgets('AC2: success toast after persist (not CSS-only)',
        (tester) async {
      var value = false;
      var saves = 0;
      final gate = Completer<void>();

      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return SettingsPersistToggle(
              title: 'Quiet hours',
              value: value,
              switchKey: const Key('persist_switch'),
              successMessage: 'Saved OK',
              errorMessage: 'Save failed',
              onPersist: (next) async {
                saves++;
                await gate.future;
                setState(() => value = next);
              },
            );
          },
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
      await tester.tap(find.byKey(const Key('persist_switch')));
      await tester.pump(); // loading frame
      expect(find.byKey(SettingsPersistToggleKeys.loading), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();

      expect(saves, 1);
      expect(value, isTrue);
      expect(find.text('Saved OK'), findsOneWidget);
      expect(find.byKey(SettingsPersistToggleKeys.error), findsNothing);
      // AC3: Switch is real Material control, not a CSS classList flip.
      expect(find.byType(Switch), findsOneWidget);
      AppToast.dismiss();
      await tester.pump();
    });

    testWidgets('AC1: save failure shows error and reverts switch',
        (tester) async {
      var value = false;

      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return SettingsPersistToggle(
              title: 'Quiet hours',
              value: value,
              switchKey: const Key('persist_switch'),
              successMessage: 'Saved OK',
              errorMessage: 'Save failed',
              onPersist: (next) async {
                throw StateError('persist denied');
              },
            );
          },
        ),
      );

      await tester.tap(find.byKey(const Key('persist_switch')));
      await tester.pumpAndSettle();

      expect(find.byKey(SettingsPersistToggleKeys.error), findsOneWidget);
      expect(find.text('Save failed'), findsOneWidget);
      expect(find.text('Saved OK'), findsNothing);
      final sw = tester.widget<Switch>(find.byKey(const Key('persist_switch')));
      expect(sw.value, isFalse);
      expect(value, isFalse);
    });

    testWidgets('rapid taps debounce — only one persist', (tester) async {
      var value = false;
      var saves = 0;
      final gate = Completer<void>();

      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return SettingsPersistToggle(
              title: 'Quiet hours',
              value: value,
              switchKey: const Key('persist_switch'),
              successMessage: 'Saved OK',
              debounce: const Duration(milliseconds: 400),
              onPersist: (next) async {
                saves++;
                await gate.future;
                setState(() => value = next);
              },
            );
          },
        ),
      );

      await tester.tap(find.byKey(const Key('persist_switch')));
      await tester.pump();
      // Second tap while saving / within debounce — ignored.
      await tester.tap(find.byKey(SettingsPersistToggleKeys.loading));
      await tester.pump(const Duration(milliseconds: 50));
      gate.complete();
      await tester.pumpAndSettle();

      expect(saves, 1);
      expect(value, isTrue);
      AppToast.dismiss();
      await tester.pump();
    });
  });
}
