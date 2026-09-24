import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

import 'offline_ai_safety_service.dart';
import 'offline_ai_safety_store.dart';

/// Stage-1 composition for FS-007-SIG.
final class Stage1OfflineAiSafetyRuntime {
  Stage1OfflineAiSafetyRuntime._();

  static FamilyLocalDatabase get db => FsSessionKernel.db;
  static final FamilyId familyId = FamilyId('fam_stage1');

  static LocalOfflineAiSafetyStore? _store;
  static OfflineAiSafetyService? _service;
  static CapabilityRegistry? _capabilities;
  static var _opened = false;

  static Future<void> ensureOpen() async {
    if (_opened) return;
    await FsSessionKernel.ensureOpen();
    _store = LocalOfflineAiSafetyStore(db);
    _service = OfflineAiSafetyService(store: _store!, familyId: familyId);
    _capabilities = CapabilityRegistry(db);
    await _capabilities!.applyFs007SigCapabilities();
    _opened = true;
  }

  static OfflineAiSafetyService get service {
    final s = _service;
    if (s == null) {
      throw StateError('Call Stage1OfflineAiSafetyRuntime.ensureOpen() first');
    }
    return s;
  }

  static LocalOfflineAiSafetyStore get store {
    final s = _store;
    if (s == null) {
      throw StateError('Call Stage1OfflineAiSafetyRuntime.ensureOpen() first');
    }
    return s;
  }

  static CapabilityRegistry get capabilities {
    final c = _capabilities;
    if (c == null) {
      throw StateError('Call Stage1OfflineAiSafetyRuntime.ensureOpen() first');
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
