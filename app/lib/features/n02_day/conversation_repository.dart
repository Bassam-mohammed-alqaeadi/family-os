import 'package:flutter/foundation.dart';

/// Delivery ticks for outbound bubbles (prototype ✓ / ✓✓).
enum ConversationDeliveryStatus {
  sending,
  sent,
  delivered,
  read,
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
    this.status = ConversationDeliveryStatus.delivered,
  });

  final String id;
  final String body;
  final String timeLabel;

  /// True → right/me bubble (parent outbound).
  final bool isMine;

  /// Group chats show sender above body (generic role label).
  final String? senderLabel;

  final ConversationDeliveryStatus status;

  ConversationMessage copyWith({
    String? id,
    String? body,
    String? timeLabel,
    bool? isMine,
    String? senderLabel,
    ConversationDeliveryStatus? status,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      body: body ?? this.body,
      timeLabel: timeLabel ?? this.timeLabel,
      isMine: isMine ?? this.isMine,
      senderLabel: senderLabel ?? this.senderLabel,
      status: status ?? this.status,
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
    this.messages = const [],
    this.familyPinnedNote = false,
    this.toneChips = const [],
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

  bool get isEmpty => messages.isEmpty;

  ConversationDetail copyWith({
    String? chatWith,
    String? title,
    String? subtitle,
    String? emoji,
    List<ConversationMessage>? messages,
    bool? familyPinnedNote,
    List<String>? toneChips,
  }) {
    return ConversationDetail(
      chatWith: chatWith ?? this.chatWith,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      emoji: emoji ?? this.emoji,
      messages: messages ?? this.messages,
      familyPinnedNote: familyPinnedNote ?? this.familyPinnedNote,
      toneChips: toneChips ?? this.toneChips,
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
    _threads[key] = existing.copyWith(
      messages: [...existing.messages, msg],
    );
    return msg;
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1ConversationRepository = InMemoryConversationRepository();
