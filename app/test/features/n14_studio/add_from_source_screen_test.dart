import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n14_studio/add_from_source_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('father sees PDF hero + six source options', (tester) async {
    final nav = <String>[];
    await _pump(tester, onNavigate: nav.add);

    expect(find.byKey(AddFromSourceKeys.body), findsOneWidget);
    expect(find.byKey(AddFromSourceKeys.pdfHero), findsOneWidget);
    expect(find.byKey(AddFromSourceKeys.rowAssignment), findsOneWidget);
    expect(find.byKey(AddFromSourceKeys.rowCamera), findsOneWidget);
    expect(find.byKey(AddFromSourceKeys.rowLink), findsOneWidget);
    expect(find.byKey(AddFromSourceKeys.rowTopic), findsOneWidget);
    expect(find.byKey(AddFromSourceKeys.rowVoice), findsOneWidget);
    expect(find.byKey(AddFromSourceKeys.rowLibrary), findsOneWidget);

    await tester.tap(find.byKey(AddFromSourceKeys.rowCamera));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-042'));

    await tester.ensureVisible(find.byKey(AddFromSourceKeys.rowLibrary));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddFromSourceKeys.rowLibrary));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-046'));

    await tester.ensureVisible(find.byKey(AddFromSourceKeys.rowAssignment));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddFromSourceKeys.rowAssignment));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-049'));
  });

  testWidgets('PDF hero opens sheet then generate → FAT-043', (tester) async {
    final nav = <String>[];
    await _pump(tester, onNavigate: nav.add);

    await tester.tap(find.byKey(AddFromSourceKeys.pdfHero));
    await tester.pumpAndSettle();
    expect(find.byKey(AddFromSourceKeys.pdfSheet), findsOneWidget);
    expect(find.byKey(AddFromSourceKeys.pdfGenerate), findsOneWidget);

    await tester.tap(find.byKey(AddFromSourceKeys.pdfGenerate));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-043'));
  });

  testWidgets('link / topic / voice show mock toasts', (tester) async {
    await _pump(tester);

    await tester.ensureVisible(find.byKey(AddFromSourceKeys.rowLink));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddFromSourceKeys.rowLink));
    await tester.pump();
    AppToast.dismiss();

    await tester.ensureVisible(find.byKey(AddFromSourceKeys.rowTopic));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddFromSourceKeys.rowTopic));
    await tester.pump();
    AppToast.dismiss();

    await tester.ensureVisible(find.byKey(AddFromSourceKeys.rowVoice));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddFromSourceKeys.rowVoice));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(find.byKey(AddFromSourceKeys.body), findsOneWidget);
  });

  testWidgets('mother observer view-only — create taps blocked', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(AddFromSourceKeys.observerHint), findsOneWidget);
    expect(find.byKey(AddFromSourceKeys.body), findsOneWidget);

    await tester.tap(find.byKey(AddFromSourceKeys.rowCamera));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);

    await tester.tap(find.byKey(AddFromSourceKeys.pdfHero));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.byKey(AddFromSourceKeys.pdfSheet), findsNothing);
  });

  testWidgets('mother partner can open camera', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(AddFromSourceKeys.observerHint), findsNothing);
    await tester.tap(find.byKey(AddFromSourceKeys.rowCamera));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-042'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(
      tester,
      role: AppRole.child,
      onSos: () => sos = true,
    );

    expect(find.byKey(AddFromSourceKeys.childLean), findsOneWidget);
    expect(find.byKey(AddFromSourceKeys.body), findsNothing);
    expect(find.byKey(AddFromSourceKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(AddFromSourceKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
  VoidCallback? onSos,
  void Function(String screenId)? onNavigate,
}) async {
  final roleCtrl = RoleController(role);
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
        home: AddFromSourceScreen(
          roleOverride: role,
          motherLevel: motherLevel,
          onSos: onSos,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
