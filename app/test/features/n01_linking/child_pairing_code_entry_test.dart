// A-01 regression: the child's manual pairing field must carry the whole one-time code.
// The server issues base64url(32 random bytes) = 43 characters, case-sensitive, and accepts
// 32..128 characters (backend/src/validation.js claimDevicePairingInput). The field used to cap
// input at 10 characters and force capitals, so a valid code could never reach the server.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/native_device_pairing_screens.dart';
import 'package:family_os/foundation_gate/family_device_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

// Exactly 43 characters, mixed case, with '-' and '_': the shape the server issues.
const _issuedCode = 'aB3-xY9_qW2eR7tL0pN5mZ8vC1bH4gJ6kD0sF9uT3yA';

final class _CapturingClient extends Fake implements FamilyDeviceApiClient {
  String? claimed;

  @override
  Future<FoundationGateClaimedDevice> claimPairing({
    required String pairingCode,
  }) async {
    claimed = pairingCode;
    // Stop here: the test asserts what was sent, not what happens after a claim.
    throw const FoundationGateApiException(FoundationGateApiFailure.invalidInput);
  }
}

Future<_CapturingClient> _pumpChildEntry(WidgetTester tester) async {
  final client = _CapturingClient();
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChildModePairingScreen(apiClient: client),
    ),
  );
  await tester.pump();
  return client;
}

void main() {
  testWidgets('the manual field keeps the whole 43-character code, case intact', (
    tester,
  ) async {
    final client = await _pumpChildEntry(tester);

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    await tester.enterText(field, _issuedCode);
    await tester.pump();

    final widget = tester.widget<TextField>(field);
    expect(widget.maxLength, greaterThanOrEqualTo(_issuedCode.length));
    expect(widget.maxLength, lessThanOrEqualTo(128));
    expect(widget.textCapitalization, TextCapitalization.none);
    expect(widget.controller!.text, _issuedCode);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 100));

    expect(client.claimed, _issuedCode, reason: 'the server must receive the full code, unchanged');
  });

  testWidgets('a 128-character code (the server maximum) is not truncated', (tester) async {
    final client = await _pumpChildEntry(tester);
    final longest = (_issuedCode + _issuedCode + _issuedCode).substring(0, 128);

    await tester.enterText(find.byType(TextField), longest);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 100));

    expect(client.claimed, longest);
    expect(client.claimed!.length, 128);
  });
}
