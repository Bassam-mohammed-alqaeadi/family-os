import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n07_privacy/audit_log_models.dart';
import 'package:family_os/features/n07_privacy/audit_log_repository.dart';
import 'package:family_os/features/n07_privacy/audit_log_screen.dart';

void main() {
  testWidgets('empty state shows append banner + empty', (tester) async {
    final repo = InMemoryAuditLogRepository(seed: auditLogEmptyFixture());
    await _pump(tester, repository: repo);

    expect(find.byKey(AuditLogKeys.empty), findsOneWidget);
    expect(find.byKey(AuditLogKeys.appendBanner), findsOneWidget);
    expect(find.byKey(AuditLogKeys.body), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.delete_forever), findsNothing);
  });

  testWidgets('one entry loads body + row', (tester) async {
    final repo = InMemoryAuditLogRepository(seed: auditLogOneFixture());
    await _pump(tester, repository: repo);

    expect(find.byKey(AuditLogKeys.body), findsOneWidget);
    expect(find.byKey(AuditLogKeys.list), findsOneWidget);
    expect(find.byKey(AuditLogKeys.entry('audit-consent-1')), findsOneWidget);
    expect(find.byKey(AuditLogKeys.empty), findsNothing);
  });

  testWidgets('prototype many entries · no delete control', (tester) async {
    final repo = InMemoryAuditLogRepository(seed: auditLogPrototypeFixture());
    await _pump(tester, repository: repo);

    expect(find.byKey(AuditLogKeys.body), findsOneWidget);
    expect(find.byKey(AuditLogKeys.appendBanner), findsOneWidget);
    expect(find.byKey(AuditLogKeys.entry('audit-sos-1')), findsOneWidget);
    expect(find.byKey(AuditLogKeys.entry('audit-level-1')), findsOneWidget);
    expect(find.byKey(AuditLogKeys.entry('audit-unlock-1')), findsOneWidget);
    expect(find.byKey(AuditLogKeys.entry('audit-forget-1')), findsOneWidget);
    expect(find.byKey(AuditLogKeys.entry('audit-consent-1')), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.delete_forever), findsNothing);
    expect(find.widgetWithText(TextButton, 'Delete'), findsNothing);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryAuditLogRepository(seed: auditLogOneFixture())
      ..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(AuditLogKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(AuditLogKeys.body), findsOneWidget);
  });

  testWidgets('mother partner may view list', (tester) async {
    final repo = InMemoryAuditLogRepository(seed: auditLogPrototypeFixture());
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
    );

    expect(find.byKey(AuditLogKeys.body), findsOneWidget);
    expect(find.byKey(AuditLogKeys.observerHint), findsNothing);
  });

  testWidgets('mother observer view-only hint', (tester) async {
    final repo = InMemoryAuditLogRepository(seed: auditLogOneFixture());
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );

    expect(find.byKey(AuditLogKeys.body), findsOneWidget);
    expect(find.byKey(AuditLogKeys.observerHint), findsOneWidget);
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = 0;
    final repo = InMemoryAuditLogRepository(seed: auditLogPrototypeFixture());
    await _pump(
      tester,
      repository: repo,
      role: AppRole.child,
      onSos: () => sos++,
    );

    expect(find.byKey(AuditLogKeys.childLean), findsOneWidget);
    expect(find.byKey(AuditLogKeys.body), findsNothing);

    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });

  test('repository append-only · no update/delete API', () {
    final repo = InMemoryAuditLogRepository(seed: auditLogEmptyFixture());
    expect(repo.lengthForTests, 0);

    repo.append(
      AuditLogEntry(
        id: 'a1',
        kind: AuditLogEntryKind.forgetUsed,
        actor: AuditLogActor.father,
        at: DateTime.utc(2026, 9, 22),
      ),
    );
    expect(repo.lengthForTests, 1);

    // R10 static contract: product interface has only load + append.
    expect(AuditLogRepository, isNot(equals(Object)));
    final methods = <String>{'load', 'append'};
    expect(methods.contains('update'), isFalse);
    expect(methods.contains('delete'), isFalse);
    expect(methods.contains('remove'), isFalse);
    expect(methods.contains('clear'), isFalse);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required AuditLogRepository repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
  VoidCallback? onSos,
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
        home: AuditLogScreen(
          repository: repository,
          roleOverride: role,
          motherLevel: motherLevel,
          onSos: onSos,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}
