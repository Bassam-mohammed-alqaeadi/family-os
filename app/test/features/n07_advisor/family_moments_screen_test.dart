import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n07_advisor/family_moments_repository.dart';
import 'package:family_os/features/n07_advisor/family_moments_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryFamilyMomentsRepository(
        seed: familyMomentsEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(FamilyMomentsKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('share pride + add moment', (tester) async {
    final repo = InMemoryFamilyMomentsRepository(
      seed: familyMomentsPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    expect(find.byKey(FamilyMomentsKeys.hero), findsOneWidget);
    expect(find.byKey(FamilyMomentsKeys.stars), findsOneWidget);
    await tester.tap(find.byKey(FamilyMomentsKeys.shareCta));
    await tester.pump();
    expect(find.textContaining('Pride card'), findsOneWidget);
    expect(repo.prideShared, isTrue);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(FamilyMomentsKeys.addMomentCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyMomentsKeys.addMomentCta));
    await tester.pump();
    expect(find.textContaining('Added to moments'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('touch remind CTA', (tester) async {
    final repo = InMemoryFamilyMomentsRepository(
      seed: familyMomentsOneFixture(),
    );
    await _pump(tester, repository: repo);
    await tester.ensureVisible(find.byKey(FamilyMomentsKeys.touchCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyMomentsKeys.touchCta));
    await tester.pump();
    expect(find.textContaining('Surprise promised'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryFamilyMomentsRepository(
      seed: familyMomentsOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(FamilyMomentsKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(FamilyMomentsKeys.body), findsOneWidget);
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);
    expect(find.byKey(FamilyMomentsKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(FamilyMomentsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  FamilyMomentsRepository? repository,
  AppRole role = AppRole.father,
  VoidCallback? onSos,
  void Function(String)? onNavigate,
  bool settle = true,
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
        home: FamilyMomentsScreen(
          repository: repository,
          roleOverride: role,
          onSos: onSos,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
