import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';

/// One position statement made at the moment the button was pressed.
///
/// The values are the server's own vocabulary. `acquiring` and `unavailable` are real
/// answers - the handset looked and could not say - and they carry no coordinates. A
/// screen that turned "we could not look" into a place would be sending a family to a
/// door it guessed.
enum FoundationGateSosLocationClass {
  ready,
  acquiring,
  staleLastKnown,
  unavailable;

  bool get carriesCoordinates =>
      this == FoundationGateSosLocationClass.ready ||
      this == FoundationGateSosLocationClass.staleLastKnown;

  static FoundationGateSosLocationClass? parse(Object? value) {
    return switch (value) {
      'ready' => FoundationGateSosLocationClass.ready,
      'acquiring' => FoundationGateSosLocationClass.acquiring,
      'stale_last_known' => FoundationGateSosLocationClass.staleLastKnown,
      'unavailable' => FoundationGateSosLocationClass.unavailable,
      _ => null,
    };
  }

  String get wireValue => switch (this) {
    FoundationGateSosLocationClass.ready => 'ready',
    FoundationGateSosLocationClass.acquiring => 'acquiring',
    FoundationGateSosLocationClass.staleLastKnown => 'stale_last_known',
    FoundationGateSosLocationClass.unavailable => 'unavailable',
  };
}

enum FoundationGateSosConnectionClass {
  online,
  degraded,
  offline;

  static FoundationGateSosConnectionClass? parse(Object? value) {
    return switch (value) {
      'online' => FoundationGateSosConnectionClass.online,
      'degraded' => FoundationGateSosConnectionClass.degraded,
      'offline' => FoundationGateSosConnectionClass.offline,
      _ => null,
    };
  }

  String get wireValue => switch (this) {
    FoundationGateSosConnectionClass.online => 'online',
    FoundationGateSosConnectionClass.degraded => 'degraded',
    FoundationGateSosConnectionClass.offline => 'offline',
  };
}

enum FoundationGateSosAlertStatus {
  active,
  acknowledged,
  escalating,
  resolved;

  bool get isOpen => this != FoundationGateSosAlertStatus.resolved;

  static FoundationGateSosAlertStatus? parse(Object? value) {
    return switch (value) {
      'active' => FoundationGateSosAlertStatus.active,
      'acknowledged' => FoundationGateSosAlertStatus.acknowledged,
      'escalating' => FoundationGateSosAlertStatus.escalating,
      'resolved' => FoundationGateSosAlertStatus.resolved,
      _ => null,
    };
  }
}

enum FoundationGateSosTerminalReason {
  helped,
  falseAlarm,
  other;

  static FoundationGateSosTerminalReason? parse(Object? value) {
    return switch (value) {
      'helped' => FoundationGateSosTerminalReason.helped,
      'false_alarm' => FoundationGateSosTerminalReason.falseAlarm,
      'other' => FoundationGateSosTerminalReason.other,
      _ => null,
    };
  }

  String get wireValue => switch (this) {
    FoundationGateSosTerminalReason.helped => 'helped',
    FoundationGateSosTerminalReason.falseAlarm => 'false_alarm',
    FoundationGateSosTerminalReason.other => 'other',
  };
}

/// What the platform can honestly claim it did with one recipient.
///
/// There is no `delivered` value, on purpose and at the database. A row is either
/// `recorded` - a durable payload was written for a transport to pick up - or
/// `notConfigured`, with a reason. This client cannot express a delivery nobody made,
/// which is the whole point of the two-value enum.
enum FoundationGateSosDeliveryState {
  recorded,
  notConfigured;

  static FoundationGateSosDeliveryState? parse(Object? value) {
    return switch (value) {
      'recorded' => FoundationGateSosDeliveryState.recorded,
      'not_configured' => FoundationGateSosDeliveryState.notConfigured,
      _ => null,
    };
  }
}

enum FoundationGateSosBackupVerification {
  unverified,
  verified,
  revoked;

  bool get escalates => this == FoundationGateSosBackupVerification.verified;

  static FoundationGateSosBackupVerification? parse(Object? value) {
    return switch (value) {
      'unverified' => FoundationGateSosBackupVerification.unverified,
      'verified' => FoundationGateSosBackupVerification.verified,
      'revoked' => FoundationGateSosBackupVerification.revoked,
      _ => null,
    };
  }

  String get wireValue => switch (this) {
    FoundationGateSosBackupVerification.unverified => 'unverified',
    FoundationGateSosBackupVerification.verified => 'verified',
    FoundationGateSosBackupVerification.revoked => 'revoked',
  };
}

/// The picture as it was stored with the press, not as it is now.
class FoundationGateSosPicture {
  const FoundationGateSosPicture({
    required this.locationClass,
    required this.connectionClass,
    required this.panicQuiet,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.batteryPercent,
    this.placeLabel,
    this.fixId,
  });

  final FoundationGateSosLocationClass locationClass;
  final FoundationGateSosConnectionClass connectionClass;
  final bool panicQuiet;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final int? batteryPercent;
  final String? placeLabel;

  /// The trail sample this press points at, when the handset had one.
  final String? fixId;

  bool get hasPosition => latitude != null && longitude != null;
}

class FoundationGateSosDelivery {
  const FoundationGateSosDelivery({
    required this.recipientKind,
    required this.channel,
    required this.deliveryState,
    this.recipientMembershipId,
    this.recipientContactId,
    this.reasonCode,
    this.createdAt,
  });

  final String recipientKind;
  final String channel;
  final FoundationGateSosDeliveryState deliveryState;
  final String? recipientMembershipId;
  final String? recipientContactId;

  /// Present exactly when the state is [FoundationGateSosDeliveryState.notConfigured].
  final String? reasonCode;
  final DateTime? createdAt;
}

class FoundationGateSosAlert {
  const FoundationGateSosAlert({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.raisedByKind,
    required this.status,
    required this.picture,
    required this.deliveries,
    required this.version,
    this.raisedByMembershipId,
    this.pressedAt,
    this.receivedAt,
    this.acknowledgedAt,
    this.escalatedAt,
    this.resolvedAt,
    this.terminalReason,
    this.resolvedByKind,
  });

  final String id;
  final String familyId;
  final String childId;
  final String raisedByKind;
  final FoundationGateSosAlertStatus status;
  final FoundationGateSosPicture picture;
  final List<FoundationGateSosDelivery> deliveries;
  final int version;
  final String? raisedByMembershipId;
  final DateTime? pressedAt;
  final DateTime? receivedAt;
  final DateTime? acknowledgedAt;
  final DateTime? escalatedAt;
  final DateTime? resolvedAt;
  final FoundationGateSosTerminalReason? terminalReason;

  /// `guardian`, `child_device`, or null while the incident is open.
  final String? resolvedByKind;

  bool get isOpen => status.isOpen;
}

class FoundationGateSosEscalationSummary {
  const FoundationGateSosEscalationSummary({
    required this.eligibleContacts,
    required this.skippedUnverified,
  });

  /// Verified and enabled contacts the escalation reached.
  final int eligibleContacts;

  /// Contacts the family added but has not verified. Reported rather than dropped.
  final int skippedUnverified;
}

/// The answer to a press.
///
/// It carries the incident that exists. When one was already open for this child the
/// server answers 409 with that incident's id, and this client turns that into
/// [existingAlertId] rather than an error: pressing the button twice is not a mistake the
/// child made, and the screen should show the incident rather than a failure.
class FoundationGateSosFireOutcome {
  const FoundationGateSosFireOutcome({
    required this.opened,
    this.alert,
    this.existingAlertId,
  });

  final bool opened;
  final FoundationGateSosAlert? alert;
  final String? existingAlertId;

  bool get isDuplicate => existingAlertId != null;
}

class FoundationGateSosEscalationReceipt {
  const FoundationGateSosEscalationReceipt({
    required this.alert,
    required this.escalation,
    required this.replayed,
  });

  final FoundationGateSosAlert alert;
  final FoundationGateSosEscalationSummary escalation;
  final bool replayed;
}

class FoundationGateSosBackupContact {
  const FoundationGateSosBackupContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phoneE164,
    required this.verification,
    required this.enabled,
    required this.priority,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String relation;
  final String phoneE164;
  final FoundationGateSosBackupVerification verification;
  final bool enabled;
  final int priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Only a verified and enabled contact ever escalates.
  bool get escalates => enabled && verification.escalates;
}

/// Everything the emergency surface may ask the server, with a bearer token.
///
/// Nine operations, and one honest gap: the two device-credential routes
/// (`POST /v1/devices/{deviceId}/sos-alerts` and its resolve) belong to the handset's own
/// credential, which this app hands to the native layer at pairing and does not keep. They
/// exist on the server, are covered by the real-PostgreSQL journey, and are deliberately
/// absent here rather than present and unused.
///
/// Nothing in this class invents state. A press that the server refused throws; an incident
/// that already exists is returned as the incident, not as a failure.
class FamilySosApiClient {
  FamilySosApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  /// The family's incidents. `open` is the default because an open one is the one that
  /// needs answering.
  Future<List<FoundationGateSosAlert>> listAlerts({
    required String familyId,
    required String idToken,
    String status = 'open',
  }) async {
    if (!isFoundationGateUuid(familyId)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    if (status != 'open' && status != 'resolved' && status != 'all') {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _get(
      _configuration.familySosAlertsUri(familyId, status: status),
      idToken,
      familyId: familyId,
    );
    return switch (response.statusCode) {
      200 => _parseAlertList(response.body),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// One incident, exactly as every member of the family reads it.
  Future<FoundationGateSosAlert> readAlert({
    required String familyId,
    required String alertId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familySosAlertUri(familyId, alertId),
      idToken,
      familyId: familyId,
    );
    return switch (response.statusCode) {
      200 => _parseAlertEnvelope(response.body),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// A guardian opens an incident for a child whose handset is not the one in use.
  ///
  /// The picture must obey the same law the server enforces: a position needs its accuracy,
  /// and "no position" is expressed by null coordinates rather than by a placeholder.
  Future<FoundationGateSosFireOutcome> raiseForChild({
    required String familyId,
    required String childId,
    required FoundationGateSosLocationClass locationClass,
    required FoundationGateSosConnectionClass connectionClass,
    required String idempotencyKey,
    required String idToken,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    int? batteryPercent,
    String? placeLabel,
    bool panicQuiet = false,
    String? fixId,
    DateTime? pressedAt,
  }) async {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final body = _pressBody(
      locationClass: locationClass,
      connectionClass: connectionClass,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      batteryPercent: batteryPercent,
      placeLabel: placeLabel,
      panicQuiet: panicQuiet,
      fixId: fixId,
      pressedAt: pressedAt,
    );
    final response = await _post(
      _configuration.familyChildSosAlertsUri(familyId, childId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return _fireOutcome(response);
  }

  /// A guardian says "I have seen this". Not the same act as closing it.
  Future<FoundationGateSosAlert> acknowledge({
    required String familyId,
    required String alertId,
    required String idempotencyKey,
    required String idToken,
  }) async {
    final response = await _post(
      _configuration.familySosAlertAcknowledgeUri(familyId, alertId),
      idToken,
      const <String, Object>{},
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      200 => _parseAlertEnvelope(response.body),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      409 => throw const FoundationGateApiException(
        FoundationGateApiFailure.conflict,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// The family's own ladder, climbed in the family's own order.
  Future<FoundationGateSosEscalationReceipt> escalate({
    required String familyId,
    required String alertId,
    required String idempotencyKey,
    required String idToken,
  }) async {
    final response = await _post(
      _configuration.familySosAlertEscalateUri(familyId, alertId),
      idToken,
      const <String, Object>{},
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      200 => _parseEscalationReceipt(response.body),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      409 => throw const FoundationGateApiException(
        FoundationGateApiFailure.conflict,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// A guardian closes the incident, stating why.
  Future<FoundationGateSosAlert> resolve({
    required String familyId,
    required String alertId,
    required FoundationGateSosTerminalReason reason,
    required String idempotencyKey,
    required String idToken,
  }) async {
    final response = await _post(
      _configuration.familySosAlertResolveUri(familyId, alertId),
      idToken,
      <String, Object>{'terminalReason': reason.wireValue},
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      200 => _parseAlertEnvelope(response.body),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      409 => throw const FoundationGateApiException(
        FoundationGateApiFailure.conflict,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// The ladder rung 2 and below, in the family's own order.
  Future<List<FoundationGateSosBackupContact>> listBackupContacts({
    required String familyId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familySosBackupContactsUri(familyId),
      idToken,
      familyId: familyId,
    );
    return switch (response.statusCode) {
      200 => _parseContactList(response.body),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// Adds a rung. It is created unverified whatever this request says, and verifying it is
  /// a separate act - a number that verifies itself on the way in is a number nobody
  /// checked.
  Future<FoundationGateSosBackupContact> createBackupContact({
    required String familyId,
    required String name,
    required String phoneE164,
    required String idempotencyKey,
    required String idToken,
    String? relation,
    int? priority,
    bool? enabled,
  }) async {
    if (!isFoundationGateUuid(familyId)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final body = <String, Object>{
      'name': name,
      'phoneE164': phoneE164,
      if (relation != null) 'relation': relation,
      if (priority != null) 'priority': priority,
      if (enabled != null) 'enabled': enabled,
    };
    final response = await _post(
      _configuration.familySosBackupContactsUri(familyId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return _contactFromWrite(response);
  }

  /// Renames, renumbers, verifies, switches off or archives one rung.
  Future<FoundationGateSosBackupContact> updateBackupContact({
    required String familyId,
    required String contactId,
    required String idempotencyKey,
    required String idToken,
    String? name,
    String? relation,
    String? phoneE164,
    FoundationGateSosBackupVerification? verification,
    bool? enabled,
    int? priority,
    bool? archived,
  }) async {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(contactId)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final body = <String, Object>{
      if (name != null) 'name': name,
      if (relation != null) 'relation': relation,
      if (phoneE164 != null) 'phoneE164': phoneE164,
      if (verification != null) 'verification': verification.wireValue,
      if (enabled != null) 'enabled': enabled,
      if (priority != null) 'priority': priority,
      if (archived != null) 'archived': archived,
    };
    if (body.isEmpty) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _patch(
      _configuration.familySosBackupContactUri(familyId, contactId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return _contactFromWrite(response);
  }

  Map<String, Object> _pressBody({
    required FoundationGateSosLocationClass locationClass,
    required FoundationGateSosConnectionClass connectionClass,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    int? batteryPercent,
    String? placeLabel,
    required bool panicQuiet,
    String? fixId,
    DateTime? pressedAt,
  }) {
    final carries = locationClass.carriesCoordinates;
    // The client's own honesty check, before the server's: a place requires its accuracy,
    // and a press with no place must not carry coordinates or an accuracy.
    if (carries != (latitude != null && longitude != null)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    if (carries && accuracyMeters == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    if (!carries && accuracyMeters != null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    return <String, Object>{
      'locationClass': locationClass.wireValue,
      'connectionClass': connectionClass.wireValue,
      'panicQuiet': panicQuiet,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      if (batteryPercent != null) 'batteryPercent': batteryPercent,
      if (placeLabel != null) 'placeLabel': placeLabel,
      if (fixId != null) 'fixId': fixId,
      if (pressedAt != null) 'pressedAt': pressedAt.toUtc().toIso8601String(),
    };
  }

  FoundationGateSosFireOutcome _fireOutcome(
    FoundationGateHttpResponse response,
  ) {
    switch (response.statusCode) {
      case 201:
        return FoundationGateSosFireOutcome(
          opened: true,
          alert: _parseAlertEnvelope(response.body),
        );
      case 409:
        // The incident that already exists is the answer, not an error: the screen goes to
        // it instead of telling a child that pressing the button twice failed.
        final existing = _existingAlertId(response.body);
        if (existing == null) {
          throw const FoundationGateApiException(
            FoundationGateApiFailure.conflict,
          );
        }
        return FoundationGateSosFireOutcome(
          opened: false,
          existingAlertId: existing,
        );
      case 400:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidInput,
        );
      case 401:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
        );
      case 403:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.accessDenied,
        );
      case 404:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.notFound,
        );
      case 429:
      case 503:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.serviceUnavailable,
        );
      default:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidResponse,
        );
    }
  }

  /// Reads `error.details.alertId` from the 409 body, or null when it is not there.
  String? _existingAlertId(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) return null;
      final error = decoded['error'];
      if (error is! Map<String, Object?>) return null;
      final details = error['details'];
      if (details is! Map<String, Object?>) return null;
      final alertId = details['alertId'];
      if (alertId is! String || !isFoundationGateUuid(alertId)) return null;
      return alertId;
    } catch (_) {
      return null;
    }
  }

  FoundationGateSosBackupContact _contactFromWrite(
    FoundationGateHttpResponse response,
  ) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseContactEnvelope(response.body);
    }
    switch (response.statusCode) {
      case 400:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidInput,
        );
      case 401:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
        );
      case 403:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.accessDenied,
        );
      case 404:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.notFound,
        );
      case 409:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.conflict,
        );
      case 429:
      case 503:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.serviceUnavailable,
        );
      default:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidResponse,
        );
    }
  }

  Future<FoundationGateHttpResponse> _get(
    Uri uri,
    String idToken, {
    required String familyId,
  }) async {
    if (!isFoundationGateUuid(familyId)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    try {
      return await _transport.get(uri, headers: _headers(idToken));
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _post(
    Uri uri,
    String idToken,
    Map<String, Object> body, {
    required String idempotencyKey,
  }) async {
    try {
      return await _transport.post(
        uri,
        headers: {
          ..._headers(idToken),
          'content-type': 'application/json',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode(body),
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _patch(
    Uri uri,
    String idToken,
    Map<String, Object> body, {
    required String idempotencyKey,
  }) async {
    try {
      return await _transport.patch(
        uri,
        headers: {
          ..._headers(idToken),
          'content-type': 'application/json',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode(body),
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Map<String, String> _headers(String idToken) => {
    'accept': 'application/json',
    'authorization': 'Bearer $idToken',
  };

  List<FoundationGateSosAlert> _parseAlertList(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final raw = decoded['alerts'];
      if (raw is! List<Object?>) throw const FormatException();
      return List.unmodifiable(raw.map(_alertFrom));
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateSosAlert _parseAlertEnvelope(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      return _alertFrom(decoded['alert']);
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateSosEscalationReceipt _parseEscalationReceipt(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final escalation = decoded['escalation'];
      if (escalation is! Map<String, Object?>) throw const FormatException();
      final eligible = escalation['eligibleContacts'];
      final skipped = escalation['skippedUnverified'];
      final replayed = decoded['replayed'];
      if (eligible is! int || skipped is! int || replayed is! bool) {
        throw const FormatException();
      }
      return FoundationGateSosEscalationReceipt(
        alert: _alertFrom(decoded['alert']),
        escalation: FoundationGateSosEscalationSummary(
          eligibleContacts: eligible,
          skippedUnverified: skipped,
        ),
        replayed: replayed,
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  List<FoundationGateSosBackupContact> _parseContactList(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final raw = decoded['contacts'];
      if (raw is! List<Object?>) throw const FormatException();
      return List.unmodifiable(raw.map(_contactFrom));
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateSosBackupContact _parseContactEnvelope(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      return _contactFrom(decoded['contact']);
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateSosAlert _alertFrom(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final id = value['id'];
    final familyId = value['familyId'];
    final childId = value['childId'];
    final raisedByKind = value['raisedByKind'];
    final status = FoundationGateSosAlertStatus.parse(value['status']);
    final version = value['version'];
    final pressedAt = _parseTimestamp(value['pressedAt']);
    final receivedAt = _parseTimestamp(value['receivedAt']);
    final rawDeliveries = value['deliveries'];
    if (id is! String ||
        !isFoundationGateUuid(id) ||
        familyId is! String ||
        !isFoundationGateUuid(familyId) ||
        childId is! String ||
        !isFoundationGateUuid(childId) ||
        raisedByKind is! String ||
        status == null ||
        version is! int ||
        version < 1 ||
        pressedAt == null ||
        receivedAt == null ||
        rawDeliveries is! List<Object?>) {
      throw const FormatException();
    }
    // The role's own vocabulary is checked after its type, because a value test on the
    // same variable tells the analyzer nothing about the variable's type.
    if (raisedByKind != 'child_device' && raisedByKind != 'guardian') {
      throw const FormatException();
    }
    final terminalReason = value['terminalReason'];
    final resolvedByKind = value['resolvedByKind'];
    return FoundationGateSosAlert(
      id: id,
      familyId: familyId,
      childId: childId,
      raisedByKind: raisedByKind,
      status: status,
      picture: _pictureFrom(value['picture']),
      deliveries: List.unmodifiable(rawDeliveries.map(_deliveryFrom)),
      version: version,
      raisedByMembershipId: value['raisedByMembershipId'] is String
          ? value['raisedByMembershipId'] as String
          : null,
      pressedAt: pressedAt,
      receivedAt: receivedAt,
      acknowledgedAt: _parseTimestamp(value['acknowledgedAt']),
      escalatedAt: _parseTimestamp(value['escalatedAt']),
      resolvedAt: _parseTimestamp(value['resolvedAt']),
      terminalReason: FoundationGateSosTerminalReason.parse(terminalReason),
      resolvedByKind: resolvedByKind == 'guardian' || resolvedByKind == 'child_device'
          ? resolvedByKind as String
          : null,
    );
  }

  FoundationGateSosPicture _pictureFrom(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final locationClass = FoundationGateSosLocationClass.parse(
      value['locationClass'],
    );
    final connectionClass = FoundationGateSosConnectionClass.parse(
      value['connectionClass'],
    );
    final panicQuiet = value['panicQuiet'];
    if (locationClass == null || connectionClass == null || panicQuiet is! bool) {
      throw const FormatException();
    }
    final lat = value['latitude'];
    final lng = value['longitude'];
    final accuracy = value['accuracyMeters'];
    final battery = value['batteryPercent'];
    final placeLabel = value['placeLabel'];
    final fixId = value['fixId'];
    final latitude = lat is num ? lat.toDouble() : null;
    final longitude = lng is num ? lng.toDouble() : null;
    if (lat != null && latitude == null) throw const FormatException();
    if (lng != null && longitude == null) throw const FormatException();
    // The same invariant the schema holds: a place and its accuracy travel together, and
    // a press that says it has no position carries neither.
    if (locationClass.carriesCoordinates !=
        (latitude != null && longitude != null)) {
      throw const FormatException();
    }
    if (latitude != null &&
        (latitude < -90 || latitude > 90 || longitude! < -180 || longitude > 180)) {
      throw const FormatException();
    }
    if (latitude != null && (accuracy is! num || accuracy <= 0)) {
      throw const FormatException();
    }
    if (battery != null && (battery is! int || battery < 0 || battery > 100)) {
      throw const FormatException();
    }
    if (placeLabel != null && placeLabel is! String) throw const FormatException();
    if (fixId != null && (fixId is! String || !isFoundationGateUuid(fixId))) {
      throw const FormatException();
    }
    return FoundationGateSosPicture(
      locationClass: locationClass,
      connectionClass: connectionClass,
      panicQuiet: panicQuiet,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracy is num ? accuracy.toDouble() : null,
      batteryPercent: battery is int ? battery : null,
      placeLabel: placeLabel is String ? placeLabel : null,
      fixId: fixId is String ? fixId : null,
    );
  }

  FoundationGateSosDelivery _deliveryFrom(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final recipientKind = value['recipientKind'];
    final channel = value['channel'];
    final state = FoundationGateSosDeliveryState.parse(value['deliveryState']);
    final reasonCode = value['reasonCode'];
    final membershipId = value['recipientMembershipId'];
    final contactId = value['recipientContactId'];
    if (recipientKind is! String) throw const FormatException();
    if (recipientKind != 'guardian' && recipientKind != 'backup') {
      throw const FormatException();
    }
    if (channel is! String) throw const FormatException();
    if (state == null) throw const FormatException();
    // The reason is present exactly when the state is not_configured - the same pairing the
    // database enforces, checked here so a screen never renders a blank explanation.
    if ((state == FoundationGateSosDeliveryState.notConfigured) !=
        (reasonCode != null)) {
      throw const FormatException();
    }
    if (membershipId != null &&
        (membershipId is! String || !isFoundationGateUuid(membershipId))) {
      throw const FormatException();
    }
    if (contactId != null &&
        (contactId is! String || !isFoundationGateUuid(contactId))) {
      throw const FormatException();
    }
    return FoundationGateSosDelivery(
      recipientKind: recipientKind,
      channel: channel,
      deliveryState: state,
      recipientMembershipId: membershipId is String ? membershipId : null,
      recipientContactId: contactId is String ? contactId : null,
      reasonCode: reasonCode is String ? reasonCode : null,
      createdAt: _parseTimestamp(value['createdAt']),
    );
  }

  FoundationGateSosBackupContact _contactFrom(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final id = value['id'];
    final name = value['name'];
    final relation = value['relation'];
    final phone = value['phoneE164'];
    final verification = FoundationGateSosBackupVerification.parse(
      value['verification'],
    );
    final enabled = value['enabled'];
    final priority = value['priority'];
    if (id is! String ||
        !isFoundationGateUuid(id) ||
        name is! String ||
        name.isEmpty ||
        relation is! String ||
        phone is! String ||
        !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone) ||
        verification == null ||
        enabled is! bool ||
        priority is! int ||
        priority < 1 ||
        priority > 20) {
      throw const FormatException();
    }
    return FoundationGateSosBackupContact(
      id: id,
      name: name,
      relation: relation,
      phoneE164: phone,
      verification: verification,
      enabled: enabled,
      priority: priority,
      createdAt: _parseTimestamp(value['createdAt']),
      updatedAt: _parseTimestamp(value['updatedAt']),
    );
  }

  DateTime? _parseTimestamp(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }
}
