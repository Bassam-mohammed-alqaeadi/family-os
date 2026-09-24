import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/chat_preferences_repository.dart';
import 'package:family_os/core/data/communication_rules.dart';
import 'package:family_os/core/data/communication_repository.dart';
import 'package:family_os/core/data/family_database.dart';

/// ADR-053 — «إعدادات هذه المحادثة»: الكتم والأرشفة والتثبيت والخلفية والثيم.
///
/// The point measured here is ownership: these settings belong to the READER, so
/// the father's mute must not mute the room for the child, and one member's
/// archive must not hide the thread from the family.
final DateTime _base = DateTime(2026, 9, 24, 20);

void main() {
  late FamilyDatabase db;
  late DriftCommunicationRepository comms;
  late DriftChatPreferencesRepository prefs;

  setUp(() async {
    db = FamilyDatabase(NativeDatabase.memory());
    comms = DriftCommunicationRepository(db);
    prefs = DriftChatPreferencesRepository(db);
    await comms.openConversation(
      id: 'conv-1',
      familyId: 'fam-1',
      kind: ConvKind.family,
      approvedBy: 'acc-father',
      title: 'غرفة العائلة',
    );
  });

  tearDown(() => db.close());

  Future<ChatPreference> mute({
    String ownerKey = 'child-1',
    String ownerKind = 'CHILD',
    Duration? preset,
  }) =>
      prefs.muteChat(
        conversationId: 'conv-1',
        ownerKey: ownerKey,
        ownerKind: ownerKind,
        preset: preset,
        at: _base,
      );

  group('mute (كتم)', () {
    test('a preset turns into a window that expires on its own', () async {
      final row = await mute(preset: kMuteEightHours);

      expect(row.mutedUntil, _base.add(const Duration(hours: 8)));
      expect(
        chatIsMuted(mutedUntil: row.mutedUntil, now: _base),
        isTrue,
      );
      expect(
        chatIsMuted(
          mutedUntil: row.mutedUntil,
          now: _base.add(const Duration(hours: 9)),
        ),
        isFalse,
      );
    });

    test('"دائمًا" is stored as the far instant, not as null', () async {
      final row = await mute(preset: null);

      expect(row.mutedUntil, kMuteForeverUntil);
      expect(row.mutedUntil, isNotNull);
      expect(chatIsMuted(mutedUntil: row.mutedUntil, now: _base), isTrue);
    });

    test('unmuting clears the window', () async {
      await mute(preset: kMuteOneWeek);
      final cleared = await prefs.unmuteChat(
        conversationId: 'conv-1',
        ownerKey: 'child-1',
        ownerKind: 'CHILD',
      );

      expect(cleared.mutedUntil, isNull);
      expect(chatIsMuted(mutedUntil: cleared.mutedUntil, now: _base), isFalse);
    });
  });

  group('archive and pin in the list', () {
    test('hidden then back, and pinned above the rest', () async {
      final archived = await prefs.setArchived(
        conversationId: 'conv-1',
        ownerKey: 'child-1',
        ownerKind: 'CHILD',
        archived: true,
        at: _base,
      );
      expect(archived.archivedAt, _base);

      final back = await prefs.setArchived(
        conversationId: 'conv-1',
        ownerKey: 'child-1',
        ownerKind: 'CHILD',
        archived: false,
        at: _base,
      );
      expect(back.archivedAt, isNull);

      final pinned = await prefs.setPinned(
        conversationId: 'conv-1',
        ownerKey: 'child-1',
        ownerKind: 'CHILD',
        pinned: true,
        at: _base,
      );
      expect(pinned.pinnedAt, _base);

      final unpinned = await prefs.setPinned(
        conversationId: 'conv-1',
        ownerKey: 'child-1',
        ownerKind: 'CHILD',
        pinned: false,
        at: _base,
      );
      expect(unpinned.pinnedAt, isNull);
    });
  });

  group('the look of one chat', () {
    test('a wallpaper and a theme from the reference sets are saved', () async {
      final row = await prefs.setLook(
        conversationId: 'conv-1',
        ownerKey: 'child-1',
        ownerKind: 'CHILD',
        wallpaper: 'rose',
        bubbleTheme: 'rose',
        at: _base,
      );

      expect(row.wallpaper, 'rose');
      expect(row.bubbleTheme, 'rose');
      expect(kWallpapers, contains(row.wallpaper));
      expect(kBubbleThemes, contains(row.bubbleTheme));
    });

    test('a value outside the set is refused, and nothing is written', () async {
      await expectLater(
        prefs.setLook(
          conversationId: 'conv-1',
          ownerKey: 'child-1',
          ownerKind: 'CHILD',
          wallpaper: 'marble',
          bubbleTheme: 'rose',
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        prefs.setLook(
          conversationId: 'conv-1',
          ownerKey: 'child-1',
          ownerKind: 'CHILD',
          wallpaper: 'rose',
          bubbleTheme: 'rainbow',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        await prefs.preferenceFor(
          conversationId: 'conv-1',
          ownerKey: 'child-1',
        ),
        isNull,
      );
    });

    test('an unknown owner kind never reaches the table', () async {
      await expectLater(
        prefs.muteChat(
          conversationId: 'conv-1',
          ownerKey: 'child-1',
          ownerKind: 'ROBOT',
          preset: kMuteEightHours,
          at: _base,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(await prefs.preferencesOf('child-1'), isEmpty);
    });
  });

  group('ownership — these settings are the reader\'s, not the room\'s', () {
    test('the father muting the room leaves the child unmuted', () async {
      await mute(ownerKey: 'acc-father', ownerKind: 'ACCOUNT', preset: null);
      await prefs.setArchived(
        conversationId: 'conv-1',
        ownerKey: 'acc-father',
        ownerKind: 'ACCOUNT',
        archived: true,
        at: _base,
      );

      final father = await prefs.preferenceFor(
        conversationId: 'conv-1',
        ownerKey: 'acc-father',
      );
      final child = await prefs.preferenceFor(
        conversationId: 'conv-1',
        ownerKey: 'child-1',
      );

      expect(chatIsMuted(mutedUntil: father!.mutedUntil, now: _base), isTrue);
      expect(father.archivedAt, isNotNull);
      // The child has never touched these settings: still no row, not a default
      // that silently inherited the father's.
      expect(child, isNull);
      expect(await prefs.preferencesOf('child-1'), isEmpty);
    });
  });

  group('acceptance — the chat settings survive a database reopen', () {
    test('mute, archive and look come back from the file unchanged', () async {
      final dir = Directory.systemTemp.createTempSync('family_os_adr053_prefs');
      final file = File('${dir.path}/family_os.sqlite');

      try {
        var fileDb = FamilyDatabase(NativeDatabase(file));
        var fileComms = DriftCommunicationRepository(fileDb);
        var filePrefs = DriftChatPreferencesRepository(fileDb);

        await fileComms.openConversation(
          id: 'conv-1',
          familyId: 'fam-1',
          kind: ConvKind.family,
          approvedBy: 'acc-father',
        );
        await filePrefs.muteChat(
          conversationId: 'conv-1',
          ownerKey: 'child-1',
          ownerKind: 'CHILD',
          preset: null,
          at: _base,
        );
        await filePrefs.setArchived(
          conversationId: 'conv-1',
          ownerKey: 'child-1',
          ownerKind: 'CHILD',
          archived: true,
          at: _base,
        );
        await filePrefs.setLook(
          conversationId: 'conv-1',
          ownerKey: 'child-1',
          ownerKind: 'CHILD',
          wallpaper: 'mint',
          bubbleTheme: 'teal',
          at: _base,
        );
        await fileDb.close();

        // A fresh handle over the same file — nothing shared in memory.
        fileDb = FamilyDatabase(NativeDatabase(file));
        filePrefs = DriftChatPreferencesRepository(fileDb);

        final row = await filePrefs.preferenceFor(
          conversationId: 'conv-1',
          ownerKey: 'child-1',
        );

        expect(row, isNotNull);
        expect(row!.mutedUntil, kMuteForeverUntil);
        expect(row.archivedAt, _base);
        expect(row.wallpaper, 'mint');
        expect(row.bubbleTheme, 'teal');
        await fileDb.close();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
