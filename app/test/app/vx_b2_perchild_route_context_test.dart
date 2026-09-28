import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/route_child_context.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/family_context_store.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/features/n03_screen_time/stage1_child_scope.dart';

/// VX-B2 · FVX-G-04 — per-child routes carry the profile's child.
void main() {
  const perChildBuilders = <String, String>{
    'SCR-FAT-032':
        'ChildScreenTimeScreen(childId: routeScopedChildId(context, state))',
    'SCR-FAT-036': 'WebFilterScreen(childId: routeChildId(context, state))',
    'SCR-FAT-037': 'InstantLockScreen(childId: routeChildId(context, state))',
    'SCR-FAT-065': 'SmartAlertsScreen(childId: routeChildId(context, state))',
    'SCR-FAT-067':
        'SmartSupervisionScreen(childId: routeChildId(context, state).value)',
    'SCR-FAT-068':
        'PlatformMonitoringScreen(childId: routeChildId(context, state).value)',
    'SCR-FAT-072':
        'QuranProgressScreen(childId: routeChildId(context, state))',
    'SCR-FAT-085':
        'SmartModesScreen(childId: routeChildId(context, state).value)',
    'SCR-CHD-004':
        'ChildDayBoardScreen(childId: routeChildId(context, state), '
        'screenTimeChildId: routeScopedChildId(context, state))',
    'SCR-CHD-005':
        'ChildSosButtonScreen(childId: routeChildId(context, state).value)',
    'SCR-CHD-021': 'TimeExpiryScreen(childId: routeChildId(context, state))',
  };

  group('router source guard', () {
    for (final path in ['lib/app/router.dart', 'tool/gen_routes.dart']) {
      test('$path passes the route child to every per-child tool', () {
        final source = File(path).readAsStringSync();
        expect(
          source,
          contains("import 'package:family_os/app/route_child_context.dart';"),
        );
        for (final entry in perChildBuilders.entries) {
          expect(source, contains(entry.value), reason: entry.key);
        }
      });
    }
  });

  group('routeChildId / routeScopedChildId', () {
    late IdentityRuntime runtime;

    setUp(() {
      runtime = createStage1IdentityRuntime(
        familyContextStore: MemoryFamilyContextStore(),
      );
    });

    Future<String> resolve(
      WidgetTester tester,
      String location, {
      bool scoped = false,
    }) async {
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: '/t',
            builder: (context, state) {
              final id = scoped
                  ? routeScopedChildId(context, state)
                  : routeChildId(context, state);
              return Text(id.value, textDirection: TextDirection.ltr);
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        CurrentIdentity(
          runtime: runtime,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return tester.widget<Text>(find.byType(Text)).data!;
    }

    testWidgets('query childId wins over the active child', (tester) async {
      expect(runtime.activeChildId, isNot(ChildId('child_b')));
      expect(await resolve(tester, '/t?childId=child_b'), 'child_b');
    });

    testWidgets('missing / blank childId → family context child', (
      tester,
    ) async {
      runtime.setActiveChild(ChildId('child_b'));
      expect(await resolve(tester, '/t'), 'child_b');
      expect(await resolve(tester, '/t?childId=%20'), 'child_b');
    });

    testWidgets('scoped id = active family :: route child', (tester) async {
      final expected = familyScopedChildId(
        familyId: FamilyId('fam_stage1'),
        childId: ChildId('child_b'),
      ).value;
      expect(
        await resolve(tester, '/t?childId=child_b', scoped: true),
        expected,
      );
      expect(
        await resolve(tester, '/t?childId=$expected', scoped: true),
        expected,
      );
    });
  });
}
