import 'package:family_os/features/n02_day/call_history_repository.dart';

/// Test / demo fixtures for SCR-FAT-024 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن 1 / ابن 2 / شريكة 1…). Never screen default (Rule 23).
/// Mirrors frozen prototype FAT-024 rows; [callId] aligns with ActiveCallMock.
abstract final class CallHistoryMock {
  const CallHistoryMock._();

  /// Single outgoing voice call (prototype first row shape).
  static const CallHistorySnapshot one = CallHistorySnapshot(
    entries: [
      CallLogEntry(
        id: 'log_child_a',
        callId: 'call_child_a',
        peerLabel: 'ابن 1',
        emoji: '🦁',
        avatarColor: 0xFF7C5CE6,
        direction: CallLogDirection.outgoing,
        durationLabel: '3:26 د',
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
        peerLabel: 'ابن 1',
        emoji: '🦁',
        avatarColor: 0xFF7C5CE6,
        direction: CallLogDirection.outgoing,
        durationLabel: '3:26 د',
        whenLabel: 'الآن',
      ),
      CallLogEntry(
        id: 'log_child_b_missed',
        callId: 'call_child_b',
        peerLabel: 'ابن 2',
        emoji: '🐱',
        avatarColor: 0xFF4FC3F7,
        direction: CallLogDirection.missed,
        whenLabel: 'أمس 7:40 م',
      ),
      CallLogEntry(
        id: 'log_mother',
        callId: 'call_mother',
        peerLabel: 'شريكة 1',
        emoji: '🌸',
        avatarColor: 0xFFFF8FA3,
        direction: CallLogDirection.incoming,
        durationLabel: '12:10 د',
        whenLabel: 'أمس',
      ),
      CallLogEntry(
        id: 'log_child_c_video',
        callId: 'call_child_c_video',
        peerLabel: 'ابن 3',
        emoji: '🐼',
        avatarColor: 0xFFFFB547,
        direction: CallLogDirection.outgoing,
        kind: CallLogKind.video,
        durationLabel: '8:15 د',
        whenLabel: 'الجمعة',
      ),
    ],
  );
}
