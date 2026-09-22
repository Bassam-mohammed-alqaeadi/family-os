import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
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
}

Widget _app({required Widget child}) {
  return MaterialApp(
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
}
