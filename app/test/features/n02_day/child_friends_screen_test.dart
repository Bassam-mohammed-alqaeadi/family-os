import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/child_friends_repository.dart';
import 'package:family_os/features/n02_day/child_friends_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty + empty CTA add toast', (tester) async {
    await _pump(
      tester,
      repository: InMemoryChildFriendsRepository(
        seed: childFriendsEmptyFixture(),
      ),
    );
    expect(find.byKey(ChildFriendsKeys.empty), findsOneWidget);
    await tester.tap(find.text('Request add friend'));
    await tester.pump();
    expect(find.textContaining('Request sent'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('body + chat/add toasts', (tester) async {
    await _pump(
      tester,
      repository: InMemoryChildFriendsRepository(
        seed: childFriendsPrototypeFixture(),
      ),
    );
    expect(find.byKey(ChildFriendsKeys.body), findsOneWidget);

    await tester.tap(find.byKey(ChildFriendsKeys.chat('f1')));
    await tester.pump();
    expect(find.textContaining('Opened a safe chat'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(ChildFriendsKeys.addCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildFriendsKeys.addCta));
    await tester.pump();
    expect(find.textContaining('Request sent'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildFriendsRepository(seed: childFriendsOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildFriendsKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildFriendsKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildFriendsKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildFriendsRepository(
        seed: childFriendsOneFixture(),
      ),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildFriendsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildFriendsRepository? repository,
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
        home: ChildFriendsScreen(
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
