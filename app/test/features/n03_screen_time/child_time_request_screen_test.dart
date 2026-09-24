import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n02_day/request_inbox_screen.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_repository.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-004', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildTimeRequestRepository(
        seed: childTimeRequestEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildTimeRequestKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to my day'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-004'));
  });

  testWidgets('submit →004 + toast', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildTimeRequestRepository(
        seed: childTimeRequestOneFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildTimeRequestKeys.body), findsOneWidget);

    await tester.ensureVisible(find.byKey(ChildTimeRequestKeys.submitCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildTimeRequestKeys.submitCta));
    await tester.pump();
    expect(find.textContaining('reached your parents'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-004'));
  });

  testWidgets('tasked →022', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildTimeRequestRepository(
        seed: childTimeRequestTaskedFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildTimeRequestKeys.statusBanner), findsOneWidget);
    await tester.ensureVisible(find.byKey(ChildTimeRequestKeys.tasksCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildTimeRequestKeys.tasksCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-022'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildTimeRequestRepository(
      seed: childTimeRequestOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildTimeRequestKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildTimeRequestKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildTimeRequestKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildTimeRequestRepository(
        seed: childTimeRequestOneFixture(),
      ),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildTimeRequestKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });

  testWidgets('CHD-020 submit lands in FAT-033 pending inbox', (tester) async {
    final repo = InMemoryTimeRequestRepository();
    final service = TimeRequestService(repository: repo);
    addTearDown(service.dispose);
    final nav = <String>[];

    await _pump(
      tester,
      repository: ServiceChildTimeRequestRepository(
        service: service,
        repository: repo,
        childId: ChildId('demo-child'),
      ),
      onNavigate: nav.add,
    );

    await tester.ensureVisible(find.byKey(ChildTimeRequestKeys.submitCta));
    await tester.tap(find.byKey(ChildTimeRequestKeys.submitCta));
    await tester.pumpAndSettle();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-004'));

    final pending = await service.listPending();
    expect(pending, hasLength(1));

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
        home: RequestInboxScreen(
          service: service,
          role: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(RequestInboxKeys.list), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildTimeRequestRepository? repository,
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
        home: ChildTimeRequestScreen(
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
