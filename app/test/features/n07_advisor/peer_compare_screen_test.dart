import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n07_advisor/peer_compare_repository.dart';
import 'package:family_os/features/n07_advisor/peer_compare_screen.dart';

void main() {
  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryPeerCompareRepository(
        seed: peerCompareEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(PeerCompareKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('prototype anonymous metrics', (tester) async {
    await _pump(
      tester,
      repository: InMemoryPeerCompareRepository(
        seed: peerComparePrototypeFixture(),
      ),
    );
    expect(find.byKey(PeerCompareKeys.body), findsOneWidget);
    expect(find.byKey(PeerCompareKeys.privacy), findsOneWidget);
    expect(find.byKey(PeerCompareKeys.metrics), findsOneWidget);
    expect(find.textContaining('anonymous'), findsOneWidget);
    expect(find.byKey(PeerCompareKeys.compass), findsOneWidget);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryPeerCompareRepository(seed: peerCompareOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(PeerCompareKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(PeerCompareKeys.body), findsOneWidget);
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);
    expect(find.byKey(PeerCompareKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(PeerCompareKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  PeerCompareRepository? repository,
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
        home: PeerCompareScreen(
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
