import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/shared_onboarding/session_recovery.dart';

void main() {
  test('allows only canonical guardian onboarding steps', () {
    expect(
      safeGuardianResumeLocation('/scr-fat-001?ignored=value'),
      '/scr-fat-001',
    );
    expect(safeGuardianResumeLocation('/scr-fat-003'), '/scr-fat-003');
    expect(
      safeGuardianResumeLocation(
        '/scr-fat-004?childId=22222222-2222-4222-8222-222222222222&source=server&token=secret',
      ),
      '/scr-fat-004?childId=22222222-2222-4222-8222-222222222222&source=server',
    );
  });

  test('rejects external, unsupported, and malformed pairing destinations', () {
    expect(safeGuardianResumeLocation('https://evil.example/capture'), isNull);
    expect(safeGuardianResumeLocation('//evil.example/capture'), isNull);
    expect(safeGuardianResumeLocation('/scr-fat-012'), isNull);
    expect(safeGuardianResumeLocation('/scr-fat-004'), isNull);
    expect(
      safeGuardianResumeLocation('/scr-fat-004?childId=not-a-server-id'),
      isNull,
    );
  });

  test('login location encodes the safe destination as one query value', () {
    final location = guardianSessionRecoveryLoginLocation(
      '/scr-fat-004?childId=22222222-2222-4222-8222-222222222222&source=server',
    );
    final uri = Uri.parse(location);
    expect(uri.path, '/scr-shr-003');
    expect(
      uri.queryParameters['resume'],
      '/scr-fat-004?childId=22222222-2222-4222-8222-222222222222&source=server',
    );
  });
}
