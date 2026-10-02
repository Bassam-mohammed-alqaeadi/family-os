import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_roster_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_mock.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/children_list_screen.dart';

void main() {
  testWidgets('SCR-FAT-012 empty → AppEmptyState + add CTA', (tester) async {
    final repo = InMemoryChildrenListRepository();

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onAddChild: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.list), findsNothing);
  });

  testWidgets('SCR-FAT-012 roster + health tags + status ring', (tester) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onAddChild: () {},
          onOpenChildProfile: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.list), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.addChild), findsOneWidget);
    expect(
      find.byKey(ChildrenListKeys.childRow('child_a')),
      findsOneWidget,
    );
    expect(
      find.byKey(ChildrenListKeys.childRow('child_b')),
      findsOneWidget,
    );
    expect(find.text('ممتاز'), findsWidgets);
    expect(find.text('قد ينقطع'), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.sharedPoliciesCard), findsOneWidget);
  });

  testWidgets('SCR-FAT-012 open profile seam', (tester) async {
    String? opened;
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onOpenChildProfile: (id) => opened = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildrenListKeys.childRow('child_a')));
    await tester.pumpAndSettle();
    expect(opened, 'child_a');
  });

  testWidgets('SCR-FAT-012 shared policies sheet + father apply', (
    tester,
  ) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onAddChild: () {},
          onOpenChildProfile: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildrenListKeys.sharedPoliciesCard));
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.sharedPoliciesSheet), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.sharedEnforceHonesty), findsOneWidget);
    expect(find.textContaining('محرك السياسة'), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.sharedApply), findsOneWidget);

    await tester.tap(find.byKey(ChildrenListKeys.sharedApply));
    await tester.pumpAndSettle();

    final saved = await repo.loadSharedPolicies();
    expect(saved.dailyCapHours, 4);
    expect(find.byKey(ChildrenListKeys.sharedPoliciesSheet), findsNothing);
  });

  testWidgets('SCR-FAT-012 mother — shared sheet without apply', (
    tester,
  ) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.mother,
          onAddChild: () {},
          onOpenChildProfile: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.list), findsOneWidget);
    await tester.tap(find.byKey(ChildrenListKeys.sharedPoliciesCard));
    await tester.pumpAndSettle();
    expect(find.byKey(ChildrenListKeys.sharedPoliciesSheet), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.sharedApply), findsNothing);
  });

  testWidgets('SCR-FAT-012 child lean — not parent roster', (tester) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.child,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.childLean), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.list), findsNothing);
  });

  testWidgets('SCR-FAT-012 load error → AppErrorState + Retry', (tester) async {
    final repo = InMemoryChildrenListRepository(failLoad: true);

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.error), findsOneWidget);
    expect(find.byKey(const Key('app_error_retry')), findsOneWidget);

    repo
      ..failLoad = false
      ..seed(ChildrenListMock.manyFixture);
    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.list), findsOneWidget);
  });

  testWidgets('SCR-FAT-012 Rule 23 — no planted Khaled on empty default', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: InMemoryChildrenListRepository(),
          roleOverride: AppRole.father,
          onAddChild: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('خالد'), findsNothing);
    expect(find.textContaining('نورة'), findsNothing);
    expect(find.textContaining('سعد'), findsNothing);
  });

  testWidgets('SCR-FAT-012 LOCAL_DEMO provenance → honesty BannerNote', (
    tester,
  ) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
      provenance: kChildrenListLocalDemoProvenance,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onAddChild: () {},
          onOpenChildProfile: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.localDemoBanner), findsOneWidget);
    expect(find.textContaining('تجريبي'), findsOneWidget);
    expect(find.textContaining('GPS'), findsOneWidget);
    expect(
      find.byKey(ChildrenListKeys.childRow('child_a')),
      findsOneWidget,
    );
  });

  testWidgets(
    'SCR-FAT-012 runtime roster renders profile repair instead of fake child facts',
    (tester) async {
      const familyId = FamilyId('fam_runtime');
      final runtime = AppRuntime(
        identity: _StaticIdentitySource(
          const IdentitySnapshot(
            authority: IdentityAuthority.localOnly,
            accountId: AccountId('parent_runtime'),
            familyId: familyId,
            role: AppRole.father,
            isPrimaryOwner: true,
          ),
        ),
        roster: _StaticRosterSource(
          const FamilyRosterSnapshot(
            familyId: familyId,
            origin: RuntimeDataOrigin.localOnly,
            children: [
              FamilyRosterChild(childId: ChildId('child_profile_missing')),
            ],
          ),
        ),
      );
      addTearDown(runtime.dispose);

      await tester.pumpWidget(
        _app(
          runtime: runtime,
          child: const ChildrenListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ChildrenListKeys.profileRepair('child_profile_missing')),
        findsOneWidget,
      );
      expect(
        find.byKey(ChildrenListKeys.childRow('child_profile_missing')),
        findsNothing,
      );
      expect(find.text('child_profile_missing'), findsNothing);
      expect(find.byKey(ChildrenListKeys.localOnlyBanner), findsOneWidget);
    },
  );

  testWidgets('SCR-FAT-012 no provenance → no demo BannerNote', (tester) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onAddChild: () {},
          onOpenChildProfile: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.localDemoBanner), findsNothing);
    expect(find.byKey(ChildrenListKeys.list), findsOneWidget);
  });
}

Widget _app({required Widget child, AppRuntime? runtime}) {
  final app = MaterialApp(
    theme: buildFamilyTheme(),
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
  if (runtime == null) return app;
  return AppScope(runtime: runtime, child: app);
}

final class _StaticIdentitySource extends ChangeNotifier implements IdentitySource {
  _StaticIdentitySource(this._value);

  IdentitySnapshot _value;

  @override
  IdentitySnapshot get value => _value;

  @override
  Future<IdentitySnapshot> refresh() async => _value;
}

final class _StaticRosterSource extends ChangeNotifier implements FamilyRosterSource {
  _StaticRosterSource(this._value);

  FamilyRosterSnapshot _value;

  @override
  FamilyRosterSnapshot get value => _value;

  @override
  Future<FamilyRosterSnapshot> load(FamilyId familyId) async => _value;
}
