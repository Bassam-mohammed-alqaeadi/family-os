import 'package:family_os/foundation_gate/foundation_gate_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('isolated Foundation Gate starts unconfigured without legacy mock data', (tester) async {
    await tester.pumpWidget(const FoundationGateApp());

    expect(find.text('Foundation Gate is not configured.'), findsOneWidget);
    expect(find.textContaining('family', findRichText: true), findsNothing);
  });
}
