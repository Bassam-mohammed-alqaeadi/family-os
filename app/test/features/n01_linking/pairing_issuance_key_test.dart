import 'package:family_os/features/n01_linking/pairing_issuance_key.dart';
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
}
