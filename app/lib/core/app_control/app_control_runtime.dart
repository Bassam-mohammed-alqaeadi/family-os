import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/policy/app_access_rules_repository.dart';

import 'app_control_overlay_store.dart';
import 'app_control_service.dart';
import 'app_control_store.dart';
import 'domain_app_access_rules_repository.dart';

/// Stage-1 composition for FS-003-OWN.
final class Stage1AppControlRuntime {
  Stage1AppControlRuntime._();

  static FamilyLocalDatabase get db => FsSessionKernel.db;
  static final FamilyId familyId = FamilyId('fam_stage1');

  static LocalAppControlStore? _store;
  static LocalAppAccessExceptionStore? _exceptions;
  static LocalAppLockNowStore? _lockNow;
  static LocalAppInstallTicketStore? _installs;
  static AppControlService? _service;
  static DomainAppAccessRulesRepository? _accessRules;
  static CapabilityRegistry? _capabilities;
  static var _opened = false;

  static Future<void> ensureOpen() async {
    if (_opened) return;
    await FsSessionKernel.ensureOpen();
    _store = LocalAppControlStore(db);
    _exceptions = LocalAppAccessExceptionStore(db);
    _lockNow = LocalAppLockNowStore(db);
    _installs = LocalAppInstallTicketStore(db);
    _service = AppControlService(
      documents: _store!,
      exceptions: _exceptions!,
      lockNow: _lockNow!,
      installs: _installs!,
      familyId: familyId,
    );
    _accessRules = DomainAppAccessRulesRepository(
      _store!,
      familyId: familyId,
      stAxes: PrefsAppAccessRulesRepository(stage1AppAccessRulesStore),
    );
    _capabilities = CapabilityRegistry(db);
    await _capabilities!.applyFs003OwnCapabilities();
    _opened = true;
  }

  static AppControlService get service {
    final s = _service;
    if (s == null) {
      throw StateError('Call Stage1AppControlRuntime.ensureOpen() first');
    }
    return s;
  }

  static LocalAppControlStore get store {
    final s = _store;
    if (s == null) {
      throw StateError('Call Stage1AppControlRuntime.ensureOpen() first');
    }
    return s;
  }

  static AppAccessRulesRepository get accessRules {
    final r = _accessRules;
    if (r == null) {
      throw StateError('Call Stage1AppControlRuntime.ensureOpen() first');
    }
    return r;
  }

  static CapabilityRegistry get capabilities {
    final c = _capabilities;
    if (c == null) {
      throw StateError('Call Stage1AppControlRuntime.ensureOpen() first');
    }
    return c;
  }

  /// Clears this runtime only — does not close [FsSessionKernel].
  static void resetForTest() {
    _opened = false;
    _store = null;
    _exceptions = null;
    _lockNow = null;
    _installs = null;
    _service = null;
    _accessRules = null;
    _capabilities = null;
  }
}
