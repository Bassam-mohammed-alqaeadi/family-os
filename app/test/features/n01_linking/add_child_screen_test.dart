import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
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

void main() {
  testWidgets('empty name disables continue; field starts empty', (
    tester,
  ) async {
    var continued = 0;
    await _pumpAddChild(
      tester,
      onContinue: () => continued++,
      mockAlias: 'child_a7f3',
    );

    final nameField = tester.widget<TextField>(
      find.byKey(const Key('add_child_name')),
    );
    expect(nameField.controller!.text, isEmpty);

    final btn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('add_child_continue')),
    );
    expect(btn.onPressed, isNull);

    await tester.tap(find.byKey(const Key('add_child_continue')));
    await tester.pump();
    expect(continued, 0);
  });

  testWidgets('filled name → /scr-fat-004', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-003',
      routes: [
        GoRoute(
          path: '/scr-fat-003',
          builder: (context, state) => const AddChildScreen(),
        ),
        GoRoute(
          path: '/scr-fat-004',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-004',
            title: 'رمز الربط',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('add_child_name')), 'سارة');
    await tester.pump();

    final btn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('add_child_continue')),
    );
    expect(btn.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('add_child_continue')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-004');
    expect(find.byType(PlaceholderScreen), findsOneWidget);
    expect(find.text('SCR-FAT-004'), findsWidgets);
  });

  testWidgets('Rule 23 — no خالد in tree by default', (tester) async {
    await _pumpAddChild(tester, mockAlias: 'child_abcd');

    expect(find.textContaining('خالد'), findsNothing);

    final nameField = tester.widget<TextField>(
      find.byKey(const Key('add_child_name')),
    );
    expect(nameField.controller!.text, isNot(contains('خالد')));
    expect(nameField.decoration?.hintText, isNot(contains('خالد')));
  });

  testWidgets('alias matches child_[a-f0-9]{4}', (tester) async {
    await _pumpAddChild(tester);

    final aliasText = tester.widget<Text>(
      find.byKey(const Key('add_child_alias_ltr')),
    );
    expect(aliasText.data, matches(RegExp(r'^child_[a-f0-9]{4}$')));
  });

  testWidgets('renders header, ages, characters, colors', (tester) async {
    await _pumpAddChild(tester, mockAlias: 'child_a7f3');

    expect(find.text('إضافة ابن'), findsOneWidget);
    expect(find.text('١ من ٣'), findsOneWidget);
    expect(find.text('متابعة — رمز الربط'), findsOneWidget);
    expect(find.textContaining('اسمه لا يغادر العائلة'), findsOneWidget);
    expect(find.text('child_a7f3'), findsOneWidget);

    expect(find.text('🦁'), findsOneWidget);
    expect(find.text('🐰'), findsOneWidget);
    expect(find.byKey(const Key('add_child_color_0')), findsOneWidget);
    expect(find.byKey(const Key('add_child_color_5')), findsOneWidget);
    expect(find.text('١٤ سنة'), findsWidgets);
  });

  testWidgets('creates child through management repository', (tester) async {
    final runtime = IdentityRuntime(
      account: Account(id: AccountId('acc')),
      session: Session(
        id: SessionId('sess'),
        accountId: AccountId('acc'),
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(
          id: FamilyId('fam_a'),
          name: 'A',
          ownerMemberId: MemberId('mem'),
        ),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('mem'),
          accountId: AccountId('acc'),
          familyId: FamilyId('fam_a'),
          role: AppRole.father,
          tier: MembershipTier.primary,
          isPrimaryOwner: true,
        ),
      ],
      activeFamilyId: FamilyId('fam_a'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_a'),
        childId: ChildId('old_child'),
      ),
      children: [
        ChildIdentity(id: ChildId('old_child'), familyId: FamilyId('fam_a')),
      ],
    );
    final management = RuntimeChildDeviceManagementRepository(runtime: runtime);
    await tester.pumpWidget(
      CurrentIdentity(
        runtime: runtime,
        child: MaterialApp(
          theme: buildFamilyTheme(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AddChildScreen(
            managementRepository: management,
            mockAlias: 'child_new1',
            onContinue: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('add_child_name')), 'ولد');
    await tester.pump();
    await tester.tap(find.byKey(const Key('add_child_continue')));
    await tester.pumpAndSettle();
    expect(
      runtime.children.any((child) => child.id == ChildId('child_new1')),
      isTrue,
    );
  });
}

Future<void> _pumpAddChild(
  WidgetTester tester, {
  VoidCallback? onContinue,
  String? mockAlias,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AddChildScreen(onContinue: onContinue, mockAlias: mockAlias),
    ),
  );
  await tester.pumpAndSettle();
}
