import 'package:drift/drift.dart';

import 'communication_rules.dart';
import 'family_database.dart';

/// Raised when a message would be from nobody, or from two senders at once — the
/// contract's `one_sender` CHECK, applied on device too.
class MessageSenderException implements Exception {
  const MessageSenderException({
    required this.hasAccount,
    required this.hasChild,
  });

  final bool hasAccount;
  final bool hasChild;

  @override
  String toString() =>
      'message.one_sender violated (account=$hasAccount, child=$hasChild)';
}

/// Raised when an edit is attempted by someone who is not the author, or after
/// the fifteen minutes of S-COM-006.
class MessageEditRefused implements Exception {
  const MessageEditRefused(this.reason);

  final String reason;

  @override
  String toString() => 'message edit refused: $reason';
}

/// Rule 25 seam — conversations, messages and calls as real rows.
///
/// The store never sees a message body: it takes ciphertext bytes and gives them
/// back unchanged. Key management is not this layer's business, and pretending
/// otherwise would be the most dangerous kind of stub.
abstract class CommunicationRepository {
  Future<Conversation> openConversation({
    required String id,
    required String familyId,
    required ConvKind kind,
    required String approvedBy,
    String? title,
    DateTime? at,
  });

  Future<Conversation?> conversationById(String id);

  Future<List<Conversation>> conversationsInFamily(String familyId);

  /// Appends a message. Re-sending with the same [requestId] returns the
  /// **same** message rather than a second one.
  Future<Message> appendMessage({
    required String id,
    required String conversationId,
    required String requestId,
    required Uint8List ciphertext,
    String? senderAccountId,
    String? senderChildId,
    String? replyTo,
    DateTime? at,
  });

  Future<Message?> messageById(String id);

  Future<Message?> messageByRequestId(String requestId);

  /// Oldest-last. Tombstoned rows are included on purpose: a deleted message is
  /// a tombstone the thread still points at, not a gap.
  Future<List<Message>> messagesIn(String conversationId, {int limit = 200});

  /// Replaces the body within S-COM-006's window, by the author only.
  Future<Message> editMessage({
    required String id,
    required String actorKey,
    required Uint8List ciphertext,
    DateTime? at,
  });

  /// "حذف للجميع" — the row survives, the body goes.
  Future<Message> tombstoneMessage(String id, {DateTime? at});

  Future<CallLog> recordCall({
    required String id,
    required String familyId,
    required DateTime startedAt,
    required String kind,
    required String outcome,
    int? durationS,
  });

  Future<List<CallLog>> callsInFamily(String familyId, {int limit = 100});
}

final class DriftCommunicationRepository implements CommunicationRepository {
  DriftCommunicationRepository(this._db);

  final FamilyDatabase _db;

  @override
  Future<Conversation> openConversation({
    required String id,
    required String familyId,
    required ConvKind kind,
    required String approvedBy,
    String? title,
    DateTime? at,
  }) async {
    await _db.into(_db.conversations).insertOnConflictUpdate(
          ConversationsCompanion.insert(
            id: id,
            familyId: familyId,
            kind: kind,
            title: Value(title),
            approvedBy: approvedBy,
            createdAt: Value(at ?? DateTime.now()),
          ),
        );
    return (await conversationById(id))!;
  }

  @override
  Future<Conversation?> conversationById(String id) {
    return (_db.select(_db.conversations)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<List<Conversation>> conversationsInFamily(String familyId) {
    return (_db.select(_db.conversations)
          ..where((t) => t.familyId.equals(familyId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  @override
  Future<Message> appendMessage({
    required String id,
    required String conversationId,
    required String requestId,
    required Uint8List ciphertext,
    String? senderAccountId,
    String? senderChildId,
    String? replyTo,
    DateTime? at,
  }) async {
    // The contract's `one_sender`: exactly one of the two, never both, never
    // neither. Checked before the insert, so a rejected message leaves no row.
    final senders =
        (senderAccountId != null ? 1 : 0) + (senderChildId != null ? 1 : 0);
    if (senders != 1) {
      throw MessageSenderException(
        hasAccount: senderAccountId != null,
        hasChild: senderChildId != null,
      );
    }

    // A re-sent message is the same message, checked before and after the write
    // so a retry never doubles a bubble.
    final existing = await messageByRequestId(requestId);
    if (existing != null) return existing;

    try {
      await _db.into(_db.messages).insert(
            MessagesCompanion.insert(
              id: id,
              conversationId: conversationId,
              senderAccount: Value(senderAccountId),
              senderChild: Value(senderChildId),
              ciphertext: ciphertext,
              replyTo: Value(replyTo),
              sentAt: Value(at ?? DateTime.now()),
              requestId: requestId,
            ),
          );
    } on Exception {
      final raced = await messageByRequestId(requestId);
      if (raced != null) return raced;
      rethrow;
    }

    final stored = await messageById(id);
    if (stored == null) {
      throw StateError('message $id لم تُكتب');
    }
    return stored;
  }

  @override
  Future<Message?> messageById(String id) {
    return (_db.select(_db.messages)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<Message?> messageByRequestId(String requestId) {
    return (_db.select(_db.messages)
          ..where((t) => t.requestId.equals(requestId)))
        .getSingleOrNull();
  }

  @override
  Future<List<Message>> messagesIn(String conversationId, {int limit = 200}) {
    return (_db.select(_db.messages)
          ..where((t) => t.conversationId.equals(conversationId))
          // `id` breaks timestamp ties so the order is total and reproducible.
          ..orderBy([
            (t) => OrderingTerm.desc(t.sentAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .get();
  }

  @override
  Future<Message> editMessage({
    required String id,
    required String actorKey,
    required Uint8List ciphertext,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    final message = await _requireMessage(id);
    final senderKey = message.senderChild ?? message.senderAccount ?? '';

    if (!senderMayEdit(
      senderKey: senderKey,
      actorKey: actorKey,
      sentAt: message.sentAt,
      now: now,
      deleted: message.deletedAt != null,
    )) {
      throw MessageEditRefused(
        senderKey == actorKey
            ? 'مضت نافذة التعديل (S-COM-006) أو أن الرسالة محذوفة'
            : 'التعديل للكاتب وحده',
      );
    }

    await (_db.update(_db.messages)..where((t) => t.id.equals(id))).write(
      MessagesCompanion(ciphertext: Value(ciphertext), editedAt: Value(now)),
    );
    return _requireMessage(id);
  }

  @override
  Future<Message> tombstoneMessage(String id, {DateTime? at}) async {
    await _requireMessage(id);
    await (_db.update(_db.messages)..where((t) => t.id.equals(id))).write(
      MessagesCompanion(
        // The body goes with it. Keeping the ciphertext would make "حذف للجميع"
        // a UI trick: anyone holding the row could still read it. The row itself
        // stays, because replies and thread order point at it.
        ciphertext: Value(Uint8List(0)),
        deletedAt: Value(at ?? DateTime.now()),
      ),
    );
    return _requireMessage(id);
  }

  Future<Message> _requireMessage(String id) async {
    final message = await messageById(id);
    if (message == null) {
      throw ArgumentError.value(id, 'id', 'لا توجد رسالة بهذا المعرّف');
    }
    return message;
  }

  @override
  Future<CallLog> recordCall({
    required String id,
    required String familyId,
    required DateTime startedAt,
    required String kind,
    required String outcome,
    int? durationS,
  }) async {
    // `call_log.kind` and `.outcome` are `text` with a CHECK in the contract, so
    // the store keeps them inside their sets; that CHECK guards the server copy.
    requireCallKind(kind);
    requireCallOutcome(outcome);
    if (durationS != null && durationS < 0) {
      throw ArgumentError.value(durationS, 'durationS', 'لا يكون سالبًا');
    }

    await _db.into(_db.callLogs).insertOnConflictUpdate(
          CallLogsCompanion.insert(
            id: id,
            familyId: familyId,
            startedAt: startedAt,
            durationS: Value(durationS),
            kind: kind,
            outcome: outcome,
          ),
        );

    final stored = await (_db.select(_db.callLogs)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (stored == null) {
      throw StateError('call_log $id لم يُكتب');
    }
    return stored;
  }

  @override
  Future<List<CallLog>> callsInFamily(String familyId, {int limit = 100}) {
    return (_db.select(_db.callLogs)
          ..where((t) => t.familyId.equals(familyId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.startedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .get();
  }
}
