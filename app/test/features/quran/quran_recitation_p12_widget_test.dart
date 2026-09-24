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
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:family_os/features/n14_studio/quran_progress_models.dart';
import 'package:family_os/features/n14_studio/quran_progress_repository.dart';
import 'package:family_os/features/n14_studio/quran_progress_screen.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_screen.dart';
import 'package:family_os/features/quran/quran_recitation_models.dart';
import 'package:family_os/features/quran/quran_recitation_repository.dart';
import 'package:family_os/features/quran/quran_ward_plan_repository.dart';

void main() {
  tearDown(AppToast.dismiss);

  test('approve earns play minutes via WalletLedger', () async {
    final prefs = MemoryScreenTimePolicyPrefsStore();
    final wallet = WalletLedger(PrefsScreenTimePolicyRepository(prefs));
    final bus = InMemoryQuranRecitationRepository();
    addTearDown(bus.dispose);
    final childId = ChildId('child_a');
    await bus.submit(
      QuranRecitationSubmitRequest(
        childId: childId,
        surahKey: 'naba',
        rewardMinutes: Minutes(30),
      ),
    );
    final repo = InMemoryQuranProgressRepository(
      seed: quranProgressOneFixture(),
      recitations: bus,
      wallet: wallet,
      childId: childId,
    );
    final before = await wallet.balance(childId: childId, appId: 'play');
    await repo.approveRecitation();
    final after = await wallet.balance(childId: childId, appId: 'play');
    expect(after.inMinutes, before.inMinutes + 30);
    final latest = await bus.latestForChild(childId);
    expect(latest!.status, QuranRecitationSubmitStatus.approved);
  });

  testWidgets('P12: child record → father approve → child approved', (
    tester,
  ) async {
    final plans = InMemoryQuranWardPlanRepository();
    final bus = InMemoryQuranRecitationRepository();
    addTearDown(plans.dispose);
    addTearDown(bus.dispose);
    final prefs = MemoryScreenTimePolicyPrefsStore();
    final wallet = WalletLedger(PrefsScreenTimePolicyRepository(prefs));

    final childRepo = InMemoryChildQuranWardRepository(
      seed: childQuranWardOneFixture(),
      plans: plans,
      recitations: bus,
    );
    final fatherRepo = InMemoryQuranProgressRepository(
      seed: quranProgressOneFixture().copyWith(
        recitationStatus: QuranRecitationStatus.none,
      ),
      plans: plans,
      recitations: bus,
      wallet: wallet,
    );

    await _pumpChild(tester, repository: childRepo);
    await tester.tap(find.byKey(ChildQuranWardKeys.recordCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.textContaining('Sent'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _pumpFather(tester, repository: fatherRepo);
    expect(find.byKey(QuranProgressKeys.recitationCard), findsOneWidget);
    expect(find.byKey(QuranProgressKeys.approveCta), findsOneWidget);

    await tester.ensureVisible(find.byKey(QuranProgressKeys.approveCta));
    await tester.tap(find.byKey(QuranProgressKeys.approveCta));
    await tester.pump();
    expect(find.textContaining('Approved'), findsWidgets);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.byKey(QuranProgressKeys.approvedBanner), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _pumpChild(tester, repository: childRepo);
    expect(find.textContaining('Approved'), findsWidgets);
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
