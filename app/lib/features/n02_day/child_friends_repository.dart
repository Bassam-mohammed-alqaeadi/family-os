import 'package:family_os/features/n02_day/child_friends_models.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';

abstract class ChildFriendsRepository {
  Future<ChildFriendsSnapshot> load();
  Future<void> requestAddFriend({
    required String nameKey,
    required String placeKey,
  });
  Future<void> openChat(String friendId);
  Future<void> callFriend(String friendId);
}

/// CHD-030 — projects [OuterCircleRepository] friends/pending (one authority).
final class OuterCircleBoundChildFriendsRepository
    implements ChildFriendsRepository {
  OuterCircleBoundChildFriendsRepository({OuterCircleRepository? circle})
    : _circleOverride = circle;

  final OuterCircleRepository? _circleOverride;

  /// Resolve at call time so Local OuterCircle rebind is visible (CE-G020).
  OuterCircleRepository get _circle =>
      _circleOverride ?? stage1OuterCircleRepository;
  Future<void> Function()? loadGate;
  Object? loadError;
  final List<String> chatOpens = [];
  final List<String> calls = [];
  var addRequestCount = 0;

  @override
  Future<ChildFriendsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final err = loadError;
    if (err != null) {
      loadError = null;
      throw err;
    }
    final snap = await _circle.load();
    return ChildFriendsSnapshot(
      friends: snap.friends
          .map(
            (m) => ChildFriend(
              id: m.id,
              nameKey: m.nameKey,
              status: ChildFriendStatus.approved,
              metaKey: m.metaKey == 'classmateSlot' ? 'slot47' : m.metaKey,
            ),
          )
          .toList(),
      pending: snap.pending
          .map(
            (m) => ChildFriend(
              id: m.id,
              nameKey: m.nameKey,
              status: ChildFriendStatus.pending,
              metaKey: 'awaitingFather',
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> requestAddFriend({
    required String nameKey,
    required String placeKey,
  }) async {
    addRequestCount++;
    await _circle.requestFriend(nameKey: nameKey, metaKey: placeKey);
  }

  @override
  Future<void> openChat(String friendId) async {
    chatOpens.add(friendId);
  }

  @override
  Future<void> callFriend(String friendId) async {
    calls.add(friendId);
  }
}

/// Isolated in-memory seam for widget tests without FAT-070 loop.
final class InMemoryChildFriendsRepository implements ChildFriendsRepository {
  InMemoryChildFriendsRepository({ChildFriendsSnapshot? seed})
    : _snap = seed ?? childFriendsEmptyFixture();

  ChildFriendsSnapshot _snap;
  Future<void> Function()? loadGate;
  Object? loadError;
  final List<String> chatOpens = [];
  final List<String> calls = [];
  var addRequestCount = 0;

  @override
  Future<ChildFriendsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final err = loadError;
    if (err != null) {
      loadError = null;
      throw err;
    }
    return ChildFriendsSnapshot(
      friends: List<ChildFriend>.from(_snap.friends),
      pending: List<ChildFriend>.from(_snap.pending),
    );
  }

  @override
  Future<void> requestAddFriend({
    required String nameKey,
    required String placeKey,
  }) async {
    addRequestCount++;
  }

  @override
  Future<void> openChat(String friendId) async {
    chatOpens.add(friendId);
  }

  @override
  Future<void> callFriend(String friendId) async {
    calls.add(friendId);
  }

  void seed(ChildFriendsSnapshot snap) => _snap = snap;
}

/// Production Stage-1 — bound to [stage1OuterCircleRepository].
final ChildFriendsRepository stage1ChildFriendsRepository =
    OuterCircleBoundChildFriendsRepository();

ChildFriendsSnapshot childFriendsEmptyFixture() => const ChildFriendsSnapshot();

ChildFriendsSnapshot childFriendsOneFixture() {
  return const ChildFriendsSnapshot(
    friends: [
      ChildFriend(
        id: 'f1',
        nameKey: 'friendOne',
        status: ChildFriendStatus.approved,
      ),
    ],
  );
}

ChildFriendsSnapshot childFriendsPrototypeFixture() {
  return const ChildFriendsSnapshot(
    friends: [
      ChildFriend(
        id: 'f1',
        nameKey: 'friendOne',
        status: ChildFriendStatus.approved,
      ),
    ],
    pending: [
      ChildFriend(
        id: 'p1',
        nameKey: 'pendingFriend',
        status: ChildFriendStatus.pending,
        metaKey: 'awaitingFather',
      ),
    ],
  );
}
