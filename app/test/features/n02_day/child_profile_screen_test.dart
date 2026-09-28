import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/child_profile_mock.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/child_profile_screen.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/safe_zones_repository.dart';

void main() {
  testWidgets('SCR-FAT-013 missing childId → child selection', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ChildProfileScreen(
          repository: InMemoryChildProfileRepository(),
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Without identity children, picker is empty (honest, not a dead blank).
    expect(find.byKey(ChildProfileKeys.selectChildEmpty), findsOneWidget);
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
    expect(find.text('ابن 1'), findsWidgets);
    expect(find.byKey(ChildProfileKeys.tool('screen_time')), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.tool('apps')), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.tool('web_filter')), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.tool('tamper_alerts')), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.tool('smart_alerts')), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.tool('usage_report')), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.tool('focus_report')), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.tool('quran_progress')), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.tool('device_health')), findsOneWidget);
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

  testWidgets('SCR-FAT-013 LOCAL_DEMO provenance → honesty BannerNote', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: InMemoryChildProfileRepository(
            profiles: ChildProfileMock.manyFixture,
          ),
          childrenListRepository: InMemoryChildrenListRepository(
            provenance: kChildrenListLocalDemoProvenance,
          ),
          roleOverride: AppRole.father,
          onNavigateTool: (_) {},
          onOpenLocation: () {},
          onOpenDeviceHealth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildProfileKeys.localDemoBanner), findsOneWidget);
    expect(find.textContaining('تجريبي'), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.identityCard), findsOneWidget);
  });

  testWidgets('SCR-FAT-013 no provenance → no demo BannerNote', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: InMemoryChildProfileRepository(
            profiles: ChildProfileMock.manyFixture,
          ),
          childrenListRepository: InMemoryChildrenListRepository(),
          roleOverride: AppRole.father,
          onNavigateTool: (_) {},
          onOpenLocation: () {},
          onOpenDeviceHealth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildProfileKeys.localDemoBanner), findsNothing);
    expect(find.byKey(ChildProfileKeys.body), findsOneWidget);
  });

  testWidgets('LOCATION-1B FAT-013 history CTA + zones count', (tester) async {
    var historyOpened = false;
    var mapOpened = false;
    var zonesOpened = false;
    final zones = InMemorySafeZonesRepository(
      zones: [
        const SafeZone(
          id: 'z1',
          emoji: '🏫',
          name: 'مدرسة',
          description: 'assigned:1',
          assignedChildIds: ['child_a'],
        ),
        const SafeZone(
          id: 'z2',
          emoji: '🏠',
          name: 'منزل',
          description: 'assigned:1',
          assignedChildIds: ['child_b'],
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: InMemoryChildProfileRepository(
            profiles: ChildProfileMock.manyFixture,
          ),
          safeZonesRepository: zones,
          roleOverride: AppRole.father,
          onNavigateTool: (_) {},
          onOpenLocation: () => mapOpened = true,
          onOpenLocationHistory: () => historyOpened = true,
          onOpenSafeZones: () => zonesOpened = true,
          onOpenDeviceHealth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildProfileKeys.body), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(ChildProfileKeys.locationCard),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildProfileKeys.locationCard), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.locationNetworkChip), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.locationGpsHonesty), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.assignedZonesLink), findsOneWidget);

    await tester.ensureVisible(find.byKey(ChildProfileKeys.locationHistoryCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildProfileKeys.locationHistoryCta));
    await tester.pumpAndSettle();
    expect(historyOpened, isTrue);

    await tester.tap(find.byKey(ChildProfileKeys.locationMapCta));
    await tester.pumpAndSettle();
    expect(mapOpened, isTrue);

    await tester.tap(find.byKey(ChildProfileKeys.assignedZonesLink));
    await tester.pumpAndSettle();
    expect(zonesOpened, isTrue);
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
