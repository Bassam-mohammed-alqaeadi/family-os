// The showcase quarantine, proven in both directions.
//
// Added 2026-10-06 under the Phase Zero mandate: the design showcase must be structurally
// quarantined from the live production path. A quarantine that is only asserted in a
// comment is not a quarantine, so this file proves three things a reader can check:
// the policy refuses the showcase in a release build whatever the caller asks, the route
// list really loses those routes, and a deep link to a quarantined path lands on the
// product rather than on a catalogue page.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/router.dart';
import 'package:family_os/app/showcase_policy.dart';
import 'package:family_os/app/shell_config.dart';
import 'package:family_os/core/domain/role.dart';

void main() {
  group('showcase policy', () {
    test('a release build never shows the showcase, even when it is requested', () {
      // This is the property that matters: the quarantine cannot be defeated by a build
      // flag somebody forgot to remove.
      expect(showcaseEnabledFor(requested: true, isReleaseMode: true), isFalse);
      expect(showcaseEnabledFor(requested: false, isReleaseMode: true), isFalse);
    });

    test('a debug build shows the showcase when it is requested, and not otherwise', () {
      expect(showcaseEnabledFor(requested: true, isReleaseMode: false), isTrue);
      expect(showcaseEnabledFor(requested: false, isReleaseMode: false), isFalse);
    });

    test('the gallery and the QA catalogue are always quarantined', () {
      expect(isQuarantinedShowcasePath('/gallery'), isTrue);
      expect(isQuarantinedShowcasePath('/dev-screens'), isTrue);
    });

    test('a product route is never quarantined', () {
      // The entry point of a family's journey, and two screens the shell navigates to.
      // If this ever fails, the quarantine has started eating the product.
      for (final path in const <String>[
        showcaseFallbackPath,
        '/scr-shr-002',
        '/scr-chd-001',
      ]) {
        expect(
          isQuarantinedShowcasePath(path),
          isFalse,
          reason: '$path is part of the product journey and must never be quarantined',
        );
      }
    });
  });

  group('route registration', () {
    late RoleController role;

    setUp(() => role = RoleController(AppRole.father));
    tearDown(() => role.dispose());

    List<GoRoute> routesOf({required bool showcaseEnabled}) {
      final router = createAppRouter(
        roleListenable: role,
        showcaseEnabled: showcaseEnabled,
      );
      addTearDown(router.dispose);
      return router.configuration.routes.whereType<GoRoute>().toList();
    }

    test('a build without the showcase registers no quarantined route at all', () {
      final paths = routesOf(showcaseEnabled: false).map((route) => route.path).toSet();

      // Not merely hidden: absent. There is no route object to navigate to.
      expect(paths, isNot(contains('/gallery')));
      expect(paths, isNot(contains('/dev-screens')));
      for (final quarantined in quarantinedShowcasePaths) {
        expect(
          paths,
          isNot(contains(quarantined)),
          reason: '$quarantined must not be registered without the showcase',
        );
      }
    });

    test('a build without the showcase keeps every product route', () {
      final paths = routesOf(showcaseEnabled: false).map((route) => route.path).toSet();

      // The product must be untouched by the quarantine. These are the journeys a family
      // actually walks: entry, account creation, child linking, the daily board.
      for (final path in const <String>[
        '/scr-shr-001',
        '/scr-shr-002',
        '/scr-chd-001',
        '/scr-chd-002',
        '/scr-fat-001',
      ]) {
        expect(paths, contains(path), reason: '$path belongs to the product journey');
      }
    });

    test('a build with the showcase registers the gallery it was asked for', () {
      final paths = routesOf(showcaseEnabled: true).map((route) => route.path).toSet();
      expect(paths, contains('/gallery'));
      expect(paths, contains('/dev-screens'));
      for (final quarantined in quarantinedShowcasePaths) {
        expect(paths, contains(quarantined));
      }
    });

    test('no product screen is ever quarantined', () {
      // The guard that encodes this policy's own worst mistake. An earlier draft of the
      // quarantine list held sixty-three `/scr-*` routes, chosen because no literal path
      // string for them appeared outside the router - and every one of them is rendered by
      // the shell through a hub or tab entry, addressing them by screen id. Committing that
      // draft would have removed sixty-three product screens from a release build.
      //
      // So this test states the invariant directly: the quarantine is for the design
      // system, never for `/scr-*`.
      for (final path in quarantinedShowcasePaths) {
        expect(
          path.startsWith('/scr-'),
          isFalse,
          reason: '$path is addressed by screen id from the shell, so quarantining it '
              'would remove a screen a family uses',
        );
      }
    });

    test('every screen the shell offers is registered when the showcase is off', () {
      final paths =
          routesOf(showcaseEnabled: false).map((route) => route.path).toSet();

      // Every tab root and every hub entry, taken from the shell's own configuration rather
      // than from a list here. If the shell can offer a screen, a build without the showcase
      // must be able to serve it.
      final offered = <String>{
        for (final tab in parentShellTabs) _pathOf(tab.rootScreenId),
        for (final tab in childShellTabs) _pathOf(tab.rootScreenId),
        for (final entries in hubIndex.values)
          for (final entry in entries) _pathOf(entry.screenId),
        for (final id in parentTablessScreenIds) _pathOf(id),
        for (final id in childTablessScreenIds) _pathOf(id),
      };

      final missing = offered.difference(paths);
      expect(
        missing,
        isEmpty,
        reason: 'the shell offers these screens but a build without the showcase would '
            'not serve them: ${missing.join(', ')}',
      );
      expect(offered.length, greaterThan(100), reason: 'the shell surface must be intact');
    });

    test('quarantining removes routes without disturbing the order of the rest', () {
      final withShowcase = routesOf(showcaseEnabled: true).map((route) => route.path).toList();
      final without = routesOf(showcaseEnabled: false).map((route) => route.path).toList();

      // The quarantine filters; it must not rebuild the table. A reordered route table
      // would change which screen wins an ambiguous match, which is a silent behaviour
      // change in the product.
      final expected = withShowcase
          .where((path) => !isQuarantinedShowcasePath(path))
          .toList();
      expect(without, expected);
      expect(without.length, lessThan(withShowcase.length));
    });
  });

  group('deep links', () {
    testWidgets('a quarantined path is not where a deep link ends up', (tester) async {
      final role = RoleController(AppRole.father);
      addTearDown(role.dispose);
      final router = createAppRouter(
        roleListenable: role,
        showcaseEnabled: false,
        initialLocation: '/gallery',
      );
      addTearDown(router.dispose);

      // The registered product surface of this build, read from the router itself rather
      // than from a list here.
      final served = router.configuration.routes
          .whereType<GoRoute>()
          .map((route) => route.path)
          .toSet();

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      // What is under test is where the router decided the link should go. The screen it
      // lands on may need runtime scopes this test does not compose, so an exception from
      // rendering that screen is taken and discarded: it belongs to another test.
      tester.takeException();

      final landed = router.state.uri.path;
      expect(
        isQuarantinedShowcasePath(landed),
        isFalse,
        reason: 'a build without the showcase let a deep link open $landed',
      );
      expect(
        served,
        contains(landed),
        reason: 'the deep link was sent to $landed, which this build does not serve',
      );
    });
  });
}
