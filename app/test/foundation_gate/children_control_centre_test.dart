import 'dart:async';

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
    bool isCreatingChild = false,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
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
            isCreatingChild: isCreatingChild,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'presents a co-guardian family context and profile-only roster without a creation control',
    (tester) async {
      await tester.pumpWidget(host(status: ChildrenControlCentreStatus.ready));

      expect(find.text('Family context'), findsOneWidget);
      expect(find.text('Synthetic family'), findsOneWidget);
      expect(find.text('Server roster · current session'), findsOneWidget);
      expect(find.text('Children control centre'), findsOneWidget);
      expect(find.text('Synthetic child'), findsOneWidget);
      expect(find.text('Age: 8'), findsOneWidget);
      expect(
        find.textContaining('Device and policy states are not connected'),
        findsOneWidget,
      );
      expect(find.text('Add child profile'), findsNothing);
      expect(find.byIcon(Icons.person_add_alt_1_outlined), findsNothing);
    },
  );

  testWidgets(
    'primary guardian submits only name and age through the controller callback',
    (tester) async {
      String? submittedName;
      int? submittedAge;
      String? submittedKey;
      await tester.pumpWidget(
        host(
          status: ChildrenControlCentreStatus.empty,
          family: _primaryFamily,
          children: const [],
          onCreateChild:
              ({
                required displayName,
                required ageYears,
                required avatarEmoji,
                required themeColor,
                required idempotencyKey,
              }) async {
                submittedName = displayName;
                submittedAge = ageYears;
                submittedKey = idempotencyKey;
                return FoundationGateChildCreateResult.created;
              },
        ),
      );

      final addChild = find.byKey(
        const Key('foundation_gate_add_child_profile'),
      );
      await tester.ensureVisible(addChild);
      await tester.tap(addChild);
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter only a name and age.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'New child');
      await tester.tap(
        find.byKey(const Key('foundation_gate_create_child_profile_submit')),
      );
      await tester.pumpAndSettle();

      expect(submittedName, 'New child');
      expect(submittedAge, 8);
      expect(
        submittedKey,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(
        find.text('Child profile created and roster refreshed.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'renders Arabic copy and remains usable at tablet width with enlarged text',
    (tester) async {
      await tester.pumpWidget(
        host(
          status: ChildrenControlCentreStatus.ready,
          locale: const Locale('ar'),
          size: const Size(900, 1024),
          textScale: 1.7,
          children: const [_child, _child],
          family: _primaryFamily,
          onCreateChild:
              ({
                required displayName,
                required ageYears,
                required avatarEmoji,
                required themeColor,
                required idempotencyKey,
              }) async {
                return FoundationGateChildCreateResult.invalidInput;
              },
        ),
      );

      expect(find.text('سياق العائلة'), findsOneWidget);
      expect(find.text('مركز الأطفال'), findsOneWidget);
      expect(find.text('سجل الخادم · الجلسة الحالية'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('foundation_gate_add_child_profile')),
        300,
      );
      expect(find.text('إضافة ملف طفل'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('denied state reveals no family or child roster detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(status: ChildrenControlCentreStatus.accessDenied),
    );

    expect(
      find.text(
        'The children control centre is not available for this account.',
      ),
      findsOneWidget,
    );
    expect(find.text('Synthetic family'), findsNothing);
    expect(find.text('Synthetic child'), findsNothing);
  });

  testWidgets(
    'a failed creation keeps the typed name and retries with the same idempotency key',
    (tester) async {
      final submittedKeys = <String>[];
      const submitKey = Key('foundation_gate_create_child_profile_submit');
      await tester.pumpWidget(
        host(
          status: ChildrenControlCentreStatus.empty,
          family: _primaryFamily,
          children: const [],
          onCreateChild:
              ({
                required displayName,
                required ageYears,
                required avatarEmoji,
                required themeColor,
                required idempotencyKey,
              }) async {
                expect(displayName, isNotEmpty);
                submittedKeys.add(idempotencyKey);
                return FoundationGateChildCreateResult.networkUnavailable;
              },
        ),
      );

      final addChild = find.byKey(
        const Key('foundation_gate_add_child_profile'),
      );
      await tester.ensureVisible(addChild);
      await tester.tap(addChild);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'New child');
      await tester.ensureVisible(find.byKey(submitKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(submitKey));
      await tester.pumpAndSettle();

      // The failure is explained without leaking a raw error, the sheet stays
      // open and the typed name is preserved for a safe retry.
      expect(
        find.text(
          'Could not connect to create the profile. Retry with the same details.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'New child',
      );

      await tester.ensureVisible(find.byKey(submitKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(submitKey));
      await tester.pumpAndSettle();

      // A retry of identical input is the same logical request, so it must
      // reuse the key the server already saw rather than risking a duplicate.
      expect(submittedKeys.length, 2);
      expect(submittedKeys[1], submittedKeys[0]);

      // Changing the name creates a distinct logical request.
      await tester.enterText(find.byType(TextField), 'Renamed child');
      await tester.ensureVisible(find.byKey(submitKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(submitKey));
      await tester.pumpAndSettle();

      expect(submittedKeys.length, 3);
      expect(submittedKeys[2], isNot(submittedKeys[0]));
    },
  );

  testWidgets(
    'while a creation is pending the sheet cannot submit twice or be cancelled',
    (tester) async {
      final completer = Completer<FoundationGateChildCreateResult>();
      const submitKey = Key('foundation_gate_create_child_profile_submit');
      await tester.pumpWidget(
        host(
          status: ChildrenControlCentreStatus.empty,
          family: _primaryFamily,
          children: const [],
          onCreateChild:
              ({
                required displayName,
                required ageYears,
                required avatarEmoji,
                required themeColor,
                required idempotencyKey,
              }) {
                return completer.future;
              },
        ),
      );

      final addChild = find.byKey(
        const Key('foundation_gate_add_child_profile'),
      );
      await tester.ensureVisible(addChild);
      await tester.tap(addChild);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'New child');
      await tester.ensureVisible(find.byKey(submitKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(submitKey));
      await tester.pump();

      expect(
        tester.widget<FilledButton>(find.byKey(submitKey)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Cancel'))
            .onPressed,
        isNull,
      );
      expect(find.text('Child profile created and roster refreshed.'),
          findsNothing);

      completer.complete(FoundationGateChildCreateResult.created);
      await tester.pumpAndSettle();
      expect(find.text('Child profile created and roster refreshed.'),
          findsOneWidget);
    },
  );

  testWidgets(
    'the primary create form is fully Arabic and right-to-left at tablet size with enlarged text',
    (tester) async {
      String? submittedName;
      await tester.pumpWidget(
        host(
          status: ChildrenControlCentreStatus.empty,
          locale: const Locale('ar'),
          size: const Size(900, 1024),
          textScale: 1.7,
          family: _primaryFamily,
          children: const [],
          onCreateChild:
              ({
                required displayName,
                required ageYears,
                required avatarEmoji,
                required themeColor,
                required idempotencyKey,
              }) async {
                submittedName = displayName;
                return FoundationGateChildCreateResult.created;
              },
        ),
      );

      final addChild = find.byKey(
        const Key('foundation_gate_add_child_profile'),
      );
      await tester.scrollUntilVisible(addChild, 300);
      await tester.tap(addChild);
      await tester.pumpAndSettle();

      // The form itself — not only the list behind it — must be Arabic.
      expect(find.text('اسم الطفل'), findsOneWidget);
      expect(find.text('العمر بالسنوات'), findsOneWidget);
      expect(find.text('إنشاء ملف الطفل'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);

      // A translated label inside a left-to-right layout is still a broken
      // Arabic form, so the direction is asserted where the fields are built.
      final formDirection = Directionality.of(
        tester.element(find.byType(TextField)),
      );
      expect(formDirection, TextDirection.rtl);

      // Enlarged text must not clip the submit control out of reach.
      await tester.enterText(find.byType(TextField), 'سارة');
      await tester.tap(
        find.byKey(const Key('foundation_gate_create_child_profile_submit')),
      );
      await tester.pumpAndSettle();

      expect(submittedName, 'سارة');
      expect(find.text('تم إنشاء ملف الطفل وتحديث السجل.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the roster card shows the avatar and colour the guardian stored',
    (tester) async {
      await tester.pumpWidget(
        host(
          status: ChildrenControlCentreStatus.ready,
          children: const [
            FoundationGateChild(
              id: '33333333-3333-4333-8333-333333333333',
              displayName: 'Chosen child',
              ageYears: 9,
              avatarEmoji: '🦁',
              themeColor: 'amber',
            ),
          ],
        ),
      );

      // The stored facts are rendered, not replaced by the first letter of the
      // name. Before this, both were persisted and returned but never shown.
      expect(find.text('🦁'), findsOneWidget);
      expect(find.text('C'), findsNothing);
      expect(find.text('Chosen child'), findsOneWidget);
    },
  );

  testWidgets(
    'the create form offers the closed avatar and colour sets',
    (tester) async {
      await tester.pumpWidget(
        host(
          status: ChildrenControlCentreStatus.empty,
          family: _primaryFamily,
          children: const [],
          onCreateChild:
              ({
                required displayName,
                required ageYears,
                required avatarEmoji,
                required themeColor,
                required idempotencyKey,
              }) async => FoundationGateChildCreateResult.created,
        ),
      );

      final addChild = find.byKey(
        const Key('foundation_gate_add_child_profile'),
      );
      await tester.ensureVisible(addChild);
      await tester.tap(addChild);
      await tester.pumpAndSettle();

      // Every offered avatar is inside the range the transport validates, so a
      // choice can never be rejected by this client's own preflight.
      for (final emoji in kFoundationGateChildAvatarEmojis) {
        expect(
          find.byKey(Key('foundation_gate_child_avatar_$emoji')),
          findsOneWidget,
        );
      }
      for (final token in kFoundationGateChildThemeColors) {
        expect(
          find.byKey(Key('foundation_gate_child_color_$token')),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'a chosen avatar and colour reach the server, and changing them is a new request',
    (tester) async {
      final submitted = <({String emoji, String color, String key})>[];
      const submitKey = Key('foundation_gate_create_child_profile_submit');
      await tester.pumpWidget(
        host(
          status: ChildrenControlCentreStatus.empty,
          family: _primaryFamily,
          children: const [],
          onCreateChild:
              ({
                required displayName,
                required ageYears,
                required avatarEmoji,
                required themeColor,
                required idempotencyKey,
              }) async {
                submitted.add((
                  emoji: avatarEmoji,
                  color: themeColor,
                  key: idempotencyKey,
                ));
                return FoundationGateChildCreateResult.networkUnavailable;
              },
        ),
      );

      final addChild = find.byKey(
        const Key('foundation_gate_add_child_profile'),
      );
      await tester.ensureVisible(addChild);
      await tester.tap(addChild);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'New child');

      // The untouched form sends the defaults it always sent.
      await tester.ensureVisible(find.byKey(submitKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(submitKey));
      await tester.pumpAndSettle();
      expect(submitted.single.emoji, '🧒');
      expect(submitted.single.color, 'purple');

      // Choose a different avatar and colour, then retry.
      await tester.ensureVisible(
        find.byKey(const Key('foundation_gate_child_avatar_🦊')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('foundation_gate_child_avatar_🦊')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('foundation_gate_child_color_mint')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('foundation_gate_child_color_mint')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(submitKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(submitKey));
      await tester.pumpAndSettle();

      expect(submitted.length, 2);
      expect(submitted.last.emoji, '🦊');
      expect(submitted.last.color, 'mint');

      // Changing a presentation fact is a distinct logical request. Reusing the
      // first key would let the server answer the old request and silently keep
      // the avatar the guardian just changed.
      expect(submitted.last.key, isNot(submitted.first.key));

      // Retrying the *new* input unchanged reuses its key.
      await tester.ensureVisible(find.byKey(submitKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(submitKey));
      await tester.pumpAndSettle();
      expect(submitted.length, 3);
      expect(submitted.last.key, submitted[1].key);
    },
  );

  testWidgets(
    'unavailable state does not show a stale child roster and offers recovery',
    (tester) async {
      await tester.pumpWidget(
        host(status: ChildrenControlCentreStatus.unavailable),
      );

      expect(find.text('The roster is unavailable right now'), findsOneWidget);
      expect(find.text('Synthetic child'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Choose another family'), findsOneWidget);
    },
  );
}
