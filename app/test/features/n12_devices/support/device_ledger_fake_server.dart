// S0 — the spine test server for the device ledger: a transport that answers per path, plus the
// two payloads the spine really returns.
//
// It is shared by the authority test, the panel test and the screen-wiring test on purpose: two
// fakes would drift, and the one that drifted would be the one that stopped catching the bug.
//
// The payloads are written in the server's own wire shape — `reported_at`, `capabilityKey`,
// `expiresAt`, a receipt under `receipt` — because the defects this family of tests exists to catch
// are exactly the ones a hand-built fake object would hide: a screen that shows a timestamp nobody
// reported, or an order state the server never sent.
import 'dart:convert';

import 'package:family_os/features/n12_devices/device_ledger_server_authority.dart';
import 'package:family_os/foundation_gate/family_capability_api_client.dart';
import 'package:family_os/foundation_gate/family_command_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const deviceLedgerFamilyId = '11111111-1111-4111-8111-111111111111';
const deviceLedgerChildId = '22222222-2222-4222-8222-222222222222';
const deviceLedgerDeviceId = '33333333-3333-4333-8333-333333333333';
const deviceLedgerCommandId = '44444444-4444-4444-8444-444444444444';

/// The read paths, as the clients build them.
const deviceLedgerCapabilitiesPath =
    '/v1/families/$deviceLedgerFamilyId/children/$deviceLedgerChildId/device-capabilities';
const deviceLedgerCommandsPath = '/v1/families/$deviceLedgerFamilyId/commands';
const deviceLedgerCommandWritePath =
    '/v1/families/$deviceLedgerFamilyId/children/$deviceLedgerChildId'
    '/devices/$deviceLedgerDeviceId/commands';

/// A transport that answers per path suffix and records every request it was handed.
final class DeviceLedgerFakeTransport implements FoundationGateHttpTransport {
  DeviceLedgerFakeTransport([Map<String, FoundationGateHttpResponse>? responses])
    : responses = Map<String, FoundationGateHttpResponse>.of(responses ?? const {});

  final Map<String, FoundationGateHttpResponse> responses;

  /// Thrown by every verb when set: the way a build with no network is simulated.
  Object? failure;

  final List<String> calls = <String>[];
  final List<String> bodies = <String>[];
  final List<Map<String, String>> headers = <Map<String, String>>[];

  Map<String, Object?>? get lastBody =>
      bodies.isEmpty ? null : jsonDecode(bodies.last) as Map<String, Object?>;

  Map<String, String>? get lastHeaders => headers.isEmpty ? null : headers.last;

  void answer(String pathSuffix, int statusCode, String body) {
    responses[pathSuffix] = FoundationGateHttpResponse(
      statusCode: statusCode,
      body: body,
    );
  }

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('GET ${uri.path}');
    this.headers.add(headers);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('POST ${uri.path}');
    this.headers.add(headers);
    bodies.add(body);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PATCH ${uri.path}');
    this.headers.add(headers);
    bodies.add(body);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PUT ${uri.path}');
    this.headers.add(headers);
    bodies.add(body);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> delete(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('DELETE ${uri.path}');
    this.headers.add(headers);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  FoundationGateHttpResponse _match(Uri uri) {
    for (final entry in responses.entries) {
      if (uri.path.endsWith(entry.key)) return entry.value;
    }
    throw StateError('No canned answer for ${uri.path}');
  }
}

/// One capability row, as the device reported it.
Map<String, Object?> deviceLedgerCapabilityJson(
  String key, {
  String state = 'confirmed',
  String reportedAt = '2026-10-07T09:00:00.000Z',
  String? confirmedAt,
  String? appVersion = '1.4.0',
  String? osVersion = 'Android 15',
  String? evidence,
}) => {
  'capabilityKey': key,
  'state': state,
  'reportedAt': reportedAt,
  if (confirmedAt != null) 'confirmedAt': confirmedAt,
  if (appVersion != null) 'appVersion': appVersion,
  if (osVersion != null) 'osVersion': osVersion,
  if (evidence != null) 'evidence': evidence,
};

/// The guardian read of one child's devices.
String deviceLedgerCapabilitiesJson({
  String deviceId = deviceLedgerDeviceId,
  Map<String, Object?>? capabilities,
  List<Object?>? devices,
}) => jsonEncode({
  'familyId': deviceLedgerFamilyId,
  'childId': deviceLedgerChildId,
  'devices':
      devices ??
      [
        {
          'deviceId': deviceId,
          'capabilities':
              capabilities ??
              {
                'instant_lock': deviceLedgerCapabilityJson(
                  'instant_lock',
                  confirmedAt: '2026-10-01T08:00:00.000Z',
                ),
                'usage_metering': deviceLedgerCapabilityJson(
                  'usage_metering',
                  state: 'permission_needed',
                  reportedAt: '2026-10-07T08:40:00.000Z',
                ),
                'app_block_overlay': deviceLedgerCapabilityJson(
                  'app_block_overlay',
                  state: 'awaiting_setup',
                  reportedAt: '2026-10-07T08:20:00.000Z',
                  appVersion: null,
                  osVersion: null,
                ),
              },
        },
      ],
});

/// One command row, with the receipt the phone sent back for it.
Map<String, Object?> deviceLedgerCommandJson({
  String id = deviceLedgerCommandId,
  String commandType = 'refresh_policy',
  String state = 'applied',
  String createdAt = '2026-10-07T09:00:00.000Z',
  String expiresAt = '2026-10-07T09:02:00.000Z',
  String? receivedAt,
  String? failureReason,
  String? receiptKind,
}) => {
  'id': id,
  'familyId': deviceLedgerFamilyId,
  'childId': deviceLedgerChildId,
  'deviceId': deviceLedgerDeviceId,
  'commandType': commandType,
  'idempotencyKey': 'ledger-test-key',
  'priority': 100,
  'expiresAt': expiresAt,
  'state': state,
  'createdAt': createdAt,
  'payload': <String, Object?>{},
  if (receivedAt != null) 'receivedAt': receivedAt,
  if (failureReason != null) 'failureReason': failureReason,
  if (receiptKind != null)
    'receipt': {
      'commandId': id,
      'receiptKind': receiptKind,
      'effectiveState': <String, Object?>{},
      'observedAtDevice': '2026-10-07T09:00:40.000Z',
      'receivedAtServer': '2026-10-07T09:00:44.000Z',
      if (failureReason != null) 'failureReason': failureReason,
    },
};

String deviceLedgerCommandsJson(List<Object?> commands) =>
    jsonEncode({'commands': commands});

String deviceLedgerCreatedCommandJson({
  String state = 'accepted',
  String commandType = 'refresh_policy',
}) => jsonEncode({
  'command': deviceLedgerCommandJson(commandType: commandType, state: state),
});

/// The authority under test, wired to [transport] and nothing else.
DeviceLedgerAuthority deviceLedgerAuthorityFor(
  DeviceLedgerFakeTransport transport, {
  String? familyId = deviceLedgerFamilyId,
  Future<String> Function()? idToken = _testToken,
}) => DeviceLedgerAuthority(
  capabilities: FamilyCapabilityApiClient(
    configuration: _configuration,
    transport: transport,
  ),
  commands: FamilyCommandApiClient(
    configuration: _configuration,
    transport: transport,
  ),
  idToken: idToken ?? _testToken,
  familyId: () => familyId,
);

final _configuration = FoundationGateConfiguration.fromStagingApiOrigin(
  Uri.parse('https://staging.example.test'),
);

Future<String> _testToken() async => 'test-token';
