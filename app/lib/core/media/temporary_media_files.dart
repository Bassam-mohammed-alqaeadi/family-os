import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef TemporaryDirectoryPathProvider = Future<String> Function();

/// Keeps platform file-system access behind a core boundary so feature widgets do not import
/// dart:io. The only files this store creates are in the platform temporary directory.
class TemporaryMediaFileStore {
  TemporaryMediaFileStore({TemporaryDirectoryPathProvider? directoryPath})
    : _directoryPath = directoryPath ?? _platformTemporaryDirectoryPath;

  final TemporaryDirectoryPathProvider _directoryPath;

  /// Reserves a safe path in the temporary directory. Caller-provided path segments are stripped.
  Future<String> newPath(String fileName) async {
    final directory = await _directoryPath();
    final leaf = p.basename(fileName.replaceAll(r'\\', '/'));
    if (leaf.isEmpty || leaf == '.' || leaf == '..') {
      throw ArgumentError.value(fileName, 'fileName', 'must include a file name');
    }
    return p.join(directory, leaf);
  }

  Future<Uint8List> read(String path) => File(path).readAsBytes();

  Future<void> write(String path, List<int> bytes) =>
      File(path).writeAsBytes(bytes, flush: true);

  /// Removes a temporary file if it still exists. A failed cleanup must not crash the screen.
  Future<void> deleteIfPresent(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // Already gone or no longer accessible; the app shares no reference to the file.
    }
  }
}

Future<String> _platformTemporaryDirectoryPath() async =>
    (await getTemporaryDirectory()).path;

final TemporaryMediaFileStore temporaryMediaFiles = TemporaryMediaFileStore();
