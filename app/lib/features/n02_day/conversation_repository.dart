import 'package:flutter/foundation.dart';

import 'package:family_os/core/data/communication_repository.dart';
import 'package:family_os/core/data/communication_rules.dart';

/// Media carried by a bubble (ADR-053 «وسائط»). Text is the default; a voice
/// note is described in words by the UI, not by the repo.
enum ConversationMediaKind { text, image, video, file, voice }

/// The quoted message shown inside a reply bubble (`message.replyTo`),
/// resolved to a short preview by the repo so a widget never walks the store.
@immutable
final class ConversationReply {
  const ConversationReply({
    required this.id,
    required this.preview,
    required this.fromMe,
  });

  final String id;
  final String preview;
  final bool fromMe;
}

/// One bubble in SCR-FAT-022 / SCR-CHD-008.
@immutable
final class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.body,
    required this.timeLabel,
    required this.isMine,
    this.senderLabel,
    this.tick = MessageTick.sent,
    this.pinned = false,
    this.deleted = false,
    this.edited = false,
    this.sentAt,
    this.replyTo,
    this.kind = ConversationMediaKind.text,
  });

  final String id;
  final String body;
  final String timeLabel;

  /// True → this reader's own bubble.
  final bool isMine;

  /// Group chats show sender above body (generic role label).
  final String? senderLabel;

  /// ✓ while nobody has read it, ✓✓ once a read row exists — never a grey
  /// "delivered" tick we cannot observe ([MessageTick]).
  final MessageTick tick;

  final bool pinned;

  /// "حذف للجميع" — the tombstone stays in place, never a hole.
  final bool deleted;

  final bool edited;

  /// Real instant, so the 15-minute window ([kMessageEditWindow]) can close.
  final DateTime? sentAt;

  final ConversationReply? replyTo;

  final ConversationMediaKind kind;

  bool get visible => messageIsVisible(deleted: deleted);

  bool get isReply => replyTo != null;

  ConversationMessage copyWith({
    String? id,
    String? body,
    String? timeLabel,
    bool? isMine,
    String? senderLabel,
    MessageTick? tick,
    bool? pinned,
    bool? deleted,
    bool? edited,
    DateTime? sentAt,
    ConversationReply? replyTo,
    bool clearReplyTo = false,
    ConversationMediaKind? kind,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      body: body ?? this.body,
      timeLabel: timeLabel ?? this.timeLabel,
      isMine: isMine ?? this.isMine,
      senderLabel: senderLabel ?? this.senderLabel,
      tick: tick ?? this.tick,
      pinned: pinned ?? this.pinned,
      deleted: deleted ?? this.deleted,
      edited: edited ?? this.edited,
      sentAt: sentAt ?? this.sentAt,
      replyTo: clearReplyTo ? null : (replyTo ?? this.replyTo),
      kind: kind ?? this.kind,
    );
  }
}

/// Full thread payload for SCR-FAT-022 / SCR-CHD-008 (`?chatWith=`).
@immutable
final class ConversationDetail {
  const ConversationDetail({
    required this.chatWith,
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.messages = const [],
    this.familyPinnedNote = false,
    this.toneChips = const [],
    this.pinnedMessage,
    this.hasParentMember = true,
    this.locked = false,
    this.muted = false,
    this.mutedUntil,
    this.archived = false,
    this.pinned = false,
    this.wallpaper,
    this.bubbleTheme,
  });

  /// Peer / thread id — same wire values as FAT-021 (`family` / `mother` / `child_*`).
  final String chatWith;

  final String title;
  final String subtitle;
  final String emoji;
  final List<ConversationMessage> messages;

  /// Show pinned-family honesty line (prototype family branch).
  final bool familyPinnedNote;

  /// Optional calm quick-replies (tone bridge) — content from repo.
  final List<String> toneChips;

  /// S-COM-008 — the message pinned at the top of this thread, if any.
  final ConversationMessage? pinnedMessage;

  /// Whether a parent is a member — drives [receiptsMandatory] (ADR-053).
  final bool hasParentMember;

  final bool locked;
  final bool muted;
  final DateTime? mutedUntil;
  final bool archived;

  /// Effective pin in the list (family always pinned).
  final bool pinned;

  /// Per-chat look, reader-owned.
  final String? wallpaper;
  final String? bubbleTheme;

  bool get isEmpty => messages.isEmpty;

  /// Read receipts are mandatory in a thread that contains a parent, and only
  /// then is the toggle not offered ([receiptsToggleOffered]).
  bool get receiptsMandatory =>
      !receiptsToggleOffered(hasParentMember: hasParentMember);

  ConversationDetail copyWith({
    String? chatWith,
    String? title,
    String? subtitle,
    String? emoji,
    List<ConversationMessage>? messages,
    bool? familyPinnedNote,
    List<String>? toneChips,
    ConversationMessage? pinnedMessage,
    bool clearPinnedMessage = false,
    bool? hasParentMember,
    bool? locked,
    bool? muted,
    DateTime? mutedUntil,
    bool clearMutedUntil = false,
    bool? archived,
    bool? pinned,
    String? wallpaper,
    bool clearWallpaper = false,
    String? bubbleTheme,
    bool clearBubbleTheme = false,
  }) {
    return ConversationDetail(
      chatWith: chatWith ?? this.chatWith,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      emoji: emoji ?? this.emoji,
      messages: messages ?? this.messages,
      familyPinnedNote: familyPinnedNote ?? this.familyPinnedNote,
      toneChips: toneChips ?? this.toneChips,
      pinnedMessage:
          clearPinnedMessage ? null : (pinnedMessage ?? this.pinnedMessage),
      hasParentMember: hasParentMember ?? this.hasParentMember,
      locked: locked ?? this.locked,
      muted: muted ?? this.muted,
      mutedUntil: clearMutedUntil ? null : (mutedUntil ?? this.mutedUntil),
      archived: archived ?? this.archived,
      pinned: pinned ?? this.pinned,
      wallpaper: clearWallpaper ? null : (wallpaper ?? this.wallpaper),
      bubbleTheme: clearBubbleTheme ? null : (bubbleTheme ?? this.bubbleTheme),
    );
  }
}

/// Rule 25 seam — conversation thread (SCR-FAT-022 / SCR-CHD-008).
///
/// Every write that could be refused is refused by the pure rules in
/// `communication_rules.dart`, never by an ad-hoc widget check.
abstract class ConversationRepository {
  /// Resolve thread by peer id. Null → not found.
  Future<ConversationDetail?> load(String chatWith);

  /// Append an outbound message (UI-007 send seam).
  ///
  /// [timeLabel] must be ARB-sourced (Rule 12) — never plant locale in repo.
  Future<void> send(
    String chatWith,
    String text, {
    required String timeLabel,
    String? replyToId,
  });

  /// Opens a thread: read rows for the other side's messages.
  Future<void> markThreadRead(String chatWith);

  /// S-COM-008 — pin a message at the top of the thread.
  Future<void> pinMessage(String chatWith, String messageId);

  Future<void> unpinMessage(String chatWith, String messageId);

  /// S-COM-006 — replace the body within 15 minutes, by the author alone.
  Future<void> editMessage(String chatWith, String messageId, String newBody);

  /// S-COM-007 — tombstone in place.
  Future<void> deleteMessage(String chatWith, String messageId);

  Future<void> setMuted(String chatWith, Duration? preset);

  Future<void> unmute(String chatWith);

  Future<void> setArchived(String chatWith, bool archived);

  /// Ignored for the family thread — a fixed pin, not a toggle.
  Future<void> setPinned(String chatWith, bool pinned);

  Future<void> setLook(
    String chatWith, {
    required String wallpaper,
    required String bubbleTheme,
  });

  /// S-COM-009 — never hides a child's thread from the parent.
  Future<void> setLocked(String chatWith, bool locked);
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
///
/// Every refusal below comes from `communication_rules.dart`, so the mock and
/// the real adapter answer the same way to the same attempt.
final class InMemoryConversationRepository implements ConversationRepository {
  InMemoryConversationRepository({
    List<ConversationDetail>? initial,
    this.failLoad = false,
    DateTime Function()? clock,
  })  : _threads = {
          for (final t in initial ?? const <ConversationDetail>[]) t.chatWith: t,
        },
        _clock = clock ?? DateTime.now;

  final Map<String, ConversationDetail> _threads;
  final DateTime Function() _clock;
  var _sendSeq = 0;

  /// Test seam — next [load] throws.
  bool failLoad;

  void seed(List<ConversationDetail> threads) {
    _threads
      ..clear()
      ..addEntries(threads.map((t) => MapEntry(t.chatWith, t)));
  }

  ConversationDetail? _raw(String chatWith) => _threads[chatWith.trim()];

  ConversationDetail _require(String chatWith) {
    final t = _raw(chatWith);
    if (t == null) {
      throw StateError('conversation not found: $chatWith');
    }
    return t;
  }

  bool _isFamily(ConversationDetail t) => t.chatWith == 'family';

  void _put(ConversationDetail detail) => _threads[detail.chatWith] = detail;

  ConversationDetail _project(ConversationDetail t) {
    final now = _clock();
    ConversationMessage? pinned;
    for (final m in t.messages) {
      if (m.pinned && !m.deleted) pinned = m;
    }
    return t.copyWith(
      messages: List.unmodifiable(t.messages),
      toneChips: List.unmodifiable(t.toneChips),
      pinnedMessage: pinned,
      clearPinnedMessage: pinned == null,
      muted: chatIsMuted(mutedUntil: t.mutedUntil, now: now),
      pinned: chatStaysPinned(isFamily: _isFamily(t), pinned: t.pinned),
    );
  }

  @override
  Future<ConversationDetail?> load(String chatWith) async {
    if (failLoad) {
      throw StateError('mock conversation load failure');
    }
    final thread = _raw(chatWith);
    return thread == null ? null : _project(thread);
  }

  @override
  Future<void> send(
    String chatWith,
    String text, {
    required String timeLabel,
    String? replyToId,
  }) async {
    final key = chatWith.trim();
    final body = text.trim();
    if (key.isEmpty || body.isEmpty) {
      throw StateError('chatWith and text required');
    }
    final existing = _require(key);
    _sendSeq += 1;
    ConversationReply? reply;
    if (replyToId != null) {
      final target =
          existing.messages.where((m) => m.id == replyToId).firstOrNull;
      if (target != null) {
        reply = ConversationReply(
          id: target.id,
          preview: target.deleted ? '' : target.body,
          fromMe: target.isMine,
        );
      }
    }
    final msg = ConversationMessage(
      id: 'out_$_sendSeq',
      body: body,
      timeLabel: timeLabel,
      isMine: true,
      tick: MessageTick.sent,
      sentAt: _clock(),
      replyTo: reply,
    );
    _put(existing.copyWith(messages: [...existing.messages, msg]));
  }

  @override
  Future<void> markThreadRead(String chatWith) async {
    // The in-memory seam has no read rows; the Drift adapter is where S-COM-005
    // becomes a row. Reading twice is the same read either way.
    _require(chatWith);
  }

  @override
  Future<void> pinMessage(String chatWith, String messageId) async {
    final thread = _require(chatWith);
    final target = thread.messages.where((m) => m.id == messageId).firstOrNull;
    if (target == null || !mayPin(deleted: target.deleted)) {
      throw const MessagePinRefused('لا تُثبَّت رسالة محذوفة');
    }
    _put(
      thread.copyWith(
        messages: [
          for (final m in thread.messages)
            m.id == messageId
                ? m.copyWith(pinned: true)
                : m.copyWith(pinned: false),
        ],
      ),
    );
  }

  @override
  Future<void> unpinMessage(String chatWith, String messageId) async {
    final thread = _require(chatWith);
    _put(
      thread.copyWith(
        messages: [
          for (final m in thread.messages)
            m.id == messageId ? m.copyWith(pinned: false) : m,
        ],
      ),
    );
  }

  @override
  Future<void> editMessage(
    String chatWith,
    String messageId,
    String newBody,
  ) async {
    final thread = _require(chatWith);
    final now = _clock();
    final target = thread.messages.where((m) => m.id == messageId).firstOrNull;
    if (target == null) {
      throw ArgumentError.value(messageId, 'messageId', 'لا توجد رسالة');
    }
    if (!senderMayEdit(
      senderKey: target.isMine ? 'me' : 'them',
      actorKey: 'me',
      sentAt: target.sentAt ?? now,
      now: now,
      deleted: target.deleted,
    )) {
      throw MessageEditRefused(
        target.isMine
            ? 'مضت نافذة التعديل (S-COM-006) أو أن الرسالة محذوفة' // rule12-allow
            : 'التعديل للكاتب وحده', // rule12-allow
      );
    }
    _put(
      thread.copyWith(
        messages: [
          for (final m in thread.messages)
            m.id == messageId
                ? m.copyWith(body: newBody.trim(), edited: true)
                : m,
        ],
      ),
    );
  }

  @override
  Future<void> deleteMessage(String chatWith, String messageId) async {
    final thread = _require(chatWith);
    final target = thread.messages.where((m) => m.id == messageId).firstOrNull;
    if (target == null) {
      throw ArgumentError.value(messageId, 'messageId', 'لا توجد رسالة');
    }
    if (!target.isMine) {
      throw const MessageEditRefused('الحذف للكاتب وحده');
    }
    // Tombstone: the row stays, the body goes — replies still resolve.
    _put(
      thread.copyWith(
        messages: [
          for (final m in thread.messages)
            m.id == messageId
                ? m.copyWith(body: '', deleted: true, pinned: false)
                : m,
        ],
      ),
    );
  }

  @override
  Future<void> setMuted(String chatWith, Duration? preset) async {
    final thread = _require(chatWith);
    _put(
      thread.copyWith(
        mutedUntil: muteUntilFor(preset: preset, now: _clock()),
      ),
    );
  }

  @override
  Future<void> unmute(String chatWith) async {
    final thread = _require(chatWith);
    _put(thread.copyWith(clearMutedUntil: true));
  }

  @override
  Future<void> setArchived(String chatWith, bool archived) async {
    _put(_require(chatWith).copyWith(archived: archived));
  }

  @override
  Future<void> setPinned(String chatWith, bool pinned) async {
    final thread = _require(chatWith);
    _put(
      thread.copyWith(
        pinned: chatStaysPinned(isFamily: _isFamily(thread), pinned: pinned),
      ),
    );
  }

  @override
  Future<void> setLook(
    String chatWith, {
    required String wallpaper,
    required String bubbleTheme,
  }) async {
    requireWallpaper(wallpaper);
    requireBubbleTheme(bubbleTheme);
    _put(
      _require(chatWith)
          .copyWith(wallpaper: wallpaper, bubbleTheme: bubbleTheme),
    );
  }

  @override
  Future<void> setLocked(String chatWith, bool locked) async {
    // A lock never hides the thread from a parent ([parentSeesThread]).
    _put(_require(chatWith).copyWith(locked: locked));
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1ConversationRepository = InMemoryConversationRepository();
