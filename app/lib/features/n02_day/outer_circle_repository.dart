import 'package:family_os/features/n02_day/outer_circle_models.dart';

abstract class OuterCircleRepository {
  Future<OuterCircleSnapshot> load();
}

final class InMemoryOuterCircleRepository implements OuterCircleRepository {
  InMemoryOuterCircleRepository({OuterCircleSnapshot? seed})
    : _snap = seed ?? outerCirclePrototypeFixture();

  OuterCircleSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<OuterCircleSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return OuterCircleSnapshot(
      relatives: List<OuterCircleMember>.from(_snap.relatives),
      friends: List<OuterCircleMember>.from(_snap.friends),
      pending: List<OuterCircleMember>.from(_snap.pending),
      scheduleNoteKey: _snap.scheduleNoteKey,
    );
  }

  void seed(OuterCircleSnapshot snap) => _snap = snap;
}

final InMemoryOuterCircleRepository stage1OuterCircleRepository =
    InMemoryOuterCircleRepository();

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
