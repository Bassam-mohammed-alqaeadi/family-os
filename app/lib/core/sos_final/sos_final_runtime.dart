import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/location/location_store.dart';
import 'package:family_os/core/location/sos_location_handoff_service.dart';

import 'sos_cross_system.dart';
import 'sos_final_service.dart';
import 'sos_final_store.dart';

/// Stage-1 composition for FS-006 (LIFE + XSYS).
final class Stage1SosFinalRuntime {
  Stage1SosFinalRuntime._();

  static FamilyLocalDatabase get db => FsSessionKernel.db;
  static final FamilyId familyId = FamilyId('fam_stage1');

  static LocalSosFinalStore? _store;
  static SosFinalService? _service;
  static SosLocationHandoff? _handoff;
  static SosCrossSystemCoordinator? _cross;
  static CapabilityRegistry? _capabilities;
  static var _opened = false;

  static Future<void> ensureOpen() async {
    if (_opened) return;
    await FsSessionKernel.ensureOpen();
    _store = LocalSosFinalStore(db);
    _service = SosFinalService(store: _store!, familyId: familyId);
    final locStore = LocalLocationStore(db);
    _handoff = SosLocationHandoff(db, locStore);
    _capabilities = CapabilityRegistry(db);
    await _capabilities!.applyFs006XsysCapabilities();
    _cross = SosCrossSystemCoordinator(
      lifecycle: _service!,
      store: _store!,
      locationHandoff: _handoff,
      capabilities: _capabilities,
    );
    _opened = true;
  }

  static SosFinalService get service {
    final s = _service;
    if (s == null) {
      throw StateError('Call Stage1SosFinalRuntime.ensureOpen() first');
    }
    return s;
  }

  static SosCrossSystemCoordinator get crossSystem {
    final c = _cross;
    if (c == null) {
      throw StateError('Call Stage1SosFinalRuntime.ensureOpen() first');
    }
    return c;
  }

  static LocalSosFinalStore get store {
    final s = _store;
    if (s == null) {
      throw StateError('Call Stage1SosFinalRuntime.ensureOpen() first');
    }
    return s;
  }

  static CapabilityRegistry get capabilities {
    final c = _capabilities;
    if (c == null) {
      throw StateError('Call Stage1SosFinalRuntime.ensureOpen() first');
    }
    return c;
  }

  /// Clears this runtime only — does not close [FsSessionKernel].
  static void resetForTest() {
    _opened = false;
    _store = null;
    _service = null;
    _handoff = null;
    _cross = null;
    _capabilities = null;
  }
}
