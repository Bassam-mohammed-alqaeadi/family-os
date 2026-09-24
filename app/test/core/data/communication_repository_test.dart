import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/communication_repository.dart';
import 'package:family_os/core/data/family_database.dart';

/// PERS-2d — conversations, messages and calls as real rows.
///
/// The contract's rules are measured here, not assumed: one sender per message,
/// a body the store only ever sees as bytes, "حذف للجميع" as a tombstone, and a
/// fifteen-minute edit window the author alone may use.
final Uint8List _cipher = Uint8List.fromList(
  [0x00, 0xFF, 0x80, 0x01, 0xFE, 0x7F, 0x42],
);

final DateTime _base = DateTime(2026, 9, 24, 12);

void main() {
  late FamilyDatabase db;
  late DriftCommunicationRepository repo;

  setUp(() {
    db = FamilyDatabase(NativeDatabase.memory());
    repo = DriftCommunicationRepository(db);
  });

  tearDown(() => db.close());

  Future<Conversation> openFamilyRoom() => repo.openConversation(
        id: 'conv-1',
        familyId: 'fam-1',
        kind: ConvKind.family,
        approvedBy: 'acc-parent',
        title: 'غرفة العائلة',
      );

  Future<Message> send({
    String id = 'msg-1',
    String requestId = 'req-1',
    String? senderChildId = 'child-1',
    String? senderAccountId,
    String? replyTo,
    DateTime? at,
  }) =>
      repo.appendMessage(
        id: id,
        conversationId: 'conv-1',
        requestId: requestId,
        ciphertext: _cipher,
        senderChildId: senderChildId,
        senderAccountId: senderAccountId,
        replyTo: replyTo,
        at: at ?? _base,
      );

  group('conversations', () {
    test('a room is opened by a parent and read back', () async {
      final room = await openFamilyRoom();

      expect(room.kind, ConvKind.family);
      expect(room.approvedBy, 'acc-parent');
      expect(room.title, 'غرفة العائلة');
      expect(room.createdAt, isNotNull);
    });

    test('rooms are scoped to their family', () async {
      await openFamilyRoom();
      await repo.openConversation(
        id: 'conv-2',
        familyId: 'fam-2',
        kind: ConvKind.direct,
        approvedBy: 'acc-other',
      );

      expect(await repo.conversationsInFamily('fam-1'), hasLength(1));
      expect(await repo.conversationsInFamily('fam-2'), hasLength(1));
    });
  });

  group('messages', () {
    setUp(openFamilyRoom);

    test('the store holds bytes, not text, and returns them unchanged', () async {
      await send();

      final stored = await repo.messageById('msg-1');

      expect(stored, isNotNull);
      expect(stored!.ciphertext, isA<Uint8List>());
      expect(stored.ciphertext, equals(_cipher));
      expect(stored.editedAt, isNull);
      expect(stored.deletedAt, isNull);
    });

    test('exactly one sender — never two, never none', () async {
      await expectLater(
        send(senderChildId: null),
        throwsA(isA<MessageSenderException>()),
      );
      await expectLater(
        send(senderChildId: 'child-1', senderAccountId: 'acc-parent'),
        throwsA(isA<MessageSenderException>()),
      );

      expect(await repo.messageById('msg-1'), isNull);
    });

    test('re-sending the same request is the same message', () async {
      final first = await send();
      final again = await send(id: 'msg-2');

      expect(again.id, first.id);
      expect(await repo.messagesIn('conv-1'), hasLength(1));
    });

    test('the thread is newest-first and keeps its tombstones', () async {
      await send(id: 'msg-1', requestId: 'req-1', at: _base);
      await send(
        id: 'msg-2',
        requestId: 'req-2',
        at: _base.add(const Duration(minutes: 1)),
      );
      await repo.tombstoneMessage(
        'msg-1',
        at: _base.add(const Duration(minutes: 2)),
      );

      final thread = await repo.messagesIn('conv-1');

      expect(thread, hasLength(2), reason: 'a tombstone is not a gap');
      expect(thread.first.id, 'msg-2');
      expect(thread.last.deletedAt, isNotNull);
    });

    test('a reply points at the message it answers', () async {
      await send();
      final reply = await send(
        id: 'msg-2',
        requestId: 'req-2',
        replyTo: 'msg-1',
      );

      expect(reply.replyTo, 'msg-1');
    });
  });

  group('editing', () {
    setUp(openFamilyRoom);

    test('the author may edit inside the window', () async {
      await send();
      final replacement = Uint8List.fromList([0xAA, 0xBB]);

      final edited = await repo.editMessage(
        id: 'msg-1',
        actorKey: 'child-1',
        ciphertext: replacement,
        at: _base.add(const Duration(minutes: 10)),
      );

      expect(edited.ciphertext, equals(replacement));
      expect(edited.editedAt, _base.add(const Duration(minutes: 10)));
    });

    test('someone who is not the author is refused', () async {
      await send();

      await expectLater(
        repo.editMessage(
          id: 'msg-1',
          actorKey: 'acc-parent',
          ciphertext: Uint8List.fromList([0x01]),
          at: _base.add(const Duration(minutes: 1)),
        ),
        throwsA(isA<MessageEditRefused>()),
      );
    });

    test('the window closes after fifteen minutes', () async {
      await send();

      await expectLater(
        repo.editMessage(
          id: 'msg-1',
          actorKey: 'child-1',
          ciphertext: Uint8List.fromList([0x01]),
          at: _base.add(const Duration(minutes: 16)),
        ),
        throwsA(isA<MessageEditRefused>()),
      );

      expect((await repo.messageById('msg-1'))!.editedAt, isNull);
    });

    test('a tombstoned message cannot be edited back to life', () async {
      await send();
      await repo.tombstoneMessage(
        'msg-1',
        at: _base.add(const Duration(minutes: 1)),
      );

      await expectLater(
        repo.editMessage(
          id: 'msg-1',
          actorKey: 'child-1',
          ciphertext: Uint8List.fromList([0x01]),
          at: _base.add(const Duration(minutes: 2)),
        ),
        throwsA(isA<MessageEditRefused>()),
      );
    });
  });

  group('delete for everyone', () {
    setUp(openFamilyRoom);

    test('the row survives and the body does not', () async {
      await send();

      final tombstone = await repo.tombstoneMessage(
        'msg-1',
        at: _base.add(const Duration(minutes: 3)),
      );

      expect(tombstone.deletedAt, _base.add(const Duration(minutes: 3)));
      expect(
        tombstone.ciphertext,
        isEmpty,
        reason: 'the body goes too, or "حذف للجميع" is a UI trick',
      );
      expect(await repo.messageById('msg-1'), isNotNull);
    });
  });

  group('calls', () {
    test('a call is logged, and there is no column for a recording', () async {
      final call = await repo.recordCall(
        id: 'call-1',
        familyId: 'fam-1',
        startedAt: _base,
        kind: 'VIDEO',
        outcome: 'ANSWERED',
        durationS: 320,
      );

      expect(call.kind, 'VIDEO');
      expect(call.outcome, 'ANSWERED');
      expect(call.durationS, 320);
      expect(await repo.callsInFamily('fam-1'), hasLength(1));
    });

    test('an unknown kind, outcome or negative duration is refused', () async {
      Future<void> log({
        String kind = 'AUDIO',
        String outcome = 'ANSWERED',
        int? durationS,
      }) =>
          repo.recordCall(
            id: 'call-bad',
            familyId: 'fam-1',
            startedAt: _base,
            kind: kind,
            outcome: outcome,
            durationS: durationS,
          );

      await expectLater(log(kind: 'HOLOGRAM'), throwsA(isA<ArgumentError>()));
      await expectLater(log(outcome: 'IGNORED'), throwsA(isA<ArgumentError>()));
      await expectLater(log(durationS: -1), throwsA(isA<ArgumentError>()));

      expect(await repo.callsInFamily('fam-1'), isEmpty);
    });
  });

  group('acceptance — the conversation survives a database reopen', () {
    test('open a room, send, close, reopen, read the same bytes', () async {
      final dir = Directory.systemTemp.createTempSync('family_os_pers2d_comm');
      final file = File('${dir.path}/family_os.sqlite');

      try {
        var fileDb = FamilyDatabase(NativeDatabase(file));
        var fileRepo = DriftCommunicationRepository(fileDb);
        await fileRepo.openConversation(
          id: 'conv-1',
          familyId: 'fam-1',
          kind: ConvKind.family,
          approvedBy: 'acc-parent',
        );
        await fileRepo.appendMessage(
          id: 'msg-1',
          conversationId: 'conv-1',
          requestId: 'req-1',
          ciphertext: _cipher,
          senderChildId: 'child-1',
          at: _base,
        );
        await fileDb.close();

        // A fresh handle over the same file — nothing shared in memory.
        fileDb = FamilyDatabase(NativeDatabase(file));
        fileRepo = DriftCommunicationRepository(fileDb);

        final message = await fileRepo.messageById('msg-1');

        expect(message, isNotNull);
        expect(message!.ciphertext, equals(_cipher));
        expect(await fileRepo.conversationById('conv-1'), isNotNull);
        await fileDb.close();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
