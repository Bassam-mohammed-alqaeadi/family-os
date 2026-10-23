// S3 — the question leaves the handset.
//
// Until now the child's request lived in the device's preferences and the toast said it had
// reached the parents. These tests make that sentence true, and pin what the screen is
// allowed to say when it is not: the local save survives a failed delivery, and the toast
// changes to the honest one.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_models.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_repository.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_screen.dart';
import 'package:family_os/foundation_gate/child_time_request_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

final class _AnsweringTransport implements ChildTimeRequestTransport {
  _AnsweringTransport(this.statusCode, [this.body = '{"request":{}}']);

  final int statusCode;
  final String body;
  final List<String> sent = <String>[];

  @override
  Future<FoundationGateHttpResponse> postAsk({
    required String body,
    required String idempotencyKey,
  }) async {
    sent.add(body);
    return FoundationGateHttpResponse(statusCode: statusCode, body: this.body);
  }
}

final class _BrokenTransport implements ChildTimeRequestTransport {
  @override
  Future<FoundationGateHttpResponse> postAsk({
    required String body,
    required String idempotencyKey,
  }) async => throw const ChildTimeRequestNotPaired();
}

ServiceChildTimeRequestRepository _repository({
  ChildTimeRequestClient? delivery,
}) {
  final store = InMemoryTimeRequestRepository();
  final service = TimeRequestService(repository: store);
  addTearDown(service.dispose);
  return ServiceChildTimeRequestRepository(
    service: service,
    repository: store,
    childId: ChildId('child-1'),
    delivery: delivery,
  );
}

ChildTimeRequestClient _client(ChildTimeRequestTransport transport) =>
    ChildTimeRequestClient(
      transport: transport,
      clock: () => DateTime(2026, 10, 23, 18, 0),
    );

void main() {
  tearDown(AppToast.dismiss);

  test('a filed question is delivered and says so', () async {
    final transport = _AnsweringTransport(201);
    final repo = _repository(delivery: _client(transport));

    await repo.selectMinutes(30);
    final snap = await repo.submit();

    expect(snap.deliveredToServer, isTrue);
    expect(transport.sent, hasLength(1));
    final body = jsonDecode(transport.sent.single) as Map<String, Object?>;
    expect(body, <String, Object?>{
      'request': <String, Object?>{'requestedMinutes': 30, 'reasonCode': 'finishedHomework'},
    });
  });

  test('a handset with no credential keeps the question and says it has not left',
      () async {
    final repo = _repository(delivery: _client(_BrokenTransport()));

    await repo.selectMinutes(20);
    final snap = await repo.submit();

    expect(snap.status, ChildTimeRequestStatus.pending);
    expect(
      snap.deliveredToServer,
      isFalse,
      reason: 'the child asked and the device remembers, but no parent has seen it',
    );
    expect(snap.formLocked, isTrue, reason: 'asking twice is still the same question');
  });

  test('a question already waiting counts as delivered', () async {
    final transport = _AnsweringTransport(
      409,
      '{"error":{"code":"time_request_pending"}}',
    );
    final repo = _repository(delivery: _client(transport));

    await repo.selectMinutes(15);
    final snap = await repo.submit();

    expect(
      snap.deliveredToServer,
      isTrue,
      reason: 'a parent already has an open question from this child',
    );
  });

  test('a cap that does not exist is not a delivered question', () async {
    final transport = _AnsweringTransport(
      409,
      '{"error":{"code":"screen_time_no_cap"}}',
    );
    final repo = _repository(delivery: _client(transport));

    await repo.selectMinutes(15);
    final snap = await repo.submit();

    expect(snap.deliveredToServer, isFalse);
  });

  test('without a delivery channel nothing is claimed either way', () async {
    final repo = _repository();

    await repo.selectMinutes(30);
    final snap = await repo.submit();

    expect(snap.deliveredToServer, isNull);
  });

  testWidgets('the toast never promises a delivery that did not happen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ChildTimeRequestScreen(
          repository: _UndeliveredRepository(),
          onNavigate: (screenId) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(ChildTimeRequestKeys.submitCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildTimeRequestKeys.submitCta));
    await tester.pump();

    expect(
      find.text('حفظنا طلبك على هذا الجهاز، لكنه لم يصل إلى والديك بعد — أعد المحاولة حين يتصل الهاتف.'),
      findsOneWidget,
    );
    expect(find.textContaining('وصل طلبك'), findsNothing);
  });
}

/// A repository whose question is saved and never leaves.
final class _UndeliveredRepository implements ChildTimeRequestRepository {
  ChildTimeRequestSnapshot _snap = childTimeRequestOneFixture();

  @override
  Future<ChildTimeRequestSnapshot> load() async => _snap;

  @override
  Future<ChildTimeRequestSnapshot> selectMinutes(int minutes) async => _snap;

  @override
  Future<ChildTimeRequestSnapshot> selectTrade(String tradeKey) async => _snap;

  @override
  Future<ChildTimeRequestSnapshot> submit() async {
    _snap = _snap.copyWith(
      status: ChildTimeRequestStatus.pending,
      requestedMinutes: _snap.selectedMinutes,
      formLocked: true,
      deliveredToServer: false,
    );
    return _snap;
  }
}
