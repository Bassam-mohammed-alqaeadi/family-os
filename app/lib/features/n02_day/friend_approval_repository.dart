import 'package:family_os/features/n02_day/friend_approval_models.dart';
import 'package:family_os/features/n02_day/outer_circle_models.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';

abstract class FriendApprovalRepository {
  Future<FriendApprovalSnapshot> load();
  Future<FriendApprovalSnapshot> setAllowText(bool value);
  Future<FriendApprovalSnapshot> setAllowCalls(bool value);
  Future<void> approve();
  Future<void> declineGently();
}

/// FAT-071 — projects / mutates [OuterCircleRepository] pending (one authority).
final class OuterCircleBoundFriendApprovalRepository
    implements FriendApprovalRepository {
  OuterCircleBoundFriendApprovalRepository({
    OuterCircleRepository? circle,
    this.pendingMemberId,
    this.childNameKey = 'childOne',
    this.schoolKey = 'classmateSchool',
  }) : _circleOverride = circle;

  final OuterCircleRepository? _circleOverride;

  /// Resolve at call time so Local OuterCircle rebind is visible (CE-G019).
  OuterCircleRepository get _circle =>
      _circleOverride ?? stage1OuterCircleRepository;

  /// When null, uses first pending member from the circle.
  final String? pendingMemberId;
  final String childNameKey;
  final String schoolKey;

  FriendApprovalSnapshot _draft = const FriendApprovalSnapshot();
  Future<void> Function()? loadGate;
  Object? loadError;
  String? lastDecision;

  @override
  Future<FriendApprovalSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final err = loadError;
    if (err != null) {
      loadError = null;
      throw err;
    }
    final snap = await _circle.load();
    final pending = _resolvePending(snap);
    if (pending == null) {
      _draft = const FriendApprovalSnapshot();
      return _draft;
    }
    _draft = FriendApprovalSnapshot(
      requestId: pending.id,
      nameKey: pending.nameKey,
      schoolKey: schoolKey,
      childNameKey: childNameKey,
      allowText: _draft.requestId == pending.id ? _draft.allowText : true,
      allowCalls: _draft.requestId == pending.id ? _draft.allowCalls : true,
    );
    return _draft.copyWith();
  }

  @override
  Future<FriendApprovalSnapshot> setAllowText(bool value) async {
    _draft = _draft.copyWith(allowText: value);
    return _draft.copyWith();
  }

  @override
  Future<FriendApprovalSnapshot> setAllowCalls(bool value) async {
    _draft = _draft.copyWith(allowCalls: value);
    return _draft.copyWith();
  }

  @override
  Future<void> approve() async {
    final id = _draft.requestId;
    if (id == null) return;
    await _circle.approvePending(
      id,
      allowText: _draft.allowText,
      allowCalls: _draft.allowCalls,
    );
    lastDecision = 'approved';
    _draft = const FriendApprovalSnapshot();
  }

  @override
  Future<void> declineGently() async {
    final id = _draft.requestId;
    if (id == null) return;
    await _circle.declinePending(id);
    lastDecision = 'declined';
    _draft = const FriendApprovalSnapshot();
  }

  OuterCircleMember? _resolvePending(OuterCircleSnapshot snap) {
    if (pendingMemberId != null) {
      for (final m in snap.pending) {
        if (m.id == pendingMemberId) return m;
      }
      return null;
    }
    if (snap.pending.isEmpty) return null;
    return snap.pending.first;
  }
}

/// Isolated in-memory seam for widget tests that do not need FAT-070 loop.
final class InMemoryFriendApprovalRepository
    implements FriendApprovalRepository {
  InMemoryFriendApprovalRepository({FriendApprovalSnapshot? seed})
    : _snap = seed ?? friendApprovalEmptyFixture();

  FriendApprovalSnapshot _snap;
  Future<void> Function()? loadGate;
  Object? loadError;
  String? lastDecision;

  @override
  Future<FriendApprovalSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final err = loadError;
    if (err != null) {
      loadError = null;
      throw err;
    }
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

/// Production Stage-1 — bound to [stage1OuterCircleRepository].
final FriendApprovalRepository stage1FriendApprovalRepository =
    OuterCircleBoundFriendApprovalRepository();

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
