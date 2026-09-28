import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// VX-B1 / FVX-G-01 — no debug file writes or network egress ship in `lib/`.
void main() {
  late final List<File> libFiles;

  setUpAll(() {
    final lib = Directory('lib');
    expect(lib.existsSync(), isTrue, reason: 'run from app/');
    libFiles = lib
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(libFiles, isNotEmpty);
  });

  String rel(File f) => f.path.replaceAll(r'\', '/');

  test('no debug instrumentation markers anywhere in lib/', () {
    const banned = <String>[
      'HttpClient',
      '127.0.0.1',
      'localhost:',
      'debug-296a8e',
      'AGENT_DEBUG',
      'X-Debug-Session-Id',
      '#region agent log',
      '/ingest/',
    ];
    final hits = <String>[];
    for (final f in libFiles) {
      final src = f.readAsStringSync();
      for (final token in banned) {
        if (src.contains(token)) hits.add('${rel(f)} → $token');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('no dart:io in app/, features/ or main.dart (rule 25)', () {
    final hits = <String>[];
    for (final f in libFiles) {
      final path = rel(f);
      final scoped =
          path.contains('lib/app/') ||
          path.contains('lib/features/') ||
          path.endsWith('lib/main.dart');
      if (!scoped) continue;
      final src = f.readAsStringSync();
      if (src.contains("import 'dart:io'")) hits.add(path);
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('no hard-coded Windows file paths in lib/', () {
    final hits = <String>[];
    final winPath = RegExp(r"r'[A-Za-z]:\\");
    for (final f in libFiles) {
      if (winPath.hasMatch(f.readAsStringSync())) hits.add(rel(f));
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
