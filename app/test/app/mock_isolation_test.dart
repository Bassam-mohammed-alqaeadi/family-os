// The no-mocks boundary, enforced rather than asserted.
//
// Phase Zero task ص٠-د. The rule the owner set is "every mock is either outside the
// production path or deleted with its replacement", and a rule that only lives in a document
// is a rule that expires quietly. This file makes it executable in one direction, which is
// the direction that matters: a NEW mock that production code can reach fails the build.
//
// It does not fail when an existing one is removed - it fails when the list changes at all,
// because the list is the register. Deleting a mock is progress and the register has to be
// updated to say so, in docs/harness/MOCK_INVENTORY.md, in the same change. That is the
// whole point: the count can go down, it cannot go up unnoticed.
//
// What counts as a mock surface, stated plainly so the rule cannot drift:
//
//   * a file whose name carries a mock word (`_mock`, `mock_`, `_fake`, `_seed`, `_demo`,
//     `_stub`, `_fixture`), or
//   * a file that declares an identifier containing Mock or Fake - `MockSosFireService`,
//     `FakeDeviceHealthSeam`, `kChildModeLockMockPassword`, `DayChildMock`.
//
// "Production can reach it" means a file under `lib/` imports it. `lib/main.dart` counts as
// production whether or not anything imports it, because it is the entry point of the app.
//
// What this deliberately does NOT do: judge whether a given mock is acceptable. That is a
// product decision with a cost, and it belongs in the register with a reason beside it, not
// in a regular expression.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every mock surface reachable from production code, as of 2026-10-06.
///
/// Each entry is a debt with a named owner in the register. Adding one here without a row
/// in docs/harness/MOCK_INVENTORY.md is exactly what this test is built to prevent.
const Set<String> productionReachableMocks = <String>{
  'lib/app/ux_local_seed.dart',
  'lib/core/fs_foundation/mock_remote_adapter.dart',
  'lib/core/policy/advisor_repository.dart',
  'lib/core/policy/ai_stage_flags_repository.dart',
  'lib/core/policy/ai_suggestion_repository.dart',
  'lib/core/policy/chat_mock_store.dart',
  'lib/core/policy/entitlement_service.dart',
  'lib/core/policy/family_data_lifecycle.dart',
  'lib/core/policy/sos_fire.dart',
  'lib/features/n01_linking/camera_permission_seam.dart',
  'lib/features/n02_day/alert_detail_mock.dart',
  'lib/features/n02_day/alerts_hub_mock.dart',
  'lib/features/n02_day/children_list_local_seed_mock.dart',
  'lib/features/n02_day/day_board_screen.dart',
  'lib/features/n02_day/day_child_mock.dart',
  'lib/features/n02_day/family_chat_local_seed_mock.dart',
  'lib/features/n02_day/location_real_local_seed_mock.dart',
  'lib/features/n03_screen_time/child_apps_mock.dart',
  'lib/features/n03_screen_time/child_apps_real_local_seed_mock.dart',
  'lib/features/n05_lock/child_mode_lock_service.dart',
  'lib/features/n12_devices/device_health_seam.dart',
  'lib/main.dart',
};

final RegExp _mockName = RegExp(
  r'(_mock|mock_|_fake|fake_|_seed|seed_|_demo|demo_|_stub|_fixture)',
);
final RegExp _mockDeclaration = RegExp(
  r'\b(?:abstract final class|final class|class|const|final)\s+\w*(?:Mock|Fake)\w*',
);
final RegExp _importUri = RegExp("import\\s+'([^']+)'");

/// The file a package or relative import points at, or null for anything external.
String? _resolveImport(String uri, String fromFile) {
  const prefix = 'package:family_os/';
  if (uri.startsWith(prefix)) {
    return _normalise('lib/${uri.substring(prefix.length)}');
  }
  if (uri.startsWith('dart:') ||
      uri.startsWith('package:') ||
      uri.startsWith('http')) {
    return null;
  }
  final directory = fromFile.substring(0, fromFile.lastIndexOf('/'));
  return _normalise('$directory/$uri');
}

String _normalise(String path) {
  final parts = <String>[];
  for (final segment in path.split('/')) {
    if (segment == '.' || segment.isEmpty) continue;
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(segment);
  }
  return parts.join('/');
}

void main() {
  test('no mock outside the register can be reached from production code', () {
    final libFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => _normalise(file.path))
        .where((path) => path.endsWith('.dart'))
        .toList()
      ..sort();

    final sources = <String, String>{
      for (final path in libFiles) path: File(path).readAsStringSync(),
    };

    final mockSurfaces = <String>[
      for (final path in libFiles)
        if (_mockName.hasMatch(path.split('/').last.toLowerCase()) ||
            _mockDeclaration.hasMatch(sources[path]!))
          path,
    ];

    final reachable = <String>{};
    for (final candidate in mockSurfaces) {
      // The entry point is production by definition; nothing imports it.
      if (candidate == 'lib/main.dart') {
        reachable.add(candidate);
        continue;
      }
      for (final path in libFiles) {
        if (path == candidate) continue;
        final imports = _importUri
            .allMatches(sources[path]!)
            .map((match) => _resolveImport(match.group(1)!, path));
        if (imports.contains(candidate)) {
          reachable.add(candidate);
          break;
        }
      }
    }

    final added = reachable.difference(productionReachableMocks);
    final removed = productionReachableMocks.difference(reachable);

    expect(
      added,
      isEmpty,
      reason: 'These mock surfaces were not reachable from production code before this '
          'change, and now they are: ${added.join(', ')}. A mock that a family can reach is '
          'the failure the no-mocks rule exists to prevent. Remove the import, or record the '
          'mock in docs/harness/MOCK_INVENTORY.md with the reason it has to exist and what '
          'replaces it - and add it to productionReachableMocks in this file.',
    );
    expect(
      removed,
      isEmpty,
      reason: 'These mock surfaces are no longer reachable from production code: '
          '${removed.join(', ')}. That is progress, and the register has to say so: delete '
          'the row in docs/harness/MOCK_INVENTORY.md and remove the entry here, so the '
          'remaining debt is counted honestly.',
    );
  });
}
