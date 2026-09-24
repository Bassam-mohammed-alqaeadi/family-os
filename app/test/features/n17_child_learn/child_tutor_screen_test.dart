import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_tutor_repository.dart';
import 'package:family_os/features/n17_child_learn/child_tutor_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildTutorRepository(seed: childTutorEmptyFixture()),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildTutorKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('prototype choices + photo toast', (tester) async {
    await _pump(
      tester,
      repository: InMemoryChildTutorRepository(
        seed: childTutorPrototypeFixture(),
      ),
    );
    expect(find.byKey(ChildTutorKeys.body), findsOneWidget);
    expect(find.byKey(ChildTutorKeys.policyBanner), findsOneWidget);
    expect(find.textContaining('never give the ready-made'), findsOneWidget);

    await tester.ensureVisible(find.byKey(ChildTutorKeys.choice('c10')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildTutorKeys.choice('c10')));
    await tester.pump();
    expect(find.textContaining('Exactly'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(ChildTutorKeys.photoCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildTutorKeys.photoCta));
    await tester.pump();
    expect(find.textContaining("I'll explain step by step"), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildTutorRepository(seed: childTutorOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildTutorKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildTutorKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildTutorKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildTutorRepository(seed: childTutorOneFixture()),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildTutorKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildTutorRepository? repository,
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
        home: ChildTutorScreen(
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
