import 'package:flutter/foundation.dart';

/// Minimal local event envelope (EVT-01-A).
///
/// Not a full Rule-26 FamilyEvent taxonomy — channel + payload only.
/// Enqueue ≠ remote delivery (MOCK-REMOTE honesty).
@immutable
final class LocalEventEnvelope {
  const LocalEventEnvelope({
    required this.id,
    required this.channel,
    required this.at,
    required this.payload,
  });

  final String id;
  final String channel;
  final DateTime at;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
        'id': id,
        'channel': channel,
        'at': at.toUtc().toIso8601String(),
        'payload': payload,
        'deliveryClaim': 'queued_locally',
      };

  factory LocalEventEnvelope.fromJson(Map<String, Object?> json) {
    final payloadRaw = json['payload'];
    return LocalEventEnvelope(
      id: json['id']! as String,
      channel: json['channel']! as String,
      at: DateTime.parse(json['at']! as String).toUtc(),
      payload: payloadRaw is Map
          ? payloadRaw.map((k, v) => MapEntry(k.toString(), v))
          : const {},
    );
  }
}
