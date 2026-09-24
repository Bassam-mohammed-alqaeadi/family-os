import 'package:flutter/foundation.dart';

/// Honest capability vocabulary for FS-001…FS-007 (and shared seams).
///
/// UI and docs must use these statuses — never imply a fake live cloud/OS
/// capability. Maps to closure-report labels:
/// `IMPLEMENTED` · `MOCK-REMOTE` · `DEGRADED` · `UNSUPPORTED` · `NOT IMPLEMENTED`.
enum CapabilityStatus {
  /// Local domain + persistence real; claims match what the device can do.
  implemented,

  /// Behavior real locally; remote/cloud edge is mocked.
  mockRemote,

  /// Partial function with explicit honesty (e.g. last-acked offline).
  degraded,

  /// Platform cannot support the claim (e.g. iOS parity).
  unsupported,

  /// Not built yet in this campaign slice.
  notImplemented,
}

/// Stable wire / DB / report tokens (uppercase with hyphen where needed).
extension CapabilityStatusWire on CapabilityStatus {
  String get wireName => switch (this) {
    CapabilityStatus.implemented => 'IMPLEMENTED',
    CapabilityStatus.mockRemote => 'MOCK-REMOTE',
    CapabilityStatus.degraded => 'DEGRADED',
    CapabilityStatus.unsupported => 'UNSUPPORTED',
    CapabilityStatus.notImplemented => 'NOT_IMPLEMENTED',
  };

  static CapabilityStatus parse(String raw) {
    switch (raw.trim().toUpperCase().replaceAll(' ', '_')) {
      case 'IMPLEMENTED':
        return CapabilityStatus.implemented;
      case 'MOCK-REMOTE':
      case 'MOCK_REMOTE':
        return CapabilityStatus.mockRemote;
      case 'DEGRADED':
        return CapabilityStatus.degraded;
      case 'UNSUPPORTED':
        return CapabilityStatus.unsupported;
      case 'NOT_IMPLEMENTED':
      case 'NOT-IMPLEMENTED':
        return CapabilityStatus.notImplemented;
      default:
        throw FormatException('Unknown CapabilityStatus: $raw');
    }
  }
}

/// One registered capability row (persisted in LocalDatabase).
@immutable
final class CapabilityEntry {
  const CapabilityEntry({
    required this.id,
    required this.systemId,
    required this.status,
    this.note,
    required this.updatedAt,
  });

  /// Stable id, e.g. `fs001.live_location`, `fs006.sos_lifecycle`.
  final String id;

  /// FS system owner: `FS-001` … `FS-007` or `FS-A`.
  final String systemId;

  final CapabilityStatus status;
  final String? note;
  final DateTime updatedAt;

  CapabilityEntry copyWith({
    CapabilityStatus? status,
    String? note,
    DateTime? updatedAt,
    bool clearNote = false,
  }) {
    return CapabilityEntry(
      id: id,
      systemId: systemId,
      status: status ?? this.status,
      note: clearNote ? null : (note ?? this.note),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'systemId': systemId,
    'status': status.wireName,
    'note': note,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory CapabilityEntry.fromJson(Map<String, Object?> json) {
    return CapabilityEntry(
      id: json['id']! as String,
      systemId: json['systemId']! as String,
      status: CapabilityStatusWire.parse(json['status']! as String),
      note: json['note'] as String?,
      updatedAt: DateTime.parse(json['updatedAt']! as String).toUtc(),
    );
  }
}
