import 'dart:convert';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n02_day/child_chats_repository.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';
import 'package:family_os/features/n02_day/conversations_list_repository.dart';

/// Provenance for OD-09 / LDR-B3 local family-chat (device-local only).
const String kFamilyChatLocalProvenance = 'LOCAL_FAMILY_THREAD';
const String kFamilyChatRealLocalMessagesProvenance = 'REAL_LOCAL_MESSAGES';

/// Shared Local KV store for FAT-021/022 + CHD-007/008 (VX-B6 / OD-09).
final class FamilyChatLocalStore {
  FamilyChatLocalStore(
    this._db, {
    this.namespace = kvNamespace,
    IdentityRuntime Function()? runtime,
    DateTime Function()? clock,
  })  : _runtime = runtime ?? (() => stage1IdentityRuntime),
        _clock = clock ?? DateTime.now;

  static const kvNamespace = 'family_chat';
  static const _table = 'kv_store';
  static const familyChatWith = 'family';

  final FamilyLocalDatabase _db;
  final String namespace;
  final IdentityRuntime Function() _runtime;
  final DateTime Function() _clock;

  static String _threadsKey(FamilyId familyId) =>
      'threads:${familyId.value}';
  static String _messagesKey(FamilyId familyId, String chatWith) =>
      'messages:${familyId.value}:$chatWith';

  FamilyId get _familyId => _runtime().activeFamilyId;

  /// Idempotent: ensures one pinned family thread exists (zero messages).
  Future<void> ensureFamilyThreadSeeded({FamilyId? familyId}) async {
    final fid = familyId ?? _familyId;
    final existing = await _readThreads(fid);
    final hasFamily = existing.any((t) => t.chatWith == familyChatWith);
    if (hasFamily) return;
    final seed = ConversationThread(
      id: 't_family_${fid.value}',
      chatWith: familyChatWith,
      // Localized at UI via [conversationsListFamilyThreadTitle].
      title: familyChatWith,
      preview: '',
      timeLabel: '',
      emoji: '👨‍👩‍👧‍👦',
      swatch: ConversationSwatch.family,
      pinned: true,
    );
    await _writeThreads(fid, [...existing, seed]);
  }

  /// LDR-B3 — 2–3 device-local sample messages when thread has none.
  /// Honesty: saved on this device only; never claims multi-device delivery.
  Future<void> ensureRealLocalSampleMessages({FamilyId? familyId}) async {
    final fid = familyId ?? _familyId;
    await ensureFamilyThreadSeeded(familyId: fid);
    final existing = await _readMessages(fid, familyChatWith);
    if (existing.isNotEmpty) return;
    final messages = [
      ConversationMessage(
        id: 'seed_in_1',
        body: 'السلام عليكم — رسالة محفوظة على هذا الجهاز',
        timeLabel: '9:00',
        isMine: false,
        status: ConversationDeliveryStatus.sent,
      ),
      ConversationMessage(
        id: 'seed_out_1',
        body: 'وعليكم السلام',
        timeLabel: '9:01',
        isMine: true,
        status: ConversationDeliveryStatus.sent,
      ),
      ConversationMessage(
        id: 'seed_out_2',
        body: 'كيف الحال؟',
        timeLabel: '9:02',
        isMine: true,
        status: ConversationDeliveryStatus.sent,
      ),
    ];
    await _writeMessages(fid, familyChatWith, messages);
    final threads = await _readThreads(fid);
    final next = [
      for (final t in threads)
        if (t.chatWith == familyChatWith)
          ConversationThread(
            id: t.id,
            chatWith: t.chatWith,
            title: t.title,
            preview: messages.last.body,
            timeLabel: messages.last.timeLabel,
            emoji: t.emoji,
            swatch: t.swatch,
            pinned: t.pinned,
            unreadCount: t.unreadCount,
          )
        else
          t,
    ];
    await _writeThreads(fid, next);
    await _writeProvenanceMarker(fid);
  }

  Future<void> _writeProvenanceMarker(FamilyId familyId) async {
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': 'provenance:${familyId.value}',
        'value': jsonEncode({
          'provenance': kFamilyChatRealLocalMessagesProvenance,
        }),
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  Future<ConversationsListSnapshot> loadThreads({FamilyId? familyId}) async {
    final fid = familyId ?? _familyId;
    await ensureFamilyThreadSeeded(familyId: fid);
    final threads = await _readThreads(fid);
    return ConversationsListSnapshot(threads: threads);
  }

  Future<ConversationDetail?> loadDetail(
    String chatWith, {
    FamilyId? familyId,
  }) async {
    final fid = familyId ?? _familyId;
    final key = chatWith.trim();
    if (key.isEmpty) return null;
    await ensureFamilyThreadSeeded(familyId: fid);
    final threads = await _readThreads(fid);
    ConversationThread? meta;
    for (final t in threads) {
      if (t.chatWith == key) {
        meta = t;
        break;
      }
    }
    if (meta == null) return null;
    final messages = await _readMessages(fid, key);
    return ConversationDetail(
      chatWith: key,
      title: meta.title,
      subtitle: '',
      emoji: meta.emoji,
      messages: messages,
      familyPinnedNote: meta.pinned,
    );
  }

  Future<ConversationMessage> send(
    String chatWith,
    String text, {
    required String timeLabel,
    FamilyId? familyId,
  }) async {
    final fid = familyId ?? _familyId;
    final key = chatWith.trim();
    final body = text.trim();
    if (key.isEmpty || body.isEmpty) {
      throw StateError('chatWith and text required');
    }
    await ensureFamilyThreadSeeded(familyId: fid);
    final detail = await loadDetail(key, familyId: fid);
    if (detail == null) {
      throw StateError('conversation not found: $key');
    }
    final msg = ConversationMessage(
      id: 'out_${_clock().toUtc().millisecondsSinceEpoch}',
      body: body,
      timeLabel: timeLabel,
      isMine: true,
      status: ConversationDeliveryStatus.sent,
    );
    final nextMessages = [...detail.messages, msg];
    await _writeMessages(fid, key, nextMessages);
    // Refresh thread preview from last message (title stays stable key).
    final threads = await _readThreads(fid);
    final nextThreads = [
      for (final t in threads)
        if (t.chatWith == key)
          t.copyWith(preview: body, timeLabel: timeLabel, unreadCount: 0)
        else
          t,
    ];
    await _writeThreads(fid, nextThreads);
    return msg;
  }

  Future<String?> loadProvenance({FamilyId? familyId}) async {
    final fid = familyId ?? _familyId;
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, _threadsKey(fid)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return decoded['provenance'] as String?;
  }

  Future<List<ConversationThread>> _readThreads(FamilyId familyId) async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, _threadsKey(familyId)],
      limit: 1,
    );
    if (rows.isEmpty) return const [];
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];
    final list = decoded['threads'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map)
          _threadFromJson(item.map((k, v) => MapEntry(k.toString(), v))),
    ];
  }

  Future<void> _writeThreads(
    FamilyId familyId,
    List<ConversationThread> threads,
  ) async {
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': _threadsKey(familyId),
        'value': jsonEncode({
          'provenance': kFamilyChatLocalProvenance,
          'threads': [for (final t in threads) _threadToJson(t)],
        }),
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  Future<List<ConversationMessage>> _readMessages(
    FamilyId familyId,
    String chatWith,
  ) async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, _messagesKey(familyId, chatWith)],
      limit: 1,
    );
    if (rows.isEmpty) return const [];
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];
    final list = decoded['messages'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map)
          _messageFromJson(item.map((k, v) => MapEntry(k.toString(), v))),
    ];
  }

  Future<void> _writeMessages(
    FamilyId familyId,
    String chatWith,
    List<ConversationMessage> messages,
  ) async {
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': _messagesKey(familyId, chatWith),
        'value': jsonEncode({
          'messages': [for (final m in messages) _messageToJson(m)],
        }),
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  static Map<String, Object?> _threadToJson(ConversationThread t) => {
        'id': t.id,
        'chatWith': t.chatWith,
        'title': t.title,
        'preview': t.preview,
        'timeLabel': t.timeLabel,
        'emoji': t.emoji,
        'swatch': t.swatch.name,
        'pinned': t.pinned,
        'unreadCount': t.unreadCount,
      };

  static ConversationThread _threadFromJson(Map<String, Object?> json) {
    final swatchName =
        json['swatch'] as String? ?? ConversationSwatch.family.name;
    return ConversationThread(
      id: json['id'] as String? ?? '',
      chatWith: json['chatWith'] as String? ?? '',
      title: json['title'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '👨‍👩‍👧‍👦',
      swatch: ConversationSwatch.values.firstWhere(
        (s) => s.name == swatchName,
        orElse: () => ConversationSwatch.family,
      ),
      pinned: json['pinned'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  static Map<String, Object?> _messageToJson(ConversationMessage m) => {
        'id': m.id,
        'body': m.body,
        'timeLabel': m.timeLabel,
        'isMine': m.isMine,
        'senderLabel': m.senderLabel,
        'status': m.status.name,
      };

  static ConversationMessage _messageFromJson(Map<String, Object?> json) {
    final statusName =
        json['status'] as String? ?? ConversationDeliveryStatus.sent.name;
    return ConversationMessage(
      id: json['id'] as String? ?? '',
      body: json['body'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      isMine: json['isMine'] as bool? ?? false,
      senderLabel: json['senderLabel'] as String?,
      status: ConversationDeliveryStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => ConversationDeliveryStatus.sent,
      ),
    );
  }
}

/// Local [ConversationsListRepository] over [FamilyChatLocalStore].
final class LocalConversationsListRepository
    implements ConversationsListRepository {
  LocalConversationsListRepository(this._store);

  final FamilyChatLocalStore _store;

  @override
  Future<ConversationsListSnapshot> load() => _store.loadThreads();
}

/// Local [ConversationRepository] over [FamilyChatLocalStore].
final class LocalConversationRepository implements ConversationRepository {
  LocalConversationRepository(this._store);

  final FamilyChatLocalStore _store;

  @override
  Future<ConversationDetail?> load(String chatWith) =>
      _store.loadDetail(chatWith);

  @override
  Future<ConversationMessage> send(
    String chatWith,
    String text, {
    required String timeLabel,
  }) =>
      _store.send(chatWith, text, timeLabel: timeLabel);
}

/// Local [ChildChatsRepository] — same family thread as parent list.
final class LocalChildChatsRepository implements ChildChatsRepository {
  LocalChildChatsRepository(this._store);

  final FamilyChatLocalStore _store;

  @override
  Future<ConversationsListSnapshot> load() => _store.loadThreads();
}
