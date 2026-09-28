import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// VX-B6 / FVX-S-04 — add-child keeps name/age/colour on the Local roster.
void main() {
  testWidgets('continue upserts display name age emoji into children roster', (
    tester,
  ) async {
    final roster = InMemoryChildrenListRepository();
    final runtime = IdentityRuntime(
      account: Account(id: AccountId('acc_vx_b6')),
      session: Session(
        id: SessionId('sess_vx_b6'),
        accountId: AccountId('acc_vx_b6'),
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(
          id: FamilyId('fam_vx_b6'),
          name: 'V',
          ownerMemberId: MemberId('mem_vx_b6'),
        ),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('mem_vx_b6'),
          accountId: AccountId('acc_vx_b6'),
          familyId: FamilyId('fam_vx_b6'),
          role: AppRole.father,
          tier: MembershipTier.primary,
          isPrimaryOwner: true,
        ),
      ],
      activeFamilyId: FamilyId('fam_vx_b6'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_vx_b6'),
        childId: ChildId('old_child'),
      ),
      children: [
        ChildIdentity(
          id: ChildId('old_child'),
          familyId: FamilyId('fam_vx_b6'),
        ),
      ],
    );
    final management = RuntimeChildDeviceManagementRepository(runtime: runtime);

    var continued = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CurrentIdentity(
          runtime: runtime,
          child: AddChildScreen(
            mockAlias: 'child_vx_b6',
            managementRepository: management,
            childrenListRepository: roster,
            onContinue: () => continued++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('add_child_name')), 'Sara');
    await tester.pump();
    await tester.tap(find.byKey(const Key('add_child_continue')));
    await tester.pumpAndSettle();

    expect(continued, 1);
    final kids = await roster.listChildren(familyId: FamilyId('fam_vx_b6'));
    expect(kids, hasLength(1));
    expect(kids.single.id, 'child_vx_b6');
    expect(kids.single.displayName, 'Sara');
    expect(kids.single.ageYears, 14);
    expect(kids.single.emoji, kAddChildCharacters.first);
    expect(kids.single.swatch, DayChildSwatch.purple);
  });
}
