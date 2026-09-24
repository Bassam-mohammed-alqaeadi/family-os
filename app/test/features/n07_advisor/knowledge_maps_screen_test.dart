import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n07_advisor/knowledge_maps_repository.dart';
import 'package:family_os/features/n07_advisor/knowledge_maps_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryKnowledgeMapsRepository(
      seed: knowledgeMapsEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(KnowledgeMapsKeys.empty), findsOneWidget);
    expect(find.byKey(KnowledgeMapsKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('one path loads body + learning card', (tester) async {
    final repo = InMemoryKnowledgeMapsRepository(
      seed: knowledgeMapsOneFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(KnowledgeMapsKeys.body), findsOneWidget);
    expect(find.byKey(KnowledgeMapsKeys.learningCard), findsOneWidget);
    expect(find.byKey(KnowledgeMapsKeys.pathRow('path-math')), findsOneWidget);
    expect(find.byKey(KnowledgeMapsKeys.empty), findsNothing);
  });

  testWidgets('prototype paths → FAT-072/049; dinner next+send', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryKnowledgeMapsRepository(
      seed: knowledgeMapsPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(KnowledgeMapsKeys.body), findsOneWidget);
    expect(find.byKey(KnowledgeMapsKeys.pathRow('path-quran')), findsOneWidget);
    expect(find.byKey(KnowledgeMapsKeys.pathRow('path-math')), findsOneWidget);
    expect(find.byKey(KnowledgeMapsKeys.socialBar), findsOneWidget);
    expect(find.byKey(KnowledgeMapsKeys.dinnerCard), findsOneWidget);
    expect(find.textContaining('Qur'), findsOneWidget);

    await tester.tap(find.byKey(KnowledgeMapsKeys.pathCta('path-quran')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-072'));

    await tester.tap(find.byKey(KnowledgeMapsKeys.pathCta('path-math')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-049'));

    await tester.ensureVisible(find.byKey(KnowledgeMapsKeys.dinnerNextCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(KnowledgeMapsKeys.dinnerNextCta));
    await tester.pumpAndSettle();
    expect(find.textContaining('best thing that happened'), findsOneWidget);

    await tester.ensureVisible(find.byKey(KnowledgeMapsKeys.dinnerSendCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(KnowledgeMapsKeys.dinnerSendCta));
    await tester.pump();
    expect(find.textContaining('Sent to family chat'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryKnowledgeMapsRepository(
      seed: knowledgeMapsOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(KnowledgeMapsKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(KnowledgeMapsKeys.body), findsOneWidget);
  });

  testWidgets('mother observer blocks path + dinner', (tester) async {
    final nav = <String>[];
    final repo = InMemoryKnowledgeMapsRepository(
      seed: knowledgeMapsPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(KnowledgeMapsKeys.observerHint), findsOneWidget);

    await tester.tap(find.byKey(KnowledgeMapsKeys.pathCta('path-math')));
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
    expect(find.textContaining('View only'), findsWidgets);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(KnowledgeMapsKeys.dinnerSendCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(KnowledgeMapsKeys.dinnerSendCta));
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('mother partner may open math path', (tester) async {
    final nav = <String>[];
    final repo = InMemoryKnowledgeMapsRepository(
      seed: knowledgeMapsPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(KnowledgeMapsKeys.observerHint), findsNothing);
    await tester.tap(find.byKey(KnowledgeMapsKeys.pathCta('path-math')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-049'));
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = 0;
    await _pump(tester, role: AppRole.child, onSos: () => sos++);

    expect(find.byKey(KnowledgeMapsKeys.childLean), findsOneWidget);
    expect(find.byKey(KnowledgeMapsKeys.body), findsNothing);
    expect(find.byKey(KnowledgeMapsKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(KnowledgeMapsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  KnowledgeMapsRepository? repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
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
        home: KnowledgeMapsScreen(
          repository: repository,
          roleOverride: role,
          motherLevel: motherLevel,
          onSos: onSos,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}
