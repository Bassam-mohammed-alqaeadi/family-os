/// FS-001 Location Domain — facts, geometry, trail, geofence events.
///
/// Owns location facts only. Policy Kernel interprets events.
/// Native GPS remains NOT IMPLEMENTED until a later card — inject samples
/// honestly; never claim live GPS success.
///
/// Cross-system (FS-001-XSYS): [SosLocationHandoff] attaches facts to SOS
/// incidents without owning lifecycle; [ModesLocationFactFeed] publishes
/// ENTER/EXIT/NO_SHOW/presence facts without activating Modes.
library;

export 'geo_point.dart';
export 'geofence_evaluator.dart';
export 'geofence_event.dart';
export 'location_fix.dart';
export 'location_repository.dart';
export 'location_store.dart';
export 'modes_location_fact_feed.dart';
export 'safe_zone_definition.dart';
export 'sos_location_handoff.dart';
export 'sos_location_handoff_service.dart';
export 'zone_geometry.dart';
