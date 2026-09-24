/// FS-004 Screen & Camera Control domain (Prevent + Monitor + Protect).
///
/// Owns: OS camera intent, capture prevent intent, screenshot monitoring policy,
/// sensitive-surface protect. Does **not** own: FS-003 packages, ST minutes,
/// WF URLs, microphone, SOS audio, Modes schedule.
library;

export 'screen_camera_document.dart';
export 'screen_camera_engine.dart';
export 'screen_camera_protected.dart';
export 'screen_camera_repository.dart';
export 'screen_camera_runtime.dart';
export 'screen_camera_service.dart';
export 'screen_camera_store.dart';
