import 'package:family_os/core/policy/smart_modes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M-A built-in mode catalog', () {
    test('six ready modes plus custom', () {
      expect(BuiltInModeId.values, hasLength(7));
      expect(BuiltInModeId.values.toSet(), {
        BuiltInModeId.sleep,
        BuiltInModeId.school,
        BuiltInModeId.study,
        BuiltInModeId.ramadan,
        BuiltInModeId.exams,
        BuiltInModeId.vacation,
        BuiltInModeId.custom,
      });
    });
  });

  group('M-B ModeConflictResolver.stricter', () {
    test('intersection is narrowest allowed set', () {
      final a = {'youtube', 'chess', 'quran'};
      final b = {'chess', 'quran', 'maps'};
      expect(ModeConflictResolver.stricter(a, b), {'chess', 'quran'});
    });

    test('disjoint modes yield empty allowed set', () {
      expect(ModeConflictResolver.stricter({'a'}, {'b'}), isEmpty);
    });

    test('identical sets unchanged', () {
      final apps = {'quran', 'calls'};
      expect(ModeConflictResolver.stricter(apps, apps), apps);
    });
  });

  group('M-D grace clamp + manual skip', () {
    test('default grace is 2 minutes', () {
      expect(ModeGrace.defaultMinutes, 2);
    });

    test('clamp keeps 0–5', () {
      expect(ModeGrace.clamp(0), 0);
      expect(ModeGrace.clamp(2), 2);
      expect(ModeGrace.clamp(5), 5);
      expect(ModeGrace.clamp(-3), 0);
      expect(ModeGrace.clamp(9), 5);
    });

    test('scheduled activation uses clamped grace', () {
      expect(
        ModeGrace.effectiveMinutes(configured: 2, manualActivation: false),
        2,
      );
      expect(
        ModeGrace.effectiveMinutes(configured: 8, manualActivation: false),
        5,
      );
    });

    test('manualActivationSkipsGrace is true', () {
      expect(ModeGrace.manualActivationSkipsGrace, isTrue);
    });

    test('manual activation is always instant (0 grace)', () {
      expect(
        ModeGrace.effectiveMinutes(configured: 5, manualActivation: true),
        0,
      );
      expect(
        ModeGrace.effectiveMinutes(configured: 2, manualActivation: true),
        0,
      );
    });
  });

  group('Ruling C — GrantOnModeStart required', () {
    test('complete and freeze are the only choices', () {
      expect(GrantOnModeStart.values, hasLength(2));
    });

    test('missing choice throws', () {
      expect(
        () => GrantConflictPolicy.requireOnModeStart(null),
        throwsA(isA<MissingGrantOnModeStartException>()),
      );
    });

    test('complete is accepted', () {
      expect(
        GrantConflictPolicy.requireOnModeStart(GrantOnModeStart.complete),
        GrantOnModeStart.complete,
      );
    });

    test('freeze is accepted', () {
      expect(
        GrantConflictPolicy.requireOnModeStart(GrantOnModeStart.freeze),
        GrantOnModeStart.freeze,
      );
    });
  });
}
