import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/capability_honesty_badge.dart';
import 'package:family_os/core/design/components/silent_locate_sheet.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/location/location_store.dart';
import 'package:family_os/core/location/safe_zone_definition.dart';
import 'package:family_os/core/location/zone_geometry.dart';
import 'package:family_os/core/location/geo_point.dart';
import 'package:family_os/features/n02_day/create_safe_zone_screen.dart';
import 'package:family_os/features/n02_day/location_map_mock.dart';
import 'package:family_os/features/n02_day/location_map_repository.dart';
import 'package:family_os/features/n02_day/location_map_screen.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';
import 'package:family_os/features/n02_day/safe_zones_repository.dart';

void main() {
  testWidgets('FAT-014 shows GPS NOT IMPLEMENTED honesty + silent locate CTA', (
    tester,
  ) async {
    var silentChild = '';
    await tester.pumpWidget(
      _app(
        child: LocationMapScreen(
          repository: InMemoryLocationMapRepository(
            pins: LocationMapMock.manyPins,
            zones: LocationMapMock.zonesFixture,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onSilentLocate: (id) => silentChild = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationMapKeys.gpsBanner), findsOneWidget);
    expect(find.byType(CapabilityHonestyBadge), findsWidgets);
    expect(find.byKey(LocationMapKeys.silentLocateCta), findsOneWidget);

    await tester.ensureVisible(find.byKey(LocationMapKeys.silentLocateCta));
    await tester.tap(find.byKey(LocationMapKeys.silentLocateCta));
    await tester.pumpAndSettle();
    expect(silentChild, isNotEmpty);
  });

  testWidgets('FAT-017 blocks save without assignment when roster shown', (
    tester,
  ) async {
    final repo = InMemorySafeZonesRepository();
    var saved = false;
    await tester.pumpWidget(
      _app(
        child: CreateSafeZoneScreen(
          repository: repo,
          roleOverride: AppRole.father,
          assignableChildren: const [
            AssignableChild(id: 'c1', label: 'Child One'),
            AssignableChild(id: 'c2', label: 'Child Two'),
          ],
          idFactory: () => 'z_need',
          onSos: () {},
          onSaved: () => saved = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CreateSafeZoneKeys.assignSection), findsOneWidget);

    final map = tester.getRect(find.byKey(CreateSafeZoneKeys.map));
    await tester.tapAt(map.center);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(CreateSafeZoneKeys.saveCta));
    await tester.tap(find.byKey(CreateSafeZoneKeys.saveCta));
    await tester.pumpAndSettle();
    expect(saved, isFalse);
    expect(find.textContaining('Select at least one child'), findsWidgets);

    await tester.tap(find.byKey(CreateSafeZoneKeys.childChip('c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreateSafeZoneKeys.saveCta));
    await tester.pumpAndSettle();
    expect(saved, isTrue);
    expect((await repo.load()).zones.single.assignedChildIds, ['c1']);
  });

  test('DomainSafeZonesRepository persists circle assignment', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final store = LocalLocationStore(db);
    final domainRepo = DomainSafeZonesRepository(
      domain: store,
      familyId: FamilyId('fam_x'),
      listRepo: InMemorySafeZonesRepository(),
    );
    final now = DateTime.utc(2026, 9, 24);
    await domainRepo.saveDefinition(
      SafeZoneDefinition(
        id: 'z_dom',
        familyId: FamilyId('fam_x'),
        name: 'Park',
        geometry: const CircleGeometry(
          center: GeoPoint(latitude: 24.71, longitude: 46.67),
          radiusMeters: 120,
        ),
        assignedChildIds: [ChildId('c1')],
        createdAt: now,
        updatedAt: now,
      ),
    );
    final snap = await domainRepo.load();
    expect(snap.zones.single.id, 'z_dom');
    expect(snap.zones.single.assignedChildIds, ['c1']);
    await db.close();
  });

  testWidgets('SilentLocateSheet reports GPS NOT IMPLEMENTED honestly', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return PrimaryBtnStub(
                onPressed: () {
                  SilentLocateSheet.show(
                    context,
                    childId: 'c1',
                    childLabel: 'Child',
                    gpsStatus: CapabilityStatus.notImplemented,
                    onRequest: () async => const SilentLocateResult(
                      childId: 'c1',
                      status: SilentLocateResultStatus.notImplementedGps,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(SilentLocateKeys.sheet), findsOneWidget);
    await tester.tap(find.byKey(SilentLocateKeys.confirm));
    await tester.pumpAndSettle();
    expect(find.byKey(SilentLocateKeys.result), findsOneWidget);
    expect(find.textContaining('NOT IMPLEMENTED'), findsWidgets);
  });
}

/// Tiny button for sheet test without importing PrimaryBtn cycles.
class PrimaryBtnStub extends StatelessWidget {
  const PrimaryBtnStub({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Open'));
  }
}

Widget _app({required Widget child}) {
  return MaterialApp(
    locale: const Locale('en'),
    theme: buildFamilyTheme(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
