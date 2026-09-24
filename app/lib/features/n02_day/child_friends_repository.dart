import 'package:family_os/features/n02_day/child_friends_models.dart';

abstract class ChildFriendsRepository {
  Future<ChildFriendsSnapshot> load();
  Future<void> requestAddFriend({
    required String nameKey,
    required String placeKey,
  });
  Future<void> openChat(String friendId);
  Future<void> callFriend(String friendId);
}

final class InMemoryChildFriendsRepository implements ChildFriendsRepository {
  InMemoryChildFriendsRepository({ChildFriendsSnapshot? seed})
    : _snap = seed ?? childFriendsPrototypeFixture();

  ChildFriendsSnapshot _snap;
  Future<void> Function()? loadGate;
  final List<String> chatOpens = [];
  final List<String> calls = [];
  var addRequestCount = 0;

  @override
  Future<ChildFriendsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
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

final InMemoryChildFriendsRepository stage1ChildFriendsRepository =
    InMemoryChildFriendsRepository();

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
