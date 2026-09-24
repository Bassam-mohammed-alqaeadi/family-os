import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

import 'screen_camera_service.dart';
import 'screen_camera_store.dart';

/// Stage-1 composition for FS-004-OWN.
final class Stage1ScreenCameraRuntime {
  Stage1ScreenCameraRuntime._();

  static FamilyLocalDatabase get db => FsSessionKernel.db;
  static final FamilyId familyId = FamilyId('fam_stage1');

  static LocalScreenCameraStore? _store;
  static ScreenCameraService? _service;
  static CapabilityRegistry? _capabilities;
  static var _opened = false;

  static Future<void> ensureOpen() async {
    if (_opened) return;
    await FsSessionKernel.ensureOpen();
    _store = LocalScreenCameraStore(db);
    _service = ScreenCameraService(documents: _store!, familyId: familyId);
    _capabilities = CapabilityRegistry(db);
    await _capabilities!.applyFs004OwnCapabilities();
    _opened = true;
  }

  static ScreenCameraService get service {
    final s = _service;
    if (s == null) {
      throw StateError('Call Stage1ScreenCameraRuntime.ensureOpen() first');
    }
    return s;
  }

  static LocalScreenCameraStore get store {
    final s = _store;
    if (s == null) {
      throw StateError('Call Stage1ScreenCameraRuntime.ensureOpen() first');
    }
    return s;
  }

  static CapabilityRegistry get capabilities {
    final c = _capabilities;
    if (c == null) {
      throw StateError('Call Stage1ScreenCameraRuntime.ensureOpen() first');
    }
    return c;
  }

  /// Clears this runtime only — does not close [FsSessionKernel].
  static void resetForTest() {
    _opened = false;
    _store = null;
    _service = null;
    _capabilities = null;
  }
}
