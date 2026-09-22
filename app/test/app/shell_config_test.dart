import 'dart:convert';
import 'dart:io';

import 'package:family_os/app/shell_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shell tabs and tabless lengths', () {
    expect(parentShellTabs, hasLength(5));
    expect(childShellTabs, hasLength(4));

    // Card text said kids=23, but that counted tombstone SCR-FAT-039.
    // Criteria 4+5 + ADR-034 require excluding tombstones → kids == 22.
    expect(
      {for (final t in parentShellTabs) t.tabId: t.screenIds.length},
      {'today': 14, 'kids': 22, 'family': 11, 'studio': 13, 'settings': 15},
    );
    expect(
      {for (final t in childShellTabs) t.tabId: t.screenIds.length},
      {'myday': 5, 'learn': 14, 'cfam': 8, 'me': 5},
    );

    expect(parentTablessScreenIds, hasLength(17));
    expect(childTablessScreenIds, hasLength(5));
  });

  test('every active screen id appears exactly once across tabs ∪ tabless', () {
    final csvActive = _activeScreenIdsFromCsv();
    final seen = <String>[];
    for (final tab in [...parentShellTabs, ...childShellTabs]) {
      seen.addAll(tab.screenIds);
    }
    seen.addAll(parentTablessScreenIds);
    seen.addAll(childTablessScreenIds);

    expect(
      seen.toSet(),
      hasLength(seen.length),
      reason: 'duplicate screen ids',
    );
    expect(seen.toSet(), csvActive);
    expect(seen, hasLength(csvActive.length));
  });

  test('SCR-FAT-039 tombstone appears nowhere', () {
    const tomb = 'SCR-FAT-039';
    for (final tab in [...parentShellTabs, ...childShellTabs]) {
      expect(tab.screenIds, isNot(contains(tomb)));
    }
    expect(parentTablessScreenIds, isNot(contains(tomb)));
    expect(childTablessScreenIds, isNot(contains(tomb)));
    for (final entries in hubIndex.values) {
      expect(entries.map((e) => e.screenId), isNot(contains(tomb)));
    }
  });

  test('hubIndex covers 9 tabs; entries belong to tab in registry order', () {
    final expectedKeys = {
      for (final t in [...parentShellTabs, ...childShellTabs]) t.tabId,
    };
    expect(hubIndex.keys.toSet(), expectedKeys);
    expect(hubIndex, hasLength(9));

    final byTab = {
      for (final t in [...parentShellTabs, ...childShellTabs])
        t.tabId: t.screenIds,
    };
    for (final entry in hubIndex.entries) {
      final tabIds = byTab[entry.key]!;
      expect(
        entry.value.map((e) => e.screenId).toList(),
        tabIds,
        reason: 'hub ${entry.key} must match tab screenIds order',
      );
      for (final e in entry.value) {
        expect(tabIds, contains(e.screenId));
      }
    }
  });

  test('generator is idempotent (hash twice)', () {
    final appDir = _appDirectory();
    void gen() {
      final r = Process.runSync(
        'dart',
        ['run', 'tool/gen_routes.dart'],
        workingDirectory: appDir.path,
        runInShell: true,
      );
      expect(r.exitCode, 0, reason: r.stderr.toString());
    }

    gen();
    final router1 = File(
      '${appDir.path}/lib/app/router.dart',
    ).readAsBytesSync();
    final shell1 = File(
      '${appDir.path}/lib/app/shell_config.dart',
    ).readAsBytesSync();
    final h1 = '${base64Encode(router1)}|${base64Encode(shell1)}';

    gen();
    final router2 = File(
      '${appDir.path}/lib/app/router.dart',
    ).readAsBytesSync();
    final shell2 = File(
      '${appDir.path}/lib/app/shell_config.dart',
    ).readAsBytesSync();
    final h2 = '${base64Encode(router2)}|${base64Encode(shell2)}';

    expect(h2, h1);
    expect(router2, router1);
    expect(shell2, shell1);
  });

  test('shellRoutesByTabRoot maps each tab root', () {
    for (final tab in [...parentShellTabs, ...childShellTabs]) {
      final path = shellRoutesByTabRoot[tab.tabId];
      expect(path, isNotNull);
      expect(path, '/${tab.rootScreenId.toLowerCase().replaceAll('_', '-')}');
    }
  });

  test('each tab root is screenIds[0]', () {
    for (final tab in [...parentShellTabs, ...childShellTabs]) {
      expect(tab.screenIds.first, tab.rootScreenId);
    }
  });
}

Directory _appDirectory() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    if (File('${dir.path}/tool/gen_routes.dart').existsSync()) {
      return dir;
    }
    if (File('${dir.path}/app/tool/gen_routes.dart').existsSync()) {
      return Directory('${dir.path}/app');
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  fail(
    'Could not locate app/ with tool/gen_routes.dart from ${Directory.current.path}',
  );
}

Set<String> _activeScreenIdsFromCsv() {
  final csv = _resolveScreensCsv();
  final lines = csv
      .readAsStringSync()
      .split(RegExp(r'\r?\n'))
      .where((l) => l.trim().isNotEmpty)
      .toList();
  final active = <String>{};
  for (var i = 1; i < lines.length; i++) {
    final cols = lines[i].split(',');
    if (cols.isEmpty) continue;
    final id = cols[0].trim();
    if (!id.startsWith('SCR-')) continue;
    final name = cols.length > 3 ? cols[3].trim() : '';
    final notes = cols.length > 8 ? cols[8].trim() : '';
    final hay = '$name $notes'.toLowerCase();
    final tomb = hay.contains('tombstone') || name.contains('محذوفة');
    if (!tomb) active.add(id);
  }
  return active;
}

File _resolveScreensCsv() {
  final candidates = <File>[
    File('${Directory.current.path}/../prototype/_REGISTRY/screens.csv'),
    File('${Directory.current.path}/prototype/_REGISTRY/screens.csv'),
    File('${Directory.current.path}/../../prototype/_REGISTRY/screens.csv'),
  ];
  for (final f in candidates) {
    if (f.existsSync()) return f;
  }
  fail('screens.csv not found');
}
