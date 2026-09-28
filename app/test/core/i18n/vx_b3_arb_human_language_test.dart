import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// VX-B3 · D2 — ARB user-facing values must not carry engineering jargon.
void main() {
  final arPath = File('lib/core/i18n/app_ar.arb');
  final enPath = File('lib/core/i18n/app_en.arb');

  // Word-ish tokens (avoid matching "alternative" via "native").
  final banned = RegExp(
    r'\b(?:Native|Remote|REMOTE|FCM|Backend|MediaProjection|MOCK|Gateway|LiveKit|relay)\b',
    caseSensitive: false,
  );

  Map<String, String> loadValues(File file) {
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return {
      for (final e in raw.entries)
        if (!e.key.startsWith('@') && e.value is String)
          e.key: e.value as String,
    };
  }

  test('AR ARB has no banned engineering jargon', () {
    final values = loadValues(arPath);
    final hits = <String>[];
    for (final e in values.entries) {
      if (banned.hasMatch(e.value)) {
        hits.add('${e.key}: ${e.value}');
      }
    }
    expect(hits, isEmpty, reason: hits.take(12).join('\n'));
  });

  test('EN ARB has no banned engineering jargon', () {
    final values = loadValues(enPath);
    final hits = <String>[];
    for (final e in values.entries) {
      if (banned.hasMatch(e.value)) {
        hits.add('${e.key}: ${e.value}');
      }
    }
    expect(hits, isEmpty, reason: hits.take(12).join('\n'));
  });

  test('AR/EN key parity for user-facing string keys', () {
    final ar = loadValues(arPath);
    final en = loadValues(enPath);
    expect(ar.keys.toSet(), en.keys.toSet());
  });

  test('glossary v1 badge + child gentle line present', () {
    final ar = loadValues(arPath);
    final en = loadValues(enPath);
    expect(ar['capabilityStatusImplemented'], 'يعمل');
    expect(en['capabilityStatusImplemented'], 'Works');
    expect(ar['capabilityStatusMockRemote'], 'على هذا الجهاز');
    expect(en['capabilityStatusMockRemote'], 'On this device');
    expect(ar['honestyChildGentleLine'], contains('هذا الجهاز'));
    expect(en['honestyChildGentleLine'], contains('this device only'));
  });
}
