/// FS-006 SOS Final domain — incident lifecycle + evidence + readiness ownership.
///
/// Owns: durable SosIncident, lifecycle audit (indefinite), operational samples
/// (90d), Break-glass allowlist persistence, readiness evaluation.
/// Does **not** own: location facts (FS-001), web/app engines, Modes schedule,
/// remote FCM/SMS/telephony (MOCK-REMOTE honesty).
library;

export 'sos_break_glass_allowlist.dart';
export 'sos_cross_system.dart';
export 'domain_sos_alert_repository.dart';
export 'sos_evidence_policy.dart';
export 'sos_final_runtime.dart';
export 'sos_final_service.dart';
export 'sos_final_store.dart';
export 'sos_incident.dart';
export 'sos_lifecycle_engine.dart';
export 'sos_location_honesty_bridge.dart';
export 'sos_permanent_exemptions.dart';
export 'sos_readiness.dart';
