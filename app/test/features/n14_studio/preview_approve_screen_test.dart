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
import 'package:family_os/features/n14_studio/preview_approve_repository.dart';
import 'package:family_os/features/n14_studio/preview_approve_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('father: quiz+lesson + 90s rule; approve → FAT-045', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryPreviewApproveRepository(
      seed: previewApprovePrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(PreviewApproveKeys.body), findsOneWidget);
    expect(find.byKey(PreviewApproveKeys.ruleBanner), findsOneWidget);
    expect(find.byKey(PreviewApproveKeys.quizCard), findsOneWidget);
    expect(find.byKey(PreviewApproveKeys.lessonCard), findsOneWidget);
    expect(find.byKey(PreviewApproveKeys.questionRow('q1')), findsOneWidget);
    expect(find.byKey(PreviewApproveKeys.timingNote), findsOneWidget);
    expect(find.textContaining('within the 90s rule'), findsOneWidget);

    await tester.ensureVisible(find.byKey(PreviewApproveKeys.approveCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PreviewApproveKeys.approveCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-045'));
  });

  testWidgets('reject clears content to empty', (tester) async {
    final repo = InMemoryPreviewApproveRepository(
      seed: previewApprovePrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    await tester.ensureVisible(find.byKey(PreviewApproveKeys.rejectCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PreviewApproveKeys.rejectCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(find.byKey(PreviewApproveKeys.empty), findsOneWidget);
    expect(find.byKey(PreviewApproveKeys.body), findsNothing);
  });

  testWidgets('swap replaces first question with q3', (tester) async {
    final repo = InMemoryPreviewApproveRepository(
      seed: previewApprovePrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(PreviewApproveKeys.questionRow('q1')), findsOneWidget);

    await tester.ensureVisible(find.byKey(PreviewApproveKeys.swapCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PreviewApproveKeys.swapCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(find.byKey(PreviewApproveKeys.questionRow('q3')), findsOneWidget);
    expect(find.byKey(PreviewApproveKeys.questionRow('q1')), findsNothing);
  });

  testWidgets('delete removes first question', (tester) async {
    final repo = InMemoryPreviewApproveRepository(
      seed: previewApprovePrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    await tester.ensureVisible(find.byKey(PreviewApproveKeys.deleteCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PreviewApproveKeys.deleteCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(find.byKey(PreviewApproveKeys.questionRow('q1')), findsNothing);
    expect(find.byKey(PreviewApproveKeys.questionRow('q2')), findsOneWidget);
  });

  testWidgets('empty state when no preview', (tester) async {
    final repo = InMemoryPreviewApproveRepository(
      seed: previewApproveEmptyFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(PreviewApproveKeys.empty), findsOneWidget);
    expect(find.byKey(PreviewApproveKeys.body), findsNothing);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryPreviewApproveRepository(
      seed: previewApprovePrototypeFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(PreviewApproveKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(PreviewApproveKeys.body), findsOneWidget);
  });

  testWidgets('mother observer view-only — approve does not navigate', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryPreviewApproveRepository(
      seed: previewApprovePrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(PreviewApproveKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(find.byKey(PreviewApproveKeys.approveCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PreviewApproveKeys.approveCta));
    await tester.pumpAndSettle();
    expect(nav, isEmpty);

    await tester.ensureVisible(find.byKey(PreviewApproveKeys.rejectCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PreviewApproveKeys.rejectCta));
    await tester.pumpAndSettle();
    expect(find.byKey(PreviewApproveKeys.body), findsOneWidget);
  });

  testWidgets('mother partner can approve → FAT-045', (tester) async {
    final nav = <String>[];
    final repo = InMemoryPreviewApproveRepository(
      seed: previewApprovePrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(PreviewApproveKeys.observerHint), findsNothing);
    await tester.ensureVisible(find.byKey(PreviewApproveKeys.approveCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PreviewApproveKeys.approveCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-045'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(
      tester,
      role: AppRole.child,
      onSos: () => sos = true,
    );

    expect(find.byKey(PreviewApproveKeys.childLean), findsOneWidget);
    expect(find.byKey(PreviewApproveKeys.body), findsNothing);
    expect(find.byKey(PreviewApproveKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(PreviewApproveKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  PreviewApproveRepository? repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
  VoidCallback? onSos,
  void Function(String screenId)? onNavigate,
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
        home: PreviewApproveScreen(
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
