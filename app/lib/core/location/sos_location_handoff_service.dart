import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

import 'location_repository.dart';
import 'sos_location_handoff.dart';

/// FS-001 SOS location handoff — attaches Domain facts to incidents.
///
/// Does **not** own SOS lifecycle, ACK/RESOLVE, delivery, or Break-glass.
/// Never blocks SOS when GPS is missing / NOT IMPLEMENTED.
final class SosLocationHandoff {
  SosLocationHandoff(this._db, this._domain, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final LocationDomainRepository _domain;
  final DateTime Function() _clock;

  static const _table = 'loc_sos_evidence';

  /// Attempt acquire + attach. GPS failure → UNAVAILABLE honesty, SOS still OK.
  Future<SosLocationAttachResult> attachForIncident({
    required String incidentId,
    required FamilyId familyId,
    required ChildId childId,
    required DeviceId deviceId,
  }) async {
    SosBreakGlassLocationLaw.assertNotFindMyChild();

    final latest = await _domain.latestFix(familyId, childId);
    final honesty = latest == null
        ? SosLocationHonesty.unavailable
        : SosLocationHonestyWire.fromAcquisition(latest.acquisition);

    SosLocationEvidence? evidence;
    if (latest != null) {
      evidence = SosLocationEvidence(
        incidentId: incidentId,
        familyId: familyId,
        childId: childId,
        deviceId: deviceId,
        honesty: honesty,
        attachedAt: _clock().toUtc(),
        fixId: latest.id,
        latitude: latest.point?.latitude,
        longitude: latest.point?.longitude,
        accuracyMeters: latest.accuracyMeters,
      );
      await _persist(evidence);
    } else {
      evidence = SosLocationEvidence(
        incidentId: incidentId,
        familyId: familyId,
        childId: childId,
        deviceId: deviceId,
        honesty: SosLocationHonesty.unavailable,
        attachedAt: _clock().toUtc(),
      );
      await _persist(evidence);
    }

    return SosLocationAttachResult(
      firedWithoutLocationBlocked: true,
      honesty: honesty,
      childStatusWord: honesty.childStatusWord,
      evidence: evidence,
    );
  }

  /// Child status words only — no coords (Q-LOC-09).
  Future<String> childStatusWordForIncident(String incidentId) async {
    final rows = await _db.query(
      _table,
      where: 'incident_id = ?',
      whereArgs: [incidentId],
      orderBy: 'attached_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return SosLocationHonesty.unavailable.childStatusWord;
    final wire = rows.first['honesty']! as String;
    return _parseHonesty(wire).childStatusWord;
  }

  Future<List<SosLocationEvidence>> listEvidence(String incidentId) async {
    final rows = await _db.query(
      _table,
      where: 'incident_id = ?',
      whereArgs: [incidentId],
      orderBy: 'attached_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<void> _persist(SosLocationEvidence e) async {
    await _db.insert(_table, {
      'id': '${e.incidentId}_${e.attachedAt.millisecondsSinceEpoch}',
      'incident_id': e.incidentId,
      'family_id': e.familyId.value,
      'child_id': e.childId.value,
      'device_id': e.deviceId.value,
      'honesty': e.honesty.wireName,
      'fix_id': e.fixId,
      'lat': e.latitude,
      'lng': e.longitude,
      'accuracy_m': e.accuracyMeters,
      'attached_at': e.attachedAt.millisecondsSinceEpoch,
    });
  }

  static SosLocationHonesty _parseHonesty(String wire) {
    switch (wire.toUpperCase()) {
      case 'ACQUIRING':
        return SosLocationHonesty.acquiring;
      case 'LOCATED':
        return SosLocationHonesty.located;
      case 'STALE_LAST_KNOWN':
        return SosLocationHonesty.staleLastKnown;
      case 'UNAVAILABLE':
      default:
        return SosLocationHonesty.unavailable;
    }
  }

  static SosLocationEvidence _fromRow(Map<String, Object?> row) {
    return SosLocationEvidence(
      incidentId: row['incident_id']! as String,
      familyId: FamilyId(row['family_id']! as String),
      childId: ChildId(row['child_id']! as String),
      deviceId: DeviceId(row['device_id']! as String),
      honesty: _parseHonesty(row['honesty']! as String),
      attachedAt: DateTime.fromMillisecondsSinceEpoch(
        row['attached_at']! as int,
        isUtc: true,
      ),
      fixId: row['fix_id'] as String?,
      latitude: (row['lat'] as num?)?.toDouble(),
      longitude: (row['lng'] as num?)?.toDouble(),
      accuracyMeters: (row['accuracy_m'] as num?)?.toDouble(),
    );
  }
}

/// Maps FS-001 honesty → SOS UI [SosLocationClass] wire names without owning SOS.
///
/// Returns the string token SOS screens already understand.
abstract final class SosLocationClassMapper {
  static String toSosUiToken(SosLocationHonesty h) => switch (h) {
    SosLocationHonesty.acquiring => 'acquiring',
    SosLocationHonesty.located => 'ready',
    SosLocationHonesty.staleLastKnown => 'stale',
    SosLocationHonesty.unavailable => 'unavailable',
  };
}
