import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// Owns the idempotency-key lifecycle for guardian pairing issuance.
///
/// Ambiguous transport retries keep the same key. A changed device label, an
/// explicit regeneration, or the server's non-replayable conflict starts a
/// genuinely new issuance with a fresh key.
class PairingIssuanceKey {
  PairingIssuanceKey({String Function()? createKey})
    : _createKey = createKey ?? newFoundationGateIdempotencyKey;

  final String Function() _createKey;
  String? _key;
  String? _deviceLabel;

  String forRequest(String deviceLabel, {bool regenerate = false}) {
    if (_key == null || _deviceLabel != deviceLabel || regenerate) {
      _key = _createKey();
      _deviceLabel = deviceLabel;
    }
    return _key!;
  }

  void markNotReplayable() {
    _key = null;
  }
}
