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
      'package:family_os/core/fs_foundation/',
      'local_persistence',
      'sqflite',
      'shared_preferences',
      'firebase_options.dart',
    ]) {
      expect(imports, isNot(contains(prohibited)), reason: prohibited);
    }
  });
}
