import 'package:family_os/features/n02_day/conversations_list_repository.dart';

/// Rule 25 seam — child chats list for SCR-CHD-007 (no Firebase; Drift later).
///
/// Reuses [ConversationThread] / [ConversationsListSnapshot] wire shape so
/// rows open CHD-008 with the same `chatWith` values (`family` / `father` /
/// `mother`) — FAT-022 pattern lean when the child thread screen resolves.
abstract class ChildChatsRepository {
  Future<ConversationsListSnapshot> load();
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
final class InMemoryChildChatsRepository implements ChildChatsRepository {
  InMemoryChildChatsRepository({
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
      throw StateError('mock child chats load failure');
    }
    return ConversationsListSnapshot(
      threads: List.unmodifiable(_snapshot.threads),
    );
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1ChildChatsRepository = InMemoryChildChatsRepository();
