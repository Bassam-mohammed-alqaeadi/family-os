import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/safe_zones_mock.dart';
import 'package:family_os/features/n02_day/safe_zones_repository.dart';
import 'package:family_os/features/n02_day/safe_zones_screen.dart';

void main() {
  testWidgets('SCR-FAT-016 empty → AppEmptyState + create CTA', (tester) async {
    var created = false;
    await tester.pumpWidget(
      _app(
        child: SafeZonesScreen(
          repository: InMemorySafeZonesRepository(),
          roleOverride: AppRole.father,
          onSos: () {},
          onCreateZone: () => created = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SafeZonesKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.body), findsNothing);
    expect(find.byKey(SafeZonesKeys.sosCta), findsOneWidget);

    await tester.tap(find.text('رسم منطقة آمنة'));
    await tester.pumpAndSettle();
    expect(created, isTrue);
  });

  testWidgets('SCR-FAT-016 list + honesty + draw CTA', (tester) async {
    await tester.pumpWidget(
      _app(
        child: SafeZonesScreen(
          repository: InMemorySafeZonesRepository(
            zones: SafeZonesMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onCreateZone: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SafeZonesKeys.body), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.section), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.zone('z1')), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.zone('z4')), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.drawCta), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.addHeaderCta), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.appliesNote), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.readOnlyBanner), findsNothing);
  });

  testWidgets('SCR-FAT-016 father toggles alert switch', (tester) async {
    final repo = InMemorySafeZonesRepository(zones: SafeZonesMock.seeded);
    await tester.pumpWidget(
      _app(
        child: SafeZonesScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
          onCreateZone: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byKey(SafeZonesKeys.zoneSwitch('z1'));
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    final snap = await repo.load();
    expect(snap.zones.firstWhere((z) => z.id == 'z1').alertsEnabled, isFalse);
  });

  testWidgets('SCR-FAT-016 mother partner → read-only banner', (tester) async {
    await tester.pumpWidget(
      _app(
        child: SafeZonesScreen(
          repository: InMemorySafeZonesRepository(
            zones: SafeZonesMock.seeded,
          ),
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.partner,
          onSos: () {},
          onCreateZone: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SafeZonesKeys.body), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.readOnlyBanner), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.addHeaderCta), findsNothing);

    final sw = tester.widget<Switch>(
      find.byKey(SafeZonesKeys.zoneSwitch('z1')),
    );
    expect(sw.onChanged, isNull);
  });

  testWidgets('SCR-FAT-016 mother full can edit', (tester) async {
    await tester.pumpWidget(
      _app(
        child: SafeZonesScreen(
          repository: InMemorySafeZonesRepository(
            zones: SafeZonesMock.seeded,
          ),
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.full,
          onSos: () {},
          onCreateZone: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SafeZonesKeys.readOnlyBanner), findsNothing);
    expect(find.byKey(SafeZonesKeys.addHeaderCta), findsOneWidget);
    final sw = tester.widget<Switch>(
      find.byKey(SafeZonesKeys.zoneSwitch('z1')),
    );
    expect(sw.onChanged, isNotNull);
  });

  testWidgets('SCR-FAT-016 create seam from draw CTA', (tester) async {
    var created = false;
    await tester.pumpWidget(
      _app(
        child: SafeZonesScreen(
          childId: 'child_a',
          repository: InMemorySafeZonesRepository(
            zones: SafeZonesMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onCreateZone: () => created = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(SafeZonesKeys.drawCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SafeZonesKeys.drawCta));
    await tester.pumpAndSettle();
    expect(created, isTrue);
  });

  testWidgets('SCR-FAT-016 SOS seam fires on empty', (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: SafeZonesScreen(
          repository: InMemorySafeZonesRepository(),
          roleOverride: AppRole.father,
          onSos: () => sos = true,
          onCreateZone: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SafeZonesKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-016 load error → AppErrorState + SOS', (tester) async {
    await tester.pumpWidget(
      _app(
        child: SafeZonesScreen(
          repository: InMemorySafeZonesRepository(failLoad: true),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SafeZonesKeys.error), findsOneWidget);
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-016 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: SafeZonesScreen(
          repository: InMemorySafeZonesRepository(
            zones: SafeZonesMock.seeded,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SafeZonesKeys.childLean), findsOneWidget);
    expect(find.byKey(SafeZonesKeys.body), findsNothing);
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
