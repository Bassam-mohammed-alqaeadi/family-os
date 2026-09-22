import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// UI-016 / Rule 12 — CI mirror of `dart run tool/check_hardcoded_strings.dart`.
void main() {
  test('AC1: features/ has no banned user-facing string literals', () {
    final appRoot = _appRoot();
    final result = Process.runSync(
      'dart',
      const ['run', 'tool/check_hardcoded_strings.dart'],
      workingDirectory: appRoot.path,
      runInShell: true,
    );
    expect(
      result.exitCode,
      0,
      reason: 'Rule 12 violations:\n'
          '${result.stdout}\n${result.stderr}',
    );
  });
}

Directory _appRoot() {
  var dir = Directory.current;
  // flutter test cwd is usually `app/`; tolerate repo root.
  for (var i = 0; i < 4; i++) {
    final tool = File(
      '${dir.path}${Platform.pathSeparator}tool'
      '${Platform.pathSeparator}check_hardcoded_strings.dart',
    );
    if (tool.existsSync()) return dir;
    final nested = File(
      '${dir.path}${Platform.pathSeparator}app'
      '${Platform.pathSeparator}tool'
      '${Platform.pathSeparator}check_hardcoded_strings.dart',
    );
    if (nested.existsSync()) {
      return Directory('${dir.path}${Platform.pathSeparator}app');
    }
    dir = dir.parent;
  }
  fail('could not locate app/tool/check_hardcoded_strings.dart');
}
