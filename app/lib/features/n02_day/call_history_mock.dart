import 'package:family_os/features/n02_day/call_history_repository.dart';

/// Test / demo fixtures for SCR-FAT-024 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن ١ / ابن ٢ / شريكة ١…). Never screen default (Rule 23).
/// Mirrors frozen prototype FAT-024 rows; [callId] aligns with ActiveCallMock.
abstract final class CallHistoryMock {
  const CallHistoryMock._();

  /// Single outgoing voice call (prototype first row shape).
  static const CallHistorySnapshot one = CallHistorySnapshot(
    entries: [
      CallLogEntry(
        id: 'log_child_a',
        callId: 'call_child_a',
        peerLabel: 'ابن ١',
        emoji: '🦁',
        avatarColor: 0xFF7C5CE6,
        direction: CallLogDirection.outgoing,
        durationLabel: '٣:٢٦ د',
        whenLabel: 'الآن',
      ),
    ],
  );

  /// Four prototype branches — outgoing / missed / incoming / outgoing video.
  static const CallHistorySnapshot many = CallHistorySnapshot(
    entries: [
      CallLogEntry(
        id: 'log_child_a',
        callId: 'call_child_a',
        peerLabel: 'ابن ١',
        emoji: '🦁',
        avatarColor: 0xFF7C5CE6,
        direction: CallLogDirection.outgoing,
        durationLabel: '٣:٢٦ د',
        whenLabel: 'الآن',
      ),
      CallLogEntry(
        id: 'log_child_b_missed',
        callId: 'call_child_b',
        peerLabel: 'ابن ٢',
        emoji: '🐱',
        avatarColor: 0xFF4FC3F7,
        direction: CallLogDirection.missed,
        whenLabel: 'أمس ٧:٤٠ م',
      ),
      CallLogEntry(
        id: 'log_mother',
        callId: 'call_mother',
        peerLabel: 'شريكة ١',
        emoji: '🌸',
        avatarColor: 0xFFFF8FA3,
        direction: CallLogDirection.incoming,
        durationLabel: '١٢:١٠ د',
        whenLabel: 'أمس',
      ),
      CallLogEntry(
        id: 'log_child_c_video',
        callId: 'call_child_c_video',
        peerLabel: 'ابن ٣',
        emoji: '🐼',
        avatarColor: 0xFFFFB547,
        direction: CallLogDirection.outgoing,
        kind: CallLogKind.video,
        durationLabel: '٨:١٥ د',
        whenLabel: 'الجمعة',
      ),
    ],
  );
}
