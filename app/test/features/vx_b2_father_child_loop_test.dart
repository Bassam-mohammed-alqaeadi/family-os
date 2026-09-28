import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n14_studio/quran_progress_repository.dart';
import 'package:family_os/features/n14_studio/quran_progress_screen.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_repository.dart';
import 'package:family_os/features/quran/quran_ward_plan_repository.dart';

/// VX-B2 · FVX-G-04 — father sets a tool for the 2nd child from the 2nd
/// child's profile; only the 2nd child's side sees it.
void main() {
  final first = ChildId('demo-child');
  final second = ChildId('child_b');

  setUp(resetStage1IdentityRuntimeForTest);
  tearDown(() {
    AppToast.dismiss();
    resetStage1IdentityRuntimeForTest();
  });

  testWidgets('ward plan for child 2 lands on child 2, not child 1', (
    tester,
  ) async {
    expect(stage1IdentityRuntime.activeChildId, first);

    final bus = InMemoryQuranWardPlanRepository();
    addTearDown(bus.dispose);
    final father = InMemoryQuranProgressRepository(
      seed: quranProgressPrototypeFixture(),
      plans: bus,
    );

    await _pumpFather(tester, repository: father, childId: second);
    await tester.ensureVisible(find.byKey(QuranProgressKeys.publishPlanCta));
    await tester.tap(find.byKey(QuranProgressKeys.publishPlanCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    final published = await bus.latestForChild(second);
    expect(published, isNotNull);
    expect(await bus.latestForChild(first), isNull);

    // Child side reads through the family context's selected child.
    final childSide = InMemoryChildQuranWardRepository(
      seed: childQuranWardEmptyFixture(),
      plans: bus,
    );

    stage1IdentityRuntime.setActiveChild(second);
    final onSecond = await childSide.load();
    expect(onSecond.hasWard, isTrue);
    expect(onSecond.surahKey, published!.surahKey);

    stage1IdentityRuntime.setActiveChild(first);
    final onFirst = await childSide.load();
    expect(onFirst.hasWard, isFalse);
  });
}

Future<void> _pumpFather(
  WidgetTester tester, {
  required QuranProgressRepository repository,
  required ChildId childId,
}) async {
  final roleCtrl = RoleController(AppRole.father);
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
        home: QuranProgressScreen(
          childId: childId,
          repository: repository,
          roleOverride: AppRole.father,
          motherLevel: MotherLevel.partner,
          onNavigate: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
