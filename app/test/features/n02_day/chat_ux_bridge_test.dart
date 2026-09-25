import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/chat_preferences_repository.dart';
import 'package:family_os/core/data/communication_repository.dart';
import 'package:family_os/core/data/communication_rules.dart';
import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/features/n02_day/chat_ux_bridge.dart';

/// ADR-053 — the chat line measured against real rows.
///
/// Everything the four screens promise is asserted here: the two ticks earned
/// by read rows, the 15-minute author-only edit window, the tombstone, the
/// per-chat settings, the family's fixed pin, and the receipts rule.
void main() {
  group('ADR-053 pure rules', () {
    test('the family conversation is pinned always', () {
      expect(chatStaysPinned(isFamily: true, pinned: false), isTrue);
      expect(chatStaysPinned(isFamily: false, pinned: false), isFalse);
      expect(chatStaysPinned(isFamily: false, pinned: true), isTrue);
    });

    test('a chat lock never hides a child thread from the parent', () {
      expect(parentSeesThread(locked: true), isTrue);
      expect(parentSeesThread(locked: false), isTrue);
    });

    test('receipts are mandatory with a parent, offered between peers', () {
      expect(receiptsToggleOffered(hasParentMember: true), isFalse);
      expect(receiptsToggleOffered(hasParentMember: false), isTrue);
    });

    test('the 15-minute window is measured from the send, not the edit', () {
      final sentAt = DateTime(2026, 9, 24, 12);
      final now = sentAt.add(const Duration(minutes: 14, seconds: 59));
      expect(messageIsEditable(sentAt: sentAt, now: now), isTrue);
      expect(
        messageIsEditable(
          sentAt: sentAt,
          now: sentAt.add(kMessageEditWindow),
        ),
        isFalse,
      );
    });
  });

  group('bridge over real rows', () {
    late FamilyDatabase db;
    late DriftCommunicationRepository comms;
    late DriftChatPreferencesRepository prefs;
    late DateTime now;

    setUp(() {
      db = FamilyDatabase(NativeDatabase.memory());
      comms = DriftCommunicationRepository(db);
      prefs = DriftChatPreferencesRepository(db);
      now = DateTime(2026, 9, 24, 12);
    });

    tearDown(() async {
      Stage1ChatRuntime.resetForTest();
      await db.close();
    });

    Future<void> openFamily() => comms.openConversation(
          id: 'family',
          familyId: 'fam-1',
          kind: ConvKind.family,
          approvedBy: 'acc-1',
          title: 'عائلة ١',
        );

    Future<void> openDirect(String id) => comms.openConversation(
          id: id,
          familyId: 'fam-1',
          kind: ConvKind.direct,
          approvedBy: 'acc-1',
          title: 'ابن ١',
        );

    DriftConversationRepository threadRepo(
      String ownerKey,
      String ownerKind, {
      bool? hasParentMember,
    }) =>
        DriftConversationRepository(
          comms: comms,
          prefs: prefs,
          ownerKey: ownerKey,
          ownerKind: ownerKind,
          clock: () => now,
          hasParentMember: hasParentMember,
        );

    DriftConversationsListRepository listRepo(
      String ownerKey,
      String ownerKind,
    ) =>
        DriftConversationsListRepository(
          comms: comms,
          prefs: prefs,
          familyId: 'fam-1',
          ownerKey: ownerKey,
          ownerKind: ownerKind,
          clock: () => now,
        );

    test('a sent message is ✓; a read row makes it ✓✓', () async {
      await openDirect('c1');
      final child = threadRepo('child-1', 'CHILD');
      await child.send('c1', 'وصلت المدرسة', timeLabel: 'now');

      var detail = await child.load('c1');
      var mine = detail!.messages.single;
      expect(mine.isMine, isTrue);
      expect(mine.tick, MessageTick.sent);

      await comms.markRead(
        messageId: mine.id,
        readerKey: 'acc-1',
        readerKind: 'ACCOUNT',
        at: now,
      );

      detail = await child.load('c1');
      mine = detail!.messages.single;
      expect(mine.tick, MessageTick.read);
    });

    test('the edit window closes for real and stays author-only', () async {
      await openDirect('c1');
      final child = threadRepo('child-1', 'CHILD');
      await child.send('c1', 'النص الأول', timeLabel: 'now');
      final id = (await child.load('c1'))!.messages.single.id;

      now = now.add(const Duration(minutes: 10));
      await child.editMessage('c1', id, 'النص المعدّل');
      var mine = (await child.load('c1'))!.messages.single;
      expect(mine.body, 'النص المعدّل');
      expect(mine.edited, isTrue);

      now = now.add(const Duration(minutes: 10));
      await expectLater(
        child.editMessage('c1', id, 'مرة أخرى'),
        throwsA(isA<MessageEditRefused>()),
      );
      mine = (await child.load('c1'))!.messages.single;
      expect(mine.body, 'النص المعدّل');
    });

    test('a parent may not edit a child\'s words', () async {
      await openDirect('c1');
      final child = threadRepo('child-1', 'CHILD');
      await child.send('c1', 'كلامي أنا', timeLabel: 'now');
      final id = (await child.load('c1'))!.messages.single.id;

      final parent = threadRepo('acc-1', 'ACCOUNT');
      await expectLater(
        parent.editMessage('c1', id, 'كلام الأب'),
        throwsA(isA<MessageEditRefused>()),
      );
    });

    test('delete leaves a tombstone in place, never a hole', () async {
      await openDirect('c1');
      final child = threadRepo('child-1', 'CHILD');
      await child.send('c1', 'رسالة قصيرة', timeLabel: 'now');
      final id = (await child.load('c1'))!.messages.single.id;

      now = now.add(const Duration(minutes: 2));
      await child.deleteMessage('c1', id);

      final mine = (await child.load('c1'))!.messages.single;
      expect(mine.deleted, isTrue);
      expect(mine.visible, isFalse);
      expect(mine.body, isEmpty);
    });

    test('pin and unpin round-trip through the thread', () async {
      await openFamily();
      final parent = threadRepo('acc-1', 'ACCOUNT');
      await parent.send('family', 'رسالة تُثبَّت', timeLabel: 'now');
      final id = (await parent.load('family'))!.messages.single.id;

      await parent.pinMessage('family', id);
      var detail = await parent.load('family');
      expect(detail!.pinnedMessage, isNotNull);
      expect(detail.pinnedMessage!.id, id);

      await parent.unpinMessage('family', id);
      detail = await parent.load('family');
      expect(detail!.pinnedMessage, isNull);
    });

    test('a tombstone cannot be pinned', () async {
      await openDirect('c1');
      final child = threadRepo('child-1', 'CHILD');
      await child.send('c1', 'ستُحذف', timeLabel: 'now');
      final id = (await child.load('c1'))!.messages.single.id;
      await child.deleteMessage('c1', id);

      await expectLater(
        child.pinMessage('c1', id),
        throwsA(isA<MessagePinRefused>()),
      );
    });

    test('list: the family thread stays pinned even after setPinned(false)',
        () async {
      await openFamily();
      await openDirect('c1');
      final list = listRepo('acc-1', 'ACCOUNT');

      await list.setPinned('family', false);
      final snap = await list.load();
      final family = snap.threads.firstWhere((t) => t.id == 'family');
      expect(family.isFamily, isTrue);
      expect(family.pinned, isTrue);
      expect(snap.ordered.first.id, 'family');
    });

    test('list: mute 8h / week / forever windows expire correctly', () async {
      await openDirect('c1');
      final list = listRepo('acc-1', 'ACCOUNT');

      await list.setMuted('c1', kMuteEightHours);
      expect(
        (await list.load()).threads.single.muted,
        isTrue,
        reason: 'inside the 8h window',
      );
      now = now.add(const Duration(hours: 9));
      expect(
        (await list.load()).threads.single.muted,
        isFalse,
        reason: 'past the 8h window',
      );

      await list.setMuted('c1', kMuteOneWeek);
      now = now.add(const Duration(days: 6));
      expect((await list.load()).threads.single.muted, isTrue);
      now = now.add(const Duration(days: 2));
      expect((await list.load()).threads.single.muted, isFalse);

      await list.setMuted('c1', null);
      now = now.add(const Duration(days: 36500));
      expect(
        (await list.load()).threads.single.muted,
        isTrue,
        reason: '"دائمًا" is a far instant, not null',
      );

      await list.unmute('c1');
      expect((await list.load()).threads.single.muted, isFalse);
    });

    test('list: archive, pin and look round-trip', () async {
      await openDirect('c1');
      final list = listRepo('acc-1', 'ACCOUNT');

      await list.setArchived('c1', true);
      await list.setPinned('c1', true);
      await list.setLook('c1', wallpaper: 'rose', bubbleTheme: 'teal');

      final thread = (await list.load()).threads.single;
      expect(thread.archived, isTrue);
      expect(thread.pinned, isTrue);
      expect(thread.wallpaper, 'rose');
      expect(thread.bubbleTheme, 'teal');

      await list.setArchived('c1', false);
      await list.setPinned('c1', false);
      expect((await list.load()).threads.single.archived, isFalse);
      expect((await list.load()).threads.single.pinned, isFalse);
    });

    test('look refuses a value outside the contract sets', () async {
      await openDirect('c1');
      final list = listRepo('acc-1', 'ACCOUNT');
      await expectLater(
        list.setLook('c1', wallpaper: 'neon', bubbleTheme: 'teal'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('receipts: mandatory with a parent, optional between peers', () async {
      await openDirect('c1');
      final withParent = threadRepo('acc-1', 'ACCOUNT');
      expect((await withParent.load('c1'))!.receiptsMandatory, isTrue);

      final peers = threadRepo(
        'acc-1',
        'ACCOUNT',
        hasParentMember: false,
      );
      expect((await peers.load('c1'))!.receiptsMandatory, isFalse);
    });

    test('runtime wires adapters over the injected database', () async {
      await Stage1ChatRuntime.ensureOpen(override: db);
      expect(Stage1ChatRuntime.db, same(db));

      await openFamily();
      final list = Stage1ChatRuntime.conversationsList(
        familyId: 'fam-1',
        ownerKey: 'child-1',
        ownerKind: 'CHILD',
        clock: () => now,
      );
      final snap = await list.load();
      expect(snap.threads.single.isFamily, isTrue);
      expect(snap.threads.single.pinned, isTrue);
    });
  });
}
