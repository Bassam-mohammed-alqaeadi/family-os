// The Dart side of the shared pairing contract (backend/contracts/pairing.v1.json).
// The backend runs the same examples through its own validation (pairing-contract.test.js), so the
// two sides cannot disagree about a code without one of these suites failing.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/pairing_contract.generated.dart';

void main() {
  final contract =
      jsonDecode(File('../backend/contracts/pairing.v1.json').readAsStringSync())
          as Map<String, dynamic>;
  final pairing = contract['pairingCode'] as Map<String, dynamic>;
  final examples = contract['examples'] as Map<String, dynamic>;
  final accept = (examples['accept'] as List).cast<String>();
  final reject = (examples['reject'] as List).cast<String>();

  test('the app reads the same contract the backend reads', () {
    expect(PairingContract.contractId, contract['contract']);
    expect(PairingContract.codeLength, pairing['length']);
    expect(PairingContract.codePattern, pairing['pattern']);
  });

  test('accepts every example the contract accepts', () {
    final pattern = RegExp(PairingContract.codePattern);
    for (final code in accept) {
      expect(pattern.hasMatch(code), isTrue, reason: 'should accept "$code"');
    }
  });

  test('rejects every example the contract rejects', () {
    final pattern = RegExp(PairingContract.codePattern);
    for (final code in reject) {
      expect(pattern.hasMatch(code), isFalse, reason: 'should reject "$code"');
    }
  });
}
