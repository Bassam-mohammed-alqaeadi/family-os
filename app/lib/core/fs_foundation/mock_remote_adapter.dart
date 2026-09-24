import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'local_database.dart';

/// Port for remote/cloud edges — mock-only in this campaign.
///
/// Real behavior stays local; [MockRemoteAdapter] queues payloads and can
/// simulate delivery without claiming live backend success unless explicitly
/// flushed as delivered in tests/fixtures.
abstract class RemoteSyncPort {
  Future<String> enqueue({
    required String channel,
    required Map<String, Object?> payload,
  });

  Future<List<SyncOutboxItem>> pending();

  /// Attempts delivery for pending items. Mock adapter marks delivered locally.
  Future<MockRemoteFlushResult> flush();
}

@immutable
final class SyncOutboxItem {
  const SyncOutboxItem({
    required this.id,
    required this.channel,
    required this.payload,
    required this.createdAt,
    required this.attempts,
    this.lastError,
    this.deliveredAt,
  });

  final String id;
  final String channel;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
  final DateTime? deliveredAt;

  bool get isDelivered => deliveredAt != null;
}

@immutable
final class MockRemoteFlushResult {
  const MockRemoteFlushResult({
    required this.attempted,
    required this.delivered,
    required this.failed,
  });

  final int attempted;
  final int delivered;
  final int failed;
}

/// SQLite / memory-backed mock remote outbox.
final class MockRemoteAdapter implements RemoteSyncPort {
  MockRemoteAdapter(
    this._db, {
    DateTime Function()? clock,
    String Function()? idFactory,
    this.failChannels = const {},
  }) : _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? _defaultId;

  final FamilyLocalDatabase _db;
  final DateTime Function() _clock;
  final String Function() _idFactory;

  /// Channels that should fail on flush (for degraded-path tests).
  final Set<String> failChannels;

  static int _seq = 0;
  static String _defaultId() {
    _seq += 1;
    return 'outbox_${_seq}_${DateTime.now().microsecondsSinceEpoch}';
  }

  static const _table = 'sync_outbox';

  @override
  Future<String> enqueue({
    required String channel,
    required Map<String, Object?> payload,
  }) async {
    final id = _idFactory();
    final now = _clock().toUtc();
    await _db.insert(_table, {
      'id': id,
      'channel': channel,
      'payload': jsonEncode(payload),
      'created_at': now.millisecondsSinceEpoch,
      'attempts': 0,
      'last_error': null,
      'delivered_at': null,
    });
    return id;
  }

  @override
  Future<List<SyncOutboxItem>> pending() async {
    // Filter in Dart so MemoryLocalDatabase (simple = matcher) stays valid.
    final rows = await _db.query(_table, orderBy: 'created_at ASC');
    return rows
        .where((r) => r['delivered_at'] == null)
        .map(_fromRow)
        .toList(growable: false);
  }

  @override
  Future<MockRemoteFlushResult> flush() async {
    final items = await pending();
    var delivered = 0;
    var failed = 0;
    final now = _clock().toUtc();
    for (final item in items) {
      final attempts = item.attempts + 1;
      if (failChannels.contains(item.channel)) {
        failed++;
        await _db.update(
          _table,
          {
            'attempts': attempts,
            'last_error': 'MOCK_REMOTE_FAIL:${item.channel}',
          },
          where: 'id = ?',
          whereArgs: [item.id],
        );
        continue;
      }
      delivered++;
      await _db.update(
        _table,
        {
          'attempts': attempts,
          'last_error': null,
          'delivered_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [item.id],
      );
    }
    return MockRemoteFlushResult(
      attempted: items.length,
      delivered: delivered,
      failed: failed,
    );
  }

  static SyncOutboxItem _fromRow(Map<String, Object?> row) {
    final rawPayload = row['payload']! as String;
    final decoded = jsonDecode(rawPayload);
    final map = decoded is Map
        ? decoded.map((k, v) => MapEntry(k.toString(), v as Object?))
        : <String, Object?>{};
    final deliveredMs = row['delivered_at'] as int?;
    return SyncOutboxItem(
      id: row['id']! as String,
      channel: row['channel']! as String,
      payload: map,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
        isUtc: true,
      ),
      attempts: row['attempts']! as int,
      lastError: row['last_error'] as String?,
      deliveredAt: deliveredMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deliveredMs, isUtc: true),
    );
  }
}
