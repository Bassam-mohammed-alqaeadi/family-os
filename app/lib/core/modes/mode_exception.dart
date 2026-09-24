import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

/// ModeException — distinct from FS-003 App Access Exception / ST Temporary Grant
/// (MODE-OD-11). Never mutates package/URL/SC permanent policy or minutes.
@immutable
final class ModeException {
  const ModeException({
    required this.id,
    required this.familyId,
    required this.modeId,
    required this.childId,
    required this.note,
    required this.startsAt,
    required this.expiresAt,
    this.active = true,
  });

  final String id;
  final FamilyId familyId;
  final String modeId;
  final ChildId childId;
  final String note;
  final DateTime startsAt;
  final DateTime expiresAt;
  final bool active;

  bool isActiveAt(DateTime utc) {
    if (!active) return false;
    final t = utc.toUtc();
    return !t.isBefore(startsAt.toUtc()) && t.isBefore(expiresAt.toUtc());
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'family_id': familyId.value,
    'mode_id': modeId,
    'child_id': childId.value,
    'note': note,
    'starts_at': startsAt.toUtc().millisecondsSinceEpoch,
    'expires_at': expiresAt.toUtc().millisecondsSinceEpoch,
    'active': active ? 1 : 0,
  };

  factory ModeException.fromRow(Map<String, Object?> row) {
    return ModeException(
      id: row['id'] as String? ?? 'mex',
      familyId: FamilyId(row['family_id'] as String? ?? 'fam'),
      modeId: row['mode_id'] as String? ?? '',
      childId: ChildId(row['child_id'] as String? ?? 'child'),
      note: row['note'] as String? ?? '',
      startsAt: DateTime.fromMillisecondsSinceEpoch(
        (row['starts_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (row['expires_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
      active: (row['active'] as num?)?.toInt() != 0,
    );
  }
}
