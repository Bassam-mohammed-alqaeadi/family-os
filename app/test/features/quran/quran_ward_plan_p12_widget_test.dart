import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n14_studio/quran_progress_repository.dart';
import 'package:family_os/features/n14_studio/quran_progress_screen.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_screen.dart';
import 'package:family_os/features/quran/quran_ward_plan_models.dart';
import 'package:family_os/features/quran/quran_ward_plan_repository.dart';

void main() {
  tearDown(AppToast.dismiss);

  test('QuranWardPlanRepository publish lists for child', () async {
    final bus = InMemoryQuranWardPlanRepository();
    addTearDown(bus.dispose);
    final plan = await bus.publish(
      QuranWardPlanPublishRequest(
        childId: ChildId('child_a'),
        surahKey: 'naba',
        fromAyah: 1,
        toAyah: 40,
        reciterKey: 'defaultReciter',
        rewardMinutes: Minutes(30),
        ayahKey: 'naba1',
      ),
    );
    expect(plan.surahKey, 'naba');
    final latest = await bus.latestForChild(ChildId('child_a'));
    expect(latest!.id, plan.id);
  });

  testWidgets('P12: father publish plan → child ward shows live surah', (
    tester,
  ) async {
    final bus = InMemoryQuranWardPlanRepository();
    addTearDown(bus.dispose);
    final father = InMemoryQuranProgressRepository(
      seed: quranProgressPrototypeFixture(),
      plans: bus,
    );
    final child = InMemoryChildQuranWardRepository(
      seed: childQuranWardOneFixture(),
      plans: bus,
    );

    await _pumpFather(tester, repository: father);
    expect(find.textContaining('An-Naba'), findsWidgets);

    await tester.ensureVisible(find.byKey(QuranProgressKeys.cycleSurahCta));
    await tester.tap(find.byKey(QuranProgressKeys.cycleSurahCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.textContaining('Al-Mulk'), findsWidgets);

    await tester.ensureVisible(find.byKey(QuranProgressKeys.publishPlanCta));
    await tester.tap(find.byKey(QuranProgressKeys.publishPlanCta));
    await tester.pump();
    expect(find.textContaining('Ward plan sent'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _pumpChild(tester, repository: child);
    expect(find.textContaining('Al-Mulk'), findsWidgets);
    expect(find.textContaining('Ayahs (1–30)'), findsOneWidget);
  });
}

Future<void> _pumpFather(
  WidgetTester tester, {
  required QuranProgressRepository repository,
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

Future<void> _pumpChild(
  WidgetTester tester, {
  required ChildQuranWardRepository repository,
}) async {
  await tester.pumpWidget(
    CurrentRole(
      notifier: RoleController(AppRole.child),
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
        home: ChildQuranWardScreen(
          repository: repository,
          roleOverride: AppRole.child,
          onNavigate: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
