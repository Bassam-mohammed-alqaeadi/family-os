import 'package:flutter/foundation.dart';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/features/n02_day/child_chats_repository.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';
import 'package:family_os/features/n02_day/conversations_list_repository.dart';
import 'package:family_os/features/n02_day/family_chat_local_store.dart';

/// VX-B6 / OD-09 — Family chat Local KV bind (FAT-021/022 · CHD-007/008).
abstract final class FamilyChatLocalPersistence {
  FamilyChatLocalPersistence._();

  static Future<FamilyChatLocalStore> openStore() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'VX-B6 FamilyChat: refuses SQLite→Memory fallback (not restart-safe)',
      );
    }
    final store = FamilyChatLocalStore(FsSessionKernel.db);
    await store.ensureFamilyThreadSeeded();
    await store.ensureRealLocalSampleMessages();
    return store;
  }

  /// Soft bind from [main] — rebinds stage1 when SQLite honest.
  static Future<bool> tryBindStage1() async {
    try {
      final store = await openStore();
      rebindStage1ConversationsListRepository(
        LocalConversationsListRepository(store),
      );
      rebindStage1ConversationRepository(LocalConversationRepository(store));
      rebindStage1ChildChatsRepository(LocalChildChatsRepository(store));
      return true;
    } catch (e, st) {
      debugPrint(
        'VX-B6 FamilyChat Local KV bind soft-fail — '
        'InMemory empty retained (not claimed durable): $e\n$st',
      );
      return false;
    }
  }
}
