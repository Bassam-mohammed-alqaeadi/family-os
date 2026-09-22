import 'package:flutter/foundation.dart';

import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Load phase for SCR-FAT-010 dashboard projections (UI-004).
enum DayBoardPhase { loading, ready, error }

/// Pending inbox row projected onto the morning board (requests repo).
///
/// Titles/subtitles come from the repository — never planted in widgets.
@immutable
final class DayBoardPendingRequest {
  const DayBoardPendingRequest({
    required this.id,
    required this.title,
    required this.subtitle,
    this.inboxPath = '/scr-fat-033',
  });

  final String id;
  final String title;
  final String subtitle;

  /// Real inbox route (FAT-033 time-request inbox by default).
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
final class InMemoryDayBoardProjectionRepository
    implements DayBoardProjectionRepository {
  InMemoryDayBoardProjectionRepository([
    DayBoardProjection projection = DayBoardProjection.empty,
  ]) : _projection = projection;

  DayBoardProjection _projection;

  DayBoardProjection get current => _projection;

  void seed(DayBoardProjection projection) => _projection = projection;

  @override
  Future<DayBoardProjection> load() async => _projection;
}

/// Stage-1 singleton — empty until tests/repos seed events (Rule 23).
final stage1DayBoardProjectionRepository =
    InMemoryDayBoardProjectionRepository();
