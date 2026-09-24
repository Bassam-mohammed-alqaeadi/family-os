import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/child_stickers_backgrounds_repository.dart';
import 'package:family_os/features/n02_day/child_stickers_backgrounds_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-007', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildStickersBackgroundsRepository(
        seed: childStickersBackgroundsEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildStickersBackgroundsKeys.empty), findsOneWidget);
    await tester.tap(find.text('My chats'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-007'));
  });

  testWidgets('select background + unlock remind', (tester) async {
    final repo = InMemoryChildStickersBackgroundsRepository(
      seed: childStickersBackgroundsPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    expect(find.byKey(ChildStickersBackgroundsKeys.stickers), findsOneWidget);
    await tester.tap(
      find.byKey(ChildStickersBackgroundsKeys.background('indigo')),
    );
    await tester.pump();
    expect(find.textContaining('Background changed'), findsOneWidget);
    expect(repo.selectedBackgroundId, 'indigo');
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildStickersBackgroundsKeys.unlockCta));
    await tester.pump();
    expect(
      find.text(
        'Space pack unlocks automatically after two wards — you are 1 ward away!',
      ),
      findsOneWidget,
    );
    expect(repo.remindTapped, isTrue);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildStickersBackgroundsRepository(
      seed: childStickersBackgroundsOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildStickersBackgroundsKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildStickersBackgroundsKeys.body), findsOneWidget);
  });

  testWidgets('parent lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.father, onSos: () => sos = true);
    expect(find.byKey(ChildStickersBackgroundsKeys.parentLean), findsOneWidget);
    await tester.tap(find.byKey(ChildStickersBackgroundsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildStickersBackgroundsRepository? repository,
  AppRole role = AppRole.child,
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
        home: ChildStickersBackgroundsScreen(
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
