// S0 — the device ledger authority, and the four ways it refuses to guess.
//
// This file is the reason the ledger can be trusted at all. Every state below is a decision not to
// invent something: a build with no session asks nobody; a device record that is not a server child
// is named as such instead of answering "no capabilities", which a parent would read as "nothing is
// protected"; a socket that dies is called unreachable, not unreadable, because nobody replied; and
// a write the server refuses comes back with the server's own reason rather than a green tick.
//
// The tests also pin the two things that keep this screen from becoming a second door into the same
// power: it issues `refresh_policy` and nothing else, and it never sends an id the server would
// have to reject.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n12_devices/device_ledger_server_authority.dart';
import 'package:family_os/foundation_gate/family_capability_api_client.dart';
import 'package:family_os/foundation_gate/family_command_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

import 'support/device_ledger_fake_server.dart';

void main() {
  tearDown(() => DeviceLedgerAuthority.bind(null));

  test('a build with no server session asks nobody, and says so', () async {
    final transport = DeviceLedgerFakeTransport({
      deviceLedgerCapabilitiesPath: const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{}',
      ),
    });
    final authority = deviceLedgerAuthorityFor(transport, familyId: null);

    final answer = await authority.read(childId: deviceLedgerChildId);

    expect(answer.status, DeviceLedgerStatus.notConfigured);
    expect(answer.isReady, isFalse);
    // The call list is the real assertion: a screen that "shows nothing" after asking nothing has
    // invented an answer, and nobody can tell from the picture.
    expect(transport.calls, isEmpty);
  });

  test('a placeholder child record is named, not answered with an empty ledger', () async {
    // The stage-one seam keys devices `child_a` / `fam_stage1`. Those are not server ids, and
    // sending one would make the server's 404 look like a fact about the child.
    final transport = DeviceLedgerFakeTransport();
    final authority = deviceLedgerAuthorityFor(transport);

    final answer = await authority.read(childId: 'child_a');

    expect(answer.status, DeviceLedgerStatus.notLinked);
    expect(transport.calls, isEmpty);
  });

  test('a placeholder device id never reaches the server at all', () async {
    final transport = DeviceLedgerFakeTransport();
    final authority = deviceLedgerAuthorityFor(transport);

    final read = await authority.read(
      childId: deviceLedgerChildId,
      deviceId: 'dev_a',
    );
    final write = await authority.requestPolicyRefresh(
      childId: deviceLedgerChildId,
      deviceId: 'dev_a',
      idempotencyKey: 'ledger-refresh-1',
    );

    expect(read.status, DeviceLedgerStatus.notLinked);
    expect(write.status, DeviceLedgerStatus.notLinked);
    expect(write.refusal, DeviceLedgerRefusal.none);
    expect(transport.calls, isEmpty);
  });

  test('a real reading keeps the phone\'s order, times and versions', () async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(
      deviceLedgerCapabilitiesPath,
      200,
      deviceLedgerCapabilitiesJson(),
    );
    transport.answer(deviceLedgerCommandsPath, 200, deviceLedgerCommandsJson([]));
    final authority = deviceLedgerAuthorityFor(transport);

    final answer = await authority.read(
      childId: deviceLedgerChildId,
      deviceId: deviceLedgerDeviceId,
    );

    expect(answer.status, DeviceLedgerStatus.ready, reason: '${answer.status}');
    final reading = answer.value!;
    expect(reading.capabilities.length, 3);
    expect(reading.workingCount, 1);
    expect(reading.waitingCount, 2);
    expect(reading.instantLockConfirmed, isTrue);
    // Enforcement first, then what it rests on, then what only observes. Alphabetical order here
    // would bury the one line a parent came to read.
    expect(reading.capabilities.first.key, FoundationGateCapabilityKey.instantLock);
    // The fixture reported these three at different minutes; the ledger ignores both the server's
    // map order and the clock, because what protects the child is listed first.
    expect(
      reading.capabilities.map((row) => row.key).toList(),
      const [
        FoundationGateCapabilityKey.instantLock,
        FoundationGateCapabilityKey.appBlockOverlay,
        FoundationGateCapabilityKey.usageMetering,
      ],
    );
    expect(
      reading.capabilities[1].record.state,
      FoundationGateCapabilityState.awaitingSetup,
    );
    expect(
      reading.capabilities[2].record.state,
      FoundationGateCapabilityState.permissionNeeded,
    );
    expect(reading.lastReportAt, isNotNull);
    expect(reading.lastReportAt!.toIso8601String(), startsWith('2026-10-07T09:00'));
    expect(
      transport.calls,
      const [
        'GET $deviceLedgerCapabilitiesPath',
        'GET $deviceLedgerCommandsPath',
      ],
    );
  });

  test('a server that will not show this account the child says exactly that', () async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(deviceLedgerCapabilitiesPath, 403, '{}');
    final authority = deviceLedgerAuthorityFor(transport);

    final answer = await authority.read(childId: deviceLedgerChildId);

    expect(answer.status, DeviceLedgerStatus.accessDenied);
    expect(answer.value, isNull);
  });

  test('an answer that cannot be read is a defect, not an empty ledger', () async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(deviceLedgerCapabilitiesPath, 200, '{"familyId":42}');
    final authority = deviceLedgerAuthorityFor(transport);

    final answer = await authority.read(childId: deviceLedgerChildId);

    expect(answer.status, DeviceLedgerStatus.unreadable);
  });

  test('no answer at all is called unreachable, not unreadable', () async {
    final transport = DeviceLedgerFakeTransport();
    transport.failure = const SocketException('offline');
    final authority = deviceLedgerAuthorityFor(transport);

    final answer = await authority.read(childId: deviceLedgerChildId);

    expect(answer.status, DeviceLedgerStatus.unreachable);
  });

  test('a lost order list does not throw the capability truth away', () async {
    // Two reads, two answers. Blanketing the panel because the second one failed would hide what
    // the phone did report; claiming "no orders" would invent a fact.
    final transport = DeviceLedgerFakeTransport();
    transport.answer(deviceLedgerCapabilitiesPath, 200, deviceLedgerCapabilitiesJson());
    transport.answer(deviceLedgerCommandsPath, 403, '{}');
    final authority = deviceLedgerAuthorityFor(transport);

    final answer = await authority.read(childId: deviceLedgerChildId);

    expect(answer.status, DeviceLedgerStatus.ready);
    expect(answer.value!.capabilities.length, 3);
    expect(answer.value!.orders, isEmpty);
    expect(answer.value!.ordersStatus, DeviceLedgerStatus.accessDenied);
  });

  test('a refresh order is written once, as the server defines it', () async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(
      deviceLedgerCommandWritePath,
      201,
      deviceLedgerCreatedCommandJson(),
    );
    final authority = deviceLedgerAuthorityFor(transport);

    final answer = await authority.requestPolicyRefresh(
      childId: deviceLedgerChildId,
      deviceId: deviceLedgerDeviceId,
      idempotencyKey: 'ledger-refresh-1',
    );

    expect(answer.isReady, isTrue, reason: '${answer.status}');
    expect(answer.value!.state, FoundationGateCommandState.accepted);
    expect(transport.calls, const ['POST $deviceLedgerCommandWritePath']);
    expect(transport.lastBody!['commandType'], 'refresh_policy');
    expect(transport.lastBody!['deviceId'], deviceLedgerDeviceId);
    expect(transport.lastBody!['ttlSeconds'], 120);
    expect(transport.lastBody!['priority'], 100);
    // The key that makes a retry safe, and the session that makes it authorised, are the two
    // headers this screen must never forget.
    expect(transport.lastHeaders!['idempotency-key'], 'ledger-refresh-1');
    expect(transport.lastHeaders!['authorization'], contains('test-token'));
  });

  test('a device the server will not order about is named, not blurred', () async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(deviceLedgerCommandWritePath, 404, '{}');
    final authority = deviceLedgerAuthorityFor(transport);

    final answer = await authority.requestPolicyRefresh(
      childId: deviceLedgerChildId,
      deviceId: deviceLedgerDeviceId,
      idempotencyKey: 'ledger-refresh-2',
    );

    // The 404 came from the server, so the server was asked — and what it said is kept: this
    // device will not take orders. That is a different sentence from a refused read, and a parent
    // can act on it.
    expect(answer.status, DeviceLedgerStatus.refused);
    expect(answer.refusal, DeviceLedgerRefusal.deviceNotEligible);
    expect(transport.calls, const ['POST $deviceLedgerCommandWritePath']);
  });

  test('a refusal the server explains is carried to the screen', () async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(deviceLedgerCommandWritePath, 409, '{}');
    final authority = deviceLedgerAuthorityFor(transport);

    final answer = await authority.requestPolicyRefresh(
      childId: deviceLedgerChildId,
      deviceId: deviceLedgerDeviceId,
      idempotencyKey: 'ledger-refresh-3',
    );

    expect(answer.status, DeviceLedgerStatus.refused);
    expect(answer.refusal, DeviceLedgerRefusal.unexplained);
    expect(transport.calls.length, 1);
  });

  test('a capability the phone has not confirmed is reported, never assumed', () async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(
      deviceLedgerCapabilitiesPath,
      200,
      deviceLedgerCapabilitiesJson(
        capabilities: {
          'instant_lock': deviceLedgerCapabilityJson(
            'instant_lock',
            state: 'unsupported',
          ),
        },
      ),
    );
    transport.answer(deviceLedgerCommandsPath, 200, deviceLedgerCommandsJson([]));
    final authority = deviceLedgerAuthorityFor(transport);

    final reading = (await authority.read(childId: deviceLedgerChildId)).value!;

    expect(reading.instantLockConfirmed, isFalse);
    expect(reading.workingCount, 0);
    expect(reading.capabilities.single.record.osVersion, 'Android 15');
  });

  test('nothing is bound until the application binds it', () {
    expect(DeviceLedgerAuthority.bound, isNull);
  });
}
