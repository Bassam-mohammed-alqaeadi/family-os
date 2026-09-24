import 'package:family_os/features/n02_day/friend_approval_models.dart';

abstract class FriendApprovalRepository {
  Future<FriendApprovalSnapshot> load();
  Future<FriendApprovalSnapshot> setAllowText(bool value);
  Future<FriendApprovalSnapshot> setAllowCalls(bool value);
  Future<void> approve();
  Future<void> declineGently();
}

final class InMemoryFriendApprovalRepository
    implements FriendApprovalRepository {
  InMemoryFriendApprovalRepository({FriendApprovalSnapshot? seed})
    : _snap = seed ?? friendApprovalPrototypeFixture();

  FriendApprovalSnapshot _snap;
  Future<void> Function()? loadGate;
  String? lastDecision;

  @override
  Future<FriendApprovalSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<FriendApprovalSnapshot> setAllowText(bool value) async {
    _snap = _snap.copyWith(allowText: value);
    return _snap.copyWith();
  }

  @override
  Future<FriendApprovalSnapshot> setAllowCalls(bool value) async {
    _snap = _snap.copyWith(allowCalls: value);
    return _snap.copyWith();
  }

  @override
  Future<void> approve() async {
    lastDecision = 'approved';
  }

  @override
  Future<void> declineGently() async {
    lastDecision = 'declined';
  }

  void seed(FriendApprovalSnapshot snap) => _snap = snap;
}

final InMemoryFriendApprovalRepository stage1FriendApprovalRepository =
    InMemoryFriendApprovalRepository();

FriendApprovalSnapshot friendApprovalEmptyFixture() =>
    const FriendApprovalSnapshot();

FriendApprovalSnapshot friendApprovalOneFixture() =>
    friendApprovalPrototypeFixture();

FriendApprovalSnapshot friendApprovalPrototypeFixture() {
  return const FriendApprovalSnapshot(
    requestId: 'req1',
    nameKey: 'pendingFriend',
    schoolKey: 'classmateSchool',
    childNameKey: 'childOne',
  );
}
