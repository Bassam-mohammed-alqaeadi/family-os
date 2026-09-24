import 'capability_status.dart';
import 'local_database.dart';

/// Authoritative in-app registry of FS capability honesty rows.
///
/// Persists via [FamilyLocalDatabase]. Seeded defaults are campaign-honest
/// baselines — later cards upgrade statuses as real work lands.
final class CapabilityRegistry {
  CapabilityRegistry(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final DateTime Function() _clock;

  static const String table = 'capability_entry';

  /// Campaign baseline seeds (Phase A). Statuses escalate in later cards.
  static List<CapabilityEntry> defaultSeeds({required DateTime now}) {
    CapabilityEntry e(
      String id,
      String systemId,
      CapabilityStatus status, [
      String? note,
    ]) {
      return CapabilityEntry(
        id: id,
        systemId: systemId,
        status: status,
        note: note,
        updatedAt: now,
      );
    }

    return [
      e(
        'fs_a.sqlite_kernel',
        'FS-A',
        CapabilityStatus.implemented,
        'Local SQLite schema + migrations',
      ),
      e(
        'fs_a.mock_remote',
        'FS-A',
        CapabilityStatus.mockRemote,
        'Outbox only — no live cloud',
      ),
      e(
        'fs_a.delivery_pipeline',
        'FS-A',
        CapabilityStatus.implemented,
        'Configured→…→Verified vocabulary',
      ),
      e(
        'fs001.location_domain',
        'FS-001',
        CapabilityStatus.implemented,
        'Zones+trail+events domain store',
      ),
      e(
        'fs001.geofence_eval',
        'FS-001',
        CapabilityStatus.implemented,
        'ENTER/EXIT local eval; NO_SHOW explicit',
      ),
      e(
        'fs001.native_gps',
        'FS-001',
        CapabilityStatus.notImplemented,
        'Device GPS not wired — inject fixes honestly only',
      ),
      e(
        'fs001.sos_location_handoff',
        'FS-001',
        CapabilityStatus.implemented,
        'Attach location facts to SOS; never block fire',
      ),
      e(
        'fs001.modes_fact_feed',
        'FS-001',
        CapabilityStatus.implemented,
        'ENTER/EXIT/NO_SHOW/presence facts for Modes',
      ),
      e(
        'fs002.web_lists',
        'FS-002',
        CapabilityStatus.implemented,
        'Allow/block/dict + baseline/override SQLite',
      ),
      e(
        'fs002.native_block',
        'FS-002',
        CapabilityStatus.mockRemote,
        'No VPN/DNS plane yet — never claim device block',
      ),
      e(
        'fs002.taxonomy',
        'FS-002',
        CapabilityStatus.degraded,
        'Stage-1 six categories; T-WF-02 taxonomy TBD',
      ),
      e(
        'fs002.delivery_plane',
        'FS-002',
        CapabilityStatus.implemented,
        'Configured→Verified local honesty; no fake native ack',
      ),
      e(
        'fs002.timed_unlock',
        'FS-002',
        CapabilityStatus.implemented,
        'Timed temp allow; never silent allowlist (Q-WF-09)',
      ),
      e(
        'fs003.app_dispositions',
        'FS-003',
        CapabilityStatus.implemented,
        'Allow/Block/Exempt + baseline/override SQLite v6',
      ),
      e(
        'fs003.protected_packages',
        'FS-003',
        CapabilityStatus.implemented,
        'SOS/Family OS/Chat/Quran cannot be denied',
      ),
      e(
        'fs003.app_exception',
        'FS-003',
        CapabilityStatus.implemented,
        'Timed exception; never rewrites Permanent Block',
      ),
      e(
        'fs003.os_intercept',
        'FS-003',
        CapabilityStatus.mockRemote,
        'No Device Admin/Accessibility plane — never claim OS block',
      ),
      e(
        'fs004.screen_camera_policy',
        'FS-004',
        CapabilityStatus.implemented,
        'Prevent/Monitor/Protect + baseline/override SQLite v7',
      ),
      e(
        'fs004.capture_pipeline',
        'FS-004',
        CapabilityStatus.mockRemote,
        'No screenshot agent — policy configured only',
      ),
      e(
        'fs004.camera_os_plane',
        'FS-004',
        CapabilityStatus.mockRemote,
        'No MDM camera disable — never claim OS camera kill',
      ),
      e(
        'fs005.modes_scheduler',
        'FS-005',
        CapabilityStatus.implemented,
        'Lifestyle schedule + multi-mode stack SQLite v8',
      ),
      e(
        'fs005.os_wake',
        'FS-005',
        CapabilityStatus.mockRemote,
        'No AlarmManager/Focus wake — evaluate on open only',
      ),
      e(
        'fs006.sos_lifecycle',
        'FS-006',
        CapabilityStatus.implemented,
        'Durable incident + audit SQLite v9',
      ),
      e(
        'fs006.evidence_retention',
        'FS-006',
        CapabilityStatus.implemented,
        'Ops samples 90d purge; core+audit indefinite',
      ),
      e(
        'fs006.readiness',
        'FS-006',
        CapabilityStatus.implemented,
        'OD-21 checklist evaluator; no false green',
      ),
      e(
        'fs006.break_glass',
        'FS-006',
        CapabilityStatus.implemented,
        'RBAC + Q-SOS-RD-02B allowlist; local override only',
      ),
      e(
        'fs006.permanent_exemptions',
        'FS-006',
        CapabilityStatus.implemented,
        'OD-14 never-gate vs Modes/ST/AC/WF/locks/subscription',
      ),
      e(
        'fs006.location_honesty_bridge',
        'FS-006',
        CapabilityStatus.implemented,
        'Consumes FS-001 handoff; never blocks fire; Break-glass≠Find',
      ),
      e(
        'fs006.remote_delivery',
        'FS-006',
        CapabilityStatus.mockRemote,
        'FCM/SMS/telephony not live',
      ),
      e(
        'fs007.local_classifier',
        'FS-007',
        CapabilityStatus.implemented,
        'Signed local heuristic/ML signal plane; never policy engine',
      ),
      e(
        'fs007.safety_tickets',
        'FS-007',
        CapabilityStatus.implemented,
        'Gated tickets analysis|confirmed; redacted preview',
      ),
      e(
        'fs007.suggest_only',
        'FS-007',
        CapabilityStatus.implemented,
        'Human-approve hand-off; no silent WF/AC/Modes mutation',
      ),
      e(
        'fs007.cloud_classify',
        'FS-007',
        CapabilityStatus.unsupported,
        'Out of v1 by L2 AI-OD-10',
      ),
    ];
  }

  /// Phase 1.5 — idempotent post-campaign honesty on a shared session DB.
  Future<void> applyAllCampaignCapabilities() async {
    await applyFs001XsysCapabilities();
    await applyFs002EnfCapabilities();
    await applyFs003OwnCapabilities();
    await applyFs004OwnCapabilities();
    await applyFs005OwnCapabilities();
    await applyFs006XsysCapabilities();
    await applyFs007SigCapabilities();
  }

  Future<void> ensureSeeded() async {
    final existing = await listAll();
    if (existing.isNotEmpty) return;
    final now = _clock().toUtc();
    for (final entry in defaultSeeds(now: now)) {
      await upsert(entry);
    }
  }

  /// Upgrade honesty rows after FS-001-DOM ships (idempotent).
  Future<void> applyFs001DomCapabilities() async {
    await ensureSeeded();
    await setStatus(
      'fs001.location_domain',
      CapabilityStatus.implemented,
      note: 'Zones+trail+events domain store',
    );
    await setStatus(
      'fs001.geofence_eval',
      CapabilityStatus.implemented,
      note: 'ENTER/EXIT local eval; NO_SHOW explicit',
    );
    // native_gps stays NOT IMPLEMENTED — do not fake device GPS.
  }

  /// Upgrade honesty rows after FS-001-XSYS ships (idempotent).
  Future<void> applyFs001XsysCapabilities() async {
    await applyFs001DomCapabilities();
    await _ensureCapability(
      'fs001.sos_location_handoff',
      'FS-001',
      CapabilityStatus.implemented,
      'Attach location facts to SOS; never block fire',
    );
    await _ensureCapability(
      'fs001.modes_fact_feed',
      'FS-001',
      CapabilityStatus.implemented,
      'ENTER/EXIT/NO_SHOW/presence facts for Modes',
    );
    // native_gps stays NOT IMPLEMENTED — do not fake device GPS.
  }

  /// Upgrade honesty rows after FS-002-OWN ships (idempotent).
  Future<void> applyFs002OwnCapabilities() async {
    await ensureSeeded();
    await _ensureCapability(
      'fs002.web_lists',
      'FS-002',
      CapabilityStatus.implemented,
      'Allow/block/dict + baseline/override SQLite',
    );
    await _ensureCapability(
      'fs002.taxonomy',
      'FS-002',
      CapabilityStatus.degraded,
      'Stage-1 six categories; T-WF-02 taxonomy TBD',
    );
    // native_block stays MOCK-REMOTE — never fake VPN/DNS success.
    await setStatus(
      'fs002.native_block',
      CapabilityStatus.mockRemote,
      note: 'No VPN/DNS plane yet — never claim device block',
    );
  }

  /// Upgrade honesty rows after FS-002-ENF ships (idempotent).
  Future<void> applyFs002EnfCapabilities() async {
    await applyFs002OwnCapabilities();
    await _ensureCapability(
      'fs002.delivery_plane',
      'FS-002',
      CapabilityStatus.implemented,
      'Configured→Verified local honesty; no fake native ack',
    );
    await _ensureCapability(
      'fs002.timed_unlock',
      'FS-002',
      CapabilityStatus.implemented,
      'Timed temp allow; never silent allowlist (Q-WF-09)',
    );
    // native_block stays MOCK-REMOTE.
  }

  /// Upgrade honesty rows after FS-003-OWN ships (idempotent).
  Future<void> applyFs003OwnCapabilities() async {
    await ensureSeeded();
    await _ensureCapability(
      'fs003.app_dispositions',
      'FS-003',
      CapabilityStatus.implemented,
      'Allow/Block/Exempt + baseline/override SQLite v6',
    );
    await _ensureCapability(
      'fs003.protected_packages',
      'FS-003',
      CapabilityStatus.implemented,
      'SOS/Family OS/Chat/Quran cannot be denied',
    );
    await _ensureCapability(
      'fs003.app_exception',
      'FS-003',
      CapabilityStatus.implemented,
      'Timed exception; never rewrites Permanent Block',
    );
    // os_intercept stays MOCK-REMOTE — never fake device package block.
    await setStatus(
      'fs003.os_intercept',
      CapabilityStatus.mockRemote,
      note: 'No Device Admin/Accessibility plane — never claim OS block',
    );
  }

  /// Upgrade honesty rows after FS-004-OWN ships (idempotent).
  Future<void> applyFs004OwnCapabilities() async {
    await ensureSeeded();
    await _ensureCapability(
      'fs004.screen_camera_policy',
      'FS-004',
      CapabilityStatus.implemented,
      'Prevent/Monitor/Protect + baseline/override SQLite v7',
    );
    // Capture + OS camera planes stay MOCK-REMOTE — never fake enforcement.
    await setStatus(
      'fs004.capture_pipeline',
      CapabilityStatus.mockRemote,
      note: 'No screenshot agent — policy configured only',
    );
    await _ensureCapability(
      'fs004.camera_os_plane',
      'FS-004',
      CapabilityStatus.mockRemote,
      'No MDM camera disable — never claim OS camera kill',
    );
  }

  /// Upgrade honesty rows after FS-005-OWN ships (idempotent).
  Future<void> applyFs005OwnCapabilities() async {
    await ensureSeeded();
    await setStatus(
      'fs005.modes_scheduler',
      CapabilityStatus.implemented,
      note: 'Lifestyle schedule + multi-mode stack SQLite v8',
    );
    await _ensureCapability(
      'fs005.os_wake',
      'FS-005',
      CapabilityStatus.mockRemote,
      'No AlarmManager/Focus wake — evaluate on open only',
    );
  }

  /// Upgrade honesty rows after FS-006-LIFE ships (idempotent).
  Future<void> applyFs006LifeCapabilities() async {
    await ensureSeeded();
    await setStatus(
      'fs006.sos_lifecycle',
      CapabilityStatus.implemented,
      note: 'Durable incident + audit SQLite v9',
    );
    await _ensureCapability(
      'fs006.evidence_retention',
      'FS-006',
      CapabilityStatus.implemented,
      'Ops samples 90d purge; core+audit indefinite',
    );
    await _ensureCapability(
      'fs006.readiness',
      'FS-006',
      CapabilityStatus.implemented,
      'OD-21 checklist evaluator; no false green',
    );
    await _ensureCapability(
      'fs006.break_glass',
      'FS-006',
      CapabilityStatus.implemented,
      'RBAC + Q-SOS-RD-02B allowlist; local override only',
    );
    // remote_delivery stays MOCK-REMOTE — never fake FCM/SMS success.
    await setStatus(
      'fs006.remote_delivery',
      CapabilityStatus.mockRemote,
      note: 'FCM/SMS/telephony not live',
    );
  }

  /// Upgrade honesty rows after FS-006-XSYS ships (idempotent).
  Future<void> applyFs006XsysCapabilities() async {
    await applyFs006LifeCapabilities();
    await _ensureCapability(
      'fs006.permanent_exemptions',
      'FS-006',
      CapabilityStatus.implemented,
      'OD-14 never-gate vs Modes/ST/AC/WF/locks/subscription',
    );
    await _ensureCapability(
      'fs006.location_honesty_bridge',
      'FS-006',
      CapabilityStatus.implemented,
      'Consumes FS-001 handoff; never blocks fire; Break-glass≠Find',
    );
    // remote_delivery stays MOCK-REMOTE; native_gps remains FS-001 NOT IMPLEMENTED.
    await setStatus(
      'fs006.remote_delivery',
      CapabilityStatus.mockRemote,
      note: 'FCM/SMS/telephony not live',
    );
  }

  /// Upgrade honesty rows after FS-007-SIG ships (idempotent).
  Future<void> applyFs007SigCapabilities() async {
    await ensureSeeded();
    await setStatus(
      'fs007.local_classifier',
      CapabilityStatus.implemented,
      note: 'Signed local heuristic/ML signal plane; never policy engine',
    );
    await _ensureCapability(
      'fs007.safety_tickets',
      'FS-007',
      CapabilityStatus.implemented,
      'Gated tickets analysis|confirmed; redacted preview',
    );
    await _ensureCapability(
      'fs007.suggest_only',
      'FS-007',
      CapabilityStatus.implemented,
      'Human-approve hand-off; no silent WF/AC/Modes mutation',
    );
    // Cloud classify stays UNSUPPORTED in v1.
    await setStatus(
      'fs007.cloud_classify',
      CapabilityStatus.unsupported,
      note: 'Out of v1 by L2 AI-OD-10',
    );
  }

  Future<void> _ensureCapability(
    String id,
    String systemId,
    CapabilityStatus status,
    String note,
  ) async {
    final existing = await get(id);
    if (existing == null) {
      await upsert(
        CapabilityEntry(
          id: id,
          systemId: systemId,
          status: status,
          note: note,
          updatedAt: _clock().toUtc(),
        ),
      );
      return;
    }
    await setStatus(id, status, note: note);
  }

  Future<List<CapabilityEntry>> listAll() async {
    final rows = await _db.query(table, orderBy: 'system_id ASC, id ASC');
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<List<CapabilityEntry>> listBySystem(String systemId) async {
    final rows = await _db.query(
      table,
      where: 'system_id = ?',
      whereArgs: [systemId],
      orderBy: 'id ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<CapabilityEntry?> get(String id) async {
    final rows = await _db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<void> upsert(CapabilityEntry entry) async {
    await _db.insert(table, {
      'id': entry.id,
      'system_id': entry.systemId,
      'status': entry.status.wireName,
      'note': entry.note,
      'updated_at': entry.updatedAt.toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: LocalConflictAlgorithm.replace);
  }

  Future<CapabilityEntry> setStatus(
    String id,
    CapabilityStatus status, {
    String? note,
  }) async {
    final current = await get(id);
    if (current == null) {
      throw StateError('Unknown capability id: $id');
    }
    final resolved = CapabilityEntry(
      id: current.id,
      systemId: current.systemId,
      status: status,
      note: note ?? current.note,
      updatedAt: _clock().toUtc(),
    );
    await upsert(resolved);
    return resolved;
  }

  static CapabilityEntry _fromRow(Map<String, Object?> row) {
    return CapabilityEntry(
      id: row['id']! as String,
      systemId: row['system_id']! as String,
      status: CapabilityStatusWire.parse(row['status']! as String),
      note: row['note'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at']! as int,
        isUtc: true,
      ),
    );
  }
}
