import 'dart:typed_data';

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

/// A photo or voice note the person has composed and not yet sent. The client ids are fixed when
/// the draft is made, so a retry after a lost answer asks the server for the same upload and the
/// same message again, and cannot post a second copy.
final class ConversationMediaDraft {
  ConversationMediaDraft({
    required this.kind,
    required this.bytes,
    required this.mimeType,
    required this.clientMediaId,
    required this.clientMessageId,
    required this.idempotencyKey,
    this.durationMs,
    this.caption = '',
  });

  final ConversationMediaKind kind;
  final Uint8List bytes;
  final String mimeType;
  final int? durationMs;
  final String caption;
  final String clientMediaId;
  final String clientMessageId;
  final String idempotencyKey;

  /// The same draft with a different caption. Every id is kept, so the send stays idempotent.
  ConversationMediaDraft withCaption(String value) => ConversationMediaDraft(
    kind: kind,
    bytes: bytes,
    mimeType: mimeType,
    durationMs: durationMs,
    caption: value,
    clientMediaId: clientMediaId,
    clientMessageId: clientMessageId,
    idempotencyKey: idempotencyKey,
  );
}

/// A live server conversation that can also carry photos and voice notes. Only the guardian
/// surface sends media in this build; a child's handset sends text only.
abstract interface class LiveMediaConversationRepository
    implements LiveConversationRepository {
  bool get canSendMedia;

  /// Uploads the draft's bytes into the room, then posts one message that carries them.
  Future<ConversationMessage> sendMedia(
    String chatWith,
    ConversationMediaDraft draft, {
    required String timeLabel,
  });
}
