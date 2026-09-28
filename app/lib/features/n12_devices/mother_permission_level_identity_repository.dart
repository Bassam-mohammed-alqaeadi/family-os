import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n12_devices/mother_permission_level_repository.dart';

/// Stage-1 default mother membership id (createStage1IdentityRuntime).
const String kStage1MotherMembershipId = 'mem_stage1_mother';

/// Mother level repo bound to [IdentityRuntime] (FE-W1-FAT-031).
///
/// Audit log remains local in-memory (append-only UI). Level authority is
/// Identity — FAT-027 mother tag reflects changes after save.
final class IdentityMotherPermissionLevelRepository
    extends MotherPermissionLevelRepository {
  IdentityMotherPermissionLevelRepository({
    IdentityRuntime Function()? runtime,
    MemberId? membershipId,
    DateTime Function()? clock,
  }) : _runtime = runtime ?? (() => stage1IdentityRuntime),
       _membershipId =
           membershipId ?? MemberId(kStage1MotherMembershipId),
       _clock = clock ?? DateTime.now;

  final IdentityRuntime Function() _runtime;
  final MemberId _membershipId;
  final DateTime Function() _clock;
  final List<MotherLevelAuditEntry> _audit = [];

  @override
  MotherLevel get level =>
      _runtime().motherPermissionLevel(_membershipId) ?? MotherLevel.partner;

  @override
  List<MotherLevelAuditEntry> get auditLog => List.unmodifiable(_audit);

  @override
  bool setLevel(MotherLevel next, {DateTime? at}) {
    final previous = level;
    if (next == previous) return false;
    final ok = _runtime().setMotherPermissionLevel(
      membershipId: _membershipId,
      level: next,
    );
    if (!ok) return false;
    _audit.insert(
      0,
      MotherLevelAuditEntry(
        from: previous,
        to: next,
        at: at ?? _clock(),
        motherNotified: true,
      ),
    );
    notifyListeners();
    return true;
  }
}
