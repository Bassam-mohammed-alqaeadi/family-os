import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

/// Activation channel (MODE-OD-09).
enum ModeActivationChannel { manual, clock, location, seasonal }

extension ModeActivationChannelWire on ModeActivationChannel {
  String get wireName => name;

  static ModeActivationChannel parse(String raw) {
    final n = raw.trim().toLowerCase();
    return ModeActivationChannel.values.firstWhere(
      (c) => c.name == n,
      orElse: () => ModeActivationChannel.manual,
    );
  }
}

/// Persisted / evaluated Mode activation for one child (multi-mode allowed).
@immutable
final class ModeActivation {
  const ModeActivation({
    required this.id,
    required this.familyId,
    required this.modeId,
    required this.childId,
    required this.channel,
    required this.active,
    required this.startedAt,
    this.endsAt,
  });

  final String id;
  final FamilyId familyId;
  final String modeId;
  final ChildId childId;
  final ModeActivationChannel channel;
  final bool active;
  final DateTime startedAt;
  final DateTime? endsAt;

  Map<String, Object?> toRow() => {
    'id': id,
    'family_id': familyId.value,
    'mode_id': modeId,
    'child_id': childId.value,
    'channel': channel.wireName,
    'active': active ? 1 : 0,
    'started_at': startedAt.toUtc().millisecondsSinceEpoch,
    'ends_at': endsAt?.toUtc().millisecondsSinceEpoch,
  };

  factory ModeActivation.fromRow(Map<String, Object?> row) {
    final ends = (row['ends_at'] as num?)?.toInt();
    return ModeActivation(
      id: row['id'] as String? ?? 'act',
      familyId: FamilyId(row['family_id'] as String? ?? 'fam'),
      modeId: row['mode_id'] as String? ?? '',
      childId: ChildId(row['child_id'] as String? ?? 'child'),
      channel: ModeActivationChannelWire.parse(
        row['channel'] as String? ?? 'manual',
      ),
      active: (row['active'] as num?)?.toInt() != 0,
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['started_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
      endsAt: ends == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(ends, isUtc: true),
    );
  }
}
