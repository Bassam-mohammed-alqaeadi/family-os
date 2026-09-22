import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/features/n10_emergency/child_sos_in_progress_screen.dart';

void main() {
  testWidgets('child — active SOS body + P-4 banner never gated', (tester) async {
    final repo = InMemorySosAlertRepository(
      initialActive: InMemorySosAlertRepository.demoActive(
        childId: 'child_test_a',
      ),
    );

    await _pump(
      tester,
      ChildSosInProgressScreen(
        repository: repo,
        roleOverride: AppRole.child,
        childId: 'child_test_a',
        alertId: 'sos_1',
        onCallFather: () {},
        onResolved: () {},
      ),
    );

    expect(find.byKey(ChildSosInProgressKeys.screen), findsOneWidget);
    expect(find.byKey(ChildSosInProgressKeys.body), findsOneWidget);
    expect(find.byKey(ChildSosInProgressKeys.p4Banner), findsOneWidget);
    expect(find.byKey(ChildSosInProgressKeys.headline), findsOneWidget);
    expect(find.byKey(ChildSosInProgressKeys.broadcast), findsOneWidget);
    expect(find.byKey(ChildSosInProgressKeys.statusCard), findsOneWidget);
    expect(find.byKey(ChildSosInProgressKeys.callFather), findsOneWidget);
    expect(find.byKey(ChildSosInProgressKeys.cancelCta), findsOneWidget);
    expect(find.textContaining('وصل بلاغك'), findsOneWidget);
    expect(find.textContaining('لا تُكتم'), findsOneWidget);
    expect(find.byKey(ChildSosInProgressKeys.parentLean), findsNothing);
    // Rule 23 — no planted person name from demo fixture on child surface.
    expect(find.textContaining('خالد'), findsNothing);
    expect(find.textContaining('عبدالله'), findsNothing);
  });

  testWidgets('P-4 — screen module never imports entitlement', (tester) async {
    final file = File(
      'lib/features/n10_emergency/child_sos_in_progress_screen.dart',
    );
    expect(file.existsSync(), isTrue);
    final text = file.readAsStringSync();
    final importLeak = RegExp(
      r'''import\s+['"][^'"]*entitlement[^'"]*['"]''',
      caseSensitive: false,
    );
    expect(importLeak.hasMatch(text), isFalse);
    expect(text.contains('EntitlementService'), isFalse);
    expect(text.contains('MockEntitlementService'), isFalse);
  });

  testWidgets('father role — parent lean, no SOS body', (tester) async {
    final repo = InMemorySosAlertRepository(
      initialActive: InMemorySosAlertRepository.demoActive(),
    );

    await _pump(
      tester,
      ChildSosInProgressScreen(
        repository: repo,
        roleOverride: AppRole.father,
        onCallFather: () {},
        onResolved: () {},
      ),
    );

    expect(find.byKey(ChildSosInProgressKeys.parentLean), findsOneWidget);
    expect(find.byKey(ChildSosInProgressKeys.body), findsNothing);
    expect(find.byKey(ChildSosInProgressKeys.cancelCta), findsNothing);
  });

  testWidgets('cancel confirm → resolve + onResolved', (tester) async {
    final repo = InMemorySosAlertRepository(
      initialActive: InMemorySosAlertRepository.demoActive(),
    );
    var resolved = false;

    await _pump(
      tester,
      ChildSosInProgressScreen(
        repository: repo,
        roleOverride: AppRole.child,
        onResolved: () => resolved = true,
      ),
    );

    await tester.ensureVisible(find.byKey(ChildSosInProgressKeys.cancelCta));
    await tester.tap(find.byKey(ChildSosInProgressKeys.cancelCta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(ChildSosInProgressKeys.cancelSheet), findsOneWidget);
    await tester.tap(find.byKey(ChildSosInProgressKeys.confirmSafe));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(resolved, isTrue);
    expect(repo.resolveCount, 1);
    expect(await repo.loadActive(), isNull);
  });

  testWidgets('call father seam fires', (tester) async {
    final repo = InMemorySosAlertRepository(
      initialActive: InMemorySosAlertRepository.demoActive(),
    );
    var called = false;

    await _pump(
      tester,
      ChildSosInProgressScreen(
        repository: repo,
        roleOverride: AppRole.child,
        onCallFather: () => called = true,
        onResolved: () {},
      ),
    );

    await tester.tap(find.byKey(ChildSosInProgressKeys.callFather));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('empty — no active alert + open SOS button seam', (tester) async {
    final repo = InMemorySosAlertRepository();
    var opened = false;

    await _pump(
      tester,
      ChildSosInProgressScreen(
        repository: repo,
        roleOverride: AppRole.child,
        onOpenSosButton: () => opened = true,
      ),
    );

    expect(find.byKey(ChildSosInProgressKeys.empty), findsOneWidget);
    expect(find.byKey(ChildSosInProgressKeys.body), findsNothing);
    await tester.tap(find.byKey(ChildSosInProgressKeys.openButtonCta));
    await tester.pump();
    expect(opened, isTrue);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
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
      builder: (context, childWidget) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: childWidget!,
        );
      },
      home: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
