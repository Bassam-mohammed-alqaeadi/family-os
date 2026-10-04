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
const _primaryFamily = FoundationGateFamily(
  id: '11111111-1111-4111-8111-111111111111',
  displayName: 'Synthetic family',
  role: 'primary_guardian',
);
const _child = FoundationGateChild(
  id: '22222222-2222-4222-8222-222222222222',
  displayName: 'Synthetic child',
  ageYears: 8,
  avatarEmoji: '🧒',
  themeColor: 'purple',
);

void main() {
  Widget host({
    required ChildrenControlCentreStatus status,
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
    double textScale = 1,
    List<FoundationGateChild> children = const [_child],
    FoundationGateFamily family = _family,
    CreateChildProfile? onCreateChild,
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
            family: family,
            children: children,
            onChooseFamily: () {},
            onSignOut: () async {},
            onRetry: () async {},
            onCreateChild: onCreateChild,
          ),
        ),
      ),
    );
  }

  testWidgets('presents a co-guardian family context and profile-only roster without a creation control', (tester) async {
    await tester.pumpWidget(host(status: ChildrenControlCentreStatus.ready));

    expect(find.text('Family context'), findsOneWidget);
    expect(find.text('Synthetic family'), findsOneWidget);
    expect(find.text('Server roster · current session'), findsOneWidget);
    expect(find.text('Children control centre'), findsOneWidget);
    expect(find.text('Synthetic child'), findsOneWidget);
    expect(find.text('Age: 8'), findsOneWidget);
    expect(find.textContaining('Device and policy states are not connected'), findsOneWidget);
    expect(find.text('Add child profile'), findsNothing);
    expect(find.byIcon(Icons.person_add_alt_1_outlined), findsNothing);
  });

  testWidgets('primary guardian submits only name and age through the controller callback', (tester) async {
    String? submittedName;
    int? submittedAge;
    String? submittedKey;
    await tester.pumpWidget(
      host(
        status: ChildrenControlCentreStatus.empty,
        family: _primaryFamily,
        children: const [],
        onCreateChild: ({required displayName, required ageYears, required avatarEmoji, required themeColor, required idempotencyKey}) async {
          submittedName = displayName;
          submittedAge = ageYears;
          submittedKey = idempotencyKey;
          return FoundationGateChildCreateResult.created;
        },
      ),
    );

    final addChild = find.text('Add child profile');
    await tester.ensureVisible(addChild);
    await tester.tap(addChild);
    await tester.pumpAndSettle();
    expect(find.text('Enter only a name and age.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'New child');
    await tester.tap(find.byKey(const Key('foundation_gate_create_child_profile_submit')));
    await tester.pumpAndSettle();

    expect(submittedName, 'New child');
    expect(submittedAge, 8);
    expect(submittedKey, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(find.text('Child profile created and roster refreshed.'), findsOneWidget);
  });

  testWidgets('renders Arabic copy and remains usable at tablet width with enlarged text', (tester) async {
    await tester.pumpWidget(
      host(
        status: ChildrenControlCentreStatus.ready,
        locale: const Locale('ar'),
        size: const Size(900, 1024),
        textScale: 1.7,
        children: const [_child, _child],
        family: _primaryFamily,
        onCreateChild: ({required displayName, required ageYears, required avatarEmoji, required themeColor, required idempotencyKey}) async {
          return FoundationGateChildCreateResult.invalidInput;
        },
      ),
    );

    expect(find.text('سياق العائلة'), findsOneWidget);
    expect(find.text('مركز الأطفال'), findsOneWidget);
    expect(find.text('سجل الخادم · الجلسة الحالية'), findsOneWidget);
    expect(find.text('إضافة ملف طفل'), findsOneWidget);
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
