import 'dart:typed_data';

import 'package:family_os/features/n02_day/child_chats_repository.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';
import 'package:family_os/features/n02_day/conversations_list_repository.dart';
import 'package:family_os/features/n02_day/live_conversation_repository.dart';
import 'package:family_os/features/n02_day/family_chat_server_authority.dart';
import 'package:family_os/foundation_gate/family_chat_api_client.dart';
import 'package:family_os/foundation_gate/family_chat_media_client.dart';
import 'package:family_os/foundation_gate/family_chat_realtime_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// A surface may speak as the signed-in guardian or the paired device's child.
enum FamilyChatSurface { guardian, child }

final class FamilyChatRepositoryFailure implements Exception {
  const FamilyChatRepositoryFailure({
    required this.status,
    this.serverCode,
    this.statusCode,
    this.details,
  });

  final FamilyChatAuthorityStatus status;
  final String? serverCode;
  final int? statusCode;
  final Map<String, Object?>? details;
}

/// The thread-list adapter shared by the family and child's already-registered screens.
final class FamilyChatThreadListRepository
    implements ConversationsListRepository, ChildChatsRepository {
  FamilyChatThreadListRepository({
    required this.authority,
    required this.surface,
  });

  final FamilyChatServerAuthority authority;
  final FamilyChatSurface surface;
  final Map<String, String> _pendingCreateKeys = <String, String>{};

  @override
  Future<ConversationsListSnapshot> load() async {
    final answer = switch (surface) {
      FamilyChatSurface.guardian => await authority.listGuardianThreads(),
      FamilyChatSurface.child => await authority.listChildThreads(),
    };
    final threads = _requireReady(answer);
    return ConversationsListSnapshot(
      threads: threads.threads
          .map(FamilyChatServerConversationRepository._conversationThread)
          .toList(growable: false),
    );
  }

  Future<List<FamilyChatParticipant>> loadParticipants() async {
    final answer = switch (surface) {
      FamilyChatSurface.guardian => await authority.listGuardianParticipants(),
      FamilyChatSurface.child => await authority.listChildParticipants(),
    };
    return _requireReady(answer).participants;
  }

  Future<List<FamilyChatChildOption>> loadChildOptions() async {
    if (surface != FamilyChatSurface.guardian) {
      throw const FamilyChatRepositoryFailure(
        status: FamilyChatAuthorityStatus.accessDenied,
      );
    }
    return _requireReady(await authority.loadChildOptions());
  }

  Future<ConversationThread> createThread({
    required FamilyChatThreadKind kind,
    required String title,
    required List<FamilyChatParticipantReference> participants,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedParticipants = List<FamilyChatParticipantReference>.of(participants)
      ..sort((left, right) {
        final leftKey = '${left.kind.wireValue}:${left.id}';
        final rightKey = '${right.kind.wireValue}:${right.id}';
        return leftKey.compareTo(rightKey);
      });
    final participantKey = normalizedParticipants
        .map((entry) => '${entry.kind.wireValue}:${entry.id}')
        .join(',');
    final requestKey = '${kind.wireValue}\\n$normalizedTitle\\n$participantKey';
    final idempotencyKey = _pendingCreateKeys.putIfAbsent(
      requestKey,
      newFoundationGateIdempotencyKey,
    );
    final answer = switch (surface) {
      FamilyChatSurface.guardian => await authority.createGuardianThread(
        kind: kind,
        title: normalizedTitle,
        participants: normalizedParticipants,
        idempotencyKey: () => idempotencyKey,
      ),
      FamilyChatSurface.child => await authority.createChildThread(
        kind: kind,
        title: normalizedTitle,
        participants: normalizedParticipants,
        idempotencyKey: () => idempotencyKey,
      ),
    };
    final thread = _requireReady(answer);
    _pendingCreateKeys.remove(requestKey);
    return FamilyChatServerConversationRepository._conversationThread(thread);
  }
}

/// Thread data adapter used by both guardian and child conversation screens.
///
/// All content in this object was returned by the chat API. It keeps a bounded page cursor,
/// supports incremental recovery/polling, and retains one idempotency pair across retries of a
/// message that received no answer. It never paints an optimistic message as server truth.
final class FamilyChatServerConversationRepository
    implements LiveConversationRepository, LiveHintConversationRepository {
  FamilyChatServerConversationRepository({
    required this.authority,
    required this.surface,
    this.pageSize = 50,
    FamilyChatRealtimeClient? realtime,
    FamilyChatMediaClient? media,
  }) : _realtime = realtime,
       _media = media {
    if (pageSize < 1 || pageSize > 200) {
      throw ArgumentError.value(pageSize, 'pageSize', 'must be between 1 and 200');
    }
  }

  final FamilyChatServerAuthority authority;
  final FamilyChatSurface surface;
  final int pageSize;
  final Map<String, _ThreadCache> _cache = <String, _ThreadCache>{};
  final Map<String, _PendingChatSend> _pendingSends = <String, _PendingChatSend>{};
  FamilyChatMediaClient? _media;
  FamilyChatRealtimeClient? _realtime;

  FamilyChatMediaClient get _mediaClient =>
      _media ??= FamilyChatMediaClient(configuration: authority.api.configuration);

  FamilyChatRealtimeClient get _realtimeClient => _realtime ??= FamilyChatRealtimeClient(
    configuration: authority.api.configuration,
    bearer: authority.idToken,
  );

  @override
  Stream<FamilyChatRealtimeHint> get hints => _realtimeClient.hints;

  @override
  Stream<FamilyChatRealtimeState> get realtimeStates => _realtimeClient.states;

  @override
  FamilyChatRealtimeState get realtimeState => _realtime?.state ?? FamilyChatRealtimeState.stopped;

  @override
  Future<void> watchRealtime(String chatWith) async {
    // The child handset's credential lives in native storage and cannot open this socket, so the
    // child surface stays on polling and says so.
    if (surface != FamilyChatSurface.guardian || !isFoundationGateUuid(chatWith)) return;
    final family = authority.familyId()?.trim();
    if (family == null || !isFoundationGateUuid(family)) return;
    await _realtimeClient.watch(familyId: family, threadId: chatWith);
  }

  @override
  Future<void> stopRealtime() async {
    await _realtime?.stop();
  }

  @override
  bool hasMore(String chatWith) => _cache[chatWith]?.hasMore ?? false;

  @override
  Future<ConversationDetail?> load(String chatWith) async {
    if (!isFoundationGateUuid(chatWith)) {
      throw const FamilyChatRepositoryFailure(
        status: FamilyChatAuthorityStatus.refused,
      );
    }
    final existing = _cache[chatWith];
    if (existing != null) return refresh(chatWith);

    final threadList = await _listThreads();
    FamilyChatThread? thread;
    for (final candidate in threadList.threads) {
      if (candidate.id == chatWith) {
        thread = candidate;
        break;
      }
    }
    if (thread == null) return null;

    final lastKnownSequence = thread.lastMessage?.seq ?? 0;
    final afterSeq = lastKnownSequence > pageSize
        ? lastKnownSequence - pageSize
        : 0;
    final page = await _listMessages(
      thread.id,
      afterSeq: afterSeq,
      limit: pageSize,
    );
    final newestListedSequence = thread.lastMessage?.seq ?? 0;
    final newestFetchedSequence =
        page.messages.isEmpty ? 0 : page.messages.last.seq;
    final cache = _ThreadCache(thread: thread, readState: page.readState)
      ..hasMore =
          page.hasMore && newestFetchedSequence < newestListedSequence
      ..messages.addAll(page.messages);
    _cache[thread.id] = cache;
    await _markDeliveredThrough(cache, _lastSeq(cache));
    await _markReadThrough(cache, _lastSeq(cache));
    return _detail(cache);
  }

  @override
  Future<ConversationDetail?> refresh(String chatWith) async {
    final cache = _cache[chatWith];
    if (cache == null) return load(chatWith);

    // Re-read the most recent page as well as the next page. This notices an edit/deletion to
    // recent bubbles without a push transport; responses merge by server id and sequence.
    final cursor =
        (_lastSeq(cache) - pageSize).clamp(0, 0x7fffffffffffffff).toInt();
    final page = await _listMessages(
      chatWith,
      afterSeq: cursor,
      limit: (pageSize * 2).clamp(1, 200).toInt(),
    );
    cache
      ..readState = page.readState
      ..hasMore = page.hasMore;
    _mergeMessages(cache, page.messages);
    await _markDeliveredThrough(cache, _lastSeq(cache));
    await _markReadThrough(cache, _lastSeq(cache));
    return _detail(cache);
  }

  @override
  Future<ConversationDetail?> loadNextPage(String chatWith) async {
    final cache = _cache[chatWith];
    if (cache == null) return load(chatWith);
    if (!cache.hasMore) return _detail(cache);
    final page = await _listMessages(
      chatWith,
      afterSeq: _lastSeq(cache),
      limit: pageSize,
    );
    cache
      ..readState = page.readState
      ..hasMore = page.hasMore;
    _mergeMessages(cache, page.messages);
    await _markDeliveredThrough(cache, _lastSeq(cache));
    await _markReadThrough(cache, _lastSeq(cache));
    return _detail(cache);
  }

  @override
  Future<ConversationMessage> send(
    String chatWith,
    String text, {
    required String timeLabel,
  }) async {
    final body = text.trim();
    if (!isFoundationGateUuid(chatWith) || body.isEmpty || body.length > 2000) {
      throw const FamilyChatRepositoryFailure(
        status: FamilyChatAuthorityStatus.refused,
      );
    }
    final cache = _cache[chatWith];
    if (cache == null) {
      throw const FamilyChatRepositoryFailure(
        status: FamilyChatAuthorityStatus.refused,
      );
    }
    final pendingKey = '$chatWith\n$body';
    final pending = _pendingSends.putIfAbsent(
      pendingKey,
      () => _PendingChatSend(
        body: body,
        clientMessageId: newFoundationGateIdempotencyKey(),
        idempotencyKey: newFoundationGateIdempotencyKey(),
      ),
    );
    final answer = switch (surface) {
      FamilyChatSurface.guardian => await authority.sendGuardianMessage(
        threadId: chatWith,
        body: pending.body,
        clientMessageId: pending.clientMessageId,
        idempotencyKey: pending.idempotencyKey,
      ),
      FamilyChatSurface.child => await authority.sendChildMessage(
        threadId: chatWith,
        body: pending.body,
        clientMessageId: pending.clientMessageId,
        idempotencyKey: pending.idempotencyKey,
      ),
    };
    final receipt = _requireReady(answer);
    _pendingSends.remove(pendingKey);

    // Catch up page-by-page if a long thread had unread history. This preserves sequence
    // continuity instead of inserting a new message above rows the client never fetched.
    while (_lastSeq(cache) < receipt.message.seq - 1 && cache.hasMore) {
      final before = _lastSeq(cache);
      await loadNextPage(chatWith);
      if (_lastSeq(cache) == before) break;
    }
    _upsert(cache, receipt.message);
    await _markDeliveredThrough(cache, _lastSeq(cache));
    await _markReadThrough(cache, receipt.message.seq);
    return _conversationMessage(
      receipt.message,
      cache.readState,
      cache.thread.participants,
      threadId: cache.thread.id,
    ).copyWith(timeLabel: timeLabel);
  }

  @override
  Future<ConversationMessage> editMessage(
    String chatWith,
    ConversationMessage message,
    String body,
  ) async {
    final revision = message.revision;
    if (revision == null || !message.isMine || message.deleted) {
      throw const FamilyChatRepositoryFailure(
        status: FamilyChatAuthorityStatus.accessDenied,
      );
    }
    final answer = switch (surface) {
      FamilyChatSurface.guardian => await authority.editGuardianMessage(
        threadId: chatWith,
        messageId: message.id,
        body: body,
        revision: revision,
      ),
      FamilyChatSurface.child => await authority.editChildMessage(
        threadId: chatWith,
        messageId: message.id,
        body: body,
        revision: revision,
      ),
    };
    final updated = _requireReady(answer);
    final cache = _cache[chatWith];
    if (cache == null) {
      throw const FamilyChatRepositoryFailure(
        status: FamilyChatAuthorityStatus.refused,
      );
    }
    _upsert(cache, updated);
    return _conversationMessage(
      updated,
      cache.readState,
      cache.thread.participants,
      threadId: cache.thread.id,
    );
  }

  @override
  Future<ConversationMessage> deleteMessage(
    String chatWith,
    ConversationMessage message,
  ) async {
    if (!message.isMine || message.deleted) {
      throw const FamilyChatRepositoryFailure(
        status: FamilyChatAuthorityStatus.accessDenied,
      );
    }
    final key = 'chat-delete-${message.id}';
    final answer = switch (surface) {
      FamilyChatSurface.guardian => await authority.deleteGuardianMessage(
        threadId: chatWith,
        messageId: message.id,
        idempotencyKey: key,
      ),
      FamilyChatSurface.child => await authority.deleteChildMessage(
        threadId: chatWith,
        messageId: message.id,
        idempotencyKey: key,
      ),
    };
    final deleted = _requireReady(answer);
    final cache = _cache[chatWith];
    if (cache == null) {
      throw const FamilyChatRepositoryFailure(
        status: FamilyChatAuthorityStatus.refused,
      );
    }
    _upsert(cache, deleted);
    return _conversationMessage(
      deleted,
      cache.readState,
      cache.thread.participants,
      threadId: cache.thread.id,
    );
  }

  Future<FamilyChatThreadList> _listThreads() async {
    return switch (surface) {
      FamilyChatSurface.guardian => _requireReady(
        await authority.listGuardianThreads(),
      ),
      FamilyChatSurface.child => _requireReady(
        await authority.listChildThreads(),
      ),
    };
  }

  Future<FamilyChatMessagePage> _listMessages(
    String threadId, {
    required int afterSeq,
    required int limit,
  }) async {
    return switch (surface) {
      FamilyChatSurface.guardian => _requireReady(
        await authority.listGuardianMessages(
          threadId: threadId,
          afterSeq: afterSeq,
          limit: limit,
        ),
      ),
      FamilyChatSurface.child => _requireReady(
        await authority.listChildMessages(
          threadId: threadId,
          afterSeq: afterSeq,
          limit: limit,
        ),
      ),
    };
  }

  Future<void> _markReadThrough(_ThreadCache cache, int sequence) async {
    if (sequence <= cache.readState.lastReadSeq) return;
    final key = 'chat-read-${cache.thread.id}-$sequence';
    final answer = switch (surface) {
      FamilyChatSurface.guardian => await authority.markGuardianThreadRead(
        threadId: cache.thread.id,
        readSeq: sequence,
        idempotencyKey: key,
      ),
      FamilyChatSurface.child => await authority.markChildThreadRead(
        threadId: cache.thread.id,
        readSeq: sequence,
        idempotencyKey: key,
      ),
    };
    if (answer.isReady) cache.readState = answer.value!;
    // Reading the body remains available if its independent receipt write is refused/offline.
  }

  /// Tells the server what this client has received. It is sent after a fetch, never ahead of
  /// what was fetched, and only moves forward. A refused or offline acknowledgement is not shown
  /// as an error: nothing above the old mark was acknowledged, so the next fetch sends it again.
  Future<void> _markDeliveredThrough(_ThreadCache cache, int sequence) async {
    if (sequence <= cache.deliveredSent) return;
    final key = 'chat-delivered-${cache.thread.id}-$sequence';
    final answer = switch (surface) {
      FamilyChatSurface.guardian => await authority.markGuardianThreadDelivered(
        threadId: cache.thread.id,
        deliveredSeq: sequence,
        idempotencyKey: key,
      ),
      FamilyChatSurface.child => await authority.markChildThreadDelivered(
        threadId: cache.thread.id,
        deliveredSeq: sequence,
        idempotencyKey: key,
      ),
    };
    if (answer.isReady) cache.deliveredSent = sequence;
  }

  void _mergeMessages(_ThreadCache cache, List<FamilyChatMessage> incoming) {
    for (final message in incoming) {
      _upsert(cache, message);
    }
  }

  void _upsert(_ThreadCache cache, FamilyChatMessage message) {
    final index = cache.messages.indexWhere((item) => item.id == message.id);
    if (index < 0) {
      cache.messages.add(message);
    } else {
      cache.messages[index] = message;
    }
    cache.messages.sort((left, right) => left.seq.compareTo(right.seq));
  }

  int _lastSeq(_ThreadCache cache) =>
      cache.messages.isEmpty ? 0 : cache.messages.last.seq;

  ConversationDetail _detail(_ThreadCache cache) => ConversationDetail(
    chatWith: cache.thread.id,
    title: _threadTitle(cache.thread),
    subtitle: '',
    emoji: cache.thread.kind == FamilyChatThreadKind.family ? '👨‍👩‍👧‍👦' : '👥',
    threadKind: cache.thread.kind.wireValue,
    messages: List<ConversationMessage>.unmodifiable(
      cache.messages.map(
        (message) => _conversationMessage(
          message,
          cache.readState,
          cache.thread.participants,
          threadId: cache.thread.id,
        ),
      ),
    ),
    familyPinnedNote: cache.thread.kind == FamilyChatThreadKind.family,
    serverAuthoritative: true,
    hasMoreMessages: cache.hasMore,
    lastReadSeq: cache.readState.lastReadSeq,
  );

  static String _threadTitle(FamilyChatThread thread) {
    final title = thread.title.trim();
    if (title.isNotEmpty) return thread.title;
    if (thread.kind == FamilyChatThreadKind.direct) {
      for (final participant in thread.participants) {
        if (!participant.isSelf) {
          final peerName = participant.displayName?.trim();
          if (peerName != null && peerName.isNotEmpty) return peerName;
        }
      }
    }
    if (thread.kind == FamilyChatThreadKind.child) {
      for (final participant in thread.participants) {
        if (participant.kind == FamilyChatParticipantKind.child) {
          final childName = participant.displayName?.trim();
          if (childName != null && childName.isNotEmpty) return childName;
        }
      }
    }
    return '';
  }

  static ConversationThread _conversationThread(FamilyChatThread thread) {
    final last = thread.lastMessage;
    return ConversationThread(
      id: thread.id,
      chatWith: thread.id,
      title: _threadTitle(thread),
      preview: last?.body ?? '',
      timeLabel: '',
      emoji: thread.kind == FamilyChatThreadKind.family ? '👨‍👩‍👧‍👦' : '👥',
      swatch: thread.kind == FamilyChatThreadKind.family
          ? ConversationSwatch.family
          : ConversationSwatch.purple,
      pinned: false,
      unreadCount: thread.unreadCount,
      threadKind: thread.kind.wireValue,
      lastMessageAt: last?.createdAt,
      lastMessageDeleted: last?.deleted ?? false,
    );
  }

  ConversationMessage _conversationMessage(
    FamilyChatMessage message,
    FamilyChatReadState readState,
    List<FamilyChatParticipant> participants, {
    required String threadId,
  }) {
    final isMine = message.authorKind == readState.participantKind &&
        message.authorId == readState.participantId;
    String? senderLabel;
    if (!isMine) {
      for (final participant in participants) {
        if (participant.kind == message.authorKind &&
            participant.id == message.authorId) {
          senderLabel = participant.displayName ?? participant.role;
          break;
        }
      }
    }
    return ConversationMessage(
      id: message.id,
      body: message.body ?? '',
      timeLabel: '',
      isMine: isMine,
      senderLabel: senderLabel,
      status: ConversationDeliveryStatus.sent,
      createdAt: message.createdAt,
      seq: message.seq,
      revision: message.revision,
      readCount: message.readCount,
      authorKind: message.authorKind.wireValue,
      authorId: message.authorId,
      deleted: message.deleted,
      editedAt: message.editedAt,
      media: _conversationMedia(message, threadId),
      // Receipts are shown only for what this device wrote; they are counts, never names.
      receipt: isMine
          ? ConversationReceipt(
              deliveredCount: message.receipt.deliveredCount,
              readCount: message.receipt.readCount,
              otherParticipantCount: message.receipt.otherParticipantCount,
            )
          : null,
    );
  }

  ConversationMedia? _conversationMedia(FamilyChatMessage message, String threadId) {
    final item = message.media;
    if (item == null || message.deleted) return null;
    final loadable = item.isAvailable && surface == FamilyChatSurface.guardian;
    return ConversationMedia(
      id: item.id,
      kind: item.kind == FamilyChatMessageKind.image
          ? ConversationMediaKind.image
          : ConversationMediaKind.audio,
      mimeType: item.mimeType,
      durationMs: item.durationMs,
      available: item.isAvailable,
      loadBytes: loadable ? () => _loadGuardianMedia(threadId, item) : null,
    );
  }

  /// Null is the honest answer for "cannot show it now": the item was removed, the room no
  /// longer includes the caller, the network failed, or the bytes did not match what was declared.
  Future<Uint8List?> _loadGuardianMedia(String threadId, FamilyChatMedia item) async {
    final family = authority.familyId()?.trim();
    if (family == null || !isFoundationGateUuid(family)) return null;
    try {
      return await _mediaClient.fetchGuardianMedia(
        familyId: family,
        threadId: threadId,
        media: item,
        idToken: await authority.idToken(),
      );
    } on Object {
      return null;
    }
  }
}

final class _ThreadCache {
  _ThreadCache({required this.thread, required this.readState});

  /// The highest sequence this client has already acknowledged as received.
  int deliveredSent = 0;

  final FamilyChatThread thread;
  FamilyChatReadState readState;
  final List<FamilyChatMessage> messages = <FamilyChatMessage>[];
  bool hasMore = false;
}

final class _PendingChatSend {
  const _PendingChatSend({
    required this.body,
    required this.clientMessageId,
    required this.idempotencyKey,
  });

  final String body;
  final String clientMessageId;
  final String idempotencyKey;
}

ConversationsListRepository familyChatGuardianListRepository() {
  final authority = activeFamilyChatServerAuthority;
  if (authority == null) return const _UnconfiguredChatListRepository();
  return FamilyChatThreadListRepository(
    authority: authority,
    surface: FamilyChatSurface.guardian,
  );
}

ChildChatsRepository familyChatChildListRepository() {
  final authority = activeFamilyChatServerAuthority;
  if (authority == null) return const _UnconfiguredChatListRepository();
  return FamilyChatThreadListRepository(
    authority: authority,
    surface: FamilyChatSurface.child,
  );
}

ConversationRepository familyChatGuardianConversationRepository() {
  final authority = activeFamilyChatServerAuthority;
  if (authority == null) return const _UnconfiguredConversationRepository();
  return FamilyChatServerConversationRepository(
    authority: authority,
    surface: FamilyChatSurface.guardian,
  );
}

ConversationRepository familyChatChildConversationRepository() {
  final authority = activeFamilyChatServerAuthority;
  if (authority == null) return const _UnconfiguredConversationRepository();
  return FamilyChatServerConversationRepository(
    authority: authority,
    surface: FamilyChatSurface.child,
  );
}

final class _UnconfiguredChatListRepository
    implements ConversationsListRepository, ChildChatsRepository {
  const _UnconfiguredChatListRepository();

  @override
  Future<ConversationsListSnapshot> load() => Future.error(
    const FamilyChatRepositoryFailure(
      status: FamilyChatAuthorityStatus.notConfigured,
    ),
  );
}

final class _UnconfiguredConversationRepository
    implements LiveConversationRepository {
  const _UnconfiguredConversationRepository();

  FamilyChatRepositoryFailure get _failure => const FamilyChatRepositoryFailure(
    status: FamilyChatAuthorityStatus.notConfigured,
  );

  @override
  bool hasMore(String chatWith) => false;

  @override
  Future<ConversationDetail?> load(String chatWith) => Future.error(_failure);

  @override
  Future<ConversationDetail?> refresh(String chatWith) => Future.error(_failure);

  @override
  Future<ConversationDetail?> loadNextPage(String chatWith) => Future.error(_failure);

  @override
  Future<ConversationMessage> send(
    String chatWith,
    String text, {
    required String timeLabel,
  }) => Future.error(_failure);

  @override
  Future<ConversationMessage> editMessage(
    String chatWith,
    ConversationMessage message,
    String body,
  ) => Future.error(_failure);

  @override
  Future<ConversationMessage> deleteMessage(
    String chatWith,
    ConversationMessage message,
  ) => Future.error(_failure);
}

T _requireReady<T>(FamilyChatAuthorityAnswer<T> answer) {
  final value = answer.value;
  if (!answer.isReady || value == null) throw _failure(answer);
  return value;
}

FamilyChatRepositoryFailure _failure<T>(
  FamilyChatAuthorityAnswer<T> answer,
) => FamilyChatRepositoryFailure(
  status: answer.status,
  serverCode: answer.serverCode,
  statusCode: answer.statusCode,
  details: answer.details,
);
