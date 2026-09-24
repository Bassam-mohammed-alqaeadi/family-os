import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/policy/web_filter_policy_repository.dart';
import 'package:family_os/core/web_filter/domain_web_filter_policy_repository.dart';
import 'package:family_os/core/web_filter/web_filter_delivery.dart';
import 'package:family_os/core/web_filter/web_filter_store.dart';
import 'package:family_os/core/web_filter/web_filter_temp_allow_store.dart';

/// Stage-1 composition for FS-002 (OWN + ENF).
final class Stage1WebFilterRuntime {
  Stage1WebFilterRuntime._();

  static FamilyLocalDatabase get db => FsSessionKernel.db;
  static final FamilyId familyId = FamilyId('fam_stage1');

  static LocalWebFilterStore? _store;
  static LocalWebFilterTempAllowStore? _tempAllows;
  static WebFilterDeliveryTracker? _delivery;
  static DomainWebFilterPolicyRepository? _policyRepo;
  static CapabilityRegistry? _capabilities;
  static var _opened = false;

  static Future<void> ensureOpen() async {
    if (_opened) return;
    await FsSessionKernel.ensureOpen();
    _store = LocalWebFilterStore(db);
    _tempAllows = LocalWebFilterTempAllowStore(db);
    _delivery = WebFilterDeliveryTracker(db);
    _policyRepo = DomainWebFilterPolicyRepository(_store!, familyId: familyId);
    _capabilities = CapabilityRegistry(db);
    await _capabilities!.applyFs002EnfCapabilities();
    _opened = true;
  }

  static WebFilterPolicyRepository get policyRepository {
    final r = _policyRepo;
    if (r == null) {
      throw StateError('Call Stage1WebFilterRuntime.ensureOpen() first');
    }
    return r;
  }

  static LocalWebFilterStore get store {
    final s = _store;
    if (s == null) {
      throw StateError('Call Stage1WebFilterRuntime.ensureOpen() first');
    }
    return s;
  }

  static LocalWebFilterTempAllowStore get tempAllows {
    final t = _tempAllows;
    if (t == null) {
      throw StateError('Call Stage1WebFilterRuntime.ensureOpen() first');
    }
    return t;
  }

  static WebFilterDeliveryTracker get delivery {
    final d = _delivery;
    if (d == null) {
      throw StateError('Call Stage1WebFilterRuntime.ensureOpen() first');
    }
    return d;
  }

  static CapabilityRegistry get capabilities {
    final c = _capabilities;
    if (c == null) {
      throw StateError('Call Stage1WebFilterRuntime.ensureOpen() first');
    }
    return c;
  }

  /// Clears this runtime only — does not close [FsSessionKernel].
  static void resetForTest() {
    _opened = false;
    _store = null;
    _tempAllows = null;
    _delivery = null;
    _policyRepo = null;
    _capabilities = null;
  }
}
