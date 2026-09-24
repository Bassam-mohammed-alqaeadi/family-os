import 'package:flutter/foundation.dart';

import 'package:family_os/core/data/communication_rules.dart';

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

/// What kind of thing the one-line preview is. A voice note is described in
/// words ("🎤 رسالة صوتية") — and that label text comes from ARB, never from
/// this repo (Rule 12).
enum ConversationPreviewKind { text, voice }

/// One conversation row in SCR-FAT-021 / SCR-CHD-007.
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
    this.isFamily = false,
    this.muted = false,
    this.mutedUntil,
    this.archived = false,
    this.locked = false,
    this.wallpaper,
    this.bubbleTheme,
    this.previewKind = ConversationPreviewKind.text,
  });

  final String id;

  /// Passed to FAT-022 / CHD-008 as `chatWith` query param.
  final String chatWith;

  final String title;
  final String preview;
  final String timeLabel;
  final String emoji;
  final ConversationSwatch swatch;

  /// Effective pin in the list (family included via [isFamily]).
  final bool pinned;

  final int unreadCount;

  /// The family conversation — pinned always, never a user toggle (ADR-053).
  final bool isFamily;

  /// `chatIsMuted(mutedUntil, now)` computed by the repo at load time.
  final bool muted;

  /// The mute window (null = not muted; far-future = "دائمًا").
  final DateTime? mutedUntil;

  final bool archived;

  /// S-COM-009 lock — never hides a child's thread from the parent.
  final bool locked;

  /// Per-chat look (ADR-053) — null until the reader chooses one.
  final String? wallpaper;
  final String? bubbleTheme;

  final ConversationPreviewKind previewKind;

  bool get hasUnread => unreadCount > 0;

  /// A lock is shown but never hides the row from a parent
  /// ([parentSeesThread]).
  bool get visibleToParent => parentSeesThread(locked: locked);

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
    bool? isFamily,
    bool? muted,
    DateTime? mutedUntil,
    bool clearMutedUntil = false,
    bool? archived,
    bool? locked,
    String? wallpaper,
    bool clearWallpaper = false,
    String? bubbleTheme,
    bool clearBubbleTheme = false,
    ConversationPreviewKind? previewKind,
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
      isFamily: isFamily ?? this.isFamily,
      muted: muted ?? this.muted,
      mutedUntil: clearMutedUntil ? null : (mutedUntil ?? this.mutedUntil),
      archived: archived ?? this.archived,
      locked: locked ?? this.locked,
      wallpaper: clearWallpaper ? null : (wallpaper ?? this.wallpaper),
      bubbleTheme: clearBubbleTheme ? null : (bubbleTheme ?? this.bubbleTheme),
      previewKind: previewKind ?? this.previewKind,
    );
  }
}

/// Conversations list snapshot — pinned (and always the family) first.
@immutable
final class ConversationsListSnapshot {
  const ConversationsListSnapshot({this.threads = const []});

  final List<ConversationThread> threads;

  bool get isEmpty => threads.isEmpty;

  int get count => threads.length;

  /// Pinned first — and the family thread is pinned whether or not anyone
  /// remembered to toggle it ([chatStaysPinned]).
  List<ConversationThread> get ordered {
    bool isPinned(ConversationThread t) =>
        chatStaysPinned(isFamily: t.isFamily, pinned: t.pinned);
    final pinned = threads.where(isPinned).toList();
    final rest = threads.where((t) => !isPinned(t)).toList();
    return [...pinned, ...rest];
  }
}

/// Rule 25 seam — conversations list for SCR-FAT-021 / SCR-CHD-007.
///
/// The list is per reader: mute/archive/pin are the reader's own settings
/// (ADR-053), so the seam takes the thread id and lets the adapter bind the
/// owner from its composition root.
abstract class ConversationsListRepository {
  Future<ConversationsListSnapshot> load();

  /// Mutes for a window. `preset == null` is "دائمًا" ([kMuteForeverUntil]).
  Future<void> setMuted(String threadId, Duration? preset);

  Future<void> unmute(String threadId);

  Future<void> setArchived(String threadId, bool archived);

  /// Ignored for the family thread — a fixed pin, not a toggle.
  Future<void> setPinned(String threadId, bool pinned);

  Future<void> setLook(
    String threadId, {
    required String wallpaper,
    required String bubbleTheme,
  });
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
final class InMemoryConversationsListRepository
    implements ConversationsListRepository {
  InMemoryConversationsListRepository({
    ConversationsListSnapshot? initial,
    this.failLoad = false,
    DateTime Function()? clock,
  })  : _snapshot = initial ?? const ConversationsListSnapshot(),
        _clock = clock ?? DateTime.now;

  ConversationsListSnapshot _snapshot;
  final DateTime Function() _clock;
  final Map<String, _ThreadOverride> _overrides = {};

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
    final now = _clock();
    return ConversationsListSnapshot(
      threads: List.unmodifiable([
        for (final t in _snapshot.threads) _apply(t, now),
      ]),
    );
  }

  ConversationThread _apply(ConversationThread base, DateTime now) {
    final o = _overrides[base.id];
    if (o == null) return base;
    final mutedUntil = o.mutedUntil;
    return base.copyWith(
      pinned: chatStaysPinned(
        isFamily: base.isFamily,
        pinned: o.pinned ?? base.pinned,
      ),
      muted: chatIsMuted(mutedUntil: mutedUntil, now: now),
      mutedUntil: mutedUntil,
      archived: o.archived ?? base.archived,
      locked: o.locked ?? base.locked,
      wallpaper: o.wallpaper ?? base.wallpaper,
      bubbleTheme: o.bubbleTheme ?? base.bubbleTheme,
    );
  }

  _ThreadOverride _overrideFor(String id) =>
      _overrides.putIfAbsent(id, _ThreadOverride.new);

  ConversationThread _require(String threadId) {
    final t = _snapshot.threads.where((t) => t.id == threadId).firstOrNull;
    if (t == null) {
      throw ArgumentError.value(threadId, 'threadId', 'لا محادثة بهذا المعرّف');
    }
    return t;
  }

  @override
  Future<void> setMuted(String threadId, Duration? preset) async {
    _require(threadId);
    _overrideFor(threadId).mutedUntil =
        muteUntilFor(preset: preset, now: _clock());
  }

  @override
  Future<void> unmute(String threadId) async {
    _require(threadId);
    _overrideFor(threadId).mutedUntil = null;
  }

  @override
  Future<void> setArchived(String threadId, bool archived) async {
    _require(threadId);
    _overrideFor(threadId).archived = archived;
  }

  @override
  Future<void> setPinned(String threadId, bool pinned) async {
    final thread = _require(threadId);
    _overrideFor(threadId).pinned = chatStaysPinned(
      isFamily: thread.isFamily,
      pinned: pinned,
    );
  }

  @override
  Future<void> setLook(
    String threadId, {
    required String wallpaper,
    required String bubbleTheme,
  }) async {
    // The value sets are the contract's own, so the refusal is the rule's, not
    // the widget's.
    requireWallpaper(wallpaper);
    requireBubbleTheme(bubbleTheme);
    _require(threadId);
    final o = _overrideFor(threadId);
    o.wallpaper = wallpaper;
    o.bubbleTheme = bubbleTheme;
  }
}

/// Mutable per-reader settings overlay for the in-memory seam.
final class _ThreadOverride {
  DateTime? mutedUntil;
  bool? archived;
  bool? pinned;
  bool? locked;
  String? wallpaper;
  String? bubbleTheme;
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1ConversationsListRepository = InMemoryConversationsListRepository();
