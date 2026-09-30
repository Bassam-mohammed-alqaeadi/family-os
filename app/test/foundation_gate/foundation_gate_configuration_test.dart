import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Foundation Gate accepts only a canonical HTTPS staging origin', () {
    final configuration = FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    );

    expect(configuration.familyDiscoveryUri.toString(), 'https://staging.example.test/v1/me/families');
  });

  test('Foundation Gate rejects unsafe or non-canonical origins before networking', () {
    for (final value in [
      'http://staging.example.test',
      'https://user:password@staging.example.test',
      'https://staging.example.test/base-path',
      'https://staging.example.test?debug=true',
      'https://staging.example.test#fragment',
    ]) {
      expect(
        () => FoundationGateConfiguration.fromStagingApiOrigin(Uri.parse(value)),
        throwsArgumentError,
      );
    }
  });
}
