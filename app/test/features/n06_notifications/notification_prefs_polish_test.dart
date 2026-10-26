import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/i18n/numeral_format.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/policy/notification_prefs_repository.dart';
import 'package:family_os/features/n06_notifications/device_notification_permission.dart';
import 'package:family_os/features/n06_notifications/notification_prefs_screen.dart';

/// The polished surface of SCR-FAT-058 — what the screen promises about its own state.
///
/// These are not the acceptance lines of SET-010/011 (those stay pinned in
/// `notification_prefs_screen_test.dart` and `ui_010_quiet_hours_sos_test.dart`). They pin the four
/// things the polish added, each of which is a claim a parent acts on: a change that is not saved
/// says so and can be taken back; a disabled save explains itself; the "what happens right now"
/// line is the app's own gate speaking; and the screen states where its rows live, following the
/// repository it was given rather than a caption.
/// The screen is taller than the default 800×600 test surface, and a `ListView` only builds what
/// it can show — so the tests that reach a stepper or a state line ask for a tall phone first.
/// The idiom is the one `link_success_screen_test.dart` already uses.
Future<void> _tallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pump(
  WidgetTester tester, {
  required NotificationPrefsRepository repository,
  required AppRole role,
  String? memberId,
  DateTime Function()? now,
  Locale locale = const Locale('ar'),
  bool twentyFour = true,
  Key? screenKey,
  DeviceNotificationPermissionBridge? permissionBridge,
}) async {
  await _tallSurface(tester);
  await tester.pumpWidget(
    CurrentRole(
      notifier: RoleController(role),
      child: MaterialApp(
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
          ).copyWith(alwaysUse24HourFormat: twentyFour),
          child: child ?? const SizedBox.shrink(),
        ),
        home: NotificationPrefsScreen(
          key: screenKey,
          memberId: memberId,
          repository: repository,
          now: now,
          permissionBridge:
              permissionBridge ??
              _AnsweringPermissionBridge(DeviceNotificationPermission.granted),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A repository whose rows live on the family account — the shape the wiring slice will ship.
final class _ServerBackedRepository implements NotificationPrefsRepository {
  _ServerBackedRepository([Map<String, NotificationPrefs>? seed])
    : _byMember = {if (seed != null) for (final e in seed.entries) e.key: e.value};

  final Map<String, NotificationPrefs> _byMember;

  @override
  bool get serverBacked => true;

  @override
  Future<NotificationPrefs> load(String memberId) async =>
      _byMember[memberId] ?? NotificationPrefs.defaults(memberId: memberId);

  @override
  Future<void> save(NotificationPrefs prefs) async =>
      _byMember[prefs.memberId] = prefs;

  @override
  Future<void> setSosMuted(String memberId, bool muted) async {
    throw ForbiddenSosMuteFieldException('setSosMuted');
  }

}

/// A repository that refuses to write, so the screen's failure honesty is testable.
final class _FailingRepository implements NotificationPrefsRepository {
  @override
  bool get serverBacked => false;

  @override
  Future<NotificationPrefs> load(String memberId) async =>
      const NotificationPrefs(
        memberId: 'father',
        quietHoursEnabled: true,
        quietStart: TimeOfDay(hour: 22, minute: 0),
        quietEnd: TimeOfDay(hour: 7, minute: 0),
      );

  @override
  Future<void> save(NotificationPrefs prefs) async {
    throw StateError('storage refused');
  }

  @override
  Future<void> setSosMuted(String memberId, bool muted) async {
    throw ForbiddenSosMuteFieldException('setSosMuted');
  }
}

/// Taps a control that may be below the fold: scrolling first is what a finger does, and a tap
/// that lands on empty canvas only warns — which is how a test can pass on a screen nobody reaches.
/// Answers the way a handset would: one answer until asked, another after.
final class _AnsweringPermissionBridge extends DeviceNotificationPermissionBridge {
  _AnsweringPermissionBridge(
    this.answer, {
    DeviceNotificationPermission? afterRequest,
  }) : reply = afterRequest;

  DeviceNotificationPermission answer;
  final DeviceNotificationPermission? reply;
  int requests = 0;

  @override
  Future<DeviceNotificationPermission> status() async => answer;

  @override
  Future<DeviceNotificationPermission> request() async {
    requests++;
    if (reply != null) answer = reply!;
    return answer;
  }
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(AppToast.dismiss);
  tearDown(AppNumerals.clearFamilyChoice);

  testWidgets('a nudged time stays a draft until the parent saves it', (
    tester,
  ) async {
    final repo = InMemoryNotificationPrefsRepository({
      'father': const NotificationPrefs(
        memberId: 'father',
        quietHoursEnabled: true,
        quietStart: TimeOfDay(hour: 22, minute: 0),
        quietEnd: TimeOfDay(hour: 7, minute: 0),
      ),
    });
    await _pump(tester, repository: repo, role: AppRole.father, memberId: 'father');

    expect(
      find.byKey(NotificationPrefsKeys.draftBadge),
      findsNothing,
      reason: 'nothing is pending when the screen opens',
    );

    await _tap(tester, NotificationPrefsKeys.quietStartLater);

    expect(find.byKey(NotificationPrefsKeys.draftBadge), findsOneWidget);
    expect(find.text('احفظ وقت الصمت'), findsOneWidget);
    expect(
      (await repo.load('father')).quietStart,
      const TimeOfDay(hour: 22, minute: 0),
      reason: 'the row must still hold the old time while the change is only on screen',
    );

    await _tap(tester, NotificationPrefsKeys.save);
    await tester.pump();
    expect(find.text('تم حفظ إعدادات الإشعارات'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    final saved = await repo.load('father');
    expect(saved.quietStart, const TimeOfDay(hour: 22, minute: 15));
    expect(
      find.byKey(NotificationPrefsKeys.draftBadge),
      findsNothing,
      reason: 'a draft cannot outlive the write that carried it',
    );
  });

  testWidgets('تراجع drops the draft and leaves the row untouched', (
    tester,
  ) async {
    final repo = InMemoryNotificationPrefsRepository({
      'father': const NotificationPrefs(
        memberId: 'father',
        quietHoursEnabled: true,
        quietStart: TimeOfDay(hour: 22, minute: 0),
        quietEnd: TimeOfDay(hour: 7, minute: 0),
      ),
    });
    await _pump(tester, repository: repo, role: AppRole.father, memberId: 'father');

    await _tap(tester, NotificationPrefsKeys.quietStartEarlier);
    expect(find.byKey(NotificationPrefsKeys.draftBadge), findsOneWidget);

    await _tap(tester, NotificationPrefsKeys.undo);

    expect(find.byKey(NotificationPrefsKeys.draftBadge), findsNothing);
    expect(
      (await repo.load('father')).quietStart,
      const TimeOfDay(hour: 22, minute: 0),
    );
    expect(find.text('22:00'), findsWidgets);
  });

  testWidgets('a silence of zero length is refused, and says why', (tester) async {
    final repo = InMemoryNotificationPrefsRepository({
      'father': const NotificationPrefs(
        memberId: 'father',
        quietHoursEnabled: true,
        quietStart: TimeOfDay(hour: 22, minute: 0),
        quietEnd: TimeOfDay(hour: 22, minute: 0),
      ),
    });
    await _pump(tester, repository: repo, role: AppRole.father, memberId: 'father');

    expect(
      find.text(
        'البداية والنهاية الوقت نفسه — اختر وقتين مختلفين ليبدأ الصمت ويتوقف',
      ),
      findsOneWidget,
    );

    await _tap(tester, NotificationPrefsKeys.save);
    expect(
      find.text('تم حفظ إعدادات الإشعارات'),
      findsNothing,
      reason: 'an invalid window must never reach the row',
    );
  });

  testWidgets('the state line is the gate speaking, not a caption', (
    tester,
  ) async {
    const quiet = NotificationPrefs(
      memberId: 'father',
      quietHoursEnabled: true,
      quietStart: TimeOfDay(hour: 22, minute: 0),
      quietEnd: TimeOfDay(hour: 7, minute: 0),
    );

    await _pump(
      tester,
      repository: InMemoryNotificationPrefsRepository({'father': quiet}),
      role: AppRole.father,
      memberId: 'father',
      now: () => DateTime(2026, 1, 1, 23, 30),
      screenKey: const Key('inside'),
    );
    expect(
      find.text('الآن أنت داخل وقت الصمت: لا يصلك إلا نداء الاستغاثة'),
      findsOneWidget,
    );

    await _pump(
      tester,
      repository: InMemoryNotificationPrefsRepository({'father': quiet}),
      role: AppRole.father,
      memberId: 'father',
      now: () => DateTime(2026, 1, 1, 9, 0),
      screenKey: const Key('outside'),
    );
    expect(
      find.text('الآن أنت خارج وقت الصمت: تصلك التنبيهات العادية لحظة حدوثها'),
      findsOneWidget,
    );

    await _pump(
      tester,
      repository: InMemoryNotificationPrefsRepository({
        'father': const NotificationPrefs(memberId: 'father'),
      }),
      role: AppRole.father,
      memberId: 'father',
      now: () => DateTime(2026, 1, 1, 23, 30),
      screenKey: const Key('inside'),
    );
    expect(
      find.text('وقت الصمت متوقف: كل تنبيه يصلك لحظة حدوثه'),
      findsOneWidget,
    );
  });

  testWidgets('the quiet window tells its length in the family digits', (
    tester,
  ) async {
    final repo = InMemoryNotificationPrefsRepository({
      'father': const NotificationPrefs(
        memberId: 'father',
        quietHoursEnabled: true,
        quietStart: TimeOfDay(hour: 22, minute: 0),
        quietEnd: TimeOfDay(hour: 7, minute: 30),
      ),
    });
    await _pump(tester, repository: repo, role: AppRole.father, memberId: 'father');

    expect(find.text('مدة الصمت: 9 ساعة و30 دقيقة'), findsOneWidget);
    expect(
      find.text('يمتدّ من مساء اليوم إلى فجر الغد'),
      findsOneWidget,
      reason: '22:00 to 07:30 is tonight into tomorrow, and that must be said',
    );

    AppNumerals.applyFamilyChoice(AppNumeralSystem.eastern);
    await _pump(
      tester,
      repository: repo,
      role: AppRole.father,
      memberId: 'father',
      screenKey: const Key('eastern-digits'),
    );
    expect(find.text('٢٢:٠٠'), findsWidgets);
    expect(find.text('مدة الصمت: ٩ ساعة و٣٠ دقيقة'), findsOneWidget);
  });

  testWidgets('the screen names where its rows live, following its repository', (
    tester,
  ) async {
    await _pump(
      tester,
      repository: InMemoryNotificationPrefsRepository(),
      role: AppRole.father,
      memberId: 'father',
      screenKey: const Key('on-handset'),
    );
    expect(
      find.text('محفوظٌ على هذا الجهاز وحده — لا تقرأه بقية أجهزتك'),
      findsOneWidget,
    );
    expect(find.textContaining('في حساب عائلتك'), findsNothing);
    expect(
      find.text(
        'لا تُرسَل إشعارات في هذا الإصدار — اختياراتك تُحفظ إلى أن يبدأ الإرسال',
      ),
      findsOneWidget,
    );

    await _pump(
      tester,
      repository: _ServerBackedRepository(),
      role: AppRole.father,
      memberId: 'father',
      screenKey: const Key('in-family-account'),
    );
    expect(
      find.text('في حساب عائلتك — كل أجهزتك تقرؤها'),
      findsOneWidget,
      reason: 'the day the row is server-backed, the copy changes by itself',
    );
    expect(find.textContaining('محفوظٌ على هذا الجهاز'), findsNothing);
  });

  testWidgets('a write that fails keeps what the parent picked', (tester) async {
    await _pump(
      tester,
      repository: _FailingRepository(),
      role: AppRole.father,
      memberId: 'father',
    );

    await _tap(tester, NotificationPrefsKeys.quietStartLater);
    expect(find.text('22:15'), findsWidgets);

    await _tap(tester, NotificationPrefsKeys.save);
    await tester.pump();
    expect(find.text('تعذر الحفظ — حاول مرة أخرى'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(
      find.text('22:15'),
      findsWidgets,
      reason: 'a failed save must not roll the screen back in silence',
    );
    expect(find.byKey(NotificationPrefsKeys.draftBadge), findsOneWidget);
    expect(
      find.text('لم يُحفظ التغيير بعد — يمكنك المحاولة مرة أخرى، وسنبقي ما اخترته'),
      findsOneWidget,
    );
  });

  testWidgets('a child reads the screen and is told who owns it', (tester) async {
    await _pump(
      tester,
      repository: InMemoryNotificationPrefsRepository({
        'child': const NotificationPrefs(
          memberId: 'child',
          quietHoursEnabled: true,
          quietStart: TimeOfDay(hour: 21, minute: 0),
          quietEnd: TimeOfDay(hour: 6, minute: 30),
        ),
      }),
      role: AppRole.child,
      memberId: 'child',
    );

    expect(
      find.text('إعدادات الإشعارات هنا يملكها والدك — يمكنك قراءتها دون أن تغيّرها'),
      findsOneWidget,
    );
    expect(find.byKey(NotificationPrefsKeys.quietStartLater), findsNothing);
    expect(find.byKey(NotificationPrefsKeys.save), findsOneWidget);

    // The button itself, not the widget it happens to be built on: a read-only row has no write
    // to offer, and that must stay true if PrimaryBtn changes its internals.
    final save = tester.widget<PrimaryBtn>(find.byKey(NotificationPrefsKeys.save));
    expect(save.onPressed, isNull);
    expect(save.label, 'حفظ الإشعارات');
  });

  testWidgets('a handset that blocks notifications stops the page promising delivery', (tester) async {
    // The launch case the audit found: every family setting says "send it", and the operating
    // system says "you may not display anything". A screen that reads only its own settings is a
    // lying screen, so the page states the refusal and offers the ask.
    final repo = _ServerBackedRepository();
    final bridge = _AnsweringPermissionBridge(
      DeviceNotificationPermission.denied,
      afterRequest: DeviceNotificationPermission.granted,
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.father,
      memberId: 'father',
      screenKey: const Key('permission-denied'),
      permissionBridge: bridge,
    );

    final banner = find.byKey(NotificationPrefsKeys.devicePermission);
    expect(tester.widget<BannerNote>(banner).message, contains('يمنع الإشعارات'));
    expect(tester.widget<BannerNote>(banner).variant, BannerVariant.a);
    expect(find.text('إشعارات هذا الهاتف مسموحة'), findsNothing);

    await _tap(tester, NotificationPrefsKeys.devicePermissionRequest);
    expect(bridge.requests, 1);
    expect(
      tester.widget<BannerNote>(banner).message,
      contains('إشعارات هذا الهاتف مسموحة'),
    );
    expect(
      find.byKey(NotificationPrefsKeys.devicePermissionRequest),
      findsNothing,
      'an answered question stops being a button',
    );
  });

  testWidgets('no answer from the device is reported as no answer', (tester) async {
    // A build whose device channel does not reply must not be shown as "allowed" — that is the
    // same claim in a different font. And there is nothing to tap, so no button is invented.
    final repo = _ServerBackedRepository();
    await _pump(
      tester,
      repository: repo,
      role: AppRole.father,
      memberId: 'father',
      screenKey: const Key('permission-unknown'),
      permissionBridge: _AnsweringPermissionBridge(
        DeviceNotificationPermission.unknownAnswer,
      ),
    );

    expect(
      tester.widget<BannerNote>(
        find.byKey(NotificationPrefsKeys.devicePermission),
      ).message,
      contains('لم نتمكن من قراءة إذن العرض'),
    );
    expect(
      find.byKey(NotificationPrefsKeys.devicePermissionRequest),
      findsNothing,
    );
  });
}
