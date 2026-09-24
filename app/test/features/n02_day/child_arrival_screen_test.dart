import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/child_arrival_repository.dart';
import 'package:family_os/features/n02_day/child_arrival_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-004', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildArrivalRepository(
        seed: childArrivalEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildArrivalKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to my day'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-004'));
  });

  testWidgets('check-in toast →004', (tester) async {
    final nav = <String>[];
    final repo = InMemoryChildArrivalRepository(
      seed: childArrivalPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);
    expect(find.byKey(ChildArrivalKeys.body), findsOneWidget);
    expect(find.byKey(ChildArrivalKeys.liveCard), findsOneWidget);
    expect(
      find.textContaining('Check-in only'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(ChildArrivalKeys.zone('z1')));
    await tester.pump();
    expect(find.textContaining('Reassurance sent'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-004'));
    expect(repo.lastCheckInZoneId, 'z1');
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildArrivalRepository(seed: childArrivalOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildArrivalKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildArrivalKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildArrivalKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildArrivalRepository(
        seed: childArrivalOneFixture(),
      ),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildArrivalKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildArrivalRepository? repository,
  AppRole role = AppRole.child,
  VoidCallback? onSos,
  void Function(String screenId)? onNavigate,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    CurrentRole(
      notifier: RoleController(role),
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
        home: ChildArrivalScreen(
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
