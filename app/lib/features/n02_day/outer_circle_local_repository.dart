import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/prefs_misc/kv_snapshot_store.dart';
import 'package:family_os/features/n02_day/outer_circle_models.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';

/// Durable Outer Circle via kv_store (CE-B1 / CE-G018–020).
final class LocalOuterCircleRepository implements OuterCircleRepository {
  LocalOuterCircleRepository(FamilyLocalDatabase db)
    : _store = KvSnapshotStore(db, namespace: kvNamespace);

  static const kvNamespace = 'outer_circle';

  final KvSnapshotStore _store;
  var _nextPendingSeq = 100;

  Future<OuterCircleSnapshot> _read() async {
    final map = await _store.readMap();
    if (map == null) return outerCircleEmptyFixture();
    return OuterCircleSnapshot.fromJson(map);
  }

  Future<void> _write(OuterCircleSnapshot snap) =>
      _store.writeMap(snap.toJson());

  @override
  Future<OuterCircleSnapshot> load() => _read();

  @override
  Future<OuterCircleSnapshot> approvePending(
    String memberId, {
    bool allowText = true,
    bool allowCalls = true,
  }) async {
    final snap = await _read();
    final pending = List<OuterCircleMember>.from(snap.pending);
    final idx = pending.indexWhere((m) => m.id == memberId);
    if (idx == -1) return snap;
    final member = pending.removeAt(idx);
    final meta = [if (allowText) 'text', if (allowCalls) 'calls'].join('+');
    final friends = List<OuterCircleMember>.from(snap.friends)
      ..add(
        OuterCircleMember(
          id: member.id,
          kind: OuterCircleMemberKind.friend,
          nameKey: member.nameKey,
          metaKey: meta.isEmpty ? 'approved' : meta,
          statusKey: 'approved',
        ),
      );
    final next = OuterCircleSnapshot(
      relatives: List<OuterCircleMember>.from(snap.relatives),
      friends: friends,
      pending: pending,
      scheduleNoteKey: snap.scheduleNoteKey,
    );
    await _write(next);
    return next;
  }

  @override
  Future<OuterCircleSnapshot> declinePending(String memberId) async {
    final snap = await _read();
    final pending = List<OuterCircleMember>.from(snap.pending)
      ..removeWhere((m) => m.id == memberId);
    final next = OuterCircleSnapshot(
      relatives: List<OuterCircleMember>.from(snap.relatives),
      friends: List<OuterCircleMember>.from(snap.friends),
      pending: pending,
      scheduleNoteKey: snap.scheduleNoteKey,
    );
    await _write(next);
    return next;
  }

  @override
  Future<OuterCircleSnapshot> requestFriend({
    required String nameKey,
    required String metaKey,
  }) async {
    final snap = await _read();
    _nextPendingSeq++;
    final pending = List<OuterCircleMember>.from(snap.pending)
      ..add(
        OuterCircleMember(
          id: 'p$_nextPendingSeq',
          kind: OuterCircleMemberKind.pendingFriend,
          nameKey: nameKey,
          metaKey: metaKey,
          statusKey: 'pending',
        ),
      );
    final next = OuterCircleSnapshot(
      relatives: List<OuterCircleMember>.from(snap.relatives),
      friends: List<OuterCircleMember>.from(snap.friends),
      pending: pending,
      scheduleNoteKey: snap.scheduleNoteKey,
    );
    await _write(next);
    return next;
  }

  /// LDR-B3 — one relative + one friend + one pending when empty.
  Future<void> ensureRealLocalSeeded() async {
    final snap = await _read();
    if (!snap.isEmpty) return;
    await _write(
      const OuterCircleSnapshot(
        relatives: [
          OuterCircleMember(
            id: 'r_grandpa_real_local',
            kind: OuterCircleMemberKind.relative,
            nameKey: 'grandpa',
            metaKey: 'callsAnytime',
          ),
        ],
        friends: [
          OuterCircleMember(
            id: 'f_friend_real_local',
            kind: OuterCircleMemberKind.friend,
            nameKey: 'friendOne',
            metaKey: 'classmateSlot',
          ),
        ],
        pending: [
          OuterCircleMember(
            id: 'p_pending_real_local',
            kind: OuterCircleMemberKind.pendingFriend,
            nameKey: 'pendingFriend',
            metaKey: 'classmatePending',
            statusKey: 'pending',
          ),
        ],
      ),
    );
  }
}
