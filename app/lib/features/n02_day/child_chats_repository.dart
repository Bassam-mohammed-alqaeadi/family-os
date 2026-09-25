import 'package:family_os/features/n02_day/conversations_list_repository.dart';

/// Rule 25 seam — child chats list for SCR-CHD-007.
///
/// Closed circle only (family · father · mother). Reuses [ConversationThread] /
/// [ConversationsListSnapshot] and the same per-chat settings seam so rows open
/// CHD-008 with the same `chatWith` values (`family` / `father` / `mother`).
abstract class ChildChatsRepository implements ConversationsListRepository {
  @override
  Future<ConversationsListSnapshot> load();
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
///
/// Delegates to the same in-memory list seam so the per-chat settings behave
/// identically for the child's list.
final class InMemoryChildChatsRepository implements ChildChatsRepository {
  InMemoryChildChatsRepository({
    ConversationsListSnapshot? initial,
    bool failLoad = false,
    DateTime Function()? clock,
  }) : _inner = InMemoryConversationsListRepository(
          initial: initial,
          clock: clock,
        ) {
    _inner.failLoad = failLoad;
  }

  final InMemoryConversationsListRepository _inner;

  /// Test seam — next [load] throws.
  bool get failLoad => _inner.failLoad;
  set failLoad(bool value) => _inner.failLoad = value;

  void seed(ConversationsListSnapshot snapshot) => _inner.seed(snapshot);

  @override
  Future<ConversationsListSnapshot> load() => _inner.load();

  @override
  Future<void> setMuted(String threadId, Duration? preset) =>
      _inner.setMuted(threadId, preset);

  @override
  Future<void> unmute(String threadId) => _inner.unmute(threadId);

  @override
  Future<void> setArchived(String threadId, bool archived) =>
      _inner.setArchived(threadId, archived);

  @override
  Future<void> setPinned(String threadId, bool pinned) =>
      _inner.setPinned(threadId, pinned);

  @override
  Future<void> setLook(
    String threadId, {
    required String wallpaper,
    required String bubbleTheme,
  }) =>
      _inner.setLook(threadId, wallpaper: wallpaper, bubbleTheme: bubbleTheme);
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1ChildChatsRepository = InMemoryChildChatsRepository();
