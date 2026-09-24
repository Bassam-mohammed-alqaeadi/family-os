/// FS-007 Offline AI Safety — classification / signal plane only.
///
/// Owns: typed SafetySignal, gated tickets, suggest-only hand-offs, signed
/// model manifests, child transparency facts.
/// Does **not** own: WF lists, AC packages, Modes, SOS, ST minutes, Advisor LLM.
/// Never silent policy mutation; never SOS fire; cloud classify out of v1.
library;

export 'local_safety_classifier.dart';
export 'offline_ai_safety_runtime.dart';
export 'offline_ai_safety_service.dart';
export 'offline_ai_safety_store.dart';
export 'safety_models.dart';
export 'safety_taxonomy.dart';
