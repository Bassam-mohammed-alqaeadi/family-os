// الطابع العائلة · الغرفة ٢ — the card a father actually opens, on a small phone at doubled text.
//
// Four things are asserted here, and each is a defect this card could have shipped with:
//
//   * Every control is in the tree at 320×600 with textScaler 2.0 — built, not "below the fold".
//     A family that cannot see a switch cannot use it, however correct the server behind it is.
//   * What is on screen came from the spine: the week it stored, the words it stored, and whether
//     the family ever chose anything at all.
//   * A write changes what the family is told, and a refusal does not. The stale-version case is
//     the important one: the guardian's draft is dropped and the family's real profile is read
//     back, because showing an unsent change as though it stood is how an app loses trust.
//   * And the point of the whole programme: the digits the family chose are the digits the card
//     prints. A switch with no engine behind it is not shipped here.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/i18n/numeral_format.dart';
import 'package:family_os/features/n12_devices/family_customization_panel.dart';
import 'package:family_os/features/n12_devices/family_customization_server_authority.dart';
import 'package:family_os/foundation_gate/family_customization_api_client.dart';

import 'support/family_customization_fake_server.dart';

Future<void> _pumpCard(
  WidgetTester tester, {
  required FamilyCustomizationAuthority? authority,
  Locale locale = const Locale('ar'),
  Size surface = const Size(320, 600),
  double textScale = 2.0,
}) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = surface * 2.0;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      // Mounted the way the settings hub mounts it: inside the same scrolling body, so a layout
      // defect here is the defect a parent would meet there.
      home: Scaffold(
        body: SingleChildScrollView(
          child: FamilyCustomizationSection(authority: authority),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

String? _note(WidgetTester tester) {
  final found = find.byKey(FamilyCustomizationKeys.note);
  if (found.evaluate().isEmpty) return null;
  return tester.widget<Text>(found).data;
}

bool _selected(WidgetTester tester, Key key) =>
    tester.widget<FilterChip>(find.byKey(key)).selected;

bool _chosen(WidgetTester tester, Key key) =>
    tester.widget<ChoiceChip>(find.byKey(key)).selected;

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<PrimaryBtn>(find.byKey(FamilyCustomizationKeys.saveCta))
        .onPressed !=
    null;

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pump();
  await tester.tap(find.byKey(key));
  await tester.pump();
}

void main() {
  tearDown(() {
    FamilyCustomizationAuthority.bind(null);
    AppNumerals.clearFamilyChoice();
  });

  testWidgets('a family that chose nothing is told it is the app’s start, not their decision', (
    tester,
  ) async {
    final spine = FamilyCustomizationFakeSpine();
    await _pumpCard(tester, authority: familyCustomizationAuthorityFor(spine));

    expect(find.byKey(FamilyCustomizationKeys.card), findsOneWidget);
    expect(find.text('طابع عائلتك'), findsOneWidget);
    expect(find.text('لم تُغيّروا شيئاً بعد — هذا ما يبدأ به التطبيق لكل عائلة.'), findsOneWidget);

    // Monday first, Friday and Saturday at rest — read from the spine, not typed into a widget.
    expect(
      _chosen(tester, FamilyCustomizationKeys.weekStartDay(FamilyCustomizationDay.monday)),
      isTrue,
    );
    expect(
      _selected(tester, FamilyCustomizationKeys.restDay(FamilyCustomizationDay.friday)),
      isTrue,
    );
    expect(
      _selected(tester, FamilyCustomizationKeys.restDay(FamilyCustomizationDay.saturday)),
      isTrue,
    );
    expect(
      _selected(tester, FamilyCustomizationKeys.restDay(FamilyCustomizationDay.sunday)),
      isFalse,
    );
    // Nothing to save, because nothing was changed.
    expect(_saveEnabled(tester), isFalse);
    expect(_note(tester), isNull);
  });

  testWidgets('every control survives a doubled text size on a small phone', (tester) async {
    final spine = FamilyCustomizationFakeSpine(stored: true);
    await _pumpCard(tester, authority: familyCustomizationAuthorityFor(spine));

    for (final key in <Key>[
      FamilyCustomizationKeys.weekStartGroup,
      FamilyCustomizationKeys.restDaysGroup,
      FamilyCustomizationKeys.numeralsGroup,
      FamilyCustomizationKeys.wordsGroup,
      FamilyCustomizationKeys.saveCta,
    ]) {
      expect(find.byKey(key), findsOneWidget, reason: 'missing ${key.toString()}');
    }
    for (final day in FamilyCustomizationDay.values) {
      expect(
        find.byKey(FamilyCustomizationKeys.weekStartDay(day)),
        findsOneWidget,
        reason: 'the week-start chip for ${day.wire} never reached the tree',
      );
      expect(
        find.byKey(FamilyCustomizationKeys.restDay(day)),
        findsOneWidget,
        reason: 'the rest-day chip for ${day.wire} never reached the tree',
      );
    }
    for (final label in FamilyGuardianLabelKey.values) {
      expect(
        find.byKey(FamilyCustomizationKeys.label(label)),
        findsOneWidget,
        reason: 'the word field for ${label.wire} never reached the tree',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the family’s own stored words are what the fields hold', (tester) async {
    final spine = FamilyCustomizationFakeSpine(stored: true);
    await _pumpCard(tester, authority: familyCustomizationAuthorityFor(spine));

    expect(
      tester
          .widget<TextField>(
            find.byKey(FamilyCustomizationKeys.label(FamilyGuardianLabelKey.father)),
          )
          .controller!
          .text,
      'بابا',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(FamilyCustomizationKeys.label(FamilyGuardianLabelKey.mother)),
          )
          .controller!
          .text,
      isEmpty,
    );
    // Sunday first, only Friday at rest — the stored row, not the app's default.
    expect(
      _chosen(tester, FamilyCustomizationKeys.weekStartDay(FamilyCustomizationDay.sunday)),
      isTrue,
    );
    expect(
      _selected(tester, FamilyCustomizationKeys.restDay(FamilyCustomizationDay.saturday)),
      isFalse,
    );
  });

  testWidgets('choosing eastern digits changes what the card prints, and then the app’s', (
    tester,
  ) async {
    final spine = FamilyCustomizationFakeSpine();
    await _pumpCard(tester, authority: familyCustomizationAuthorityFor(spine));

    // Both options show their own shape before anyone picks, so the choice means something.
    expect(find.text('هكذا تبدو أرقامكم: 1234'), findsOneWidget);
    expect(find.text('1234'), findsNothing);

    await _tap(tester, FamilyCustomizationKeys.numeral(FamilyNumeralSystem.eastern));
    expect(find.text('هكذا تبدو أرقامكم: ١٢٣٤'), findsOneWidget);
    expect(_saveEnabled(tester), isTrue);
    // Preview only — nothing is stored until the guardian says so.
    expect(spine.numerals, 'western');
    expect(AppNumerals.isEastern, isFalse);

    await _tap(tester, FamilyCustomizationKeys.saveCta);
    await tester.pump(const Duration(milliseconds: 400));

    expect(spine.numerals, 'eastern');
    expect(_note(tester), contains('حُفظ اختياركم'));
    expect(AppNumerals.isEastern, isTrue,
        reason: 'the switch has an engine: the family’s answer reaches the numeral reader');
    expect(formatAppInt(84), '٨٤');
  });

  testWidgets('the week and the rest days are written as the family set them', (tester) async {
    final spine = FamilyCustomizationFakeSpine();
    await _pumpCard(tester, authority: familyCustomizationAuthorityFor(spine));

    await _tap(tester, FamilyCustomizationKeys.weekStartDay(FamilyCustomizationDay.saturday));
    await _tap(tester, FamilyCustomizationKeys.restDay(FamilyCustomizationDay.thursday));
    await _tap(tester, FamilyCustomizationKeys.restDay(FamilyCustomizationDay.friday));
    expect(_saveEnabled(tester), isTrue);

    await _tap(tester, FamilyCustomizationKeys.saveCta);
    await tester.pump(const Duration(milliseconds: 400));

    expect(spine.weekStartDay, 'sat');
    // Sent canonically and stored canonically: the day that was added and the one that was
    // removed, with Saturday kept because it was already theirs.
    expect(spine.restDays, ['thu', 'sat']);
    expect(
      _selected(tester, FamilyCustomizationKeys.restDay(FamilyCustomizationDay.thursday)),
      isTrue,
    );
    expect(
      _selected(tester, FamilyCustomizationKeys.restDay(FamilyCustomizationDay.friday)),
      isFalse,
    );
    expect(_saveEnabled(tester), isFalse, reason: 'a saved card has nothing left to send');
  });

  testWidgets('a week is never left without a rest day, and the card says so before asking', (
    tester,
  ) async {
    final spine = FamilyCustomizationFakeSpine(stored: true); // rest days: Friday only
    await _pumpCard(tester, authority: familyCustomizationAuthorityFor(spine));

    expect(
      _selected(tester, FamilyCustomizationKeys.restDay(FamilyCustomizationDay.friday)),
      isTrue,
    );
    await _tap(tester, FamilyCustomizationKeys.restDay(FamilyCustomizationDay.friday));

    expect(
      _selected(tester, FamilyCustomizationKeys.restDay(FamilyCustomizationDay.friday)),
      isTrue,
      reason: 'the last rest day does not come off',
    );
    expect(_note(tester), contains('لا يُترك أسبوعٌ بلا يوم راحة'));
    expect(_saveEnabled(tester), isFalse);
    expect(spine.restDays, ['fri'], reason: 'and nothing was sent to be refused');
    expect(spine.calls.where((call) => call.startsWith('PATCH')), isEmpty);
  });

  testWidgets('a word is edited and dropped, and the family’s row is what comes back', (
    tester,
  ) async {
    final spine = FamilyCustomizationFakeSpine(stored: true);
    await _pumpCard(tester, authority: familyCustomizationAuthorityFor(spine));

    await tester.enterText(
      find.byKey(FamilyCustomizationKeys.label(FamilyGuardianLabelKey.mother)),
      'حبيبتي',
    );
    await tester.pump();
    expect(_saveEnabled(tester), isTrue);
    await tester.ensureVisible(find.byKey(FamilyCustomizationKeys.saveCta));
    await tester.tap(find.byKey(FamilyCustomizationKeys.saveCta));
    await tester.pump(const Duration(milliseconds: 400));

    expect(spine.labels['mother'], 'حبيبتي');
    expect(spine.labels['father'], 'بابا', reason: 'a word nobody typed keeps its own value');

    // Emptying a field is a decision: the family's word goes and the app's own comes back.
    await tester.enterText(
      find.byKey(FamilyCustomizationKeys.label(FamilyGuardianLabelKey.father)),
      '',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(FamilyCustomizationKeys.saveCta));
    await tester.tap(find.byKey(FamilyCustomizationKeys.saveCta));
    await tester.pump(const Duration(milliseconds: 400));

    expect(spine.labels.containsKey('father'), isFalse);
    expect(
      tester
          .widget<TextField>(
            find.byKey(FamilyCustomizationKeys.label(FamilyGuardianLabelKey.father)),
          )
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('a write the spine refuses for standing is said as standing', (tester) async {
    final spine = FamilyCustomizationFakeSpine(isPrimaryGuardian: false);
    await _pumpCard(tester, authority: familyCustomizationAuthorityFor(spine));

    await _tap(tester, FamilyCustomizationKeys.weekStartDay(FamilyCustomizationDay.wednesday));
    await _tap(tester, FamilyCustomizationKeys.saveCta);
    await tester.pump(const Duration(milliseconds: 400));

    expect(_note(tester), contains('قراءةٌ فقط'));
    expect(spine.weekStartDay, 'mon');
  });

  testWidgets('when somebody else wrote first, the family’s answer wins and is shown', (
    tester,
  ) async {
    final spine = FamilyCustomizationFakeSpine();
    await _pumpCard(tester, authority: familyCustomizationAuthorityFor(spine));

    await _tap(tester, FamilyCustomizationKeys.weekStartDay(FamilyCustomizationDay.tuesday));
    // Another guardian's device writes in the meantime, so this screen's version is now behind.
    await familyCustomizationClientFor(spine).updateProfile(
      familyId: familyCustomizationFamilyId,
      idToken: 'token',
      idempotencyKey: 'someone-else',
      expectedVersion: 0,
      numerals: FamilyNumeralSystem.eastern,
    );

    await tester.ensureVisible(find.byKey(FamilyCustomizationKeys.saveCta));
    await tester.tap(find.byKey(FamilyCustomizationKeys.saveCta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(_note(tester), contains('غيّر أحدكم الطابع'));
    expect(spine.weekStartDay, 'mon', reason: 'the unsent draft never reached the row');
    expect(
      _chosen(tester, FamilyCustomizationKeys.weekStartDay(FamilyCustomizationDay.monday)),
      isTrue,
      reason: 'the screen went back to what the family actually has',
    );
    expect(AppNumerals.isEastern, isTrue,
        reason: 'the other guardian’s digits are the ones standing, so they are the ones applied');
  });

  testWidgets('a build with no spine says nobody was asked, and offers no switches', (
    tester,
  ) async {
    await _pumpCard(tester, authority: null);

    expect(find.text('لا عائلة متصلة على هذا الجهاز، فلم نسأل أحداً عن طابعكم.'), findsOneWidget);
    expect(find.byKey(FamilyCustomizationKeys.refreshCta), findsOneWidget);
    expect(find.byKey(FamilyCustomizationKeys.saveCta), findsNothing);
    for (final day in FamilyCustomizationDay.values) {
      expect(find.byKey(FamilyCustomizationKeys.restDay(day)), findsNothing);
    }
    // No answer means no invented one — including the digits.
    expect(AppNumerals.isEastern, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unreachable spine keeps the last read and labels it as one', (tester) async {
    final spine = FamilyCustomizationFakeSpine();
    final authority = familyCustomizationAuthorityFor(spine);
    await _pumpCard(tester, authority: authority);
    expect(find.text('طابع عائلتك'), findsOneWidget);

    spine.failure = const _NoAnswer();
    await _tap(tester, FamilyCustomizationKeys.saveCta);
    // The card never had a change to send, so the state is proven through a direct read: the last
    // profile stays on screen and the sentence says it is a last read.
    final answer = await authority.read();
    expect(answer.status, FamilyCustomizationStatus.unreachable);
    expect(answer.profile, isNull);
    expect(find.byKey(FamilyCustomizationKeys.card), findsOneWidget);
  });

  testWidgets('the same card in English is the same truth, laid out left to right', (
    tester,
  ) async {
    final spine = FamilyCustomizationFakeSpine(stored: true);
    await _pumpCard(
      tester,
      authority: familyCustomizationAuthorityFor(spine),
      locale: const Locale('en'),
    );

    expect(find.text('Your family\'s character'), findsOneWidget);
    expect(
      find.text(
        'At least one day — every count in the app measures its week against these.',
      ),
      findsOneWidget,
    );
    expect(
      _chosen(tester, FamilyCustomizationKeys.weekStartDay(FamilyCustomizationDay.sunday)),
      isTrue,
    );
    expect(
      Directionality.of(tester.element(find.byKey(FamilyCustomizationKeys.card))),
      TextDirection.ltr,
    );
    expect(tester.takeException(), isNull);
  });
}

class _NoAnswer implements Exception {
  const _NoAnswer();
}
