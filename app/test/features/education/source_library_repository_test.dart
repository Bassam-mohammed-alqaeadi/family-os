import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/education/source_library_repository.dart';
import 'package:family_os/features/education/source_ref_models.dart';

void main() {
  test('attach stores SourceRef and lists it', () async {
    final repo = InMemorySourceLibraryRepository();
    addTearDown(repo.dispose);

    final ref = await repo.attach(
      const SourceAttachRequest(
        kind: SourceKind.pdfDevice,
        labelKey: 'pdfDevice',
        uri: 'mock://device/picked.pdf',
      ),
    );
    expect(ref.kind, SourceKind.pdfDevice);
    expect(ref.uri, 'mock://device/picked.pdf');

    final list = await repo.list();
    expect(list, hasLength(1));
    expect(list.single.id, ref.id);
  });

  test('empty uri is rejected', () async {
    final repo = InMemorySourceLibraryRepository();
    addTearDown(repo.dispose);
    expect(
      () => repo.attach(
        const SourceAttachRequest(
          kind: SourceKind.link,
          labelKey: 'link',
          uri: '  ',
        ),
      ),
      throwsArgumentError,
    );
  });
}
