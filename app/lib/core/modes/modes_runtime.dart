import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/location/modes_location_fact_feed.dart';

import 'modes_service.dart';
import 'modes_store.dart';

/// Stage-1 composition for FS-005-OWN.
final class Stage1ModesRuntime {
  Stage1ModesRuntime._();

  static FamilyLocalDatabase get db => FsSessionKernel.db;
  static final FamilyId familyId = FamilyId('fam_stage1');

  static LocalModesStore? _store;
  static ModesService? _service;
  static ModesLocationFactFeed? _facts;
  static CapabilityRegistry? _capabilities;
  static var _opened = false;

  static Future<void> ensureOpen() async {
    if (_opened) return;
    await FsSessionKernel.ensureOpen();
    _store = LocalModesStore(db);
    _facts = ModesLocationFactFeed(db);
    _service = ModesService(
      store: _store!,
      familyId: familyId,
      locationFacts: _facts,
    );
    _capabilities = CapabilityRegistry(db);
    await _capabilities!.applyFs005OwnCapabilities();
    _opened = true;
  }

  static ModesService get service {
    final s = _service;
    if (s == null) {
      throw StateError('Call Stage1ModesRuntime.ensureOpen() first');
    }
    return s;
  }

  static LocalModesStore get store {
    final s = _store;
    if (s == null) {
      throw StateError('Call Stage1ModesRuntime.ensureOpen() first');
    }
    return s;
  }

  static ModesLocationFactFeed get locationFacts {
    final f = _facts;
    if (f == null) {
      throw StateError('Call Stage1ModesRuntime.ensureOpen() first');
    }
    return f;
  }

  static CapabilityRegistry get capabilities {
    final c = _capabilities;
    if (c == null) {
      throw StateError('Call Stage1ModesRuntime.ensureOpen() first');
    }
    return c;
  }

  /// Clears this runtime only — does not close [FsSessionKernel].
  static void resetForTest() {
    _opened = false;
    _store = null;
    _service = null;
    _facts = null;
    _capabilities = null;
  }
}
