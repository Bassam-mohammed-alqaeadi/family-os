import 'package:flutter/foundation.dart';

import 'package:family_os/core/app_control/app_control_install.dart';
import 'package:family_os/core/app_control/app_control_runtime.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/features/education/learning_result_models.dart';
import 'package:family_os/features/education/learning_result_repository.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n02_day/outer_circle_models.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_repository.dart';
import 'package:family_os/features/quran/quran_local_bridge.dart';

/// Load phase for SCR-FAT-010 dashboard projections (UI-004).
enum DayBoardPhase { loading, ready, error }

/// Importance kind for the FAT-010 live-event ladder (prototype density).
///
/// Lower [ladderRank] = higher urgency. SOS/lock/arrival reserved for real
/// producers — never plant sample rows.
enum DayBoardPendingKind {
  sos,
  lockAsk,
  arrival,
  friend,
  time,
  app,
  learning,
  athkar,
  other,
}

extension DayBoardPendingKindX on DayBoardPendingKind {
  int get ladderRank => index;
}

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
    this.kind = DayBoardPendingKind.other,
  });

  final String id;
  final String title;
  final String subtitle;

  /// ARB discriminator when set (P15-EDU-008 learning results · VX-B5 pending).
  final String? titleKey;
  final String? subtitleKey;
  final int? minutes;

  /// Real inbox route (FAT-033 time · FAT-035 app · FAT-071 friend · FAT-050 · FAT-072).
  final String inboxPath;

  /// Ladder urgency — set by producers; UI sorts via [DayBoardProjection.importanceLadder].
  final DayBoardPendingKind kind;
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
    this.localDemoSeeded = false,
  });

  final DayBoardPhase phase;
  final List<DayChildMock> children;
  final List<DayBoardPendingRequest> pendingRequests;

  /// Honest last-synced label when known; null → local-save honesty line in UI.
  final String? lastSyncLabel;
  final bool offline;
  final String? errorMessage;

  /// True when roster provenance is `LOCAL_DEMO_SEEDED` (Identity-B).
  final bool localDemoSeeded;

  static const empty = DayBoardProjection();
  static const loading = DayBoardProjection(phase: DayBoardPhase.loading);

  bool get hasChildren => children.isNotEmpty;
  bool get hasPending => pendingRequests.isNotEmpty;

  /// Sorted by [DayBoardPendingKind.ladderRank], stable within the same kind.
  List<DayBoardPendingRequest> get importanceLadder {
    if (pendingRequests.isEmpty) return const [];
    final indexed = pendingRequests.asMap().entries.toList(growable: false);
    indexed.sort((a, b) {
      final byKind = a.value.kind.ladderRank.compareTo(b.value.kind.ladderRank);
      if (byKind != 0) return byKind;
      return a.key.compareTo(b.key);
    });
    return [for (final e in indexed) e.value];
  }

  DayBoardPendingRequest? get primaryPending {
    final ladder = importanceLadder;
    return ladder.isEmpty ? null : ladder.first;
  }

  DayBoardProjection copyWith({
    DayBoardPhase? phase,
    List<DayChildMock>? children,
    List<DayBoardPendingRequest>? pendingRequests,
    String? lastSyncLabel,
    bool? offline,
    String? errorMessage,
    bool? localDemoSeeded,
  }) {
    return DayBoardProjection(
      phase: phase ?? this.phase,
      children: children ?? this.children,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      lastSyncLabel: lastSyncLabel ?? this.lastSyncLabel,
      offline: offline ?? this.offline,
      errorMessage: errorMessage ?? this.errorMessage,
      localDemoSeeded: localDemoSeeded ?? this.localDemoSeeded,
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
            kind: DayBoardPendingKind.learning,
          ),
        )
        .toList(growable: false);
    final athkarPending = _athkarPendingRows();
    final seen = <String>{};
    final merged = <DayBoardPendingRequest>[];
    for (final p in [
      ...athkarPending,
      ...learningPending,
      ..._projection.pendingRequests,
    ]) {
      if (seen.add(p.id)) merged.add(p);
    }
    return _projection.copyWith(pendingRequests: merged);
  }
}

/// Unbound Quran / wallet axes — not planted demo numerals (Rule 23 honesty).
const String kDayBoardUnboundStat = '—';

/// Maps Identity Local roster rows → day-board child cards.
///
/// LDR-B1: roster identity fields only — location/battery/time-left empty
/// unless filled by a real local producer later (never fake GPS/OS telemetry).
DayChildMock dayChildFromRosterEntry(ChildrenListEntry entry) {
  return DayChildMock(
    id: entry.id,
    displayName: entry.displayName,
    emoji: entry.emoji,
    swatch: entry.swatch,
    ageYears: entry.ageYears,
    locationLabel: entry.locationLabel,
    batteryLabel: entry.batteryLabel,
    timeLeftLabel: entry.timeLeftLabel,
    quranLabel: kDayBoardUnboundStat,
    walletLabel: kDayBoardUnboundStat,
  );
}

List<DayBoardPendingRequest> _athkarPendingRows() {
  return stage1QuranLocalBridge.athkarBlessings
      .asMap()
      .entries
      .map(
        (e) => DayBoardPendingRequest(
          id: 'athkar-${e.key}',
          titleKey: 'athkarBlessing',
          subtitleKey: 'athkarDone',
          // FVX-S-03: parent surface — never route father to CHD-027.
          inboxPath: '/scr-fat-072',
          kind: DayBoardPendingKind.athkar,
        ),
      )
      .toList(growable: false);
}

List<DayBoardPendingRequest> _timeRequestPendingRows(
  List<TimeRequest> pending,
) {
  return [
    for (final r in pending)
      DayBoardPendingRequest(
        id: 'tr-${r.id}',
        titleKey: 'timeRequest',
        subtitleKey: 'timeRequestWaiting',
        minutes: r.requestedMinutes,
        inboxPath: '/scr-fat-033',
        kind: DayBoardPendingKind.time,
      ),
  ];
}

List<DayBoardPendingRequest> _friendPendingRows(OuterCircleSnapshot snap) {
  return [
    for (final m in snap.pending)
      DayBoardPendingRequest(
        id: 'friend-${m.id}',
        titleKey: 'friendRequest',
        subtitleKey: 'friendRequestWaiting',
        inboxPath: '/scr-fat-071',
        kind: DayBoardPendingKind.friend,
      ),
  ];
}

List<DayBoardPendingRequest> _appInstallPendingRows(
  List<AppInstallTicket> tickets,
) {
  return [
    for (final t in tickets)
      if (t.status == AppInstallDecisionStatus.pendingDecision)
        DayBoardPendingRequest(
          id: 'app-${t.id}',
          titleKey: 'appApproval',
          subtitleKey: 'appApprovalWaiting',
          inboxPath:
              '/scr-fat-035?childId=${Uri.encodeQueryComponent(t.childId.value)}',
          kind: DayBoardPendingKind.app,
        ),
  ];
}

/// Day board projection bound to [ChildrenListRepository] (FAT-010 ↔ FAT-012).
///
/// VX-B5 / FVX-S-03: merges time-request, app-install, and friend-approval
/// pending rows ahead of learning/athkar. Athkar opens parent Quran (FAT-072).
final class RosterDayBoardProjectionRepository
    implements DayBoardProjectionRepository {
  RosterDayBoardProjectionRepository({
    ChildrenListRepository? children,
    LearningResultRepository? results,
    FamilyId Function()? familyId,
    Future<List<TimeRequest>> Function()? listTimePending,
    OuterCircleRepository? outerCircle,
    Future<List<AppInstallTicket>> Function()? listAppInstallPending,
  }) : _children = children,
       _results = results,
       _familyId = familyId,
       _listTimePending = listTimePending,
       _outerCircle = outerCircle,
       _listAppInstallPending = listAppInstallPending;

  final ChildrenListRepository? _children;
  final LearningResultRepository? _results;
  final FamilyId Function()? _familyId;
  final Future<List<TimeRequest>> Function()? _listTimePending;
  final OuterCircleRepository? _outerCircle;
  final Future<List<AppInstallTicket>> Function()? _listAppInstallPending;

  ChildrenListRepository get _roster =>
      _children ?? stage1ChildrenListRepository;

  LearningResultRepository? get _learning =>
      _results ?? stage1LearningResultRepository;

  FamilyId get _activeFamily =>
      _familyId?.call() ?? ChildrenListLocalSeed.famStage1;

  Future<List<TimeRequest>> _timePending() async {
    final inject = _listTimePending;
    if (inject != null) return inject();
    try {
      return await stage1TimeRequestService.listPending();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AppInstallTicket>> _appPending(List<DayChildMock> kids) async {
    final inject = _listAppInstallPending;
    if (inject != null) return inject();
    try {
      await Stage1AppControlRuntime.ensureOpen();
      final service = Stage1AppControlRuntime.service;
      final out = <AppInstallTicket>[];
      for (final kid in kids) {
        final rows = await service.listPendingInstalls(ChildId(kid.id));
        out.addAll(rows);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<DayBoardProjection> load() async {
    final kids = await _roster.listChildren(familyId: _activeFamily);
    final mapped = kids.map(dayChildFromRosterEntry).toList(growable: false);

    final results = _learning;
    final live = results == null
        ? const <LearningResultSubmission>[]
        : await results.listRecent();
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
            kind: DayBoardPendingKind.learning,
          ),
        )
        .toList(growable: false);

    final provenance = await _roster.loadProvenance(familyId: _activeFamily);

    final timePending = _timeRequestPendingRows(await _timePending());
    OuterCircleSnapshot circle;
    try {
      circle = await (_outerCircle ?? stage1OuterCircleRepository).load();
    } catch (_) {
      circle = const OuterCircleSnapshot();
    }
    final friendPending = _friendPendingRows(circle);
    final appPending = _appInstallPendingRows(await _appPending(mapped));
    final athkarPending = _athkarPendingRows();

    // Most time-sensitive first (FVX-S-03).
    final seen = <String>{};
    final merged = <DayBoardPendingRequest>[];
    for (final p in [
      ...timePending,
      ...appPending,
      ...friendPending,
      ...learningPending,
      ...athkarPending,
    ]) {
      if (seen.add(p.id)) merged.add(p);
    }

    return DayBoardProjection(
      phase: DayBoardPhase.ready,
      children: mapped,
      pendingRequests: merged,
      // Honesty line rendered in UI via dayBoardLocalSaveLine (FVX-S-03).
      lastSyncLabel: null,
      offline: false,
      localDemoSeeded: isChildrenListSeededProvenance(provenance),
    );
  }
}

/// Stage-1 singleton — Identity Local roster (DOM-IDENTITY-B), not Register §10.
///
/// Empty when roster unbound/empty. After `tryBindStage1ChildrenList`, cards
/// use roster child ids. Register mock remains in `mock/` for demos/tests only.
final DayBoardProjectionRepository stage1DayBoardProjectionRepository =
    RosterDayBoardProjectionRepository();
