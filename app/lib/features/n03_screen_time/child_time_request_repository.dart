import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_models.dart';
import 'package:family_os/features/n03_screen_time/stage1_child_scope.dart';

abstract class ChildTimeRequestRepository {
  Future<ChildTimeRequestSnapshot> load();
  Future<ChildTimeRequestSnapshot> selectMinutes(int minutes);
  Future<ChildTimeRequestSnapshot> selectTrade(String tradeKey);
  Future<ChildTimeRequestSnapshot> submit();
}

/// Stage-1 fallback childId for compatibility only.
final ChildId kStage1TimeRequestChildId = activeScopedChildId();

/// Shared Stage-1 service (same prefs + decision bus as FAT-033 inbox).
final TimeRequestService stage1TimeRequestService = TimeRequestService(
  repository: PrefsTimeRequestRepository(stage1TimeRequestPrefsStore),
  decisionBus: stage1TimeRequestDecisionBus,
);

/// Wires CHD-020 → [TimeRequestService] (G-A Temporary Grant, not WalletLedger).
final class ServiceChildTimeRequestRepository
    implements ChildTimeRequestRepository {
  ServiceChildTimeRequestRepository({
    required TimeRequestService service,
    TimeRequestRepository? repository,
    ChildId? childId,
  }) : _service = service,
       _repo =
           repository ??
           PrefsTimeRequestRepository(stage1TimeRequestPrefsStore),
       _childId = childId ?? activeScopedChildId();

  final TimeRequestService _service;
  final TimeRequestRepository _repo;
  final ChildId _childId;

  ChildTimeRequestSnapshot _form = const ChildTimeRequestSnapshot();

  @override
  Future<ChildTimeRequestSnapshot> load() async {
    await _service.expireStaleRequests();
    final all = await _repo.loadAll();
    final forChild = all.where((r) => r.childId == _childId).toList();

    TimeRequest? pending;
    for (final r in forChild) {
      if (r.isPending) {
        pending = r;
        break;
      }
    }
    if (pending != null) {
      _form = _form.copyWith(
        status: ChildTimeRequestStatus.pending,
        requestedMinutes: pending.requestedMinutes,
        selectedMinutes: pending.requestedMinutes,
        formLocked: true,
        clearGrantedMinutes: true,
        clearDecisionReason: true,
        clearSubmitError: true,
      );
      return _form.copyWith();
    }

    final bus = _service.decisionBus.lastDecision;
    if (bus != null && bus.childId == _childId) {
      _form = _mapDecision(bus);
      return _form.copyWith();
    }

    TimeRequest? latest;
    for (final r in forChild) {
      if (latest == null || r.createdAt.isAfter(latest.createdAt)) {
        latest = r;
      }
    }
    if (latest != null) {
      _form = _mapDecision(latest);
      return _form.copyWith();
    }

    _form = _form.copyWith(
      status: ChildTimeRequestStatus.none,
      formLocked: false,
      clearGrantedMinutes: true,
      clearDecisionReason: true,
      clearSubmitError: true,
    );
    return _form.copyWith();
  }

  ChildTimeRequestSnapshot _mapDecision(TimeRequest r) {
    final status = switch (r.status) {
      TimeRequestStatus.pending => ChildTimeRequestStatus.pending,
      TimeRequestStatus.approved => ChildTimeRequestStatus.approved,
      TimeRequestStatus.rejected => ChildTimeRequestStatus.rejected,
      TimeRequestStatus.expired => ChildTimeRequestStatus.expired,
    };
    return _form.copyWith(
      status: status,
      requestedMinutes: r.requestedMinutes,
      grantedMinutes: r.grantedMinutes,
      decisionReason: r.decisionReason,
      formLocked: status == ChildTimeRequestStatus.pending,
      clearSubmitError: true,
      clearGrantedMinutes: r.grantedMinutes == null,
      clearDecisionReason: r.decisionReason == null,
    );
  }

  @override
  Future<ChildTimeRequestSnapshot> selectMinutes(int minutes) async {
    if (_form.formLocked) return _form.copyWith();
    _form = _form.copyWith(selectedMinutes: minutes, clearSubmitError: true);
    return _form.copyWith();
  }

  @override
  Future<ChildTimeRequestSnapshot> selectTrade(String tradeKey) async {
    if (_form.formLocked) return _form.copyWith();
    _form = _form.copyWith(tradeKey: tradeKey, clearSubmitError: true);
    return _form.copyWith();
  }

  @override
  Future<ChildTimeRequestSnapshot> submit() async {
    if (_form.formLocked) {
      return _form.copyWith(submitErrorKey: 'duplicatePending');
    }
    try {
      final created = await _service.createRequest(
        childId: _childId,
        requestedMinutes: _form.selectedMinutes,
        childReason: _composeReason(),
      );
      _form = _form.copyWith(
        status: ChildTimeRequestStatus.pending,
        requestedMinutes: created.requestedMinutes,
        formLocked: true,
        clearGrantedMinutes: true,
        clearDecisionReason: true,
        clearSubmitError: true,
      );
      return _form.copyWith();
    } on TimeRequestNotAllowedException {
      _form = _form.copyWith(
        status: ChildTimeRequestStatus.pending,
        formLocked: true,
        submitErrorKey: 'duplicatePending',
      );
      return _form.copyWith();
    }
  }

  String _composeReason() {
    return 'reason:${_form.reasonKey};trade:${_form.tradeKey}';
  }

  void seedForm(ChildTimeRequestSnapshot snap) => _form = snap;
}

/// In-memory fake for widget tests (Rule 25 alternate).
final class InMemoryChildTimeRequestRepository
    implements ChildTimeRequestRepository {
  InMemoryChildTimeRequestRepository({ChildTimeRequestSnapshot? seed})
    : _snap = seed ?? childTimeRequestPrototypeFixture();

  ChildTimeRequestSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildTimeRequestSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<ChildTimeRequestSnapshot> selectMinutes(int minutes) async {
    if (_snap.formLocked) return _snap.copyWith();
    _snap = _snap.copyWith(selectedMinutes: minutes);
    return _snap.copyWith();
  }

  @override
  Future<ChildTimeRequestSnapshot> selectTrade(String tradeKey) async {
    if (_snap.formLocked) return _snap.copyWith();
    _snap = _snap.copyWith(tradeKey: tradeKey);
    return _snap.copyWith();
  }

  @override
  Future<ChildTimeRequestSnapshot> submit() async {
    if (_snap.formLocked || _snap.status == ChildTimeRequestStatus.pending) {
      _snap = _snap.copyWith(
        formLocked: true,
        submitErrorKey: 'duplicatePending',
      );
      return _snap.copyWith();
    }
    _snap = _snap.copyWith(
      status: ChildTimeRequestStatus.pending,
      requestedMinutes: _snap.selectedMinutes,
      formLocked: true,
      clearSubmitError: true,
    );
    return _snap.copyWith();
  }

  void seed(ChildTimeRequestSnapshot snap) => _snap = snap;
}

final ChildTimeRequestRepository stage1ChildTimeRequestRepository =
    ServiceChildTimeRequestRepository(service: stage1TimeRequestService);

ChildTimeRequestSnapshot childTimeRequestEmptyFixture() =>
    const ChildTimeRequestSnapshot(formAvailable: false);

ChildTimeRequestSnapshot childTimeRequestOneFixture() =>
    const ChildTimeRequestSnapshot(
      status: ChildTimeRequestStatus.none,
      selectedMinutes: 30,
    );

ChildTimeRequestSnapshot childTimeRequestPrototypeFixture() =>
    const ChildTimeRequestSnapshot(
      status: ChildTimeRequestStatus.pending,
      requestedMinutes: 30,
      selectedMinutes: 30,
      reasonKey: 'finishedHomework',
      tradeKey: 'wirdMulk',
      formLocked: true,
    );

ChildTimeRequestSnapshot childTimeRequestTaskedFixture() =>
    const ChildTimeRequestSnapshot(
      status: ChildTimeRequestStatus.tasked,
      requestedMinutes: 30,
      taskTitleKey: 'tidyDesk',
      taskMins: 20,
    );
