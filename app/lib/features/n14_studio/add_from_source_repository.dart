import 'package:flutter/foundation.dart';

/// SCR-FAT-041 input gates — which door the family used to bring content in.
enum AddSourceKind { pdf, assignment, camera, link, topic, voice, library }

/// What staging a source produced: the pack the studio will generate from.
@immutable
final class AddFromSourceResult {
  const AddFromSourceResult({required this.kind, required this.packId});

  final AddSourceKind kind;

  /// The staged `content_pack` row this source opened (P15-EDU-048…053).
  final String packId;
}

/// Rule 25 seam — Stage-1 uses the prototype's own copies: staging names the
/// door, it does not import or generate anything (no AI, no file picker).
abstract class AddFromSourceRepository {
  Future<AddFromSourceResult> addSource(AddSourceKind kind);
}

final class InMemoryAddFromSourceRepository
    implements AddFromSourceRepository {
  InMemoryAddFromSourceRepository();

  var _seq = 0;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? addGate;

  @override
  Future<AddFromSourceResult> addSource(AddSourceKind kind) async {
    final gate = addGate;
    if (gate != null) await gate();
    _seq += 1;
    return AddFromSourceResult(kind: kind, packId: 'staged-source-$_seq');
  }
}

/// Shared Stage-1 singleton (screens/tests may inject their own).
final InMemoryAddFromSourceRepository stage1AddFromSourceRepository =
    InMemoryAddFromSourceRepository();
