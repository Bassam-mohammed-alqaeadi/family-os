import 'package:flutter/foundation.dart';

/// Display status for chat bubbles: how far THIS device's own send has got.
///
/// [sent] means the family server accepted the message. Whether others received or read it is
/// shown separately, as aggregate counts in [ConversationReceipt], and only for messages this
/// device wrote. [delivered] and [read] are legacy aliases and are never drawn as ticks.
enum ConversationDeliveryStatus {
  sending,
  sent,

  /// Legacy alias — UI shows local-sent only until chat relay is authorized.
  delivered,

  /// Legacy alias — UI shows local-sent only until chat relay is authorized.
  read,
}

/// What a photo or voice note is. Text messages have no media.
enum ConversationMediaKind { image, audio }

/// A photo or voice note attached to a message. The bytes are not held here: [loadBytes] fetches
/// them from the server for the room the caller is in, and returns null when the item is removed
/// or no longer reachable. A screen must treat null as "unavailable", never as an empty file.
@immutable
final class ConversationMedia {
  const ConversationMedia({
    required this.id,
    required this.kind,
    required this.mimeType,
    required this.available,
    this.durationMs,
    this.loadBytes,
  });

  final String id;
  final ConversationMediaKind kind;
  final String mimeType;

  /// The uploader's declared length for a voice note. Not measured by the server.
  final int? durationMs;
  final bool available;
  final Future<Uint8List?> Function()? loadBytes;
}

/// Aggregate receipts for one of MY messages: "N of M", never who. Counts only.
@immutable
final class ConversationReceipt {
  const ConversationReceipt({
    required this.deliveredCount,
    required this.readCount,
    required this.otherParticipantCount,
  });

  final int deliveredCount;
  final int readCount;
  final int otherParticipantCount;
}

/// One bubble in SCR-FAT-022.
@immutable
final class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.body,
    required this.timeLabel,
    required this.isMine,
    this.senderLabel,
    this.status = ConversationDeliveryStatus.sent,
    this.createdAt,
    this.seq,
    this.revision,
    this.readCount = 0,
    this.authorKind,
    this.authorId,
    this.deleted = false,
    this.editedAt,
    this.media,
    this.receipt,
  });

  final String id;
  final String body;
  final String timeLabel;

  /// True → right/me bubble (parent outbound).
  final bool isMine;

  /// Group chats show sender above body (generic role label).
  final String? senderLabel;

  final ConversationDeliveryStatus status;

  /// Present only for a server-authoritative message; local preview messages have no sequence.
  final DateTime? createdAt;
  final int? seq;
  final int? revision;
  final int readCount;
  final String? authorKind;
  final String? authorId;
  final bool deleted;
  final DateTime? editedAt;

  /// Present for a photo or voice note that is still live. A deleted message has none.
  final ConversationMedia? media;

  /// Present only for a message this device wrote, on a server-authoritative thread.
  final ConversationReceipt? receipt;

  ConversationMessage copyWith({
    String? id,
    String? body,
    String? timeLabel,
    bool? isMine,
    String? senderLabel,
    ConversationDeliveryStatus? status,
    DateTime? createdAt,
    int? seq,
    int? revision,
    int? readCount,
    String? authorKind,
    String? authorId,
    bool? deleted,
    DateTime? editedAt,
    ConversationMedia? media,
    ConversationReceipt? receipt,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      body: body ?? this.body,
      timeLabel: timeLabel ?? this.timeLabel,
      isMine: isMine ?? this.isMine,
      senderLabel: senderLabel ?? this.senderLabel,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      seq: seq ?? this.seq,
      revision: revision ?? this.revision,
      readCount: readCount ?? this.readCount,
      authorKind: authorKind ?? this.authorKind,
      authorId: authorId ?? this.authorId,
      deleted: deleted ?? this.deleted,
      editedAt: editedAt ?? this.editedAt,
      media: media ?? this.media,
      receipt: receipt ?? this.receipt,
    );
  }
}

/// Full thread payload for SCR-FAT-022 (`?chatWith=` from FAT-021).
@immutable
final class ConversationDetail {
  const ConversationDetail({
    required this.chatWith,
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.threadKind,
    this.messages = const [],
    this.familyPinnedNote = false,
    this.toneChips = const [],
    this.serverAuthoritative = false,
    this.hasMoreMessages = false,
    this.lastReadSeq = 0,
  });

  /// Peer / thread id — same wire values as FAT-021 (`family` / `mother` / `child_*`).
  final String chatWith;

  final String title;
  final String subtitle;
  final String emoji;
  final String? threadKind;
  final List<ConversationMessage> messages;

  /// Show pinned-family honesty line (prototype family branch).
  final bool familyPinnedNote;

  /// Optional calm quick-replies (tone bridge) — content from repo.
  final List<String> toneChips;

  /// True only when every visible message came from the family chat API.
  final bool serverAuthoritative;
  final bool hasMoreMessages;
  final int lastReadSeq;

  bool get isEmpty => messages.isEmpty;

  ConversationDetail copyWith({
    String? chatWith,
    String? title,
    String? subtitle,
    String? emoji,
    String? threadKind,
    List<ConversationMessage>? messages,
    bool? familyPinnedNote,
    List<String>? toneChips,
    bool? serverAuthoritative,
    bool? hasMoreMessages,
    int? lastReadSeq,
  }) {
    return ConversationDetail(
      chatWith: chatWith ?? this.chatWith,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      emoji: emoji ?? this.emoji,
      threadKind: threadKind ?? this.threadKind,
      messages: messages ?? this.messages,
      familyPinnedNote: familyPinnedNote ?? this.familyPinnedNote,
      toneChips: toneChips ?? this.toneChips,
      serverAuthoritative: serverAuthoritative ?? this.serverAuthoritative,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      lastReadSeq: lastReadSeq ?? this.lastReadSeq,
    );
  }
}

/// Rule 25 seam — conversation thread for SCR-FAT-022 (no Firebase; Drift later).
abstract class ConversationRepository {
  /// Resolve thread by peer id. Null → not found.
  Future<ConversationDetail?> load(String chatWith);

  /// Append outbound mock message (UI-007 send seam).
  ///
  /// [timeLabel] must be ARB-sourced (Rule 12) — never plant locale in repo.
  Future<ConversationMessage> send(
    String chatWith,
    String text, {
    required String timeLabel,
  });
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
final class InMemoryConversationRepository implements ConversationRepository {
  InMemoryConversationRepository({
    List<ConversationDetail>? initial,
    this.failLoad = false,
  }) : _threads = {
         for (final t in initial ?? const <ConversationDetail>[]) t.chatWith: t,
       };

  final Map<String, ConversationDetail> _threads;
  var _sendSeq = 0;

  /// Test seam — next [load] throws.
  bool failLoad;

  void seed(List<ConversationDetail> threads) {
    _threads
      ..clear()
      ..addEntries(threads.map((t) => MapEntry(t.chatWith, t)));
  }

  @override
  Future<ConversationDetail?> load(String chatWith) async {
    if (failLoad) {
      throw StateError('mock conversation load failure');
    }
    final key = chatWith.trim();
    if (key.isEmpty) return null;
    final thread = _threads[key];
    if (thread == null) return null;
    return thread.copyWith(
      messages: List.unmodifiable(thread.messages),
      toneChips: List.unmodifiable(thread.toneChips),
    );
  }

  @override
  Future<ConversationMessage> send(
    String chatWith,
    String text, {
    required String timeLabel,
  }) async {
    final key = chatWith.trim();
    final body = text.trim();
    if (key.isEmpty || body.isEmpty) {
      throw StateError('chatWith and text required');
    }
    final existing = _threads[key];
    if (existing == null) {
      throw StateError('conversation not found: $key');
    }
    _sendSeq += 1;
    final msg = ConversationMessage(
      id: 'out_$_sendSeq',
      body: body,
      timeLabel: timeLabel,
      isMine: true,
      status: ConversationDeliveryStatus.sent,
    );
    _threads[key] = existing.copyWith(messages: [...existing.messages, msg]);
    return msg;
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final InMemoryConversationRepository _stage1ConversationMemory =
    InMemoryConversationRepository();

ConversationRepository? _stage1ConversationBound;

/// Stage-1 conversation — Local when bound, else InMemory.
ConversationRepository get stage1ConversationRepository =>
    _stage1ConversationBound ?? _stage1ConversationMemory;

void rebindStage1ConversationRepository(ConversationRepository repository) {
  _stage1ConversationBound = repository;
}

@visibleForTesting
void resetStage1ConversationRepositoryForTest() {
  _stage1ConversationBound = null;
  _stage1ConversationMemory.seed(const []);
  _stage1ConversationMemory.failLoad = false;
}
