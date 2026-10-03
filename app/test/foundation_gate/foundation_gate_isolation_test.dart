import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isolated Foundation Gate source does not import legacy bootstrap or persistence domains', () {
    final directory = Directory('lib/foundation_gate');
    final imports = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
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
    ]) {
      expect(imports, isNot(contains(prohibited)), reason: prohibited);
    }
  });

  test('the connected roster client exposes no mutation transport or local configuration source', () {
    final source = File('lib/foundation_gate/children_roster_api_client.dart').readAsStringSync();
    final configuration = Directory('lib/foundation_gate/local');

    expect(source, contains('Future<List<FoundationGateChild>> list'));
    expect(source, isNot(contains('.post(')));
    expect(source, isNot(contains('Idempotency-Key')));
    expect(configuration.existsSync(), isFalse);
  });

  test('the refined control centre reuses shared design tokens and has no device or policy model', () {
    final source = File('lib/foundation_gate/children_control_centre.dart').readAsStringSync();

    expect(source, contains('package:family_os/core/design/tokens.dart'));
    expect(source, contains('FamilyColors'));
    expect(source, contains('ChildrenControlCentreStatus'));
    expect(source, isNot(contains('deviceState')));
    expect(source, isNot(contains('policyState')));
    expect(source, isNot(contains('Icon(Icons.add')));
  });
}
