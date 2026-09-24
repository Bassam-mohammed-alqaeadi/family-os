import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:family_os/core/data/durable_persistence.dart';
import 'package:family_os/core/policy/smart_mode_prefs.dart';
import 'package:family_os/core/policy/smart_mode_prefs_repository.dart';

/// Rule 25 acceptance — Stage-1 settings must survive an app restart.
///
/// Before this card, every `stage1*Store` was a process-lifetime Dart map:
/// closing the app dropped the father's whole configuration. These tests
/// prove the same seams now write through to platform storage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DurablePrefsStore', () {
    test('writes through to platform storage, not a Dart map', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = DurablePrefsStore(prefs);

      await store.write('demo:key', 'value-1');

      expect(
        prefs.getString('${DurablePrefsStore.namespace}demo:key'),
        'value-1',
        reason: 'the value must live in platform storage',
      );
    });

    test('a later process reads back what an earlier one wrote', () async {
      final store = DurablePrefsStore(await SharedPreferences.getInstance());
      await store.write('demo:key', 'persisted');

      // Simulate a fresh launch: a brand-new store over the same platform
      // storage, with no shared Dart state.
      final reopened = DurablePrefsStore(await SharedPreferences.getInstance());

      expect(await reopened.read('demo:key'), 'persisted');
    });

    test('missing keys read as null, and writes overwrite', () async {
      final store = DurablePrefsStore(await SharedPreferences.getInstance());

      expect(await store.read('never-written'), isNull);

      await store.write('k', 'first');
      await store.write('k', 'second');

      expect(await store.read('k'), 'second');
    });

    test('keys are namespaced away from any other prefs user', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = DurablePrefsStore(prefs);

      await prefs.setString('borrowed-key', 'foreign');
      await store.write('borrowed-key', 'family');

      expect(prefs.getString('borrowed-key'), 'foreign');
      expect(
        prefs.getString('${DurablePrefsStore.namespace}borrowed-key'),
        'family',
      );
    });
  });

  group('repository round-trip over durable storage', () {
    test('father configuration survives a restart', () async {
      const childId = 'child-1';
      final saved = SmartModePrefs.defaults(childId: childId);

      final firstRun = PrefsSmartModePrefsRepository(
        DurablePrefsStore(await SharedPreferences.getInstance()),
      );
      await firstRun.save(saved);

      final secondRun = PrefsSmartModePrefsRepository(
        DurablePrefsStore(await SharedPreferences.getInstance()),
      );
      final loaded = await secondRun.load(childId);

      expect(jsonEncode(loaded.toJson()), jsonEncode(saved.toJson()));
      expect(loaded.childId, childId);
    });
  });

  group('installation over the Stage-1 seams', () {
    tearDown(() {
      // Keep the global as a memory store for any test that runs after us.
      stage1SmartModePrefsStore = MemorySmartModePrefsStore();
    });

    test('installDurablePersistence swaps the seam to platform storage',
        () async {
      expect(
        stage1SmartModePrefsStore,
        isA<MemorySmartModePrefsStore>(),
        reason: 'hermetic default before installation',
      );

      await installDurablePersistence();

      expect(stage1SmartModePrefsStore, isA<DurablePrefsStore>());

      final prefs = await SharedPreferences.getInstance();
      final repo = PrefsSmartModePrefsRepository(stage1SmartModePrefsStore);
      await repo.save(SmartModePrefs.defaults(childId: 'child-9'));

      expect(
        prefs.getString('${DurablePrefsStore.namespace}smart_modes:child-9'),
        isNotNull,
        reason: 'a save through the seam must reach platform storage',
      );
    });
  });
}
