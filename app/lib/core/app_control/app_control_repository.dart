import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'app_control_document.dart';
import 'app_control_exception.dart';
import 'app_control_install.dart';
import 'app_control_lock_now.dart';

/// Domain repository seam for App Control policy documents (Rule 25).
abstract class AppControlDomainRepository {
  Future<AppControlDocument?> loadFamilyBaseline(FamilyId familyId);

  Future<AppControlDocument?> loadChildOverride(
    FamilyId familyId,
    ChildId childId,
  );

  Future<AppControlDocument> loadEffective(FamilyId familyId, ChildId childId);

  Future<void> save(AppControlDocument document);

  Future<void> removeChildOverride(FamilyId familyId, ChildId childId);
}

/// Overlay stores for exception / Lock Now / install tickets.
abstract class AppAccessExceptionRepository {
  Future<void> save(AppAccessException exception);
  Future<List<AppAccessException>> listForChild(
    FamilyId familyId,
    ChildId childId,
  );
  Future<Set<String>> activePackageIds(
    FamilyId familyId,
    ChildId childId,
    DateTime now,
  );
}

abstract class AppLockNowRepository {
  Future<void> save(AppLockNowOverlay overlay);
  Future<List<AppLockNowOverlay>> listForChild(
    FamilyId familyId,
    ChildId childId,
  );
  Future<Set<String>> activePackageIds(
    FamilyId familyId,
    ChildId childId,
    DateTime now,
  );
}

abstract class AppInstallTicketRepository {
  Future<void> save(AppInstallTicket ticket);
  Future<List<AppInstallTicket>> listPending(
    FamilyId familyId,
    ChildId childId,
  );
  Future<bool> isPending(FamilyId familyId, ChildId childId, String packageId);
}
