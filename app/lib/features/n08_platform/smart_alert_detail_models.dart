import 'package:flutter/foundation.dart';

@immutable
final class SmartAlertDetailChange {
  const SmartAlertDetailChange({
    required this.id,
    required this.titleKey,
    required this.subtitleKey,
  });

  final String id;
  final String titleKey;
  final String subtitleKey;
}

@immutable
final class SmartAlertDetailSnapshot {
  const SmartAlertDetailSnapshot({
    this.alertId,
    this.titleKey = 'withdrawal',
    this.changes = const [],
    this.dialogueQuoteKey = 'walkTalk',
    this.dialogueHintKey = 'careNotInterrogate',
  });

  final String? alertId;
  final String titleKey;
  final List<SmartAlertDetailChange> changes;
  final String dialogueQuoteKey;
  final String dialogueHintKey;

  bool get isEmpty => alertId == null;
}
