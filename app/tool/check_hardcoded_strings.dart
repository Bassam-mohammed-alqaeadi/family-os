// ignore_for_file: avoid_print

import 'dart:io';

/// Rule 12 / UI-016 — reject user-facing string literals in feature widgets.
///
/// Run from `app/`:
///   dart run tool/check_hardcoded_strings.dart
///
/// Exit 0 = clean · Exit 1 = violations.
///
/// ## Residual allowlist (documented, incremental)
/// - Paths matching `*mock*.dart` or `*_seam.dart` (demo fixtures / fake seams)
/// - Eastern-digit maps (`٠١٢٣٤٥٦٧٨٩`) used only for numeral shaping
/// - Decorative glyphs (`✓`, `·`, …) with no letters
/// - String interpolations whose static remainder is only whitespace/punctuation
/// - Lines marked `// rule12-allow`
/// - Debug/assert messages and `throw`/`print` arguments (not UI)
///
/// Keys, route paths, and single-token identifiers are not flagged.
void main(List<String> args) {
  final root = _featuresRoot();
  if (!root.existsSync()) {
    stderr.writeln('features/ not found at ${root.path}');
    exit(1);
  }

  final violations = scanFeatures(root);
  if (violations.isEmpty) {
    stdout.writeln(
      'check_hardcoded_strings: OK '
      '(${_countDartFiles(root)} feature files scanned)',
    );
    exit(0);
  }

  stderr.writeln(
    'check_hardcoded_strings: ${violations.length} Rule-12 violation(s):',
  );
  for (final v in violations) {
    stderr.writeln('  ${v.path}:${v.line}  ${v.literal}');
    stderr.writeln('    ${v.context}');
  }
  exit(1);
}

Directory _featuresRoot() {
  final cwd = Directory.current;
  final candidates = <Directory>[
    Directory('${cwd.path}${Platform.pathSeparator}lib'
        '${Platform.pathSeparator}features'),
    Directory('${cwd.path}${Platform.pathSeparator}app'
        '${Platform.pathSeparator}lib${Platform.pathSeparator}features'),
  ];
  for (final d in candidates) {
    if (d.existsSync()) return d;
  }
  return candidates.first;
}

int _countDartFiles(Directory root) =>
    root.listSync(recursive: true).whereType<File>().where(_isDart).length;

bool _isDart(FileSystemEntity e) => e is File && e.path.endsWith('.dart');

/// Public for unit tests — scan [featuresRoot] and return violations.
List<HardcodedHit> scanFeatures(Directory featuresRoot) {
  final hits = <HardcodedHit>[];
  final files = featuresRoot
      .listSync(recursive: true)
      .whereType<File>()
      .where(_isDart)
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final norm = file.path.replaceAll('\\', '/');
    if (_isAllowlistedPath(norm)) continue;

    final lines = file.readAsStringSync().split('\n');
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final trimmed = raw.trimLeft();
      if (trimmed.startsWith('//') ||
          trimmed.startsWith('*') ||
          trimmed.startsWith('///')) {
        continue;
      }
      if (raw.contains('rule12-allow')) continue;
      if (_isNonUiStatement(trimmed)) continue;

      for (final lit in _extractStringLiterals(raw)) {
        if (_isSuspiciousUiLiteral(lit, line: raw)) {
          hits.add(
            HardcodedHit(
              path: norm,
              line: i + 1,
              literal: lit.length > 80 ? '${lit.substring(0, 80)}…' : lit,
              context: trimmed.length > 120
                  ? '${trimmed.substring(0, 120)}…'
                  : trimmed,
            ),
          );
        }
      }
    }
  }
  return hits;
}

bool _isAllowlistedPath(String norm) {
  final base = norm.split('/').last.toLowerCase();
  if (base.contains('mock')) return true;
  if (base.endsWith('_seam.dart')) return true;
  return false;
}

bool _isNonUiStatement(String trimmed) {
  // Debug / errors / asserts are not user-facing UI copy.
  if (trimmed.startsWith('print(') ||
      trimmed.startsWith('debugPrint(') ||
      trimmed.startsWith('assert(') ||
      trimmed.startsWith('throw ') ||
      trimmed.contains('AssertionError(') ||
      trimmed.contains('StateError(') ||
      trimmed.contains('ArgumentError(') ||
      trimmed.contains('FlutterError(')) {
    return true;
  }
  return false;
}

final _stringLit = RegExp(r"""(['"])((?:\\.|(?!\1).)*?)\1""");

/// Named UI props that must not carry prose literals.
final _uiNamedProp = RegExp(
  r'(?:Text|title|label|hintText|labelText|tooltip|semanticsLabel|'
  r'message|subtitle|helperText|content|semanticLabel)\s*:',
);

List<String> _extractStringLiterals(String line) {
  final out = <String>[];
  for (final m in _stringLit.allMatches(line)) {
    out.add(_unescape(m.group(2)!));
  }
  return out;
}

String _unescape(String s) => s
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\t', '\t')
    .replaceAll(r"\'", "'")
    .replaceAll(r'\"', '"')
    .replaceAll(r'\\', r'\');

final _arabicLetter = RegExp(r'[\u0600-\u06FF]');
final _easternDigitsOnly = RegExp(r'^[\u0660-\u0669]+$');
final _decorativeOnly = RegExp(r'^[✓✔✕×·•…—–.,:;!?%\s\u200e\u200f]*$');
final _interp = RegExp(r'\$\{[^}]+\}|\$\w+');
final _latinWord = RegExp(r'[A-Za-z]{2,}');
final _identifierLike = RegExp(r'^[A-Za-z0-9_./\-:#]+$');

bool _isSuspiciousUiLiteral(String lit, {required String line}) {
  if (lit.isEmpty) return false;
  if (_easternDigitsOnly.hasMatch(lit)) return false;
  if (_decorativeOnly.hasMatch(lit)) return false;

  // Asset / URL / package paths
  if (lit.startsWith('assets/') ||
      lit.startsWith('http://') ||
      lit.startsWith('https://') ||
      lit.startsWith('package:')) {
    return false;
  }

  // Strip `$vars` — if only punctuation remains, this is composition not copy.
  final staticTrim = lit.replaceAll(_interp, '').trim();
  if (staticTrim.isEmpty || _decorativeOnly.hasMatch(staticTrim)) {
    return false;
  }

  if (_arabicLetter.hasMatch(staticTrim)) return true;

  if (!_latinWord.hasMatch(staticTrim)) return false;
  final wordCount = _latinWord.allMatches(staticTrim).length;
  final hasSpace = staticTrim.contains(' ');

  // Incremental: ban multi-word English UI phrases on Text / UI-named props.
  if (hasSpace && wordCount >= 2) {
    if (_isUiSite(line) || _looksLikeTextWidgetLiteral(line)) return true;
  }

  // Single-token identifiers / keys stay allowed.
  if (_identifierLike.hasMatch(lit)) return false;

  return false;
}

bool _isUiSite(String line) {
  if (_uiNamedProp.hasMatch(line)) return true;
  if (line.contains('Text(') || line.contains('Text.rich(')) return true;
  if (line.contains('SnackBar(') || line.contains('AppBar(')) return true;
  if (line.contains('Tooltip(') || line.contains('InputDecoration(')) {
    return true;
  }
  return false;
}

bool _looksLikeTextWidgetLiteral(String line) {
  return RegExp(r'''Text\s*\(\s*(?:const\s+)?['"]''').hasMatch(line);
}

class HardcodedHit {
  const HardcodedHit({
    required this.path,
    required this.line,
    required this.literal,
    required this.context,
  });

  final String path;
  final int line;
  final String literal;
  final String context;
}
