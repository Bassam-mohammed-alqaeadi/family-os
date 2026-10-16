import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_repository.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_screen.dart';
import 'package:family_os/foundation_gate/child_minutes_balance_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const _balanceBody =
    '{"daily":0,"temporary":0,"free":0,'
    '"apps":[{"appId":"youtube","minutes":25},{"appId":"games","minutes":10}],'
    '"total":35,"asOf":"2026-10-15T10:00:00.000Z"}';

/// Answers at the transport seam only: the client and the repository run for real.
final class _FakeBalanceTransport implements ChildMinutesBalanceTransport {
  _FakeBalanceTransport(this._body, {this.deviceId = 'device-1'});

  final String _body;
  final String? deviceId;

  @override
  Future<String?> configuredDeviceId() async => deviceId;

  @override
  Future<FoundationGateHttpResponse> readBalance(String id) async =>
      FoundationGateHttpResponse(statusCode: 200, body: _body);
}

void main() {
  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildWalletRepository(
        seed: childWalletEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildWalletKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('prototype body + earn nav', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildWalletRepository(
        seed: childWalletPrototypeFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildWalletKeys.body), findsOneWidget);
    expect(find.byKey(ChildWalletKeys.hero), findsOneWidget);
    expect(find.textContaining('minutes'), findsWidgets);
    expect(find.textContaining('pride'), findsOneWidget);

    await tester.ensureVisible(find.byKey(ChildWalletKeys.earnTasks));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildWalletKeys.earnTasks));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-022'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildWalletRepository(seed: childWalletOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildWalletKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildWalletKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildWalletKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildWalletRepository(seed: childWalletOneFixture()),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildWalletKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });

  testWidgets('CHD-019 reads the server balance and is never simulated', (tester) async {
    final client = ChildMinutesBalanceClient(
      transport: _FakeBalanceTransport(_balanceBody),
    );
    final repo = ServerChildWalletRepository(client: client);

    final snap = await repo.load();
    expect(snap.simulated, isFalse);
    expect(snap.totalMinutes, 35);

    await _pump(tester, repository: repo);

    expect(find.byKey(ChildWalletKeys.appRow('youtube')), findsOneWidget);
    expect(find.byKey(ChildWalletKeys.appRow('games')), findsOneWidget);
    expect(find.textContaining('35'), findsWidgets);
  });

  testWidgets('unpaired handset shows the empty state, never a number', (tester) async {
    final repo = ServerChildWalletRepository(
      client: ChildMinutesBalanceClient(
        transport: _FakeBalanceTransport(_balanceBody, deviceId: null),
      ),
    );

    await _pump(tester, repository: repo);

    expect(find.byKey(ChildWalletKeys.empty), findsOneWidget);
    expect(find.textContaining('35'), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildWalletRepository? repository,
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
        home: ChildWalletScreen(
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
