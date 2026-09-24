import 'dart:async';

import 'package:family_os/features/education/source_ref_models.dart';

/// Rule 25 seam — father attaches PDF/device/link sources (P15-EDU-003 · P11).
abstract class SourceLibraryRepository {
  Future<List<SourceRef>> list();

  Future<SourceRef> attach(SourceAttachRequest request);

  Stream<SourceRef> get attachments;
}

final class InMemorySourceLibraryRepository implements SourceLibraryRepository {
  InMemorySourceLibraryRepository({List<SourceRef>? seed})
    : _items = List<SourceRef>.from(seed ?? const []);

  final List<SourceRef> _items;
  final _controller = StreamController<SourceRef>.broadcast();
  var _seq = 0;

  @override
  Stream<SourceRef> get attachments => _controller.stream;

  @override
  Future<List<SourceRef>> list() async {
    return List<SourceRef>.unmodifiable(_items);
  }

  @override
  Future<SourceRef> attach(SourceAttachRequest request) async {
    final uri = request.uri.trim();
    if (uri.isEmpty) {
      throw ArgumentError.value(
        request.uri,
        'uri',
        'Source URI cannot be empty',
      );
    }
    _seq += 1;
    final ref = SourceRef(
      id: 'src_$_seq',
      kind: request.kind,
      labelKey: request.labelKey,
      uri: uri,
      attachedAt: DateTime.now().toUtc(),
    );
    _items.add(ref);
    _controller.add(ref);
    return ref;
  }

  void seed(List<SourceRef> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  void dispose() {
    _controller.close();
  }
}

/// Shared Stage-1 singleton — DI swap later (Rule 25).
final InMemorySourceLibraryRepository stage1SourceLibraryRepository =
    InMemorySourceLibraryRepository();
