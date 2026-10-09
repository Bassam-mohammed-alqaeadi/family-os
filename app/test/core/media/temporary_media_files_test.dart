import 'dart:io';
import 'dart:typed_data';

import 'package:family_os/core/media/temporary_media_files.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory directory;
  late TemporaryMediaFileStore files;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('family-os-media-test-');
    files = TemporaryMediaFileStore(directoryPath: () async => directory.path);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('writes, reads and removes temporary media bytes', () async {
    final path = await files.newPath('voice-test.m4a');
    final bytes = Uint8List.fromList(<int>[0, 1, 2, 127, 255]);

    await files.write(path, bytes);
    expect(await files.read(path), orderedEquals(bytes));
    expect(await File(path).exists(), isTrue);

    await files.deleteIfPresent(path);
    expect(await File(path).exists(), isFalse);
  });

  test('reduces a supplied path to a filename within the temporary directory', () async {
    final path = await files.newPath('../nested/voice-test.m4a');

    expect(p.dirname(path), directory.path);
    expect(p.basename(path), 'voice-test.m4a');
  });

  test('deleting an already absent file is safe', () async {
    final path = await files.newPath('already-absent.m4a');

    await files.deleteIfPresent(path);
    await files.deleteIfPresent(path);

    expect(await File(path).exists(), isFalse);
  });
}
