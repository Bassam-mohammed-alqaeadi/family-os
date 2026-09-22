import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/child_profile_mock.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/child_profile_screen.dart';

void main() {
  testWidgets('SCR-FAT-013 missing childId → AppEmptyState', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ChildProfileScreen(
          repository: InMemoryChildProfileRepository(),
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildProfileKeys.missingId), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.body), findsNothing);
  });

  testWidgets('SCR-FAT-013 unknown childId → not found', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ChildProfileScreen(
          childId: 'missing_child',
          repository: InMemoryChildProfileRepository(
            profiles: ChildProfileMock.manyFixture,
          ),
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildProfileKeys.notFound), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.body), findsNothing);
  });

  testWidgets('SCR-FAT-013 profile renders identity + tools', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: InMemoryChildProfileRepository(
            profiles: ChildProfileMock.manyFixture,
          ),
          roleOverride: AppRole.father,
          onNavigateTool: (_) {},
          onOpenLocation: () {},
          onOpenDeviceHealth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildProfileKeys.body), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.identityCard), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.toolsGrid), findsOneWidget);
    expect(find.text('ابن ١'), findsWidgets);
    expect(find.byKey(ChildProfileKeys.tool('screen_time')), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.tool('web_filter')), findsOneWidget);
  });

  testWidgets('SCR-FAT-013 tool navigation seam', (tester) async {
    ChildProfileTool? opened;
    await tester.pumpWidget(
      _app(
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: InMemoryChildProfileRepository(
            profiles: ChildProfileMock.manyFixture,
          ),
          roleOverride: AppRole.father,
          onNavigateTool: (t) => opened = t,
          onOpenLocation: () {},
          onOpenDeviceHealth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildProfileKeys.tool('screen_time')));
    await tester.pumpAndSettle();
    expect(opened?.id, 'screen_time');
    expect(opened?.routePath, '/scr-fat-032');
  });

  testWidgets('SCR-FAT-013 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: InMemoryChildProfileRepository(
            profiles: ChildProfileMock.manyFixture,
          ),
          roleOverride: AppRole.child,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildProfileKeys.childLean), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.body), findsNothing);
  });
}

Widget _app({required Widget child}) {
  return MaterialApp(
    theme: buildFamilyTheme(),
    locale: const Locale('ar'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
