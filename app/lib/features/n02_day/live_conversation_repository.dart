import 'package:family_os/foundation_gate/family_chat_realtime_client.dart';

import 'conversation_repository.dart';

/// Optional live surface for server conversations. It never queues an unconfirmed message:
/// refresh and retry always ask the server again, with the original idempotency values.
abstract interface class LiveConversationRepository
    implements ConversationRepository {
  bool hasMore(String chatWith);

  Future<ConversationDetail?> refresh(String chatWith);

  Future<ConversationDetail?> loadNextPage(String chatWith);

  Future<ConversationMessage> editMessage(
    String chatWith,
    ConversationMessage message,
    String body,
  );

  Future<ConversationMessage> deleteMessage(
    String chatWith,
    ConversationMessage message,
  );
}

/// The hint channel for a server conversation. Hints say a room changed; the screen answers by
/// asking the REST API again. A repository that cannot open the channel reports `stopped`, and the
/// screen keeps its polling interval, so degradation is explicit rather than silent.
abstract interface class LiveHintConversationRepository
    implements LiveConversationRepository {
  Stream<FamilyChatRealtimeHint> get hints;

  Stream<FamilyChatRealtimeState> get realtimeStates;

  FamilyChatRealtimeState get realtimeState;

  /// Points the channel at the room on screen. Guardian surface only in this build.
  Future<void> watchRealtime(String chatWith);

  Future<void> stopRealtime();
}
