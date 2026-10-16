// The child's manual pairing field takes the six-digit code the server issues.
// A-01 history: the field used to cap input at 10 characters and force capitals, so a longer
// code could never reach the server. The code is now six digits (backend
// claimDevicePairingInput: ^\d{6}$), so the field is numeric, capped at six, and digits only.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/native_device_pairing_screens.dart';
import 'package:family_os/foundation_gate/family_device_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

const _issuedCode = '482913';

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
  testWidgets('the manual field takes the whole six-digit code and sends it unchanged', (
    tester,
  ) async {
    final client = await _pumpChildEntry(tester);

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    await tester.enterText(field, _issuedCode);
    await tester.pump();

    final widget = tester.widget<TextField>(field);
    expect(widget.maxLength, _issuedCode.length);
    expect(widget.keyboardType, TextInputType.number);
    expect(widget.controller!.text, _issuedCode);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 100));

    expect(client.claimed, _issuedCode, reason: 'the server must receive the full code, unchanged');
  });

  testWidgets('letters and spaces are not accepted into the code field', (tester) async {
    final client = await _pumpChildEntry(tester);

    await tester.enterText(find.byType(TextField), '48a 2913');
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '482913');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 100));
    expect(client.claimed, '482913');
  });
}
