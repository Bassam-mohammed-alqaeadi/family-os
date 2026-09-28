import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';

/// DOM-ST-02C — single production TimeRequest/TimeGrant authority on Local KV.
///
/// Call [ensureOpen] before reading [service] / [repository]. Explicit inject
/// seams on screens remain for tests. Does not use [stage1TimeRequestPrefsStore].
abstract final class Stage1TimeRequestRuntime {
  Stage1TimeRequestRuntime._();

  static TimeRequestRepository? _repository;
  static TimeRequestService? _service;
  static var _opened = false;

  /// Opens FsSessionKernel + Local KV (`st_time`); refuses Memory fallback.
  static Future<TimeRequestService> ensureOpen() async {
    if (_opened && _service != null && _repository != null) {
      return _service!;
    }
    final repo = await ScreenTimeLocalPersistence.openTimeRequestRepository();
    _repository = repo;
    _service = TimeRequestService(
      repository: repo,
      decisionBus: stage1TimeRequestDecisionBus,
    );
    _opened = true;
    return _service!;
  }

  static TimeRequestService get service {
    final s = _service;
    if (s == null) {
      throw StateError('Call Stage1TimeRequestRuntime.ensureOpen() first');
    }
    return s;
  }

  static TimeRequestRepository get repository {
    final r = _repository;
    if (r == null) {
      throw StateError('Call Stage1TimeRequestRuntime.ensureOpen() first');
    }
    return r;
  }

  /// Clears this runtime only — does not close [FsSessionKernel].
  static void resetForTest() {
    _opened = false;
    _service?.dispose();
    _service = null;
    _repository = null;
  }
}
