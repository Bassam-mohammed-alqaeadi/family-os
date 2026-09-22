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
import 'package:family_os/features/n14_studio/community_library_repository.dart';
import 'package:family_os/features/n14_studio/community_library_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-041', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCommunityLibraryRepository(
      seed: communityLibraryEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(CommunityLibraryKeys.empty), findsOneWidget);
    expect(find.byKey(CommunityLibraryKeys.body), findsNothing);

    await tester.tap(find.text('Add from any source'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-041'));
  });

  testWidgets('one pack; import → FAT-047', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCommunityLibraryRepository(
      seed: communityLibraryOneFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(CommunityLibraryKeys.body), findsOneWidget);
    expect(
      find.byKey(CommunityLibraryKeys.packageRow('pkg-fractions')),
      findsOneWidget,
    );
    expect(find.byKey(CommunityLibraryKeys.publishCard), findsOneWidget);

    await tester.tap(
      find.byKey(CommunityLibraryKeys.packageRow('pkg-fractions')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(CommunityLibraryKeys.importSheet), findsOneWidget);

    await tester.tap(find.byKey(CommunityLibraryKeys.importCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-047'));
  });

  testWidgets('many packs + path CTA → FAT-047', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCommunityLibraryRepository(
      seed: communityLibraryManyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(
      find.byKey(CommunityLibraryKeys.packageRow('pkg-fractions')),
      findsOneWidget,
    );
    expect(
      find.byKey(CommunityLibraryKeys.packageRow('pkg-juz')),
      findsOneWidget,
    );
    expect(
      find.byKey(CommunityLibraryKeys.packageRow('pkg-english')),
      findsOneWidget,
    );
    expect(find.byKey(CommunityLibraryKeys.controlsNote), findsOneWidget);

    await tester.ensureVisible(find.byKey(CommunityLibraryKeys.pathCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CommunityLibraryKeys.pathCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-047'));
  });

  testWidgets('father publish toast', (tester) async {
    final repo = InMemoryCommunityLibraryRepository(
      seed: communityLibraryManyFixture(),
    );
    await _pump(tester, repository: repo);

    await tester.ensureVisible(find.byKey(CommunityLibraryKeys.publishCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CommunityLibraryKeys.publishCta));
    await tester.pump();
    expect(find.textContaining('Sent for review'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryCommunityLibraryRepository(
      seed: communityLibraryOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(CommunityLibraryKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(CommunityLibraryKeys.body), findsOneWidget);
  });

  testWidgets('mother observer view-only — import does not navigate', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryCommunityLibraryRepository(
      seed: communityLibraryOneFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(CommunityLibraryKeys.observerHint), findsOneWidget);

    await tester.tap(
      find.byKey(CommunityLibraryKeys.packageRow('pkg-fractions')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CommunityLibraryKeys.importCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner import → FAT-047', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCommunityLibraryRepository(
      seed: communityLibraryOneFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(CommunityLibraryKeys.observerHint), findsNothing);

    await tester.tap(
      find.byKey(CommunityLibraryKeys.packageRow('pkg-fractions')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CommunityLibraryKeys.importCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-047'));
  });

  testWidgets('mother partner publish needs father approval toast', (
    tester,
  ) async {
    final repo = InMemoryCommunityLibraryRepository(
      seed: communityLibraryManyFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
    );

    await tester.ensureVisible(find.byKey(CommunityLibraryKeys.publishCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CommunityLibraryKeys.publishCta));
    await tester.pump();
    expect(find.textContaining('father approval'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(CommunityLibraryKeys.childLean), findsOneWidget);
    expect(find.byKey(CommunityLibraryKeys.body), findsNothing);
    expect(find.byKey(CommunityLibraryKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(CommunityLibraryKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  CommunityLibraryRepository? repository,
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
        home: CommunityLibraryScreen(
          repository: repository,
          roleOverride: role,
          motherLevel: motherLevel,
          onSos: onSos,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
