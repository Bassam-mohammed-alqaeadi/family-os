import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/child_media_share_repository.dart';
import 'package:family_os/features/n02_day/child_media_share_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-007', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildMediaShareRepository(
        seed: childMediaShareEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildMediaShareKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to my chats'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-007'));
  });

  testWidgets('share photo toast', (tester) async {
    await _pump(
      tester,
      repository: InMemoryChildMediaShareRepository(
        seed: childMediaShareOneFixture(),
      ),
    );
    expect(find.byKey(ChildMediaShareKeys.body), findsOneWidget);
    expect(find.byKey(ChildMediaShareKeys.row('m1')), findsOneWidget);
    expect(find.byKey(ChildMediaShareKeys.safeCircleBanner), findsOneWidget);

    await tester.tap(find.byKey(ChildMediaShareKeys.quickAction('photo')));
    await tester.pump();
    expect(find.textContaining('Capture and share'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildMediaShareRepository(
      seed: childMediaShareOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildMediaShareKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildMediaShareKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildMediaShareKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildMediaShareRepository(
        seed: childMediaShareOneFixture(),
      ),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildMediaShareKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildMediaShareRepository? repository,
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
        home: ChildMediaShareScreen(
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
