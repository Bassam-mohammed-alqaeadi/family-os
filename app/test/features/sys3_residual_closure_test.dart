import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/link_success_screen.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/child_profile_screen.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/sys3_identity/sys3_identity_screens.dart';

void main() {
  IdentityRuntime primaryRuntime() {
    final accountId = AccountId('acc_owner');
    return IdentityRuntime(
      account: Account(id: accountId),
      session: Session(
        id: SessionId('sess_owner'),
        accountId: accountId,
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(
          id: FamilyId('fam_a'),
          name: 'Family A',
          ownerMemberId: MemberId('mem_owner'),
        ),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('mem_owner'),
          accountId: accountId,
          familyId: FamilyId('fam_a'),
          role: AppRole.father,
          tier: MembershipTier.primary,
          isPrimaryOwner: true,
        ),
      ],
      activeFamilyId: FamilyId('fam_a'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_a'),
      ),
      children: [
        ChildIdentity(id: ChildId('child_a'), familyId: FamilyId('fam_a')),
      ],
      devices: [
        DeviceIdentity(
          id: DeviceId('dev_1'),
          familyId: FamilyId('fam_a'),
          childId: ChildId('child_a'),
        ),
      ],
      enrollments: [
        Enrollment(
          id: EnrollmentId('enr_1'),
          deviceId: DeviceId('dev_1'),
          familyId: FamilyId('fam_a'),
          childId: ChildId('child_a'),
          createdAt: DateTime.utc(2026, 1, 1),
          state: EnrollmentState.enrolled,
        ),
      ],
    );
  }

  testWidgets(
    'enrollment revoke from profile opens sys3-revoke-confirm then revokes',
    (tester) async {
      final runtime = primaryRuntime();
      final management = RuntimeChildDeviceManagementRepository(
        runtime: runtime,
      );
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => ChildProfileScreen(
              childId: 'child_a',
              repository: InMemoryChildProfileRepository(
                profiles: const [
                  ChildProfile(
                    id: 'child_a',
                    displayName: 'Child A',
                    emoji: '🧒',
                    swatch: DayChildSwatch.purple,
                    ageYears: 10,
                    locationLabel: 'home',
                    lastSeenLabel: 'now',
                    batteryLabel: '80%',
                    walletLabel: '10m',
                    todayUsedLabel: '',
                    todayCapLabel: '',
                    lastHeartbeatLabel: '1m',
                    health: ChildListHealth.excellent,
                  ),
                ],
              ),
              managementRepository: management,
              roleOverride: AppRole.father,
              onNavigateTool: (_) {},
              onOpenLocation: () {},
              onOpenDeviceHealth: () {},
              onOpenPairing: ({required childId, deviceId, enrollmentId}) {},
            ),
          ),
          GoRoute(
            path: '/sys3-revoke-confirm',
            builder: (context, state) => RevokeConfirmScreen(
              kind: state.uri.queryParameters['kind'],
              id: state.uri.queryParameters['id'],
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: buildFamilyTheme(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
          builder: (context, child) => CurrentIdentity(
            runtime: runtime,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ChildProfileKeys.closeRevoke('enr_1')));
      await tester.pumpAndSettle();
      expect(find.byKey(Sys3Keys.revokeConfirm), findsOneWidget);
      expect(
        runtime.enrollments.singleWhere((e) => e.id.value == 'enr_1').state,
        EnrollmentState.enrolled,
      );

      await tester.tap(find.byKey(const Key('sys3_revoke_action')));
      await tester.pumpAndSettle();
      expect(find.byKey(Sys3Keys.success), findsOneWidget);
      expect(
        runtime.enrollments.singleWhere((e) => e.id.value == 'enr_1').state,
        EnrollmentState.revoked,
      );
    },
  );

  testWidgets(
    'legacy FAT-006 without enrolled device shows honesty, not managed success',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFamilyTheme(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LinkSuccessScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('link_success_legacy_honesty')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('link_success_legacy_hero')), findsOneWidget);
      expect(find.byKey(const Key('link_success_managed_hero')), findsNothing);
      expect(find.textContaining('connected now'), findsNothing);
    },
  );

  testWidgets(
    'FAT-006 with enrolled IdentityRuntime shows managed enrollment hero',
    (tester) async {
      final runtime = primaryRuntime();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFamilyTheme(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: CurrentIdentity(
            runtime: runtime,
            child: const LinkSuccessScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('link_success_legacy_honesty')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('link_success_managed_hero')),
        findsOneWidget,
      );
    },
  );
}
