import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/app_control/app_control.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/capability_honesty_badge.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/app_deny_page.dart';
import 'package:family_os/features/n03_screen_time/child_apps_models.dart';
import 'package:family_os/features/n03_screen_time/child_apps_repository.dart';
import 'package:family_os/features/n03_screen_time/child_apps_screen.dart';
import 'package:family_os/features/n03_screen_time/new_app_approval_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  late MemoryLocalDatabase db;
  late AppControlService service;
  final family = FamilyId('fam_ux');
  final child = ChildId('demo-child');
  final now = DateTime.utc(2026, 9, 24, 20);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    final store = LocalAppControlStore(db, clock: () => now);
    service = AppControlService(
      documents: store,
      exceptions: LocalAppAccessExceptionStore(db),
      lockNow: LocalAppLockNowStore(db),
      installs: LocalAppInstallTicketStore(db),
      familyId: family,
      clock: () => now,
      idFactory: () => 'ux-1',
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('FAT-034 honesty + protected badge + block writes AC', (
    tester,
  ) async {
    final repo = InMemoryChildAppsRepository(
      seed: {
        'demo-child': [
          const ChildAppEntry(
            id: 'minecraft',
            name: 'Minecraft',
            category: ChildAppCategory.games,
            status: ChildAppStatus.allowed,
            usedMins: 10,
            limitMins: 60,
          ),
          const ChildAppEntry(
            id: 'quran',
            name: 'Quran',
            category: ChildAppCategory.edu,
            status: ChildAppStatus.free,
            limitMins: -1,
          ),
        ],
      },
    );

    await tester.pumpWidget(
      _app(
        role: AppRole.father,
        child: ChildAppsScreen(
          repository: repo,
          appControl: service,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildAppsKeys.honestyBanner), findsOneWidget);
    expect(find.byType(CapabilityHonestyBadge), findsWidgets);
    expect(find.byKey(ChildAppsKeys.protectedBadge('quran')), findsOneWidget);

    await tester.tap(find.byKey(ChildAppsKeys.appTile('minecraft')));
    await tester.pumpAndSettle();
    expect(find.byKey(ChildAppsKeys.previewDeny('minecraft')), findsOneWidget);
    await tester.tap(find.byKey(ChildAppsKeys.block('minecraft')));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(repo.appsFor(child).first.status, ChildAppStatus.blocked);
    final doc = await service.loadEffective(child);
    expect(doc.dispositionOf('minecraft'), AppPackageDisposition.block);
  });

  testWidgets('AppDenyPage exception request does not rewrite block', (
    tester,
  ) async {
    await service.setPermanentBlock(
      childId: child,
      packageId: 'roblox',
      actor: const AppControlActor.father(),
    );
    final verdict = AppControlVerdict.deny(
      policyVersion: 1,
      denySource: AppControlDenySource.permanentBlock,
      underlyingDisposition: AppPackageDisposition.block,
    );
    var requested = false;

    await tester.pumpWidget(
      _app(
        role: AppRole.child,
        child: AppDenyPage(
          packageId: 'roblox',
          packageLabel: 'Roblox',
          verdict: verdict,
          childId: child,
          appControl: service,
          onExceptionRequested: () => requested = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppDenyPageKeys.disclosure), findsOneWidget);
    expect(find.byKey(AppDenyPageKeys.sosCta), findsOneWidget);
    await tester.tap(find.byKey(AppDenyPageKeys.exceptionCta));
    await tester.pumpAndSettle();
    expect(requested, isTrue);

    final doc = await service.loadEffective(child);
    expect(doc.dispositionOf('roblox'), AppPackageDisposition.block);
  });

  testWidgets('FAT-035 approve is child-scoped via AC install ticket', (
    tester,
  ) async {
    final repo = InMemoryChildAppsRepository(
      seed: {
        'demo-child': [
          const ChildAppEntry(
            id: 'snapchat',
            name: 'Snapchat',
            category: ChildAppCategory.social,
            status: ChildAppStatus.pending,
            limitMins: 30,
          ),
        ],
      },
    );

    await tester.pumpWidget(
      _app(
        role: AppRole.mother,
        motherLevel: MotherLevel.partner,
        child: NewAppApprovalScreen(
          repository: repo,
          appControl: service,
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.partner,
          appId: 'snapchat',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(NewAppApprovalKeys.childScopedHonesty), findsOneWidget);
    await tester.tap(find.byKey(NewAppApprovalKeys.approve));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(repo.appsFor(child).single.status, ChildAppStatus.allowed);
    final childDoc = await service.loadEffective(child);
    expect(childDoc.dispositionOf('snapchat'), AppPackageDisposition.allow);
    final baseline = await LocalAppControlStore(db).loadFamilyBaseline(family);
    expect(baseline?.dispositionOf('snapchat'), isNull);
  });

  test('CapabilityStatus.mockRemote remains for os_intercept', () {
    expect(CapabilityStatus.mockRemote.wireName, 'MOCK-REMOTE');
  });
}

Widget _app({
  required Widget child,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
}) {
  return CurrentRole(
    notifier: RoleController(role),
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildFamilyTheme(),
      home: child,
    ),
  );
}
