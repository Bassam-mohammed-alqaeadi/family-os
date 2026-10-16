// GENERATED from backend/contracts/pairing.v1.json by tools/contracts/generate-dart.mjs.
// Do not edit by hand: change the contract and run the generator.

/// The one-time child pairing code contract, shared with the backend.
abstract final class PairingContract {
  static const String contractId = 'pairing.v1';
  static const int codeLength = 6;
  static const String codePattern = r'^\d{6}$';
  /// Failed claims a source may make within one window. A claim that succeeds is not counted.
  static const int claimMaxFailures = 5;
  static const int claimWindowMinutes = 10;
}
