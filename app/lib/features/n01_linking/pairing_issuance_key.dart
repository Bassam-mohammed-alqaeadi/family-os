import 'package:family_os/foundation_gate/family_device_api_client.dart';
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

/// Recovers once when the server confirms that a previous response cannot be
/// replayed because its raw one-time code was deliberately not persisted.
///
/// The replacement uses a fresh idempotency key. Network failures do not enter
/// this path and therefore keep their original key for an ambiguity-safe retry.
Future<FoundationGateDevicePairingCreateResult>
issuePairingWithNonReplayableRecovery({
  required PairingIssuanceKey issuanceKey,
  required String deviceLabel,
  required Future<FoundationGateDevicePairingCreateResult> Function(
    String idempotencyKey,
  ) issue,
  bool regenerate = false,
}) async {
  var result = await issue(
    issuanceKey.forRequest(deviceLabel, regenerate: regenerate),
  );
  if (result.failure ==
      FoundationGateDevicePairingCreateFailure.pairingCodeNotReplayable) {
    issuanceKey.markNotReplayable();
    result = await issue(issuanceKey.forRequest(deviceLabel));
  }
  if (result.failure ==
          FoundationGateDevicePairingCreateFailure.pairingCodeNotReplayable ||
      result.failure == FoundationGateDevicePairingCreateFailure.conflict) {
    // A later explicit attempt must never repeat a key the server rejected.
    issuanceKey.markNotReplayable();
  }
  return result;
}
