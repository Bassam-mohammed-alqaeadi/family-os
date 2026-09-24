import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/location_map_mock.dart';
import 'package:family_os/features/n02_day/location_map_repository.dart';
import 'package:family_os/features/n02_day/location_map_screen.dart';

void main() {
  testWidgets('SCR-FAT-014 empty family → AppEmptyState', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationMapScreen(
          repository: InMemoryLocationMapRepository(),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationMapKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(LocationMapKeys.body), findsNothing);
    // P-4 — SOS remains reachable on empty.
    expect(find.byKey(LocationMapKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-014 unknown childId → not found', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationMapScreen(
          childId: 'missing_child',
          repository: InMemoryLocationMapRepository(
            pins: LocationMapMock.manyPins,
            zones: LocationMapMock.zonesFixture,
            threadsByChildId: LocationMapMock.threadsFixture,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationMapKeys.notFound), findsOneWidget);
    expect(find.byKey(LocationMapKeys.body), findsNothing);
    expect(find.byKey(LocationMapKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-014 map + pins + thread + honesty', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationMapScreen(
          childId: 'child_a',
          repository: InMemoryLocationMapRepository(
            pins: LocationMapMock.manyPins,
            zones: LocationMapMock.zonesFixture,
            threadsByChildId: LocationMapMock.threadsFixture,
          ),
          roleOverride: AppRole.father,
          onOpenHistory: (_) {},
          onOpenSafeZones: () {},
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationMapKeys.body), findsOneWidget);
    expect(find.byKey(LocationMapKeys.mapCanvas), findsOneWidget);
    expect(find.byKey(LocationMapKeys.pinsList), findsOneWidget);
    expect(find.byKey(LocationMapKeys.dayThread), findsOneWidget);
    expect(find.byKey(LocationMapKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(LocationMapKeys.safeZonesCta), findsOneWidget);
    expect(find.byKey(LocationMapKeys.pin('child_a')), findsOneWidget);
    expect(find.byKey(LocationMapKeys.pinRow('child_b')), findsOneWidget);
    expect(find.textContaining('ابن ١'), findsWidgets);
  });

  testWidgets('SCR-FAT-014 history + safe-zones seams', (tester) async {
    String? historyId;
    var zonesOpened = false;
    await tester.pumpWidget(
      _app(
        child: LocationMapScreen(
          childId: 'child_a',
          repository: InMemoryLocationMapRepository(
            pins: LocationMapMock.manyPins,
            zones: LocationMapMock.zonesFixture,
            threadsByChildId: LocationMapMock.threadsFixture,
          ),
          roleOverride: AppRole.father,
          onOpenHistory: (id) => historyId = id,
          onOpenSafeZones: () => zonesOpened = true,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(LocationMapKeys.pinRow('child_b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LocationMapKeys.pinRow('child_b')));
    await tester.pumpAndSettle();
    expect(historyId, 'child_b');

    await tester.ensureVisible(find.byKey(LocationMapKeys.safeZonesCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LocationMapKeys.safeZonesCta));
    await tester.pumpAndSettle();
    expect(zonesOpened, isTrue);
  });

  testWidgets('SCR-FAT-014 SOS seam fires on empty map', (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: LocationMapScreen(
          repository: InMemoryLocationMapRepository(),
          roleOverride: AppRole.father,
          onSos: () => sos = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LocationMapKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-014 load error → AppErrorState + SOS', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationMapScreen(
          repository: InMemoryLocationMapRepository(failLoad: true),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationMapKeys.error), findsOneWidget);
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.byKey(LocationMapKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-014 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationMapScreen(
          childId: 'child_a',
          repository: InMemoryLocationMapRepository(
            pins: LocationMapMock.manyPins,
            zones: LocationMapMock.zonesFixture,
            threadsByChildId: LocationMapMock.threadsFixture,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationMapKeys.childLean), findsOneWidget);
    expect(find.byKey(LocationMapKeys.body), findsNothing);
  });

  testWidgets('SCR-FAT-014 mother can view map', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationMapScreen(
          repository: InMemoryLocationMapRepository(
            pins: LocationMapMock.manyPins,
            zones: LocationMapMock.zonesFixture,
            threadsByChildId: LocationMapMock.threadsFixture,
          ),
          roleOverride: AppRole.mother,
          onOpenHistory: (_) {},
          onOpenSafeZones: () {},
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationMapKeys.body), findsOneWidget);
    expect(find.byKey(LocationMapKeys.childLean), findsNothing);
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
