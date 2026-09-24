import 'package:flutter/foundation.dart';

enum ChildTimeRequestStatus {
  none,
  pending,
  approved,
  tasked,
  rejected,
  expired,
}

@immutable
final class ChildTimeRequestSnapshot {
  const ChildTimeRequestSnapshot({
    this.status = ChildTimeRequestStatus.none,
    this.requestedMinutes = 30,
    this.grantedMinutes,
    this.taskTitleKey,
    this.taskMins,
    this.selectedMinutes = 30,
    this.reasonKey = 'finishedHomework',
    this.tradeKey = 'wirdMulk',
    this.formAvailable = true,
    this.formLocked = false,
    this.decisionReason,
    this.submitErrorKey,
  });

  final ChildTimeRequestStatus status;
  final int requestedMinutes;
  final int? grantedMinutes;
  final String? taskTitleKey;
  final int? taskMins;
  final int selectedMinutes;
  final String reasonKey;
  final String tradeKey;
  final bool formAvailable;

  /// True when a pending request already exists (ST-OD-006) — UI stays locked.
  final bool formLocked;

  /// Parent reject / approve note from [TimeRequestDecisionBus].
  final String? decisionReason;

  /// ARB-facing error key, e.g. `duplicatePending`.
  final String? submitErrorKey;

  bool get isEmpty => !formAvailable;

  ChildTimeRequestSnapshot copyWith({
    ChildTimeRequestStatus? status,
    int? requestedMinutes,
    int? grantedMinutes,
    String? taskTitleKey,
    int? taskMins,
    int? selectedMinutes,
    String? reasonKey,
    String? tradeKey,
    bool? formAvailable,
    bool? formLocked,
    String? decisionReason,
    String? submitErrorKey,
    bool clearGrantedMinutes = false,
    bool clearDecisionReason = false,
    bool clearSubmitError = false,
  }) {
    return ChildTimeRequestSnapshot(
      status: status ?? this.status,
      requestedMinutes: requestedMinutes ?? this.requestedMinutes,
      grantedMinutes: clearGrantedMinutes
          ? null
          : (grantedMinutes ?? this.grantedMinutes),
      taskTitleKey: taskTitleKey ?? this.taskTitleKey,
      taskMins: taskMins ?? this.taskMins,
      selectedMinutes: selectedMinutes ?? this.selectedMinutes,
      reasonKey: reasonKey ?? this.reasonKey,
      tradeKey: tradeKey ?? this.tradeKey,
      formAvailable: formAvailable ?? this.formAvailable,
      formLocked: formLocked ?? this.formLocked,
      decisionReason: clearDecisionReason
          ? null
          : (decisionReason ?? this.decisionReason),
      submitErrorKey: clearSubmitError
          ? null
          : (submitErrorKey ?? this.submitErrorKey),
    );
  }
}
