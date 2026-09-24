import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';

import 'app_control_disposition.dart';
import 'app_control_document.dart';
import 'app_control_exception.dart';
import 'app_control_install.dart';
import 'app_control_lock_now.dart';
import 'app_control_overlay_store.dart';
import 'app_control_protected.dart';
import 'app_control_repository.dart';
import 'app_control_store.dart';
import 'package_id.dart';

/// Actor for App Control decisions (Stage-1 role bridge).
@immutable
final class AppControlActor {
  const AppControlActor.father() : role = AppRole.father, motherLevel = null;

  const AppControlActor.mother(this.motherLevel) : role = AppRole.mother;

  /// Child never configures access or decides tickets.
  const AppControlActor.child() : role = AppRole.child, motherLevel = null;

  final AppRole role;
  final MotherLevel? motherLevel;

  /// Primary Parent (father) or Co-Parent Full — configure / Permanent Block.
  bool get canConfigure =>
      role == AppRole.father ||
      (role == AppRole.mother && motherLevel == MotherLevel.full);

  /// Primary only — reopen Permanent Block (APP-OD-04).
  bool get canReopenBlock => role == AppRole.father;

  /// Primary + Partner + Full — install / exception decide.
  bool get canDecideTickets =>
      role == AppRole.father ||
      (role == AppRole.mother &&
          (motherLevel == MotherLevel.partner ||
              motherLevel == MotherLevel.full));
}

/// Coordinates dispositions + overlays (FS-003-OWN).
final class AppControlService {
  AppControlService({
    required AppControlDomainRepository documents,
    required AppAccessExceptionRepository exceptions,
    required AppLockNowRepository lockNow,
    required AppInstallTicketRepository installs,
    required this.familyId,
    DateTime Function()? clock,
    String Function()? idFactory,
    Duration? exceptionDuration,
    Duration? lockNowDuration,
  }) : _documents = documents,
       _exceptions = exceptions,
       _lockNow = lockNow,
       _installs = installs,
       _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? _defaultId,
       _exceptionDuration =
           exceptionDuration ?? AppAccessExceptionDefaults.placeholderDuration,
       _lockNowDuration =
           lockNowDuration ?? AppLockNowDefaults.placeholderDuration;

  final AppControlDomainRepository _documents;
  final AppAccessExceptionRepository _exceptions;
  final AppLockNowRepository _lockNow;
  final AppInstallTicketRepository _installs;
  final FamilyId familyId;
  final DateTime Function() _clock;
  final String Function() _idFactory;
  final Duration _exceptionDuration;
  final Duration _lockNowDuration;

  static var _seq = 0;
  static String _defaultId() {
    _seq += 1;
    return 'ac-$_seq';
  }

  Future<AppControlDocument> loadEffective(ChildId childId) {
    return _documents.loadEffective(familyId, childId);
  }

  /// Set Permanent Block (Primary + Full). Protected packages rejected.
  Future<AppControlDocument> setPermanentBlock({
    required ChildId childId,
    required String packageId,
    required AppControlActor actor,
  }) async {
    if (!actor.canConfigure) {
      throw StateError('Actor cannot set Permanent Block');
    }
    final pkg = PackageId.normalize(packageId);
    if (ProtectedPackageIds.isProtected(pkg)) {
      throw StateError('Protected package cannot be permanently blocked');
    }
    return _upsertChildDisposition(childId, pkg, AppPackageDisposition.block);
  }

  /// Reopen Permanent Block — Primary only (APP-OD-04).
  Future<AppControlDocument> reopenPermanentBlock({
    required ChildId childId,
    required String packageId,
    required AppControlActor actor,
  }) async {
    if (!actor.canReopenBlock) {
      throw StateError('Only Primary may reopen Permanent Block');
    }
    return _upsertChildDisposition(
      childId,
      PackageId.normalize(packageId),
      AppPackageDisposition.allow,
    );
  }

  Future<AppControlDocument> setDisposition({
    required ChildId childId,
    required String packageId,
    required AppPackageDisposition disposition,
    required AppControlActor actor,
  }) async {
    if (!actor.canConfigure) {
      throw StateError('Actor cannot configure App Control');
    }
    final pkg = PackageId.normalize(packageId);
    if (ProtectedPackageIds.isProtected(pkg) &&
        disposition == AppPackageDisposition.block) {
      throw StateError('Protected package cannot be blocked');
    }
    return _upsertChildDisposition(childId, pkg, disposition);
  }

  Future<AppAccessException> requestException({
    required ChildId childId,
    required String packageId,
    String? note,
  }) async {
    final pkg = PackageId.normalize(packageId);
    if (ProtectedPackageIds.isProtected(pkg)) {
      throw StateError('Exception not needed for protected packages');
    }
    final ex = AppAccessException(
      id: _idFactory(),
      familyId: familyId,
      childId: childId,
      packageId: pkg,
      status: AppAccessExceptionStatus.pending,
      requestedAt: _clock().toUtc(),
      requestNote: note,
    );
    await _exceptions.save(ex);
    return ex;
  }

  Future<AppAccessException> approveException({
    required String exceptionId,
    required ChildId childId,
    required AppControlActor actor,
  }) async {
    if (!actor.canDecideTickets) {
      throw StateError('Actor cannot decide exceptions');
    }
    final list = await _exceptions.listForChild(familyId, childId);
    final found = list.where((e) => e.id == exceptionId).toList();
    if (found.isEmpty) throw StateError('Exception not found');
    final pending = found.first;
    if (pending.status != AppAccessExceptionStatus.pending) {
      throw StateError('Exception is not pending');
    }
    final now = _clock().toUtc();
    final active = AppAccessException(
      id: pending.id,
      familyId: pending.familyId,
      childId: pending.childId,
      packageId: pending.packageId,
      status: AppAccessExceptionStatus.active,
      requestedAt: pending.requestedAt,
      startsAt: now,
      expiresAt: now.add(_exceptionDuration),
      requestNote: pending.requestNote,
    );
    await _exceptions.save(active);
    return active;
  }

  Future<AppLockNowOverlay> lockNow({
    required ChildId childId,
    required String packageId,
    required AppControlActor actor,
  }) async {
    if (!actor.canConfigure) {
      throw StateError('Actor cannot Lock Now');
    }
    final pkg = PackageId.normalize(packageId);
    if (ProtectedPackageIds.isProtected(pkg)) {
      throw StateError('Protected package cannot Lock Now');
    }
    final now = _clock().toUtc();
    final overlay = AppLockNowOverlay(
      id: _idFactory(),
      familyId: familyId,
      childId: childId,
      packageId: pkg,
      status: AppLockNowStatus.active,
      startsAt: now,
      expiresAt: now.add(_lockNowDuration),
    );
    await _lockNow.save(overlay);
    return overlay;
  }

  Future<AppInstallTicket> observeInstall({
    required ChildId childId,
    required String packageId,
    String? label,
  }) async {
    final ticket = AppInstallTicket(
      id: _idFactory(),
      familyId: familyId,
      childId: childId,
      packageId: packageId,
      status: AppInstallDecisionStatus.pendingDecision,
      observedAt: _clock().toUtc(),
      labelSnapshot: label,
    );
    await _installs.save(ticket);
    return ticket;
  }

  /// Approve install → child-scoped Allow (APP-OD-18); never family-wide.
  Future<AppInstallTicket> approveInstall({
    required String ticketId,
    required ChildId childId,
    required AppControlActor actor,
  }) async {
    if (!actor.canDecideTickets) {
      throw StateError('Actor cannot decide installs');
    }
    final pending = await _installs.listPending(familyId, childId);
    final found = pending.where((t) => t.id == ticketId).toList();
    if (found.isEmpty) throw StateError('Install ticket not found');
    final ticket = found.first;
    await _upsertChildDisposition(
      childId,
      ticket.packageId,
      AppPackageDisposition.allow,
    );
    final decided = AppInstallTicket(
      id: ticket.id,
      familyId: ticket.familyId,
      childId: ticket.childId,
      packageId: ticket.packageId,
      status: AppInstallDecisionStatus.approved,
      observedAt: ticket.observedAt,
      labelSnapshot: ticket.labelSnapshot,
    );
    await _installs.save(decided);
    return decided;
  }

  Future<AppInstallTicket> denyInstall({
    required String ticketId,
    required ChildId childId,
    required AppControlActor actor,
  }) async {
    if (!actor.canDecideTickets) {
      throw StateError('Actor cannot decide installs');
    }
    final pending = await _installs.listPending(familyId, childId);
    final found = pending.where((t) => t.id == ticketId).toList();
    if (found.isEmpty) throw StateError('Install ticket not found');
    final ticket = found.first;
    await _upsertChildDisposition(
      childId,
      ticket.packageId,
      AppPackageDisposition.block,
    );
    final decided = AppInstallTicket(
      id: ticket.id,
      familyId: ticket.familyId,
      childId: ticket.childId,
      packageId: ticket.packageId,
      status: AppInstallDecisionStatus.denied,
      observedAt: ticket.observedAt,
      labelSnapshot: ticket.labelSnapshot,
    );
    await _installs.save(decided);
    return decided;
  }

  /// APP-OD-19: clears child override + temporary overlays.
  Future<void> restoreBaseline(ChildId childId) async {
    final store = _documents;
    if (store is LocalAppControlStore) {
      await store.restoreBaseline(
        familyId,
        childId,
        clearOverlays: () async {
          final ex = _exceptions;
          if (ex is LocalAppAccessExceptionStore) {
            await ex.clearForChild(familyId, childId);
          }
          final ln = _lockNow;
          if (ln is LocalAppLockNowStore) {
            await ln.clearForChild(familyId, childId);
          }
          final inst = _installs;
          if (inst is LocalAppInstallTicketStore) {
            await inst.clearPendingForChild(familyId, childId);
          }
        },
      );
    } else {
      await _documents.removeChildOverride(familyId, childId);
    }
  }

  Future<AppControlDocument> _upsertChildDisposition(
    ChildId childId,
    String packageId,
    AppPackageDisposition disposition,
  ) async {
    final existing = await _documents.loadChildOverride(familyId, childId);
    final base =
        existing ??
        AppControlDocument(
          familyId: familyId,
          scopeKind: AppControlScopeKind.childOverride,
          childId: childId,
          dispositions: const {},
        );
    final next = base.upsertDisposition(packageId, disposition);
    await _documents.save(next);
    return next;
  }
}
