import 'package:flutter/foundation.dart';

/// Family wipe lifecycle job (SET-013). Execution is deferred by regret window.
enum WipeJobStatus { pending, cancelled, executed }

@immutable
final class WipeJob {
  const WipeJob({
    required this.id,
    required this.requestedAt,
    required this.pendingUntil,
    required this.status,
    required this.requestedBy,
  });

  final String id;
  final DateTime requestedAt;

  /// End of 7-day regret window — cancel allowed while now < pendingUntil
  /// and status == pending.
  final DateTime pendingUntil;
  final WipeJobStatus status;

  /// Actor label (e.g. father).
  final String requestedBy;

  static const regretDays = 7;

  bool isCancellableAt(DateTime now) =>
      status == WipeJobStatus.pending && now.isBefore(pendingUntil);

  WipeJob copyWith({
    String? id,
    DateTime? requestedAt,
    DateTime? pendingUntil,
    WipeJobStatus? status,
    String? requestedBy,
  }) {
    return WipeJob(
      id: id ?? this.id,
      requestedAt: requestedAt ?? this.requestedAt,
      pendingUntil: pendingUntil ?? this.pendingUntil,
      status: status ?? this.status,
      requestedBy: requestedBy ?? this.requestedBy,
    );
  }

  /// Schedules a new pending wipe with a 7-day regret window from [now].
  factory WipeJob.schedule({
    required String id,
    required DateTime now,
    required String requestedBy,
  }) {
    return WipeJob(
      id: id,
      requestedAt: now.toUtc(),
      pendingUntil: now.toUtc().add(const Duration(days: regretDays)),
      status: WipeJobStatus.pending,
      requestedBy: requestedBy,
    );
  }
}
