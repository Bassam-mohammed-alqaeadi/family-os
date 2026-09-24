import 'package:flutter/foundation.dart';

enum OuterCircleMemberKind { relative, friend, pendingFriend }

@immutable
final class OuterCircleMember {
  const OuterCircleMember({
    required this.id,
    required this.kind,
    required this.nameKey,
    required this.metaKey,
    this.statusKey = 'approved',
  });

  final String id;
  final OuterCircleMemberKind kind;

  /// ARB discriminator — never planted person names in widgets.
  final String nameKey;
  final String metaKey;
  final String statusKey;
}

@immutable
final class OuterCircleSnapshot {
  const OuterCircleSnapshot({
    this.relatives = const [],
    this.friends = const [],
    this.pending = const [],
    this.scheduleNoteKey = 'friendsEvening',
  });

  final List<OuterCircleMember> relatives;
  final List<OuterCircleMember> friends;
  final List<OuterCircleMember> pending;
  final String scheduleNoteKey;

  bool get isEmpty => relatives.isEmpty && friends.isEmpty && pending.isEmpty;
}
