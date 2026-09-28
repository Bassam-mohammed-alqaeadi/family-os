import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n14_studio/add_from_source_screen.dart';

/// VX-B1 / FVX-C-03 — SCR-FAT-041 PDF source choice is a real selection.
void main() {
  tearDown(AppToast.dismiss);

  testWidgets('choosing a PDF source moves the selection and sticks', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    await tester.tap(find.byKey(AddFromSourceKeys.pdfHero));
    await tester.pumpAndSettle();

    final math = find.byKey(AddFromSourceKeys.pdfOptionMath);
    final science = find.byKey(AddFromSourceKeys.pdfOptionScience);
    expect(tester.getSemantics(math), containsSemantics(isSelected: true));
    expect(
      tester.getSemantics(science),
      isNot(containsSemantics(isSelected: true)),
    );

    await tester.tap(science);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(science), containsSemantics(isSelected: true));
    expect(
      tester.getSemantics(math),
      isNot(containsSemantics(isSelected: true)),
    );

    // Close and reopen — the parent's choice is kept for this visit.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(AddFromSourceKeys.pdfSheet), findsNothing);
    await tester.tap(find.byKey(AddFromSourceKeys.pdfHero));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(AddFromSourceKeys.pdfOptionScience)),
      containsSemantics(isSelected: true),
    );

    semantics.dispose();
  });

  testWidgets('selecting a source shows no fake "selected (demo)" toast', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(AddFromSourceKeys.pdfHero));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddFromSourceKeys.pdfOptionScience));
    await tester.pump();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.addFromSourcePdfSelectedToast), findsNothing);
  });
}

Future<void> _pump(WidgetTester tester) async {
  final roleCtrl = RoleController(AppRole.father);
  addTearDown(roleCtrl.dispose);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AddFromSourceScreen(roleOverride: AppRole.father),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
