/// FS campaign shared foundations (Phase A).
///
/// Stack: domain types → LocalDatabase (SQLite / memory) → MockRemoteAdapter.
/// No backend. Capability honesty vocabulary is mandatory for FS-001…007.
library;

export 'capability_registry.dart';
export 'capability_status.dart';
export 'fs_session_kernel.dart';
export 'local_database.dart';
export 'memory_local_database.dart';
export 'mock_remote_adapter.dart';
export 'policy_delivery.dart';
export 'sqlite_local_database.dart';
