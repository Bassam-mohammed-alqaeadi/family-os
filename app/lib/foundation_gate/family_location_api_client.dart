import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';

/// Why a position report was or was not judged against a boundary.
///
/// The server answers with the reason rather than a bare success, because the four cases
/// mean four different things to a family and collapsing them would be the beginning of a
/// false safety state:
///
///   * [evaluated]           - the report was newer than the last one and was judged.
///   * [duplicate]           - this fix id was already stored; no second crossing exists.
///   * [noCoordinates]       - the device answered (acquiring / unavailable) without a
///                             position, which is honest but places the child nowhere.
///   * [storedOutOfOrder]    - the report is older than what is already stored. It joins
///                             the trail and is NOT judged, so a late retry cannot replay
///                             history backwards and announce an arrival that already
///                             happened.
enum FoundationGateFixEvaluation {
  evaluated,
  duplicate,
  noCoordinates,
  storedOutOfOrder;

  static FoundationGateFixEvaluation? parse(Object? value) {
    return switch (value) {
      'evaluated' => FoundationGateFixEvaluation.evaluated,
      'duplicate' => FoundationGateFixEvaluation.duplicate,
      'no_coordinates' => FoundationGateFixEvaluation.noCoordinates,
      'stored_out_of_order' => FoundationGateFixEvaluation.storedOutOfOrder,
      _ => null,
    };
  }
}

/// How a device's reporting reads to the family.
///
/// `silent` and `never` stay distinct: a device that used to report and stopped is a fact
/// worth acting on, and a device that has never reported may simply not be set up yet.
enum FoundationGateDeviceState {
  live,
  silent,
  never;

  static FoundationGateDeviceState? parse(Object? value) {
    return switch (value) {
      'live' => FoundationGateDeviceState.live,
      'silent' => FoundationGateDeviceState.silent,
      'never' => FoundationGateDeviceState.never,
      _ => null,
    };
  }
}

/// What the device knows about the child's position right now.
enum FoundationGateAcquisition {
  located,
  staleLastKnown,
  acquiring,
  unavailable;

  static FoundationGateAcquisition? parse(Object? value) {
    return switch (value) {
      'located' => FoundationGateAcquisition.located,
      'stale_last_known' => FoundationGateAcquisition.staleLastKnown,
      'acquiring' => FoundationGateAcquisition.acquiring,
      'unavailable' => FoundationGateAcquisition.unavailable,
      _ => null,
    };
  }

  /// Whether a position is expected at all. The other two are honest non-answers, and the
  /// server refuses a payload that carries coordinates with them.
  bool get carriesCoordinates =>
      this == FoundationGateAcquisition.located ||
      this == FoundationGateAcquisition.staleLastKnown;
}

class FoundationGateGeoPoint {
  const FoundationGateGeoPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

/// A boundary shape, both kinds first-class.
sealed class FoundationGateZoneGeometry {
  const FoundationGateZoneGeometry({required this.version});

  /// The zone version this geometry was read at. A crossing records the version it was
  /// judged against, so the version travels with the shape rather than beside it.
  final int version;

  String get kind;
}

final class FoundationGateCircleGeometry
    extends FoundationGateZoneGeometry {
  const FoundationGateCircleGeometry({
    required super.version,
    required this.center,
    required this.radiusMeters,
  });

  final FoundationGateGeoPoint center;
  final double radiusMeters;

  @override
  String get kind => 'CIRCLE';
}

final class FoundationGatePolygonGeometry
    extends FoundationGateZoneGeometry {
  const FoundationGatePolygonGeometry({
    required super.version,
    required this.vertices,
  });

  final List<FoundationGateGeoPoint> vertices;

  @override
  String get kind => 'POLYGON';
}

/// One family safe zone exactly as the server publishes it.
class FoundationGateLocationZone {
  const FoundationGateLocationZone({
    required this.id,
    required this.name,
    required this.emoji,
    required this.geometry,
    required this.childIds,
    required this.alertEnter,
    required this.alertExit,
    required this.version,
  });

  final String id;
  final String name;
  final String emoji;
  final FoundationGateZoneGeometry geometry;
  final List<String> childIds;
  final bool alertEnter;
  final bool alertExit;
  final int version;
}

/// One device's standing in the family picture.
class FoundationGateDeviceReading {
  const FoundationGateDeviceReading({
    required this.deviceId,
    required this.deviceLabel,
    required this.state,
    required this.acquisition,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.recordedAt,
  });

  final String deviceId;
  final String deviceLabel;
  final FoundationGateDeviceState state;
  final FoundationGateAcquisition acquisition;

  /// Null, not zero, when the device has no position: a fix that carries no coordinates
  /// must never be rendered as a point at (0, 0) in the Gulf of Guinea.
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DateTime? recordedAt;

  bool get hasPosition => latitude != null && longitude != null;
}

/// A child's standing relative to one zone.
class FoundationGateZoneStanding {
  const FoundationGateZoneStanding({
    required this.zoneId,
    required this.inside,
    required this.observedCrossing,
  });

  final String zoneId;
  final bool inside;

  /// False when this standing comes from a baseline sighting: the state is known, but no
  /// crossing was ever watched happening.
  final bool observedCrossing;
}

class FoundationGateChildLocation {
  const FoundationGateChildLocation({
    required this.childId,
    required this.displayName,
    required this.devices,
    required this.zones,
  });

  final String childId;
  final String displayName;
  final List<FoundationGateDeviceReading> devices;
  final List<FoundationGateZoneStanding> zones;
}

/// The family's live picture: one read, one visibility rule for every member.
class FoundationGateFamilyLocation {
  const FoundationGateFamilyLocation({
    required this.visibility,
    required this.observedAt,
    required this.children,
  });

  final String visibility;
  final DateTime observedAt;
  final List<FoundationGateChildLocation> children;
}

/// One recorded arrival or departure.
class FoundationGateCrossingRow {
  const FoundationGateCrossingRow({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.childId,
    required this.kind,
    required this.baseline,
    required this.zoneVersion,
    required this.occurredAt,
  });

  final String id;
  final String zoneId;
  final String? zoneName;
  final String childId;

  /// `ENTER` or `EXIT`. A missed-deadline state is not one of them.
  final String kind;
  final bool baseline;
  final int zoneVersion;
  final DateTime occurredAt;
}

/// One crossing as the ingest answer reports it, including whether it was announced.
class FoundationGateCrossing {
  const FoundationGateCrossing({
    required this.zoneId,
    required this.kind,
    required this.baseline,
    required this.notified,
    required this.zoneVersion,
  });

  final String zoneId;
  final String kind;
  final bool baseline;
  final bool notified;
  final int zoneVersion;
}

/// The trail a family can read back.
class FoundationGateLocationHistory {
  const FoundationGateLocationHistory({
    required this.visibility,
    required this.childId,
    required this.displayName,
    required this.retentionDays,
    required this.fixes,
  });

  final String visibility;
  final String childId;
  final String displayName;

  /// How long a fix survives on the server. The window is published rather than assumed,
  /// so a screen can say what is kept instead of implying it keeps everything.
  final int retentionDays;
  final List<FoundationGateTrailFix> fixes;
}

/// One stored fix, with `null` coordinates when the device answered without a position.
class FoundationGateTrailFix {
  const FoundationGateTrailFix({
    required this.id,
    required this.acquisition,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.integritySoftWarning = false,
    this.recordedAt,
    this.receivedAt,
  });

  final String id;
  final FoundationGateAcquisition acquisition;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final bool integritySoftWarning;
  final DateTime? recordedAt;
  final DateTime? receivedAt;

  bool get hasPosition => latitude != null && longitude != null;
}

/// The server's answer to a reported position.
class FoundationGateFixReceipt {
  const FoundationGateFixReceipt({
    required this.evaluated,
    required this.reason,
    required this.replayed,
    required this.crossings,
    required this.pruned,
  });

  final bool evaluated;
  final FoundationGateFixEvaluation reason;
  final bool replayed;
  final List<FoundationGateCrossing> crossings;
  final int pruned;
}

/// Narrow client for the location and safe-zone contract.
///
/// Everything a family's location surface needs is one of six operations, and every one of
/// them is authorized by the server against the resource in the path rather than against a
/// claim in the body: the family id or the device id is in the URL, so a credential can
/// only ever act on the thing it names.
class FamilyLocationApiClient {
  FamilyLocationApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  /// The zones this family defined. Readable by every active member, a child included.
  Future<List<FoundationGateLocationZone>> listZones({
    required String familyId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familySafeZonesUri(familyId),
      idToken,
      familyId: familyId,
    );
    switch (response.statusCode) {
      case 200:
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is! Map<String, Object?>) throw const FormatException();
          final raw = decoded['zones'];
          if (raw is! List<Object?>) throw const FormatException();
          return List.unmodifiable(raw.map(_parseZone));
        } catch (_) {
          throw const FoundationGateApiException(
            FoundationGateApiFailure.invalidResponse,
          );
        }
      case 401:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
        );
      case 403:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.accessDenied,
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

  /// Draws a new boundary for named children of this family.
  Future<FoundationGateLocationZone> createZone({
    required String familyId,
    required String idToken,
    required String idempotencyKey,
    required String name,
    required String emoji,
    required FoundationGateZoneGeometry geometry,
    required List<String> childIds,
    required bool alertEnter,
    required bool alertExit,
  }) async {
    if (!isFoundationGateUuid(familyId) ||
        !_validText(name, 80) ||
        !_validText(emoji, 16) ||
        !_validText(idempotencyKey, 128) ||
        childIds.isEmpty ||
        childIds.length > 24 ||
        childIds.any((id) => !isFoundationGateUuid(id)) ||
        childIds.toSet().length != childIds.length) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _post(
      _configuration.familySafeZonesUri(familyId),
      idToken,
      {
        'name': name.trim(),
        'emoji': emoji.trim(),
        'geometry': _geometryBody(geometry),
        'childIds': childIds,
        'alertEnter': alertEnter,
        'alertExit': alertExit,
      },
      idempotencyKey: idempotencyKey,
    );
    return _zoneFromWrite(response);
  }

  /// Turns the two announcement flags on or off for one zone.
  ///
  /// The geometry, the name and the assignment are not editable through this operation on
  /// purpose: a boundary that moves is a different boundary to anyone an arrival was
  /// already reported about.
  Future<FoundationGateLocationZone> updateZoneAlerts({
    required String familyId,
    required String zoneId,
    required String idToken,
    required String idempotencyKey,
    bool? alertEnter,
    bool? alertExit,
  }) async {
    if (!isFoundationGateUuid(familyId) ||
        !isFoundationGateUuid(zoneId) ||
        !_validText(idempotencyKey, 128) ||
        (alertEnter == null && alertExit == null)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _patch(
      _configuration.familySafeZoneUri(familyId, zoneId),
      idToken,
      {
        if (alertEnter != null) 'alertEnter': alertEnter,
        if (alertExit != null) 'alertExit': alertExit,
      },
      idempotencyKey: idempotencyKey,
    );
    return _zoneFromWrite(response);
  }

  /// The trail of one child, newest first.
  ///
  /// Same one-rule-for-everyone promise as the live read, so a child can see what was kept
  /// about her and not only where she is right now.
  Future<FoundationGateLocationHistory> locationHistory({
    required String familyId,
    required String childId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyChildLocationHistoryUri(familyId, childId),
      idToken,
      familyId: familyId,
    );
    return switch (response.statusCode) {
      200 => _parseHistory(response.body),
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

  /// The live picture: every child, every linked device, and where each child stands
  /// relative to each zone - the same rows for every member of the family.
  Future<FoundationGateFamilyLocation> familyLocation({
    required String familyId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyLocationUri(familyId),
      idToken,
      familyId: familyId,
    );
    return switch (response.statusCode) {
      200 => _parseFamilyLocation(response.body),
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

  /// The arrival and departure feed, newest first, baselines marked.
  Future<List<FoundationGateCrossingRow>> crossingFeed({
    required String familyId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyGeofenceEventsUri(familyId),
      idToken,
      familyId: familyId,
    );
    return switch (response.statusCode) {
      200 => _parseCrossingFeed(response.body),
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

  /// Reports one position for this device, with the device's OWN credential.
  ///
  /// The device id is in the path and the credential in the header, so a handset can only
  /// ever report for itself. `acquiring` and `unavailable` are honest answers: they carry
  /// no coordinates, and the server refuses a payload that tries to send some anyway.
  Future<FoundationGateFixReceipt> reportLocationFix({
    required String deviceId,
    required String deviceCredential,
    required String idempotencyKey,
    required String fixId,
    required FoundationGateAcquisition acquisition,
    required DateTime recordedAt,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
  }) async {
    if (!isFoundationGateUuid(deviceId) ||
        !isFoundationGateUuid(fixId) ||
        !_validText(idempotencyKey, 128) ||
        !RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(deviceCredential)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final hasPoint = latitude != null && longitude != null;
    if (acquisition.carriesCoordinates != hasPoint) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    if (latitude != null && (latitude < -90 || latitude > 90)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    if (longitude != null && (longitude < -180 || longitude > 180)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    if (accuracyMeters != null && (accuracyMeters <= 0 || accuracyMeters > 100000)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    if (recordedAt.toUtc().difference(DateTime.now().toUtc()).inMinutes > 5) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    try {
      final response = await _transport.post(
        _configuration.deviceLocationFixesUri(deviceId),
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'authorization': 'Device $deviceCredential',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode({
          'fixId': fixId,
          'acquisition': _acquisitionWire(acquisition),
          if (hasPoint) 'latitude': latitude,
          if (hasPoint) 'longitude': longitude,
          if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
          'recordedAt': recordedAt.toUtc().toIso8601String(),
        }),
      );
      return switch (response.statusCode) {
        201 => _parseFixReceipt(response.body),
        400 => throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidInput,
        ),
        401 => throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
        ),
        403 => throw const FoundationGateApiException(
          FoundationGateApiFailure.accessDenied,
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
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  /// A device id is in the path on purpose, so a malformed id is refused before any
  /// request is built rather than after a server round-trip.
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

  FoundationGateLocationZone _zoneFromWrite(
    FoundationGateHttpResponse response,
  ) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseZoneEnvelope(response.body);
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

  FoundationGateLocationZone _parseZoneEnvelope(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      return _parseZone(decoded['zone']);
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  /// One zone from its published form.
  ///
  /// Unknown extra keys are ignored - an additive server change must not make a whole
  /// family's zones unreadable - while a shape, a kind or a range the client does not
  /// understand still refuses the zone rather than rendering it with a guessed meaning.
  FoundationGateLocationZone _parseZone(Object? value) {
    try {
      if (value is! Map<String, Object?>) throw const FormatException();
      final id = value['id'];
      final name = value['name'];
      final emoji = value['emoji'];
      final version = value['version'];
      final rawChildren = value['childIds'];
      final alertEnter = value['alertEnter'];
      final alertExit = value['alertExit'];
      if (id is! String ||
          !isFoundationGateUuid(id) ||
          name is! String ||
          !_validText(name, 80) ||
          emoji is! String ||
          !_validText(emoji, 16) ||
          version is! int ||
          version < 1 ||
          rawChildren is! List<Object?> ||
          rawChildren.isEmpty ||
          rawChildren.length > 24 ||
          alertEnter is! bool ||
          alertExit is! bool) {
        throw const FormatException();
      }
      final childIds = <String>[];
      for (final raw in rawChildren) {
        if (raw is! String || !isFoundationGateUuid(raw)) {
          throw const FormatException();
        }
        childIds.add(raw);
      }
      if (childIds.toSet().length != childIds.length) {
        throw const FormatException();
      }
      return FoundationGateLocationZone(
        id: id,
        name: name,
        emoji: emoji,
        geometry: _parseGeometry(value['geometry'], version),
        childIds: List.unmodifiable(childIds),
        alertEnter: alertEnter,
        alertExit: alertExit,
        version: version,
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateZoneGeometry _parseGeometry(Object? value, int zoneVersion) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final version = value['version'];
    if (version is! int || version < 1) throw const FormatException();
    final kind = value['kind'];
    if (kind == 'CIRCLE') {
      final radius = value['radiusMeters'];
      if (radius is! num || radius < 50 || radius > 50000) {
        throw const FormatException();
      }
      return FoundationGateCircleGeometry(
        version: version,
        center: _parsePoint(value['center']),
        radiusMeters: radius.toDouble(),
      );
    }
    if (kind == 'POLYGON') {
      final raw = value['vertices'];
      if (raw is! List<Object?> || raw.length < 3 || raw.length > 64) {
        throw const FormatException();
      }
      return FoundationGatePolygonGeometry(
        version: version,
        vertices: List.unmodifiable(raw.map(_parsePoint)),
      );
    }
    throw const FormatException();
  }

  FoundationGateGeoPoint _parsePoint(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final latitude = value['latitude'];
    final longitude = value['longitude'];
    if (latitude is! num || latitude < -90 || latitude > 90) {
      throw const FormatException();
    }
    if (longitude is! num || longitude < -180 || longitude > 180) {
      throw const FormatException();
    }
    return FoundationGateGeoPoint(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }

  FoundationGateLocationHistory _parseHistory(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final visibility = decoded['visibility'];
      final childId = decoded['childId'];
      final displayName = decoded['displayName'];
      final retentionDays = decoded['retentionDays'];
      final rawFixes = decoded['fixes'];
      if (visibility is! String ||
          visibility != 'family_members' ||
          childId is! String ||
          !isFoundationGateUuid(childId) ||
          displayName is! String ||
          retentionDays is! int ||
          retentionDays < 1 ||
          rawFixes is! List<Object?>) {
        throw const FormatException();
      }
      return FoundationGateLocationHistory(
        visibility: visibility,
        childId: childId,
        displayName: displayName,
        retentionDays: retentionDays,
        fixes: List.unmodifiable(rawFixes.map(_parseTrailFix)),
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateTrailFix _parseTrailFix(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final id = value['id'];
    final acquisition = FoundationGateAcquisition.parse(value['acquisition']);
    if (id is! String || !isFoundationGateUuid(id) || acquisition == null) {
      throw const FormatException();
    }
    final latitude = value['latitude'];
    final longitude = value['longitude'];
    final accuracy = value['accuracyMeters'];
    final warning = value['integritySoftWarning'];
    if (latitude != null && (latitude is! num || latitude < -90 || latitude > 90)) {
      throw const FormatException();
    }
    if (longitude != null && (longitude is! num || longitude < -180 || longitude > 180)) {
      throw const FormatException();
    }
    if (acquisition.carriesCoordinates != (latitude != null && longitude != null)) {
      throw const FormatException();
    }
    if (accuracy != null && (accuracy is! num || accuracy <= 0 || accuracy > 100000)) {
      throw const FormatException();
    }
    if (warning != null && warning is! bool) throw const FormatException();
    return FoundationGateTrailFix(
      id: id,
      acquisition: acquisition,
      latitude: latitude is num ? latitude.toDouble() : null,
      longitude: longitude is num ? longitude.toDouble() : null,
      accuracyMeters: accuracy is num ? accuracy.toDouble() : null,
      integritySoftWarning: warning is bool && warning,
      recordedAt: _parseTimestamp(value['recordedAt']),
      receivedAt: _parseTimestamp(value['receivedAt']),
    );
  }

  FoundationGateFamilyLocation _parseFamilyLocation(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final visibility = decoded['visibility'];
      final observedAt = _parseTimestamp(decoded['observedAt']);
      final rawChildren = decoded['children'];
      if (visibility is! String ||
          visibility != 'family_members' ||
          observedAt == null ||
          rawChildren is! List<Object?>) {
        throw const FormatException();
      }
      return FoundationGateFamilyLocation(
        visibility: visibility,
        observedAt: observedAt,
        children: List.unmodifiable(rawChildren.map(_parseChildLocation)),
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateChildLocation _parseChildLocation(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final childId = value['childId'];
    final displayName = value['displayName'];
    final rawDevices = value['devices'];
    final rawZones = value['zones'];
    if (childId is! String ||
        !isFoundationGateUuid(childId) ||
        displayName is! String ||
        rawDevices is! List<Object?> ||
        rawZones is! List<Object?>) {
      throw const FormatException();
    }
    return FoundationGateChildLocation(
      childId: childId,
      displayName: displayName,
      devices: List.unmodifiable(rawDevices.map(_parseDeviceReading)),
      zones: List.unmodifiable(rawZones.map(_parseZoneStanding)),
    );
  }

  FoundationGateDeviceReading _parseDeviceReading(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final deviceId = value['deviceId'];
    final deviceLabel = value['deviceLabel'];
    final state = FoundationGateDeviceState.parse(value['state']);
    if (deviceId is! String ||
        !isFoundationGateUuid(deviceId) ||
        deviceLabel is! String ||
        state == null) {
      throw const FormatException();
    }
    final rawFix = value['lastFix'];
    if (rawFix == null) {
      // A device that has never reported has no acquisition to state. That is not the same
      // as a device that reported "acquiring", and it is not rendered as either.
      return FoundationGateDeviceReading(
        deviceId: deviceId,
        deviceLabel: deviceLabel,
        state: state,
        acquisition: FoundationGateAcquisition.unavailable,
      );
    }
    if (rawFix is! Map<String, Object?>) throw const FormatException();
    final acquisition = FoundationGateAcquisition.parse(rawFix['acquisition']);
    if (acquisition == null) throw const FormatException();
    final latitude = rawFix['latitude'];
    final longitude = rawFix['longitude'];
    final accuracy = rawFix['accuracyMeters'];
    if (latitude != null && (latitude is! num || latitude < -90 || latitude > 90)) {
      throw const FormatException();
    }
    if (longitude != null && (longitude is! num || longitude < -180 || longitude > 180)) {
      throw const FormatException();
    }
    if (acquisition.carriesCoordinates != (latitude != null && longitude != null)) {
      throw const FormatException();
    }
    return FoundationGateDeviceReading(
      deviceId: deviceId,
      deviceLabel: deviceLabel,
      state: state,
      acquisition: acquisition,
      latitude: latitude is num ? latitude.toDouble() : null,
      longitude: longitude is num ? longitude.toDouble() : null,
      accuracyMeters: accuracy is num ? accuracy.toDouble() : null,
      recordedAt: _parseTimestamp(rawFix['recordedAt']),
    );
  }

  FoundationGateZoneStanding _parseZoneStanding(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final zoneId = value['zoneId'];
    final inside = value['inside'];
    final observedCrossing = value['observedCrossing'];
    if (zoneId is! String ||
        !isFoundationGateUuid(zoneId) ||
        inside is! bool ||
        observedCrossing is! bool) {
      throw const FormatException();
    }
    return FoundationGateZoneStanding(
      zoneId: zoneId,
      inside: inside,
      observedCrossing: observedCrossing,
    );
  }

  List<FoundationGateCrossingRow> _parseCrossingFeed(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      if (decoded['visibility'] != 'family_members') throw const FormatException();
      final raw = decoded['events'];
      if (raw is! List<Object?>) throw const FormatException();
      return List.unmodifiable(raw.map(_parseCrossingRow));
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateCrossingRow _parseCrossingRow(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final id = value['id'];
    final zoneId = value['zoneId'];
    final zoneName = value['zoneName'];
    final childId = value['childId'];
    final kind = value['kind'] == 'EXIT'
        ? 'EXIT'
        : (value['kind'] == 'ENTER' ? 'ENTER' : null);
    final baseline = value['baseline'];
    final zoneVersion = value['zoneVersion'];
    final occurredAt = _parseTimestamp(value['occurredAt']);
    if (id is! String ||
        !isFoundationGateUuid(id) ||
        zoneId is! String ||
        !isFoundationGateUuid(zoneId) ||
        (zoneName != null && zoneName is! String) ||
        childId is! String ||
        !isFoundationGateUuid(childId) ||
        kind == null ||
        baseline is! bool ||
        zoneVersion is! int ||
        zoneVersion < 1 ||
        occurredAt == null) {
      throw const FormatException();
    }
    return FoundationGateCrossingRow(
      id: id,
      zoneId: zoneId,
      zoneName: zoneName is String ? zoneName : null,
      childId: childId,
      kind: kind,
      baseline: baseline,
      zoneVersion: zoneVersion,
      occurredAt: occurredAt,
    );
  }

  FoundationGateFixReceipt _parseFixReceipt(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final evaluated = decoded['evaluated'];
      final reason = FoundationGateFixEvaluation.parse(decoded['reason']);
      final replayed = decoded['replayed'];
      final rawCrossings = decoded['crossings'];
      final pruned = decoded['pruned'];
      if (evaluated is! bool ||
          reason == null ||
          replayed is! bool ||
          rawCrossings is! List<Object?> ||
          pruned is! int ||
          pruned < 0) {
        throw const FormatException();
      }
      return FoundationGateFixReceipt(
        evaluated: evaluated,
        reason: reason,
        replayed: replayed,
        crossings: List.unmodifiable(rawCrossings.map(_parseCrossing)),
        pruned: pruned,
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateCrossing _parseCrossing(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final zoneId = value['zoneId'];
    final kind = value['kind'] == 'EXIT'
        ? 'EXIT'
        : (value['kind'] == 'ENTER' ? 'ENTER' : null);
    final baseline = value['baseline'];
    final notified = value['notified'];
    final zoneVersion = value['zoneVersion'];
    if (zoneId is! String ||
        !isFoundationGateUuid(zoneId) ||
        kind == null ||
        baseline is! bool ||
        notified is! bool ||
        zoneVersion is! int ||
        zoneVersion < 1) {
      throw const FormatException();
    }
    return FoundationGateCrossing(
      zoneId: zoneId,
      kind: kind,
      baseline: baseline,
      notified: notified,
      zoneVersion: zoneVersion,
    );
  }

  Map<String, Object> _geometryBody(FoundationGateZoneGeometry geometry) {
    switch (geometry) {
      case FoundationGateCircleGeometry():
        return {
          'kind': 'CIRCLE',
          'center': {
            'latitude': geometry.center.latitude,
            'longitude': geometry.center.longitude,
          },
          'radiusMeters': geometry.radiusMeters,
        };
      case FoundationGatePolygonGeometry():
        return {
          'kind': 'POLYGON',
          'vertices': [
            for (final vertex in geometry.vertices)
              {'latitude': vertex.latitude, 'longitude': vertex.longitude},
          ],
        };
    }
  }

  String _acquisitionWire(FoundationGateAcquisition acquisition) {
    return switch (acquisition) {
      FoundationGateAcquisition.located => 'located',
      FoundationGateAcquisition.staleLastKnown => 'stale_last_known',
      FoundationGateAcquisition.acquiring => 'acquiring',
      FoundationGateAcquisition.unavailable => 'unavailable',
    };
  }

  DateTime? _parseTimestamp(Object? value) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    return parsed?.toUtc();
  }

  bool _validText(String value, int maxLength) =>
      value.trim().isNotEmpty &&
      value.trim().length <= maxLength &&
      !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value);

}
