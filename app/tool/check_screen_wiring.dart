// ignore_for_file: avoid_print

import 'dart:io';

/// WIR-00 — the dual wiring metric (plan: `harness/14_REMAINING_WIRING_PLAN.md` §3).
///
/// A screen counts as *wired* only when BOTH hold:
///   1. it binds its default through a domain runtime
///      (`widget.<seam> ?? Stage1XRuntime.<getter>`), and
///   2. that runtime getter resolves to a **Drift** adapter.
///
/// Counting `Stage1…Runtime` names alone is misleading: the default globals of
/// several domains are still `InMemoryXRepository`, so a screen can "have a
/// runtime" and read non-persisted data.
///
/// Run from `app/`:
///   dart run tool/check_screen_wiring.dart            # report + summary
///   dart run tool/check_screen_wiring.dart --strict   # exit 1 if any bound
///                                                     # screen is non-Drift
void main(List<String> args) {
  final strict = args.contains('--strict');
  final features = Directory('lib/features');
  if (!features.existsSync()) {
    stderr.writeln('features/ not found at ${features.path}');
    exit(1);
  }

  final runtimeGetters = _runtimeGetters(features);
  final screens = _screenFiles(features)
    ..sort((a, b) => a.path.compareTo(b.path));

  var wiredDrift = 0;
  var wiredOther = 0;
  var wiredLegacy = 0;
  var unbound = 0;
  final legacyLines = <String>[];

  for (final file in screens) {
    final source = file.readAsStringSync();
    final bindings = _bindingsIn(source, runtimeGetters.keys.toSet());
    final rel = file.path.replaceFirst('lib/features/', '');
    if (bindings.isEmpty) {
      unbound++;
      continue;
    }
    final resolved = bindings.map((b) {
      final adapter = runtimeGetters[b] ?? '?';
      return '$b=${_kindOf(adapter)}:$adapter';
    }).toList()..sort();
    final kinds = resolved.map((r) => r.split('=')[1].split(':')[0]).toSet();
    if (kinds.length == 1 && kinds.single == 'drift') {
      wiredDrift++;
    } else if (kinds.contains('legacy')) {
      wiredLegacy++;
      legacyLines.add('$rel -> ${resolved.join(', ')}');
    } else {
      wiredOther++;
      legacyLines.add('$rel -> ${resolved.join(', ')}');
    }
  }

  print('screens=${screens.length} drift=$wiredDrift other=$wiredOther '
      'legacy=$wiredLegacy unbound=$unbound');
  if (legacyLines.isNotEmpty) {
    print('-- bound but not fully Drift (${legacyLines.length}) --');
    legacyLines.sort();
    for (final line in legacyLines) {
      print(line);
    }
  }
  if (strict && wiredLegacy > 0) exit(1);
}

/// A resolved adapter class is one of three kinds.
///  - `drift`  — rows are read/written on the ADR-054 v6 database.
///  - `legacy` — an `InMemory…` default (a mock in the production path).
///  - `other`  — a local store / service that is not (yet) classified here.
String _kindOf(String adapter) {
  if (adapter.startsWith('Drift')) return 'drift';
  if (adapter.startsWith('InMemory')) return 'legacy';
  return 'other';
}
Map<String, String> _runtimeGetters(Directory features) {
  final getters = <String, String>{};
  final head = RegExp(
    r'static\s+[A-Za-z_][A-Za-z0-9_<>,?\s]*\s+get\s+([A-Za-z][A-Za-z0-9_]*)\s*(?:=>|\{)',
    multiLine: true,
  );
  final expr = RegExp(r'(?:=>|return)\s+([A-Za-z_][A-Za-z0-9_]*)');
  final concrete = RegExp(r'\b(Drift[A-Za-z0-9_]*|InMemory[A-Za-z0-9_]*|Local[A-Za-z0-9_]*)');
  for (final file in _dartFiles(features)) {
    if (file.path.endsWith('_screen.dart')) continue;
    final source = file.readAsStringSync();
    if (!source.contains('Runtime')) continue;
    for (final m in head.allMatches(source)) {
      final name = m.group(1)!;
      // A getter's body can be an arrow or a block; scan a bounded window from
      // the getter head for its returned expression.
      final end = (m.end + 1400).clamp(0, source.length);
      final window = source.substring(m.end, end);
      // Prefer a concrete adapter identifier over a local hop
      // (`final existing = …; return existing;`).
      final c = concrete.firstMatch(window);
      final e = expr.firstMatch(window);
      final adapter = c?.group(1) ?? e?.group(1) ?? '?';
      getters.putIfAbsent(name, () => adapter);
    }
  }
  return getters;
}

/// The runtime getters this screen binds (`Stage1XxxRuntime.<getter>`).
Set<String> _bindingsIn(String source, Set<String> known) {
  final found = <String>{};
  final re = RegExp(r'Stage1[A-Za-z]*Runtime\.([A-Za-z][A-Za-z0-9_]*)');
  for (final m in re.allMatches(source)) {
    final name = m.group(1)!;
    if (known.contains(name)) found.add(name);
  }
  return found;
}

List<File> _screenFiles(Directory root) => _dartFiles(root)
    .where((f) => f.path.endsWith('_screen.dart'))
    .toList(growable: false);

Iterable<File> _dartFiles(Directory root) => root
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));
