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
    this.deliveredToServer,
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

  /// Whether this question actually reached the family's server.
  ///
  /// Null means nobody asked: a local-only repository, a fixture, or a build that never
  /// attempts delivery. False is a fact worth telling a child - the question is safe on
  /// this device and a parent has not seen it - and it is the difference between the two
  /// sentences the submit button may say.
  final bool? deliveredToServer;

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
    bool? deliveredToServer,
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
      deliveredToServer: deliveredToServer ?? this.deliveredToServer,
    );
  }
}
