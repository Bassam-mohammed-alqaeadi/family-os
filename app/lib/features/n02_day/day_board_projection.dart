import 'package:flutter/foundation.dart';

import 'package:family_os/features/education/learning_result_models.dart';
import 'package:family_os/features/education/learning_result_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/mock/register_mock_family.dart';

/// Load phase for SCR-FAT-010 dashboard projections (UI-004).
enum DayBoardPhase { loading, ready, error }

/// Pending inbox row projected onto the morning board (requests repo).
///
/// Prefer [titleKey]/[subtitleKey] (Rule 23). Legacy [title]/[subtitle] kept for
/// Register §10 mock fixture until those rows also use keys.
@immutable
final class DayBoardPendingRequest {
  const DayBoardPendingRequest({
    required this.id,
    this.title = '',
    this.subtitle = '',
    this.titleKey,
    this.subtitleKey,
    this.minutes,
    this.inboxPath = '/scr-fat-033',
  });

  final String id;
  final String title;
  final String subtitle;

  /// ARB discriminator when set (P15-EDU-008 learning results).
  final String? titleKey;
  final String? subtitleKey;
  final int? minutes;

  /// Real inbox route (FAT-033 time-request · FAT-050 learning results).
  final String inboxPath;
}

/// Dashboard projection for SCR-FAT-010 — binds cards to repos (UI-004).
///
/// Empty / one / many / offline / error are first-class. Widgets must not
/// plant child names or sample numerals when [children] is empty.
@immutable
final class DayBoardProjection {
  const DayBoardProjection({
    this.phase = DayBoardPhase.ready,
    this.children = const [],
    this.pendingRequests = const [],
    this.lastSyncLabel,
    this.offline = false,
    this.errorMessage,
  });

  final DayBoardPhase phase;
  final List<DayChildMock> children;
  final List<DayBoardPendingRequest> pendingRequests;

  /// Honest last-synced label when known; null → omit planted sync age.
  final String? lastSyncLabel;
  final bool offline;
  final String? errorMessage;

  static const empty = DayBoardProjection();
  static const loading = DayBoardProjection(phase: DayBoardPhase.loading);

  bool get hasChildren => children.isNotEmpty;
  bool get hasPending => pendingRequests.isNotEmpty;

  DayBoardPendingRequest? get primaryPending =>
      pendingRequests.isEmpty ? null : pendingRequests.first;

  DayBoardProjection copyWith({
    DayBoardPhase? phase,
    List<DayChildMock>? children,
    List<DayBoardPendingRequest>? pendingRequests,
    String? lastSyncLabel,
    bool? offline,
    String? errorMessage,
  }) {
    return DayBoardProjection(
      phase: phase ?? this.phase,
      children: children ?? this.children,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      lastSyncLabel: lastSyncLabel ?? this.lastSyncLabel,
      offline: offline ?? this.offline,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Rule 25 seam — dashboard projections from tasks/requests/alerts (Drift later).
abstract class DayBoardProjectionRepository {
  Future<DayBoardProjection> load();
}

/// In-memory mock — default empty family (never plants Khaled / sample numerals).
///
/// P15-EDU-008: merges live [LearningResultRepository] submissions into
/// [pendingRequests] so father day-board shows child quiz submit (P12).
final class InMemoryDayBoardProjectionRepository
    implements DayBoardProjectionRepository {
  InMemoryDayBoardProjectionRepository([
    DayBoardProjection projection = DayBoardProjection.empty,
    LearningResultRepository? results,
  ]) : _projection = projection,
       _results = results;

  DayBoardProjection _projection;
  final LearningResultRepository? _results;

  DayBoardProjection get current => _projection;

  void seed(DayBoardProjection projection) => _projection = projection;

  @override
  Future<DayBoardProjection> load() async {
    final results = _results;
    final live = results == null
        ? const <LearningResultSubmission>[]
        : await results.listRecent();
    if (live.isEmpty) return _projection;
    final learningPending = live
        .map(
          (s) => DayBoardPendingRequest(
            id: s.id,
            titleKey: 'quizSubmitted',
            subtitleKey: s.rewardMinutes.inMinutes > 0
                ? 'earnedMinutes'
                : 'justSubmitted',
            minutes: s.rewardMinutes.inMinutes > 0
                ? s.rewardMinutes.inMinutes
                : null,
            inboxPath: '/scr-fat-050',
          ),
        )
        .toList(growable: false);
    final seen = <String>{};
    final merged = <DayBoardPendingRequest>[];
    for (final p in [...learningPending, ..._projection.pendingRequests]) {
      if (seen.add(p.id)) merged.add(p);
    }
    return _projection.copyWith(pendingRequests: merged);
  }
}

/// Stage-1 singleton — seeded with Register §10 mock family for phone demos.
///
/// Empty branch remains testable via [InMemoryDayBoardProjectionRepository]
/// or [DayBoardScreen.projection]. Deleting `mock/` requires swapping this seed.
/// Live LearningResult submissions merge into pending (P15-EDU-008 · P12).
final stage1DayBoardProjectionRepository = InMemoryDayBoardProjectionRepository(
  RegisterMockFamily.dayBoardProjection,
  stage1LearningResultRepository,
);
