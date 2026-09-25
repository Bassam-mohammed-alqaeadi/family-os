import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';

/// ADR-054 — the v6 contract: every screen gets its tables.
const _v6Tables = <String>[
  'learn_assignment',
  'learn_progress',
  'learn_session',
  'learn_result',
  'learn_skill_gap',
  'learn_streak',
  'learn_achievement',
  'quran_plan',
  'quran_recitation',
  'quran_memorization',
  'wallet_ledger',
  'family_challenge',
  'family_challenge_day',
  'tutor_thread',
  'tutor_turn',
  'content_pack',
  'content_item',
  'learning_path',
  'learning_path_stop',
  'attribution_rule',
  'focus_schedule',
  'focus_schedule_app',
  'focus_advisor_note',
  'community_cache',
  'task',
  'task_submission',
  'chore_distribution',
  'calendar_event',
  'subscription_state',
  'billing_event',
  'invite',
  'pairing_token',
];

void main() {
  group('ADR-054 — contract v6', () {
    late Directory dir;
    late File file;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('v6_');
      file = File('${dir.path}/v6.sqlite');
    });

    tearDown(() async => dir.delete(recursive: true));

    Future<Set<String>> tableNames(FamilyDatabase db) async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      return rows.map((r) => r.data['name'] as String).toSet();
    }

    test('a fresh database exposes all 54 contract tables at v6', () async {
      final db = FamilyDatabase(NativeDatabase(file));
      addTearDown(db.close);

      expect(db.schemaVersion, 6);
      final names = await tableNames(db);
      for (final table in _v6Tables) {
        expect(names, contains(table));
      }
      expect(names.length, greaterThanOrEqualTo(54));
    });

    test('a v5 database upgrades to v6 and gains every new table', () async {
      final db = FamilyDatabase(NativeDatabase(file));
      // Roll the store back to how v5 left it: the new tables gone, version 5.
      for (final table in _v6Tables) {
        await db.customStatement('DROP TABLE IF EXISTS $table');
      }
      await db.customStatement('PRAGMA user_version = 5');
      await db.close();

      final upgraded = FamilyDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);

      final names = await tableNames(upgraded);
      for (final table in _v6Tables) {
        expect(names, contains(table), reason: '$table missing after upgrade');
      }
    });

    test('the upgraded tables hold rows', () async {
      final db = FamilyDatabase(NativeDatabase(file));
      for (final table in _v6Tables) {
        await db.customStatement('DROP TABLE IF EXISTS $table');
      }
      await db.customStatement('PRAGMA user_version = 5');
      await db.close();

      final upgraded = FamilyDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);

      await upgraded.into(upgraded.calendarEvents).insert(
        CalendarEventsCompanion.insert(
          id: 'ev_1',
          familyId: 'fam_1',
          titleRef: 'dup:calendar/eid',
          category: 'RELIGIOUS',
          calendarType: 'HIJRI',
          startsAt: DateTime.utc(2026, 9, 25, 9),
          createdByAccount: 'acc_father',
        ),
      );
      await upgraded.into(upgraded.tasks).insert(
        TasksCompanion.insert(
          id: 'task_1',
          familyId: 'fam_1',
          titleRef: 'dup:task/dishes',
          kind: 'CHORE',
          status: 'OPEN',
          createdByAccount: 'acc_father',
          rewardMinutes: const Value(30),
        ),
      );

      final events = await upgraded.select(upgraded.calendarEvents).get();
      final tasks = await upgraded.select(upgraded.tasks).get();
      expect(events.single.titleRef, 'dup:calendar/eid');
      expect(events.single.calendarType, 'HIJRI');
      expect(tasks.single.rewardMinutes, 30);
    });

    test('no new table carries an ARB key column (§2 rule 1)', () async {
      final db = FamilyDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final offenders = <String>[];
      for (final table in _v6Tables) {
        final info = await db.customSelect("PRAGMA table_info('$table')").get();
        for (final row in info) {
          final name = (row.data['name'] as String).toLowerCase();
          if (name.endsWith('key')) offenders.add('$table.$name');
        }
      }
      expect(offenders, isEmpty, reason: 'ARB keys belong in the bundle');
    });

    test('the family-scoped tables carry their scope column', () async {
      final db = FamilyDatabase(NativeDatabase(file));
      addTearDown(db.close);

      const familyScoped = <String>[
        'learn_assignment',
        'learn_session',
        'learn_achievement',
        'quran_plan',
        'wallet_ledger',
        'family_challenge',
        'content_pack',
        'learning_path',
        'attribution_rule',
        'focus_schedule',
        'focus_advisor_note',
        'task',
        'chore_distribution',
        'calendar_event',
        'subscription_state',
        'billing_event',
        'invite',
        'pairing_token',
      ];
      for (final table in familyScoped) {
        final info = await db.customSelect("PRAGMA table_info('$table')").get();
        final columns = info.map((r) => (r.data['name'] as String)).toSet();
        expect(columns, contains('family_id'), reason: table);
      }
    });
  });
}
