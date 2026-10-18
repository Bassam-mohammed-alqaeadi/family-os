import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// S3 exit gate (static). Runs from `app/`.
///
/// 1. The minutes ledger is written by no code in `lib/` except its own file.
/// 2. The child's wallet production path reads the server and never declares itself simulated.
///
/// These are tripwires: a regression that reintroduces a local minute write, or a simulated
/// production balance, fails here before it reaches a device.
void main() {
  final libFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  bool isComment(String line) => line.trimLeft().startsWith('//');

  test('no minute write (earn / deposit) exists in lib/ outside the ledger', () {
    final offenders = <String>[];
    for (final file in libFiles) {
      if (file.path.replaceAll('\\', '/').endsWith('core/policy/wallet_ledger.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (isComment(line)) continue;
        if (line.contains('.earn(') || line.contains('.deposit(')) {
          offenders.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Local minute writes are forbidden (S3).');
  });

  test('the local ledger is constructed only inside its own file', () {
    final offenders = <String>[];
    for (final file in libFiles) {
      // Normalise separators: on Windows file.path uses backslashes.
      final portable = file.path.replaceAll('\\', '/');
      if (portable.endsWith('core/policy/wallet_ledger.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (isComment(line)) continue;
        if (line.contains('WalletLedger(')) {
          offenders.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'No screen or repository may build a local ledger (S3).');
  });

  test('CHD-019 production path reads the server and is never simulated', () {
    final text = File('lib/features/n17_child_learn/child_wallet_repository.dart')
        .readAsStringSync();
    final start = text.indexOf('final class ServerChildWalletRepository');
    final end = text.indexOf('final class InMemoryChildWalletRepository');
    expect(start, greaterThanOrEqualTo(0), reason: 'ServerChildWalletRepository must exist.');
    expect(end, greaterThan(start));
    final server = text.substring(start, end);
    expect(server, isNot(contains('simulated: true')));
    expect(server, contains('simulated: false'));
    expect(server, isNot(contains('WalletLedger')));
    expect(
      text.contains('final ChildWalletRepository stage1ChildWalletRepository =\n    ServerChildWalletRepository('),
      isTrue,
      reason: 'The production wallet must be the server repository.',
    );
  });
}
