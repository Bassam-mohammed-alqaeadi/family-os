import 'package:flutter/foundation.dart';

/// Kind of father-attached lesson source (FAT-041 · P15-EDU-003 · P11).
enum SourceKind { pdfCatalog, pdfDevice, link, topic, voice, camera }

/// Immutable source reference — mock file/link seam (Rule 25; no real I/O).
@immutable
final class SourceRef {
  const SourceRef({
    required this.id,
    required this.kind,
    required this.labelKey,
    required this.uri,
    required this.attachedAt,
  });

  final String id;
  final SourceKind kind;

  /// ARB discriminator — never a planted person name (Rule 23).
  final String labelKey;

  /// Mock URI / path / URL string (e.g. `mock://pdf/math-g5`, `https://…`).
  final String uri;

  final DateTime attachedAt;
}

@immutable
final class SourceAttachRequest {
  const SourceAttachRequest({
    required this.kind,
    required this.labelKey,
    required this.uri,
  });

  final SourceKind kind;
  final String labelKey;
  final String uri;
}
