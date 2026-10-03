import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/foundation_gate/children_control_centre.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _family = FoundationGateFamily(
  id: '11111111-1111-4111-8111-111111111111',
  displayName: 'Synthetic family',
  role: 'co_guardian',
);
const _child = FoundationGateChild(
  id: '22222222-2222-4222-8222-222222222222',
  displayName: 'Synthetic child',
  ageYears: 8,
);

void main() {
  Widget host({
    required ChildrenControlCentreStatus status,
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
    double textScale = 1,
    List<FoundationGateChild> children = const [_child],
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildFamilyTheme(),
        home: Scaffold(
          body: ChildrenControlCentre(
            status: status,
            family: _family,
            children: children,
            onChooseFamily: () {},
            onSignOut: () async {},
            onRetry: () async {},
          ),
        ),
      ),
    );
  }

  testWidgets('presents a familiar family context and profile-only roster without fake controls', (tester) async {
    await tester.pumpWidget(host(status: ChildrenControlCentreStatus.ready));

    expect(find.text('Family context'), findsOneWidget);
    expect(find.text('Synthetic family'), findsOneWidget);
    expect(find.text('Server roster · current session'), findsOneWidget);
    expect(find.text('Children control centre'), findsOneWidget);
    expect(find.text('Synthetic child'), findsOneWidget);
    expect(find.text('Age: 8'), findsOneWidget);
    expect(find.textContaining('Device and policy states are not connected'), findsOneWidget);
    expect(find.textContaining('Add child'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('renders Arabic copy and remains usable at tablet width with enlarged text', (tester) async {
    await tester.pumpWidget(
      host(
        status: ChildrenControlCentreStatus.ready,
        locale: const Locale('ar'),
        size: const Size(900, 1024),
        textScale: 1.7,
        children: const [_child, _child],
      ),
    );

    expect(find.text('سياق العائلة'), findsOneWidget);
    expect(find.text('مركز الأطفال'), findsOneWidget);
    expect(find.text('سجل الخادم · الجلسة الحالية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('denied state reveals no family or child roster detail', (tester) async {
    await tester.pumpWidget(host(status: ChildrenControlCentreStatus.accessDenied));

    expect(find.text('The children control centre is not available for this account.'), findsOneWidget);
    expect(find.text('Synthetic family'), findsNothing);
    expect(find.text('Synthetic child'), findsNothing);
  });

  testWidgets('unavailable state does not show a stale child roster and offers recovery', (tester) async {
    await tester.pumpWidget(host(status: ChildrenControlCentreStatus.unavailable));

    expect(find.text('The roster is unavailable right now'), findsOneWidget);
    expect(find.text('Synthetic child'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Choose another family'), findsOneWidget);
  });
}
