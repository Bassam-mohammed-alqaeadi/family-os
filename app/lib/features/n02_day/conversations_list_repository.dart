import 'package:flutter/foundation.dart';

/// Avatar swatch for conversation rows (token-resolved in UI).
enum ConversationSwatch {
  /// Family group gradient anchor (p500).
  family,

  /// Co-parent / mother pink-coral.
  mother,

  /// Child purple.
  purple,

  /// Child sky.
  sky,

  /// Child amber.
  amber,
}

/// One conversation row in SCR-FAT-021.
@immutable
final class ConversationThread {
  const ConversationThread({
    required this.id,
    required this.chatWith,
    required this.title,
    required this.preview,
    required this.timeLabel,
    required this.emoji,
    required this.swatch,
    this.pinned = false,
    this.unreadCount = 0,
  });

  final String id;

  /// Passed to FAT-022 as `chatWith` query param.
  final String chatWith;

  final String title;
  final String preview;
  final String timeLabel;
  final String emoji;
  final ConversationSwatch swatch;

  /// Family group is always pinned first (prototype FAT-021).
  final bool pinned;

  final int unreadCount;

  bool get hasUnread => unreadCount > 0;

  ConversationThread copyWith({
    String? id,
    String? chatWith,
    String? title,
    String? preview,
    String? timeLabel,
    String? emoji,
    ConversationSwatch? swatch,
    bool? pinned,
    int? unreadCount,
  }) {
    return ConversationThread(
      id: id ?? this.id,
      chatWith: chatWith ?? this.chatWith,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      timeLabel: timeLabel ?? this.timeLabel,
      emoji: emoji ?? this.emoji,
      swatch: swatch ?? this.swatch,
      pinned: pinned ?? this.pinned,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Conversations list snapshot — pinned family first, then others.
@immutable
final class ConversationsListSnapshot {
  const ConversationsListSnapshot({this.threads = const []});

  final List<ConversationThread> threads;

  bool get isEmpty => threads.isEmpty;

  int get count => threads.length;

  /// Pinned first, then remaining in list order.
  List<ConversationThread> get ordered {
    final pinned = threads.where((t) => t.pinned).toList();
    final rest = threads.where((t) => !t.pinned).toList();
    return [...pinned, ...rest];
  }
}

/// Rule 25 seam — conversations list for SCR-FAT-021 (no Firebase; Drift later).
abstract class ConversationsListRepository {
  Future<ConversationsListSnapshot> load();
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
final class InMemoryConversationsListRepository
    implements ConversationsListRepository {
  InMemoryConversationsListRepository({
    ConversationsListSnapshot? initial,
    this.failLoad = false,
  }) : _snapshot = initial ?? const ConversationsListSnapshot();

  ConversationsListSnapshot _snapshot;

  /// Test seam — next [load] throws.
  bool failLoad;

  void seed(ConversationsListSnapshot snapshot) {
    _snapshot = snapshot;
  }

  @override
  Future<ConversationsListSnapshot> load() async {
    if (failLoad) {
      throw StateError('mock conversations list load failure');
    }
    return ConversationsListSnapshot(
      threads: List.unmodifiable(_snapshot.threads),
    );
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1ConversationsListRepository = InMemoryConversationsListRepository();
