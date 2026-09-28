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

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'nameKey': nameKey,
        'metaKey': metaKey,
        'statusKey': statusKey,
      };

  static OuterCircleMember fromJson(Map<String, Object?> json) {
    final kindRaw = json['kind']?.toString() ?? 'friend';
    final kind = OuterCircleMemberKind.values.firstWhere(
      (k) => k.name == kindRaw,
      orElse: () => OuterCircleMemberKind.friend,
    );
    return OuterCircleMember(
      id: json['id']?.toString() ?? '',
      kind: kind,
      nameKey: json['nameKey']?.toString() ?? '',
      metaKey: json['metaKey']?.toString() ?? '',
      statusKey: json['statusKey']?.toString() ?? 'approved',
    );
  }
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

  Map<String, Object?> toJson() => {
        'relatives': relatives.map((e) => e.toJson()).toList(),
        'friends': friends.map((e) => e.toJson()).toList(),
        'pending': pending.map((e) => e.toJson()).toList(),
        'scheduleNoteKey': scheduleNoteKey,
      };

  static OuterCircleSnapshot fromJson(Map<String, Object?> json) {
    List<OuterCircleMember> parseList(Object? raw) {
      final out = <OuterCircleMember>[];
      if (raw is! List) return out;
      for (final e in raw) {
        if (e is Map) {
          out.add(
            OuterCircleMember.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
      return out;
    }

    return OuterCircleSnapshot(
      relatives: parseList(json['relatives']),
      friends: parseList(json['friends']),
      pending: parseList(json['pending']),
      scheduleNoteKey:
          json['scheduleNoteKey']?.toString() ?? 'friendsEvening',
    );
  }
}
