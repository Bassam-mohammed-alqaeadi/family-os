import 'dart:convert';

import 'package:drift/drift.dart' show Uint8List;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';

import 'package:family_os/core/data/chat_preferences_repository.dart';
import 'package:family_os/core/data/communication_repository.dart';
import 'package:family_os/core/data/communication_rules.dart';
import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';
import 'package:family_os/features/n02_day/conversations_list_repository.dart';

/// Stage-1 composition root for the chat line (ADR-053).
///
/// Same shape as [Stage1LocationRuntime]: one shared session kernel, the real
/// Drift repos constructed once, and adapters over them that speak the
/// feature-level seams. The screens keep their empty in-memory seams by default
/// (Rule 23); this runtime is how a wired surface (or a test) hands them real
/// rows.
final class Stage1ChatRuntime {
  Stage1ChatRuntime._();

  static FamilyDatabase? _db;
  static DriftCommunicationRepository? _comms;
  static DriftChatPreferencesRepository? _prefs;
  static var _opened = false;

  /// Opens once. Pass [override] to inject a database (tests own its lifecycle).
  ///
  /// Without an override the stage-1 store is an in-process Drift database —
  /// honest for this slice: no sync backend exists yet, so there is nothing to
  /// persist against. Device persistence swaps in behind the same repo when the
  /// sync phase lands; the schema is untouched.
  static Future<void> ensureOpen({FamilyDatabase? override}) async {
    await FsSessionKernel.ensureOpen();
    if (_opened && override == null) return;
    if (override != null) {
      _db = override;
    } else {
      _db ??= FamilyDatabase(NativeDatabase.memory());
    }
    _comms = DriftCommunicationRepository(_db!);
    _prefs = DriftChatPreferencesRepository(_db!);
    _opened = true;
  }

  static FamilyDatabase get db {
    final d = _db;
    if (d == null) {
      throw StateError('Call Stage1ChatRuntime.ensureOpen() first');
    }
    return d;
  }

  static DriftCommunicationRepository get comms {
    final c = _comms;
    if (c == null) {
      throw StateError('Call Stage1ChatRuntime.ensureOpen() first');
    }
    return c;
  }

  static DriftChatPreferencesRepository get prefs {
    final p = _prefs;
    if (p == null) {
      throw StateError('Call Stage1ChatRuntime.ensureOpen() first');
    }
    return p;
  }

  /// Clears this runtime only. The injected database is closed by its owner.
  static void resetForTest() {
    _opened = false;
    _db = null;
    _comms = null;
    _prefs = null;
  }

  /// Convenience: a list adapter bound to the current runtime.
  static DriftConversationsListRepository conversationsList({
    required String familyId,
    required String ownerKey,
    required String ownerKind,
    DateTime Function()? clock,
    String Function(Conversation)? titleFor,
    String Function(DateTime?)? timeLabelFor,
  }) =>
      DriftConversationsListRepository(
        comms: comms,
        prefs: prefs,
        familyId: familyId,
        ownerKey: ownerKey,
        ownerKind: ownerKind,
        clock: clock ?? DateTime.now,
        titleFor: titleFor,
        timeLabelFor: timeLabelFor,
      );

  /// Convenience: a thread adapter bound to the current runtime.
  static DriftConversationRepository conversation({
    required String ownerKey,
    required String ownerKind,
    DateTime Function()? clock,
    String Function(DateTime?)? timeLabelFor,
    String Function(String?)? senderLabelFor,
    bool? hasParentMember,
  }) =>
      DriftConversationRepository(
        comms: comms,
        prefs: prefs,
        ownerKey: ownerKey,
        ownerKind: ownerKind,
        clock: clock ?? DateTime.now,
        timeLabelFor: timeLabelFor,
        senderLabelFor: senderLabelFor,
        hasParentMember: hasParentMember,
      );
}

/// Decodes a stored body for display.
///
/// Honest stage-1 boundary: there is no key management yet, so bodies are
/// UTF-8 bytes (never a claimed ciphertext we cannot back). The moment real
/// encryption exists this becomes the one place that changes.
String decodeStoredBody(Uint8List bytes) =>
    bytes.isEmpty ? '' : utf8.decode(bytes, allowMalformed: true);

/// Projects Drift conversation rows into the SCR-FAT-021 / SCR-CHD-007 seam.
final class DriftConversationsListRepository
    implements ConversationsListRepository {
  DriftConversationsListRepository({
    required this.comms,
    required this.prefs,
    required this.familyId,
    required this.ownerKey,
    required this.ownerKind,
    DateTime Function()? clock,
    this.titleFor,
    this.timeLabelFor,
    this.emojiFor,
    this.swatchFor,
  }) : clock = clock ?? DateTime.now;

  final CommunicationRepository comms;
  final ChatPreferencesRepository prefs;
  final String familyId;
  final String ownerKey;
  final String ownerKind;
  final DateTime Function() clock;
  final String Function(Conversation)? titleFor;
  final String Function(DateTime?)? timeLabelFor;
  final String Function(Conversation)? emojiFor;
  final ConversationSwatch Function(Conversation)? swatchFor;

  @override
  Future<ConversationsListSnapshot> load() async {
    final now = clock();
    final rows = await comms.conversationsInFamily(familyId);
    final threads = <ConversationThread>[];
    for (final c in rows) {
      final pref = await prefs.preferenceFor(
        conversationId: c.id,
        ownerKey: ownerKey,
      );
      final mutedUntil = pref?.mutedUntil;
      final isFamily = c.kind == ConvKind.family;
      final messages = await comms.messagesIn(c.id);
      final last = messages.isEmpty ? null : messages.first;
      threads.add(
        ConversationThread(
          id: c.id,
          chatWith: c.id,
          title: titleFor?.call(c) ?? c.title ?? '',
          preview: last == null || last.deletedAt != null
              ? ''
              : decodeStoredBody(last.ciphertext),
          timeLabel: timeLabelFor?.call(last?.sentAt) ?? '',
          emoji: emojiFor?.call(c) ?? _emoji(c),
          swatch: swatchFor?.call(c) ?? _swatch(c),
          pinned: chatStaysPinned(
            isFamily: isFamily,
            pinned: pref?.pinnedAt != null,
          ),
          unreadCount: await _unreadCount(c.id),
          isFamily: isFamily,
          muted: chatIsMuted(mutedUntil: mutedUntil, now: now),
          mutedUntil: mutedUntil,
          archived: pref?.archivedAt != null,
          wallpaper: pref?.wallpaper,
          bubbleTheme: pref?.bubbleTheme,
        ),
      );
    }
    return ConversationsListSnapshot(threads: threads);
  }

  Future<int> _unreadCount(String conversationId) async {
    var unread = 0;
    for (final m in await comms.messagesIn(conversationId)) {
      final senderKey = m.senderChild ?? m.senderAccount ?? '';
      if (senderKey == ownerKey) continue;
      if (m.deletedAt != null) continue;
      final readers = await comms.readersOf(m.id);
      if (readers.any((r) => r.readerKey == ownerKey)) continue;
      unread++;
    }
    return unread;
  }

  @override
  Future<void> setMuted(String threadId, Duration? preset) =>
      prefs.muteChat(
        conversationId: threadId,
        ownerKey: ownerKey,
        ownerKind: ownerKind,
        preset: preset,
        at: clock(),
      );

  @override
  Future<void> unmute(String threadId) => prefs.unmuteChat(
        conversationId: threadId,
        ownerKey: ownerKey,
        ownerKind: ownerKind,
        at: clock(),
      );

  @override
  Future<void> setArchived(String threadId, bool archived) => prefs.setArchived(
        conversationId: threadId,
        ownerKey: ownerKey,
        ownerKind: ownerKind,
        archived: archived,
        at: clock(),
      );

  @override
  Future<void> setPinned(String threadId, bool pinned) async {
    final conv = await comms.conversationById(threadId);
    final effective = chatStaysPinned(
      isFamily: conv?.kind == ConvKind.family,
      pinned: pinned,
    );
    await prefs.setPinned(
      conversationId: threadId,
      ownerKey: ownerKey,
      ownerKind: ownerKind,
      pinned: effective,
      at: clock(),
    );
  }

  @override
  Future<void> setLook(
    String threadId, {
    required String wallpaper,
    required String bubbleTheme,
  }) =>
      prefs.setLook(
        conversationId: threadId,
        ownerKey: ownerKey,
        ownerKind: ownerKind,
        wallpaper: wallpaper,
        bubbleTheme: bubbleTheme,
        at: clock(),
      );

  static String _emoji(Conversation c) => switch (c.kind) {
        ConvKind.family => '👨‍👩‍👧‍👦',
        ConvKind.direct => '💬',
        ConvKind.subgroup => '👥',
      };

  static ConversationSwatch _swatch(Conversation c) => switch (c.kind) {
        ConvKind.family => ConversationSwatch.family,
        ConvKind.direct => ConversationSwatch.purple,
        ConvKind.subgroup => ConversationSwatch.sky,
      };
}

/// Projects Drift rows into the SCR-FAT-022 / SCR-CHD-008 seam, deriving ticks,
/// pins, mute and look through the pure rules — never re-decided in a widget.
final class DriftConversationRepository implements ConversationRepository {
  DriftConversationRepository({
    required this.comms,
    required this.prefs,
    required this.ownerKey,
    required this.ownerKind,
    DateTime Function()? clock,
    this.timeLabelFor,
    this.senderLabelFor,
    this.hasParentMember,
  }) : clock = clock ?? DateTime.now;

  final CommunicationRepository comms;
  final ChatPreferencesRepository prefs;
  final String ownerKey;
  final String ownerKind;
  final DateTime Function() clock;
  final String Function(DateTime?)? timeLabelFor;
  final String Function(String?)? senderLabelFor;

  /// Override for tests; otherwise a subgroup is the only peer-only room.
  final bool? hasParentMember;

  var _seq = 0;

  @override
  Future<ConversationDetail?> load(String chatWith) async {
    final conv = await comms.conversationById(chatWith);
    if (conv == null) return null;
    final pref = await prefs.preferenceFor(
      conversationId: chatWith,
      ownerKey: ownerKey,
    );
    final now = clock();
    final rows = (await comms.messagesIn(chatWith)).reversed.toList();
    final messages = <ConversationMessage>[
      for (final m in rows) await _map(m),
    ];
    final pinnedRow = await comms.pinnedMessageIn(chatWith);
    final isFamily = conv.kind == ConvKind.family;
    return ConversationDetail(
      chatWith: chatWith,
      title: conv.title ?? '',
      subtitle: '',
      emoji: _emoji(conv),
      messages: messages,
      familyPinnedNote: isFamily,
      pinnedMessage: pinnedRow == null ? null : await _map(pinnedRow),
      hasParentMember: hasParentMember ?? conv.kind != ConvKind.subgroup,
      muted: chatIsMuted(mutedUntil: pref?.mutedUntil, now: now),
      mutedUntil: pref?.mutedUntil,
      archived: pref?.archivedAt != null,
      pinned: chatStaysPinned(
        isFamily: isFamily,
        pinned: pref?.pinnedAt != null,
      ),
      wallpaper: pref?.wallpaper,
      bubbleTheme: pref?.bubbleTheme,
    );
  }

  Future<ConversationMessage> _map(Message m) async {
    final senderKey = m.senderChild ?? m.senderAccount ?? '';
    final isMine = senderKey == ownerKey;
    ConversationReply? reply;
    if (m.replyTo != null) {
      final target = await comms.messageById(m.replyTo!);
      if (target != null) {
        reply = ConversationReply(
          id: target.id,
          preview: target.deletedAt != null
              ? ''
              : decodeStoredBody(target.ciphertext),
          fromMe:
              (target.senderChild ?? target.senderAccount ?? '') == ownerKey,
        );
      }
    }
    return ConversationMessage(
      id: m.id,
      body: m.deletedAt != null ? '' : decodeStoredBody(m.ciphertext),
      timeLabel: timeLabelFor?.call(m.sentAt) ?? '',
      isMine: isMine,
      senderLabel: isMine ? null : senderLabelFor?.call(senderKey),
      tick: isMine ? await comms.tickOf(m.id) : MessageTick.sent,
      pinned: m.pinnedAt != null,
      deleted: m.deletedAt != null,
      edited: m.editedAt != null,
      sentAt: m.sentAt,
      replyTo: reply,
    );
  }

  @override
  Future<void> send(
    String chatWith,
    String text, {
    required String timeLabel,
    String? replyToId,
  }) async {
    final body = text.trim();
    if (body.isEmpty) {
      throw ArgumentError.value(text, 'text', 'الرسالة فارغة');
    }
    _seq += 1;
    final stamp = clock().microsecondsSinceEpoch;
    await comms.appendMessage(
      id: 'msg_${stamp}_$_seq',
      conversationId: chatWith,
      requestId: 'req_${stamp}_$_seq',
      ciphertext: Uint8List.fromList(utf8.encode(body)),
      senderAccountId: ownerKind == 'ACCOUNT' ? ownerKey : null,
      senderChildId: ownerKind == 'CHILD' ? ownerKey : null,
      replyTo: replyToId,
      at: clock(),
    );
  }

  @override
  Future<void> markThreadRead(String chatWith) => comms.markThreadRead(
        conversationId: chatWith,
        readerKey: ownerKey,
        readerKind: ownerKind,
        at: clock(),
      );

  @override
  Future<void> pinMessage(String chatWith, String messageId) =>
      comms.pinMessage(
        id: messageId,
        actorKey: ownerKey,
        actorKind: ownerKind,
        at: clock(),
      );

  @override
  Future<void> unpinMessage(String chatWith, String messageId) =>
      comms.unpinMessage(messageId);

  @override
  Future<void> editMessage(
    String chatWith,
    String messageId,
    String newBody,
  ) =>
      comms.editMessage(
        id: messageId,
        actorKey: ownerKey,
        ciphertext: Uint8List.fromList(utf8.encode(newBody.trim())),
        at: clock(),
      );

  @override
  Future<void> deleteMessage(String chatWith, String messageId) =>
      comms.tombstoneMessage(messageId, at: clock());

  @override
  Future<void> setMuted(String chatWith, Duration? preset) => prefs.muteChat(
        conversationId: chatWith,
        ownerKey: ownerKey,
        ownerKind: ownerKind,
        preset: preset,
        at: clock(),
      );

  @override
  Future<void> unmute(String chatWith) => prefs.unmuteChat(
        conversationId: chatWith,
        ownerKey: ownerKey,
        ownerKind: ownerKind,
        at: clock(),
      );

  @override
  Future<void> setArchived(String chatWith, bool archived) =>
      prefs.setArchived(
        conversationId: chatWith,
        ownerKey: ownerKey,
        ownerKind: ownerKind,
        archived: archived,
        at: clock(),
      );

  @override
  Future<void> setPinned(String chatWith, bool pinned) async {
    final conv = await comms.conversationById(chatWith);
    final effective = chatStaysPinned(
      isFamily: conv?.kind == ConvKind.family,
      pinned: pinned,
    );
    await prefs.setPinned(
      conversationId: chatWith,
      ownerKey: ownerKey,
      ownerKind: ownerKind,
      pinned: effective,
      at: clock(),
    );
  }

  @override
  Future<void> setLook(
    String chatWith, {
    required String wallpaper,
    required String bubbleTheme,
  }) =>
      prefs.setLook(
        conversationId: chatWith,
        ownerKey: ownerKey,
        ownerKind: ownerKind,
        wallpaper: wallpaper,
        bubbleTheme: bubbleTheme,
        at: clock(),
      );

  @override
  Future<void> setLocked(String chatWith, bool locked) {
    // S-COM-009 is registered but has no column in contract v5, and the schema
    // is frozen. The guarantee that matters — a lock never hides a child's
    // thread from a parent — is enforced by [parentSeesThread] regardless.
    throw UnsupportedError('قفل المحادثة (S-COM-009) غير مخزّن بعد');
  }

  static String _emoji(Conversation c) => switch (c.kind) {
        ConvKind.family => '👨‍👩‍👧‍👦',
        ConvKind.direct => '💬',
        ConvKind.subgroup => '👥',
      };
}
