import 'package:flutter/foundation.dart';

@immutable
final class FriendApprovalSnapshot {
  const FriendApprovalSnapshot({
    this.requestId,
    this.nameKey,
    this.schoolKey,
    this.childNameKey,
    this.allowText = true,
    this.allowCalls = true,
    this.scheduleLocked = true,
  });

  final String? requestId;
  final String? nameKey;
  final String? schoolKey;

  /// Child who sent the request — Rule 23 key.
  final String? childNameKey;
  final bool allowText;
  final bool allowCalls;
  final bool scheduleLocked;

  bool get isEmpty => requestId == null;

  FriendApprovalSnapshot copyWith({bool? allowText, bool? allowCalls}) {
    return FriendApprovalSnapshot(
      requestId: requestId,
      nameKey: nameKey,
      schoolKey: schoolKey,
      childNameKey: childNameKey,
      allowText: allowText ?? this.allowText,
      allowCalls: allowCalls ?? this.allowCalls,
      scheduleLocked: scheduleLocked,
    );
  }
}
