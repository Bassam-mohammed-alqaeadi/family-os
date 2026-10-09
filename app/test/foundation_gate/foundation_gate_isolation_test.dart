import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The owner-controlled composition root under `lib/foundation_gate/local/`
/// is deliberately gitignored (`app/.gitignore`) and exists only on owner
/// workstations — it never enters review or CI. Every guard below therefore
/// scans reviewable product source and skips that local-only subtree, while
/// separately asserting that no reviewable source imports it.
bool _isLocalOnlyCompositionRoot(String path) =>
    path.replaceAll('\\', '/').contains('lib/foundation_gate/local/');

void main() {
  test(
    'isolated Foundation Gate source does not import legacy bootstrap or persistence domains',
    () {
      final directory = Directory('lib/foundation_gate');
      final imports = directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !_isLocalOnlyCompositionRoot(file.path))
          .expand((file) => file.readAsLinesSync())
          .where((line) => line.trimLeft().startsWith('import '))
          .join('\n');

      for (final prohibited in [
        'package:family_os/app/',
        'package:family_os/features/',
        'package:family_os/core/fs_foundation/',
        'local_persistence',
        'sqflite',
        'shared_preferences',
        'firebase_options.dart',
        'foundation_gate/local',
      ]) {
        expect(imports, isNot(contains(prohibited)), reason: prohibited);
      }
    },
  );

  test(
    'the roster client exposes only the admitted typed mutation and no local configuration source',
    () {
      final source = File(
        'lib/foundation_gate/children_roster_api_client.dart',
      ).readAsStringSync();

      expect(source, contains('Future<List<FoundationGateChild>> list'));
      expect(source, contains('Future<FoundationGateChild> create'));
      expect(source, contains("'idempotency-key'"));
      expect(source, contains("'displayName'"));
      expect(source, contains("'ageYears'"));

      // No reviewable product source may import the gitignored local
      // composition root; configuration always arrives through the
      // reviewed constructor seam instead.
      final reviewableSources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !_isLocalOnlyCompositionRoot(file.path));
      for (final file in reviewableSources) {
        final content = file.readAsStringSync();
        expect(
          content.contains('foundation_gate/local/') ||
              content.contains('localFoundationGateConfiguration'),
          isFalse,
          reason: '${file.path} must not import the local composition root',
        );
      }
    },
  );

  test(
    'the refined control centre reuses shared design tokens and has no device or policy model',
    () {
      final source = File(
        'lib/foundation_gate/children_control_centre.dart',
      ).readAsStringSync();

      expect(source, contains('package:family_os/core/design/tokens.dart'));
      expect(source, contains('FamilyColors'));
      expect(source, contains('ChildrenControlCentreStatus'));
      expect(source, isNot(contains('deviceState')));
      expect(source, isNot(contains('policyState')));
      expect(source, isNot(contains('Icon(Icons.add')));
    },
  );
}
