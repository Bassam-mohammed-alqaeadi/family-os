import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// VX-B4 · design residue guard (G-10 / G-11 / G-13).
void main() {
  final features = Directory('lib/features');
  final appLib = Directory('lib/app');

  test('features/ has no ScaffoldMessenger / showSnackBar', () {
    final hits = <String>[];
    for (final f in features.listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final t = f.readAsStringSync();
      if (t.contains('ScaffoldMessenger') || t.contains('showSnackBar')) {
        hits.add(f.path);
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test(
    'features/ has no Color(0x literals (except device_user_switch parse)',
    () {
      final hits = <String>[];
      for (final f in features.listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        if (f.path.contains('device_user_switch_screen.dart')) continue;
        final t = f.readAsStringSync();
        if (RegExp(r'Color\(0x').hasMatch(t)) {
          hits.add(f.path);
        }
      }
      expect(hits, isEmpty, reason: hits.join('\n'));
    },
  );

  test('trailing drill-in chevron_left is gone from features + shell', () {
    final hits = <String>[];
    for (final dir in [features, appLib]) {
      for (final f in dir.listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final t = f.readAsStringSync();
        if (t.contains('Icons.chevron_left')) {
          hits.add(f.path);
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('shell FABs use Positioned.directional (not fixed left)', () {
    final shell = File('lib/app/family_shell.dart').readAsStringSync();
    expect(shell.contains('Positioned.directional'), isTrue);
    expect(RegExp(r'Positioned\(\s*left:\s*16').hasMatch(shell), isFalse);
  });
}
