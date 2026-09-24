/// FS-005 Modes domain — lifestyle schedule + activation ownership.
///
/// Owns: Mode definitions, schedule evaluation, multi-mode stack (tighten-only),
/// ModeException, overlay facts. Consumes FS-001 location facts.
/// Does **not** own: ST minutes, WF lists, AC packages, SC policy, SOS, geofences.
library;

export 'mode_activation.dart';
export 'mode_definition.dart';
export 'mode_exception.dart';
export 'mode_overlay.dart';
export 'modes_engine.dart';
export 'modes_repository.dart';
export 'modes_runtime.dart';
export 'modes_service.dart';
export 'modes_store.dart';
