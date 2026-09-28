import 'package:family_os/features/n02_day/outer_circle_models.dart';

/// Rule 25 seam — single outer-circle authority (FAT-070 / FAT-071 / CHD-030).
abstract class OuterCircleRepository {
  Future<OuterCircleSnapshot> load();

  /// Father approve pending friend → moves into [friends] (FAT-071).
  Future<OuterCircleSnapshot> approvePending(
    String memberId, {
    bool allowText = true,
    bool allowCalls = true,
  });

  /// Gentle decline — removes pending (FAT-071).
  Future<OuterCircleSnapshot> declinePending(String memberId);

  /// Child add-friend request lands as pending (CHD-030).
  Future<OuterCircleSnapshot> requestFriend({
    required String nameKey,
    required String metaKey,
  });
}

final class InMemoryOuterCircleRepository implements OuterCircleRepository {
  InMemoryOuterCircleRepository({OuterCircleSnapshot? seed})
      : _snap = seed ?? outerCircleEmptyFixture();

  OuterCircleSnapshot _snap;
  Future<void> Function()? loadGate;
  Object? loadError;
  var _nextPendingSeq = 100;

  @override
  Future<OuterCircleSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final err = loadError;
    if (err != null) {
      loadError = null;
      throw err;
    }
    return _copy(_snap);
  }

  @override
  Future<OuterCircleSnapshot> approvePending(
    String memberId, {
    bool allowText = true,
    bool allowCalls = true,
  }) async {
    final pending = List<OuterCircleMember>.from(_snap.pending);
    final idx = pending.indexWhere((m) => m.id == memberId);
    if (idx == -1) return _copy(_snap);
    final member = pending.removeAt(idx);
    final meta = [
      if (allowText) 'text',
      if (allowCalls) 'calls',
    ].join('+');
    final friends = List<OuterCircleMember>.from(_snap.friends)
      ..add(
        OuterCircleMember(
          id: member.id,
          kind: OuterCircleMemberKind.friend,
          nameKey: member.nameKey,
          metaKey: meta.isEmpty ? 'approved' : meta,
          statusKey: 'approved',
        ),
      );
    _snap = OuterCircleSnapshot(
      relatives: List<OuterCircleMember>.from(_snap.relatives),
      friends: friends,
      pending: pending,
      scheduleNoteKey: _snap.scheduleNoteKey,
    );
    return _copy(_snap);
  }

  @override
  Future<OuterCircleSnapshot> declinePending(String memberId) async {
    final pending = List<OuterCircleMember>.from(_snap.pending)
      ..removeWhere((m) => m.id == memberId);
    _snap = OuterCircleSnapshot(
      relatives: List<OuterCircleMember>.from(_snap.relatives),
      friends: List<OuterCircleMember>.from(_snap.friends),
      pending: pending,
      scheduleNoteKey: _snap.scheduleNoteKey,
    );
    return _copy(_snap);
  }

  @override
  Future<OuterCircleSnapshot> requestFriend({
    required String nameKey,
    required String metaKey,
  }) async {
    _nextPendingSeq++;
    final pending = List<OuterCircleMember>.from(_snap.pending)
      ..add(
        OuterCircleMember(
          id: 'p$_nextPendingSeq',
          kind: OuterCircleMemberKind.pendingFriend,
          nameKey: nameKey,
          metaKey: metaKey,
          statusKey: 'pending',
        ),
      );
    _snap = OuterCircleSnapshot(
      relatives: List<OuterCircleMember>.from(_snap.relatives),
      friends: List<OuterCircleMember>.from(_snap.friends),
      pending: pending,
      scheduleNoteKey: _snap.scheduleNoteKey,
    );
    return _copy(_snap);
  }

  void seed(OuterCircleSnapshot snap) => _snap = snap;

  OuterCircleSnapshot _copy(OuterCircleSnapshot s) {
    return OuterCircleSnapshot(
      relatives: List<OuterCircleMember>.from(s.relatives),
      friends: List<OuterCircleMember>.from(s.friends),
      pending: List<OuterCircleMember>.from(s.pending),
      scheduleNoteKey: s.scheduleNoteKey,
    );
  }
}

/// Shared Stage-1 singleton — empty until Local bind / test seed (CE-B1).
OuterCircleRepository stage1OuterCircleRepository =
    InMemoryOuterCircleRepository(seed: outerCircleEmptyFixture());

void rebindStage1OuterCircleRepository(OuterCircleRepository repository) {
  stage1OuterCircleRepository = repository;
}

OuterCircleSnapshot outerCircleEmptyFixture() => const OuterCircleSnapshot();

OuterCircleSnapshot outerCircleOneFixture() {
  return const OuterCircleSnapshot(
    relatives: [
      OuterCircleMember(
        id: 'r1',
        kind: OuterCircleMemberKind.relative,
        nameKey: 'grandpa',
        metaKey: 'callsAnytime',
      ),
    ],
  );
}

/// LOCAL_DEMO / tests only — not production stage1 default.
OuterCircleSnapshot outerCirclePrototypeFixture() {
  return const OuterCircleSnapshot(
    relatives: [
      OuterCircleMember(
        id: 'r1',
        kind: OuterCircleMemberKind.relative,
        nameKey: 'grandpa',
        metaKey: 'callsAnytime',
      ),
      OuterCircleMember(
        id: 'r2',
        kind: OuterCircleMemberKind.relative,
        nameKey: 'aunt',
        metaKey: 'messagesCalls',
      ),
    ],
    friends: [
      OuterCircleMember(
        id: 'f1',
        kind: OuterCircleMemberKind.friend,
        nameKey: 'friendOne',
        metaKey: 'classmateSlot',
      ),
    ],
    pending: [
      OuterCircleMember(
        id: 'p1',
        kind: OuterCircleMemberKind.pendingFriend,
        nameKey: 'pendingFriend',
        metaKey: 'classmatePending',
        statusKey: 'pending',
      ),
    ],
  );
}
