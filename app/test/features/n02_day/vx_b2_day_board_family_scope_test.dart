import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/family_context_store.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/safe_zones_repository.dart';
import 'package:family_os/features/n02_day/safe_zones_screen.dart';

/// VX-B2 · FVX-G-05 — Today + safe zones follow the active family.
void main() {
  late IdentityRuntime runtime;
  final fam1 = FamilyId('fam_stage1');
  final fam2 = FamilyId('fam_stage2');

  setUp(() {
    runtime = createStage1IdentityRuntime(
      familyContextStore: MemoryFamilyContextStore(),
    );
  });

  InMemoryChildrenListRepository roster() => InMemoryChildrenListRepository(
    byFamily: {
      fam1.value: ChildrenListLocalSeed.famStage1Children,
      fam2.value: ChildrenListLocalSeed.famStage2Children,
    },
  );

  test('Today projection lists the active family\'s children', () async {
    final repo = RosterDayBoardProjectionRepository(
      children: roster(),
      familyId: () => runtime.activeFamilyId,
    );
    final before = await repo.load();
    expect(before.children.map((c) => c.id), ['demo-child', 'child_b']);

    runtime.switchActiveFamily(fam2);
    final after = await repo.load();
    expect(after.children.map((c) => c.id), ['child_c']);
  });

  testWidgets('Today board reloads on family switch', (tester) async {
    final repo = _RecordingProjection(runtime);
    await _pump(
      tester,
      runtime,
      DayBoardScreen(projectionRepository: repo),
    );
    expect(repo.loadedFor, [fam1]);

    runtime.switchActiveFamily(fam2);
    await tester.pumpAndSettle();
    expect(repo.loadedFor, [fam1, fam2]);
  });

  testWidgets('safe zones bind + reload for the switched family', (
    tester,
  ) async {
    final repo = _CountingSafeZones();
    await _pump(tester, runtime, SafeZonesScreen(repository: repo));
    final state = tester.state<SafeZonesScreenState>(
      find.byType(SafeZonesScreen),
    );
    expect(state.familyId, fam1);
    final loadsBefore = repo.loads;

    runtime.switchActiveFamily(fam2);
    await tester.pumpAndSettle();
    expect(state.familyId, fam2);
    expect(repo.loads, greaterThan(loadsBefore));
  });
}

Future<void> _pump(
  WidgetTester tester,
  IdentityRuntime runtime,
  Widget home,
) async {
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
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _RecordingProjection implements DayBoardProjectionRepository {
  _RecordingProjection(this._runtime);

  final IdentityRuntime _runtime;
  final List<FamilyId> loadedFor = [];

  @override
  Future<DayBoardProjection> load() async {
    loadedFor.add(_runtime.activeFamilyId);
    return DayBoardProjection.empty;
  }
}

final class _CountingSafeZones implements SafeZonesRepository {
  final _inner = InMemorySafeZonesRepository();
  var loads = 0;

  @override
  Future<SafeZonesSnapshot> load() {
    loads += 1;
    return _inner.load();
  }

  @override
  Future<void> setAlertFlag(
    String zoneId, {
    bool? alertEnter,
    bool? alertExit,
    bool? alertNoShow,
  }) =>
      _inner.setAlertFlag(
        zoneId,
        alertEnter: alertEnter,
        alertExit: alertExit,
        alertNoShow: alertNoShow,
      );

  @override
  Future<void> setAlertsEnabled(String zoneId, bool enabled) =>
      _inner.setAlertsEnabled(zoneId, enabled);

  @override
  Future<void> add(SafeZone zone) => _inner.add(zone);
}
