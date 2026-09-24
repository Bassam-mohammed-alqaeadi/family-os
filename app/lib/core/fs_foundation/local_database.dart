/// Conflict policy for [FamilyLocalDatabase.insert].
enum LocalConflictAlgorithm { abort, replace, ignore }

/// Abstract local durable store — SQLite on device, memory in unit tests.
///
/// Rule 25: features depend on this interface; swap Memory ↔ SQLite at the
/// composition root without UI changes.
abstract class FamilyLocalDatabase {
  /// Schema version currently applied (0 if empty).
  Future<int> schemaVersion();

  /// Opens / migrates to [FamilyLocalSchema.currentVersion].
  Future<void> open();

  Future<void> close();

  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    LocalConflictAlgorithm conflictAlgorithm = LocalConflictAlgorithm.abort,
  });

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  });

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});

  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  });

  /// Raw SQL for migrations / advanced queries.
  Future<void> execute(String sql, [List<Object?>? args]);

  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]);
}

/// Canonical FS foundation schema (versioned).
abstract final class FamilyLocalSchema {
  /// v1=FS-A · v2=loc · v3=XSYS · v4=WF · v5=WF ENF · v6=AC · v7=SC · v8=Modes · v9=SOS · v10=AI.
  static const int currentVersion = 10;

  static const createStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS schema_meta (
  key TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS kv_store (
  namespace TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (namespace, key)
)
''',
    '''
CREATE TABLE IF NOT EXISTS capability_entry (
  id TEXT PRIMARY KEY NOT NULL,
  system_id TEXT NOT NULL,
  status TEXT NOT NULL,
  note TEXT,
  updated_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS sync_outbox (
  id TEXT PRIMARY KEY NOT NULL,
  channel TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  attempts INTEGER NOT NULL,
  last_error TEXT,
  delivered_at INTEGER
)
''',
    '''
CREATE TABLE IF NOT EXISTS policy_delivery (
  artifact_id TEXT PRIMARY KEY NOT NULL,
  policy_version INTEGER NOT NULL,
  phase TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  last_error TEXT
)
''',
    ...locationStatements,
    ...locationXsysStatements,
    ...webFilterStatements,
    ...webFilterEnfStatements,
    ...appControlStatements,
    ...screenCameraStatements,
    ...modesStatements,
    ...sosFinalStatements,
    ...offlineAiSafetyStatements,
  ];

  /// FS-001 Location Domain tables (schema v2).
  static const locationStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS loc_zone (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  name TEXT NOT NULL,
  emoji TEXT,
  active INTEGER NOT NULL,
  archived INTEGER NOT NULL,
  alert_enter INTEGER NOT NULL,
  alert_exit INTEGER NOT NULL,
  alert_no_show INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS loc_zone_geometry (
  zone_id TEXT PRIMARY KEY NOT NULL,
  kind TEXT NOT NULL,
  version INTEGER NOT NULL,
  center_lat REAL,
  center_lng REAL,
  radius_m REAL,
  polygon_json TEXT
)
''',
    '''
CREATE TABLE IF NOT EXISTS loc_zone_assignment (
  zone_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  PRIMARY KEY (zone_id, child_id)
)
''',
    '''
CREATE TABLE IF NOT EXISTS loc_trail_sample (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  acquisition TEXT NOT NULL,
  lat REAL,
  lng REAL,
  accuracy_m REAL,
  integrity_soft INTEGER NOT NULL,
  recorded_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS loc_geofence_event (
  event_id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  zone_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  occurred_at INTEGER NOT NULL,
  geometry_version INTEGER
)
''',
    '''
CREATE TABLE IF NOT EXISTS loc_zone_presence (
  zone_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  inside INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (zone_id, child_id)
)
''',
  ];

  /// FS-001-XSYS SOS evidence + Modes fact feed (schema v3).
  static const locationXsysStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS loc_sos_evidence (
  id TEXT PRIMARY KEY NOT NULL,
  incident_id TEXT NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  honesty TEXT NOT NULL,
  fix_id TEXT,
  lat REAL,
  lng REAL,
  accuracy_m REAL,
  attached_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS loc_mode_fact (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  zone_id TEXT,
  inside INTEGER,
  occurred_at INTEGER NOT NULL
)
''',
  ];

  /// FS-002-OWN Web Filter documents (schema v4).
  static const webFilterStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS wf_document (
  scope_key TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT,
  level TEXT NOT NULL,
  categories_json TEXT NOT NULL,
  allow_json TEXT NOT NULL,
  block_json TEXT NOT NULL,
  dict_json TEXT NOT NULL,
  policy_version INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''',
  ];

  /// FS-002-ENF timed temporary allows (schema v5).
  static const webFilterEnfStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS wf_temp_allow (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  host TEXT NOT NULL,
  request_id TEXT NOT NULL,
  starts_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  status TEXT NOT NULL
)
''',
  ];

  /// FS-003-OWN App Control dispositions + overlays (schema v6).
  static const appControlStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS ac_document (
  scope_key TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT,
  dispositions_json TEXT NOT NULL,
  policy_version INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS ac_exception (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  package_id TEXT NOT NULL,
  status TEXT NOT NULL,
  requested_at INTEGER NOT NULL,
  starts_at INTEGER,
  expires_at INTEGER,
  request_note TEXT
)
''',
    '''
CREATE TABLE IF NOT EXISTS ac_lock_now (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  package_id TEXT NOT NULL,
  status TEXT NOT NULL,
  starts_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS ac_install (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  package_id TEXT NOT NULL,
  status TEXT NOT NULL,
  observed_at INTEGER NOT NULL,
  label_snapshot TEXT
)
''',
  ];

  /// FS-004-OWN Screen & Camera Prevent/Monitor/Protect (schema v7).
  static const screenCameraStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS sc_document (
  scope_key TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT,
  prevent_camera_os INTEGER NOT NULL,
  prevent_capture INTEGER NOT NULL,
  monitor_screenshots INTEGER NOT NULL,
  monitored_packages_json TEXT NOT NULL,
  protect_sensitive INTEGER NOT NULL,
  exceptions_json TEXT NOT NULL,
  policy_version INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''',
  ];

  /// FS-005-OWN Modes lifestyle schedule + activation (schema v8).
  static const modesStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS mode_document (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  catalog_id TEXT NOT NULL,
  custom_label TEXT,
  child_scope TEXT NOT NULL,
  target_children_json TEXT NOT NULL,
  clock_json TEXT,
  location_zone_id TEXT,
  season_json TEXT,
  overlay_json TEXT NOT NULL,
  grace_minutes INTEGER NOT NULL,
  enabled INTEGER NOT NULL,
  policy_version INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS mode_activation (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  mode_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  channel TEXT NOT NULL,
  active INTEGER NOT NULL,
  started_at INTEGER NOT NULL,
  ends_at INTEGER
)
''',
    '''
CREATE TABLE IF NOT EXISTS mode_exception (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  mode_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  note TEXT NOT NULL,
  starts_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  active INTEGER NOT NULL
)
''',
  ];

  /// FS-006-LIFE SOS Final lifecycle + evidence + break-glass (schema v9).
  static const sosFinalStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS sos_incident (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  status TEXT NOT NULL,
  terminal_reason TEXT,
  triggered_at INTEGER NOT NULL,
  acknowledged_at INTEGER,
  acknowledged_by TEXT,
  resolved_at INTEGER,
  resolved_by TEXT,
  trigger_source TEXT NOT NULL,
  location_class TEXT NOT NULL,
  connection_class TEXT NOT NULL,
  battery_percent INTEGER NOT NULL,
  panic_quiet_at_trigger INTEGER NOT NULL,
  evidence_retain_until INTEGER NOT NULL,
  deliveries_json TEXT NOT NULL,
  child_display_name TEXT NOT NULL,
  child_emoji TEXT NOT NULL,
  location_label TEXT NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS sos_lifecycle_audit (
  id TEXT PRIMARY KEY NOT NULL,
  incident_id TEXT NOT NULL,
  family_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  at_ms INTEGER NOT NULL,
  actor_id TEXT,
  payload_json TEXT NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS sos_ops_sample (
  id TEXT PRIMARY KEY NOT NULL,
  incident_id TEXT NOT NULL,
  family_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  captured_at INTEGER NOT NULL,
  retain_until INTEGER NOT NULL,
  payload_json TEXT NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS sos_break_glass (
  id TEXT PRIMARY KEY NOT NULL,
  incident_id TEXT NOT NULL,
  family_id TEXT NOT NULL,
  actor_id TEXT NOT NULL,
  capability_id TEXT NOT NULL,
  reason TEXT NOT NULL,
  phase TEXT NOT NULL,
  started_at INTEGER NOT NULL,
  ends_at INTEGER NOT NULL,
  ended_at INTEGER,
  end_reason TEXT
)
''',
  ];

  /// FS-007-SIG Offline AI Safety signal plane (schema v10).
  static const offlineAiSafetyStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS ai_model_manifest (
  model_id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  version TEXT NOT NULL,
  signature TEXT NOT NULL,
  policy_version TEXT NOT NULL,
  active INTEGER NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS ai_safety_signal (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  category TEXT NOT NULL,
  certainty TEXT NOT NULL,
  severity TEXT NOT NULL,
  provenance TEXT NOT NULL,
  model_version TEXT NOT NULL,
  policy_version TEXT NOT NULL,
  tool TEXT NOT NULL,
  redacted_preview TEXT,
  notified INTEGER NOT NULL,
  ticket_id TEXT,
  created_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS ai_safety_ticket (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  signal_id TEXT NOT NULL,
  child_id TEXT NOT NULL,
  status TEXT NOT NULL,
  redacted_preview TEXT,
  created_at INTEGER NOT NULL,
  closed_at INTEGER,
  closed_by TEXT
)
''',
    '''
CREATE TABLE IF NOT EXISTS ai_safety_suggestion (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  ticket_id TEXT NOT NULL,
  target TEXT NOT NULL,
  summary TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at INTEGER NOT NULL
)
''',
    '''
CREATE TABLE IF NOT EXISTS ai_safety_audit (
  id TEXT PRIMARY KEY NOT NULL,
  family_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  at_ms INTEGER NOT NULL,
  actor_id TEXT,
  payload_json TEXT NOT NULL
)
''',
  ];
}
