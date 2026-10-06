import 'package:family_os/features/n01_linking/pairing_issuance_key.dart';
import 'package:family_os/foundation_gate/family_device_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pairing issuance keeps ambiguous retries but rotates known outcomes', () {
    var next = 0;
    final issuance = PairingIssuanceKey(createKey: () => 'key-${next++}');

    final first = issuance.forRequest('Child phone');
    expect(issuance.forRequest('Child phone'), first);

    issuance.markNotReplayable();
    final afterConflict = issuance.forRequest('Child phone');
    expect(afterConflict, isNot(first));
    expect(issuance.forRequest('Renamed phone'), isNot(afterConflict));

    final beforeRegeneration = issuance.forRequest('Renamed phone');
    expect(
      issuance.forRequest('Renamed phone', regenerate: true),
      isNot(beforeRegeneration),
    );
  });

  test('non-replayable code is replaced once without showing an error', () async {
    var next = 0;
    final keys = PairingIssuanceKey(createKey: () => 'key-${next++}');
    final issuedKeys = <String>[];
    var attempt = 0;

    final result = await issuePairingWithNonReplayableRecovery(
      issuanceKey: keys,
      deviceLabel: 'Child phone',
      issue: (key) async {
        issuedKeys.add(key);
        attempt += 1;
        if (attempt == 1) {
          return const FoundationGateDevicePairingCreateResult.failed(
            FoundationGateDevicePairingCreateFailure
                .pairingCodeNotReplayable,
          );
        }
        return FoundationGateDevicePairingCreateResult.created(
          FoundationGateDevicePairing(
            id: '33333333-3333-4333-8333-333333333333',
            childId: '22222222-2222-4222-8222-222222222222',
            deviceLabel: 'Child phone',
            pairingCode: '482910',
            expiresAt: DateTime.utc(2026, 10, 6, 12, 10),
          ),
        );
      },
    );

    expect(result.isCreated, isTrue);
    expect(issuedKeys, ['key-0', 'key-1']);
  });

  test('network ambiguity retains its key and does not auto-issue', () async {
    var next = 0;
    final keys = PairingIssuanceKey(createKey: () => 'key-${next++}');
    final issuedKeys = <String>[];

    final first = await issuePairingWithNonReplayableRecovery(
      issuanceKey: keys,
      deviceLabel: 'Child phone',
      issue: (key) async {
        issuedKeys.add(key);
        return const FoundationGateDevicePairingCreateResult.failed(
          FoundationGateDevicePairingCreateFailure.networkUnavailable,
        );
      },
    );
    final second = await issuePairingWithNonReplayableRecovery(
      issuanceKey: keys,
      deviceLabel: 'Child phone',
      issue: (key) async {
        issuedKeys.add(key);
        return const FoundationGateDevicePairingCreateResult.failed(
          FoundationGateDevicePairingCreateFailure.networkUnavailable,
        );
      },
    );

    expect(first.failure, FoundationGateDevicePairingCreateFailure.networkUnavailable);
    expect(second.failure, FoundationGateDevicePairingCreateFailure.networkUnavailable);
    expect(issuedKeys, ['key-0', 'key-0']);
  });
}
