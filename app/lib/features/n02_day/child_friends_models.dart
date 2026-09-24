import 'package:flutter/foundation.dart';

enum ChildFriendStatus { approved, pending }

@immutable
final class ChildFriend {
  const ChildFriend({
    required this.id,
    required this.nameKey,
    required this.status,
    this.metaKey = 'slot47',
  });
  final String id;
  final String nameKey;
  final ChildFriendStatus status;
  final String metaKey;
}

@immutable
final class ChildFriendsSnapshot {
  const ChildFriendsSnapshot({
    this.friends = const [],
    this.pending = const [],
  });

  final List<ChildFriend> friends;
  final List<ChildFriend> pending;

  bool get isEmpty => friends.isEmpty && pending.isEmpty;
}
