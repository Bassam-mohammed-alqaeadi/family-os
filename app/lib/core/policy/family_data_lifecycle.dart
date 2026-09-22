import 'package:flutter/foundation.dart';

import '../domain/role.dart';
import 'advisor_memory_store.dart';
import 'chat_mock_store.dart';
import 'web_unlock_service.dart' show AuditAppend;
import 'wipe_job.dart';

/// Owner-only forget / wipe (Rule 8 / SET-013 / R10).
bool canRunFamilyDataLifecycle(AppRole role) => role == AppRole.father;

@immutable
final class FamilyDataLifecycleDenied {
  const FamilyDataLifecycleDenied({
    required this.actor,
    this.statusCode = 403,
    this.message = 'FAMILY_DATA_LIFECYCLE denied',
  });

  final AppRole actor;
  final int statusCode;
  final String message;

  @override
  String toString() =>
      'FamilyDataLifecycleDenied($statusCode): $message actor=${actor.name}';
}

@immutable
sealed class ForgetResult {
  const ForgetResult();
}

final class ForgetOk extends ForgetResult {
  const ForgetOk();
}

final class ForgetDenied extends ForgetResult {
  const ForgetDenied(this.denied);
  final FamilyDataLifecycleDenied denied;
}

@immutable
sealed class WipeScheduleResult {
  const WipeScheduleResult();
}

final class WipeScheduleOk extends WipeScheduleResult {
  const WipeScheduleOk(this.job);
  final WipeJob job;
}

final class WipeScheduleDenied extends WipeScheduleResult {
  const WipeScheduleDenied(this.denied);
  final FamilyDataLifecycleDenied denied;
}

final class WipeAlreadyPending extends WipeScheduleResult {
  const WipeAlreadyPending(this.job);
  final WipeJob job;
}

@immutable
sealed class WipeCancelResult {
  const WipeCancelResult();
}

final class WipeCancelOk extends WipeCancelResult {
  const WipeCancelOk(this.job);
  final WipeJob job;
}

final class WipeCancelDenied extends WipeCancelResult {
  const WipeCancelDenied(this.denied);
  final FamilyDataLifecycleDenied denied;
}

final class WipeCancelNone extends WipeCancelResult {
  const WipeCancelNone();
}

final class WipeCancelWindowExpired extends WipeCancelResult {
  const WipeCancelWindowExpired(this.job);
  final WipeJob job;
}

/// SET-013 forget ≠ wipe lifecycle (mock-first, Rule 25 seam).
///
/// - Forget → clears [AdvisorMemoryStore] only; chat + audit untouched (R10).
/// - Wipe → two-step UI schedules [WipeJob] with 7-day regret; audit append
///   immediately; cancel within window restores (no data destroyed yet).
final class FamilyDataLifecycleService extends ChangeNotifier {
  FamilyDataLifecycleService({
    AdvisorMemoryStore? memory,
    ChatMockStore? chat,
    AuditAppend? audit,
    WipeJob? initialJob,
    DateTime Function()? clock,
    String Function()? idFactory,
  })  : _memory = memory ?? MemoryAdvisorMemoryStore(),
        _chat = chat ?? MemoryChatMockStore(),
        _audit = audit ?? AuditAppend(),
        _job = initialJob,
        _clock = clock ?? DateTime.now,
        _idFactory = idFactory ?? _defaultWipeId;

  static String _defaultWipeId() =>
      'wipe-${DateTime.now().toUtc().microsecondsSinceEpoch}';

  final AdvisorMemoryStore _memory;
  final ChatMockStore _chat;
  final AuditAppend _audit;
  final DateTime Function() _clock;
  final String Function() _idFactory;
  WipeJob? _job;

  AdvisorMemoryStore get memory => _memory;
  ChatMockStore get chat => _chat;
  AuditAppend get audit => _audit;
  WipeJob? get pendingWipe =>
      _job?.status == WipeJobStatus.pending ? _job : null;
  WipeJob? get wipeJob => _job;

  /// Clears advisor memory only. Never touches chat or audit entries.
  Future<ForgetResult> forgetAdvisorMemory({required AppRole actor}) async {
    if (!canRunFamilyDataLifecycle(actor)) {
      _audit.add(
        '403 ADVISOR_FORGET denied actor=${actor.name}',
      );
      return ForgetDenied(
        FamilyDataLifecycleDenied(actor: actor, message: 'ADVISOR_FORGET denied'),
      );
    }
    await _memory.clear();
    notifyListeners();
    return const ForgetOk();
  }

  /// Schedules wipe with 7-day regret window and appends audit immediately.
  Future<WipeScheduleResult> scheduleWipe({required AppRole actor}) async {
    if (!canRunFamilyDataLifecycle(actor)) {
      _audit.add(
        '403 FAMILY_WIPE schedule denied actor=${actor.name}',
      );
      return WipeScheduleDenied(
        FamilyDataLifecycleDenied(
          actor: actor,
          message: 'FAMILY_WIPE schedule denied',
        ),
      );
    }
    final existing = pendingWipe;
    if (existing != null) {
      return WipeAlreadyPending(existing);
    }

    final now = _clock().toUtc();
    final job = WipeJob.schedule(
      id: _idFactory(),
      now: now,
      requestedBy: actor.name,
    );
    _job = job;
    _audit.add(
      'FAMILY_WIPE_REQUESTED id=${job.id} actor=${actor.name} '
      'pendingUntil=${job.pendingUntil.toIso8601String()}',
    );
    notifyListeners();
    return WipeScheduleOk(job);
  }

  /// Cancels pending wipe within the 7-day regret window.
  Future<WipeCancelResult> cancelWipe({required AppRole actor}) async {
    if (!canRunFamilyDataLifecycle(actor)) {
      _audit.add(
        '403 FAMILY_WIPE cancel denied actor=${actor.name}',
      );
      return WipeCancelDenied(
        FamilyDataLifecycleDenied(
          actor: actor,
          message: 'FAMILY_WIPE cancel denied',
        ),
      );
    }
    final job = _job;
    if (job == null || job.status != WipeJobStatus.pending) {
      return const WipeCancelNone();
    }
    final now = _clock().toUtc();
    if (!job.isCancellableAt(now)) {
      return WipeCancelWindowExpired(job);
    }
    final cancelled = job.copyWith(status: WipeJobStatus.cancelled);
    _job = cancelled;
    _audit.add(
      'FAMILY_WIPE_CANCELLED id=${cancelled.id} actor=${actor.name}',
    );
    notifyListeners();
    return WipeCancelOk(cancelled);
  }
}

/// Stage-1 shared lifecycle service.
final FamilyDataLifecycleService stage1FamilyDataLifecycle =
    FamilyDataLifecycleService(
  memory: stage1AdvisorMemoryStore,
  chat: stage1ChatMockStore,
);
