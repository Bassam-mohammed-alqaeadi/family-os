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
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:family_os/features/n14_studio/quran_progress_models.dart';
import 'package:family_os/features/n14_studio/quran_progress_repository.dart';
import 'package:family_os/features/n14_studio/quran_progress_screen.dart';
import 'package:family_os/features/quran/quran_recitation_repository.dart';
import 'package:family_os/features/quran/quran_ward_plan_repository.dart';

void main() {
  tearDown(AppToast.dismiss);

  InMemoryQuranProgressRepository isolated({QuranProgressSnapshot? seed}) {
    final bus = InMemoryQuranRecitationRepository();
    final plans = InMemoryQuranWardPlanRepository();
    addTearDown(bus.dispose);
    addTearDown(plans.dispose);
    return InMemoryQuranProgressRepository(
      seed: seed,
      recitations: bus,
      plans: plans,
      wallet: WalletLedger(
        PrefsScreenTimePolicyRepository(MemoryScreenTimePolicyPrefsStore()),
      ),
    );
  }

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = isolated(seed: quranProgressEmptyFixture());
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(QuranProgressKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('prototype hero + approve minutes reward', (tester) async {
    final repo = isolated(seed: quranProgressPrototypeFixture());
    await _pump(tester, repository: repo);

    expect(find.byKey(QuranProgressKeys.body), findsOneWidget);
    expect(find.byKey(QuranProgressKeys.heroCard), findsOneWidget);
    expect(find.byKey(QuranProgressKeys.recitationCard), findsOneWidget);
    expect(find.textContaining('An-Naba'), findsWidgets);

    await tester.ensureVisible(find.byKey(QuranProgressKeys.approveCta));
    await tester.tap(find.byKey(QuranProgressKeys.approveCta));
    await tester.pump();
    expect(
      find.textContaining("Approved Child One's recitation"),
      findsOneWidget,
    );
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.byKey(QuranProgressKeys.approvedBanner), findsOneWidget);
  });

  testWidgets('whisper + download toasts', (tester) async {
    final repo = isolated(seed: quranProgressPrototypeFixture());
    await _pump(tester, repository: repo);

    await tester.ensureVisible(find.byKey(QuranProgressKeys.whisperCta));
    await tester.tap(find.byKey(QuranProgressKeys.whisperCta));
    await tester.pump();
    expect(find.textContaining('whisper'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(repo.whisperCount, 1);

    await tester.ensureVisible(find.byKey(QuranProgressKeys.downloadCta));
    await tester.tap(find.byKey(QuranProgressKeys.downloadCta));
    await tester.pump();
    expect(find.textContaining('Download queued'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(repo.downloadCount, 1);
  });

  testWidgets('mother observer view-only', (tester) async {
    final repo = isolated(seed: quranProgressPrototypeFixture());
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );

    expect(find.byKey(QuranProgressKeys.observerHint), findsOneWidget);
    expect(find.byKey(QuranProgressKeys.approveCta), findsOneWidget);
    expect(find.byKey(QuranProgressKeys.approvedBanner), findsNothing);

    await tester.ensureVisible(find.byKey(QuranProgressKeys.approveCta));
    await tester.tap(find.byKey(QuranProgressKeys.approveCta));
    await tester.pumpAndSettle();
    expect(find.byKey(QuranProgressKeys.approvedBanner), findsNothing);
    expect(find.byKey(QuranProgressKeys.approveCta), findsOneWidget);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = isolated(seed: quranProgressOneFixture())
      ..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(QuranProgressKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(QuranProgressKeys.body), findsOneWidget);
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(QuranProgressKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(QuranProgressKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  QuranProgressRepository? repository,
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
        home: QuranProgressScreen(
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
