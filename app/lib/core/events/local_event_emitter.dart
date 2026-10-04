import 'package:flutter/foundation.dart';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/mock_remote_adapter.dart';

import 'local_event_envelope.dart';
import 'local_event_journal.dart';

/// Emits a local journal row and enqueues MOCK-REMOTE outbox (EVT-01-A).
///
/// Never throws to callers for SOS — failures are logged (SOS must not block).
final class LocalEventEmitter {
  LocalEventEmitter({
    required LocalEventJournal journal,
    required RemoteSyncPort outbox,
    DateTime Function()? clock,
    String Function()? idFactory,
  }) : _journal = journal,
       _outbox = outbox,
       _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? _defaultId;

  final LocalEventJournal _journal;
  final RemoteSyncPort _outbox;
  final DateTime Function() _clock;
  final String Function() _idFactory;

  static var _seq = 0;
  static String _defaultId() {
    _seq += 1;
    return 'evt_${_seq}_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Append journal + enqueue. Returns envelope id, or null on soft failure.
  Future<String?> emit({
    required String channel,
    required Map<String, Object?> payload,
  }) async {
    final id = _idFactory();
    final envelope = LocalEventEnvelope(
      id: id,
      channel: channel,
      at: _clock().toUtc(),
      payload: payload,
    );
    try {
      await _journal.append(envelope);
      await _outbox.enqueue(
        channel: channel,
        payload: {'eventId': id, 'deliveryClaim': 'queued_locally', ...payload},
      );
      return id;
    } catch (e, st) {
      debugPrint('EVT-01-A LocalEventEmitter soft-fail: $e\n$st');
      return null;
    }
  }
}

/// Session composition helpers for EVT-01-A.
abstract final class LocalEventPersistence {
  LocalEventPersistence._();

  static LocalEventJournal journal(FamilyLocalDatabase db) =>
      LocalEventJournal(db);

  static RemoteSyncPort outbox(FamilyLocalDatabase db) => MockRemoteAdapter(db);

  static LocalEventEmitter emitter(FamilyLocalDatabase db) =>
      LocalEventEmitter(journal: journal(db), outbox: outbox(db));

  /// Opens session DB; refuses SQLite→Memory fallback for durable journal.
  static Future<LocalEventEmitter> openEmitter() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'EVT-01-A: Local event journal refuses SQLite→Memory '
        'fallback (not restart-safe)',
      );
    }
    return emitter(FsSessionKernel.db);
  }

  static Future<RemoteSyncPort> openOutbox() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'EVT-01-A: Outbox port refuses SQLite→Memory '
        'fallback (not restart-safe)',
      );
    }
    return FsSessionKernel.remoteSyncPort;
  }
}
