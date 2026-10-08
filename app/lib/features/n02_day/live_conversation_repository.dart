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
