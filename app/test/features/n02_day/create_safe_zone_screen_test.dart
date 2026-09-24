import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/create_safe_zone_screen.dart';
import 'package:family_os/features/n02_day/safe_zones_repository.dart';

void main() {
  testWidgets('SCR-FAT-017 father draws + saves into repo', (tester) async {
    final repo = InMemorySafeZonesRepository();
    var saved = false;

    await tester.pumpWidget(
      _app(
        child: CreateSafeZoneScreen(
          repository: repo,
          roleOverride: AppRole.father,
          childId: 'child_a',
          idFactory: () => 'z_test',
          onSos: () {},
          onSaved: () => saved = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CreateSafeZoneKeys.body), findsOneWidget);
    expect(find.byKey(CreateSafeZoneKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(CreateSafeZoneKeys.drawBanner), findsOneWidget);
    expect(find.byKey(CreateSafeZoneKeys.map), findsOneWidget);
    expect(find.byKey(CreateSafeZoneKeys.tapHint), findsOneWidget);
    expect(find.byKey(CreateSafeZoneKeys.sosCta), findsOneWidget);

    // Save without center → gentle block.
    await _tapVisible(tester, CreateSafeZoneKeys.saveCta);
    expect(saved, isFalse);
    expect(find.text('👆 ضع مركز المنطقة على الخريطة أولًا'), findsOneWidget);

    // Tap map center.
    await tester.ensureVisible(find.byKey(CreateSafeZoneKeys.map));
    await tester.pumpAndSettle();
    final map = tester.getRect(find.byKey(CreateSafeZoneKeys.map));
    await tester.tapAt(map.center);
    await tester.pumpAndSettle();

    expect(find.byKey(CreateSafeZoneKeys.tapHint), findsNothing);
    expect(find.byKey(CreateSafeZoneKeys.pin), findsOneWidget);
    expect(find.byKey(CreateSafeZoneKeys.circle), findsOneWidget);
    expect(find.byKey(CreateSafeZoneKeys.centerPlaced), findsOneWidget);

    await _tapVisible(tester, CreateSafeZoneKeys.nameField);
    await tester.enterText(
      find.byKey(CreateSafeZoneKeys.nameField),
      'نادي الحي الرياضي',
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, CreateSafeZoneKeys.saveCta);
    expect(saved, isTrue);
    final snap = await repo.load();
    expect(snap.zones, hasLength(1));
    expect(snap.zones.first.id, 'z_test');
    expect(snap.zones.first.name, 'نادي الحي الرياضي');
    expect(snap.zones.first.emoji, '🥋');
    expect(snap.zones.first.alertsEnabled, isTrue);
  });

  testWidgets('SCR-FAT-017 radius slider updates live circle', (tester) async {
    await tester.pumpWidget(
      _app(
        child: CreateSafeZoneScreen(
          repository: InMemorySafeZonesRepository(),
          roleOverride: AppRole.father,
          onSos: () {},
          onSaved: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final map = tester.getRect(find.byKey(CreateSafeZoneKeys.map));
    await tester.tapAt(map.center);
    await tester.pumpAndSettle();

    final before = tester.getSize(find.byKey(CreateSafeZoneKeys.circle));

    await tester.ensureVisible(find.byKey(CreateSafeZoneKeys.radiusSlider));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(CreateSafeZoneKeys.radiusSlider),
      const Offset(80, 0),
    );
    await tester.pumpAndSettle();

    final after = tester.getSize(find.byKey(CreateSafeZoneKeys.circle));
    expect(after.width, greaterThan(before.width));
  });

  testWidgets('SCR-FAT-017 mother partner → read-only', (tester) async {
    var saved = false;
    await tester.pumpWidget(
      _app(
        child: CreateSafeZoneScreen(
          repository: InMemorySafeZonesRepository(),
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.partner,
          onSos: () {},
          onSaved: () => saved = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CreateSafeZoneKeys.readOnlyBanner), findsOneWidget);
    expect(find.byKey(CreateSafeZoneKeys.tapHint), findsOneWidget);
    expect(find.byKey(CreateSafeZoneKeys.sosCta), findsOneWidget);

    final map = tester.getRect(find.byKey(CreateSafeZoneKeys.map));
    await tester.tapAt(map.center);
    await tester.pumpAndSettle();
    expect(find.byKey(CreateSafeZoneKeys.pin), findsNothing);

    await _tapVisible(tester, CreateSafeZoneKeys.saveCta);
    expect(saved, isFalse);
  });

  testWidgets('SCR-FAT-017 mother full can draw', (tester) async {
    await tester.pumpWidget(
      _app(
        child: CreateSafeZoneScreen(
          repository: InMemorySafeZonesRepository(),
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.full,
          onSos: () {},
          onSaved: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CreateSafeZoneKeys.readOnlyBanner), findsNothing);

    final map = tester.getRect(find.byKey(CreateSafeZoneKeys.map));
    await tester.tapAt(map.center);
    await tester.pumpAndSettle();
    expect(find.byKey(CreateSafeZoneKeys.pin), findsOneWidget);
  });

  testWidgets('SCR-FAT-017 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: CreateSafeZoneScreen(
          repository: InMemorySafeZonesRepository(),
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CreateSafeZoneKeys.childLean), findsOneWidget);
    expect(find.byKey(CreateSafeZoneKeys.body), findsNothing);
    expect(find.byKey(CreateSafeZoneKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-017 SOS seam fires', (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: CreateSafeZoneScreen(
          repository: InMemorySafeZonesRepository(),
          roleOverride: AppRole.father,
          onSos: () => sos = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CreateSafeZoneKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-017 alert toggles persist flags into alertsEnabled',
      (tester) async {
    final repo = InMemorySafeZonesRepository();
    await tester.pumpWidget(
      _app(
        child: CreateSafeZoneScreen(
          repository: repo,
          roleOverride: AppRole.father,
          childId: 'child_a',
          idFactory: () => 'z_off',
          onSos: () {},
          onSaved: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Turn off arrival + departure; leave no-show off → alertsEnabled false.
    await tester.ensureVisible(find.byKey(CreateSafeZoneKeys.alertArrival));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(CreateSafeZoneKeys.alertArrival),
        matching: find.byType(Switch),
      ),
    );
    await tester.ensureVisible(find.byKey(CreateSafeZoneKeys.alertDeparture));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(CreateSafeZoneKeys.alertDeparture),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll back to map for center tap.
    await tester.ensureVisible(find.byKey(CreateSafeZoneKeys.map));
    await tester.pumpAndSettle();
    final map = tester.getRect(find.byKey(CreateSafeZoneKeys.map));
    await tester.tapAt(map.center);
    await tester.pumpAndSettle();

    await _tapVisible(tester, CreateSafeZoneKeys.saveCta);

    final snap = await repo.load();
    expect(snap.zones.single.alertsEnabled, isFalse);
  });
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
