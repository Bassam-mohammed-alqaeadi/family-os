import 'package:family_os/core/location/geo_point.dart';
import 'package:family_os/core/location/zone_geometry.dart';
import 'package:family_os/foundation_gate/family_location_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n02_day/location_map_repository.dart';
import 'package:family_os/features/n02_day/safe_zones_repository.dart';

/// The server authority behind the location pack, when a build has one.
///
/// This is the piece that turns the safe-zone screens from a single handset's local list
/// into the family's shared truth. Until W3 the boundary lived in one phone's store, so a
/// zone the mother drew was invisible to the father and no arrival could ever be detected
/// - detection needs one answer to "where is the boundary", held somewhere both handsets
/// can read.
///
/// Everything here is a read of, or a write through, the published contract. Nothing in
/// this file decides anything: the server judges crossings, marks baselines and refuses
/// dishonest payloads, and the client reports what it was told.
final class LocationServerAuthority {
  LocationServerAuthority({
    required this.api,
    required Future<String> Function() idToken,
    required String? Function() familyId,
  }) : _idToken = idToken,
       _familyId = familyId;

  final FamilyLocationApiClient api;
  final Future<String> Function() _idToken;
  final String? Function() _familyId;

  /// The family this device is looking at, or null before a family is selected.
  String? get selectedFamilyId {
    final value = _familyId()?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  bool get isReady => selectedFamilyId != null;

  Future<List<FoundationGateLocationZone>> listZones() async {
    final familyId = _requireFamilyId();
    return api.listZones(familyId: familyId, idToken: await _idToken());
  }

  Future<void> createZone(SafeZoneDraft draft) async {
    final familyId = _requireFamilyId();
    await api.createZone(
      familyId: familyId,
      idToken: await _idToken(),
      idempotencyKey: newFoundationGateIdempotencyKey(),
      name: draft.name,
      emoji: draft.emoji,
      geometry: serverGeometryOf(draft.geometry),
      childIds: draft.assignedChildIds,
      alertEnter: draft.alertEnter,
      alertExit: draft.alertExit,
    );
  }

  Future<void> updateAlerts(
    String zoneId, {
    bool? alertEnter,
    bool? alertExit,
  }) async {
    if (alertEnter == null && alertExit == null) return;
    final familyId = _requireFamilyId();
    await api.updateZoneAlerts(
      familyId: familyId,
      zoneId: zoneId,
      idToken: await _idToken(),
      idempotencyKey: newFoundationGateIdempotencyKey(),
      alertEnter: alertEnter,
      alertExit: alertExit,
    );
  }

  Future<FoundationGateFamilyLocation> livePicture() async {
    final familyId = _requireFamilyId();
    return api.familyLocation(familyId: familyId, idToken: await _idToken());
  }

  Future<List<FoundationGateCrossingRow>> crossings() async {
    final familyId = _requireFamilyId();
    return api.crossingFeed(familyId: familyId, idToken: await _idToken());
  }

  String _requireFamilyId() {
    final familyId = selectedFamilyId;
    if (familyId == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    return familyId;
  }
}

/// The zone writes, expressed as the seam the create screen already speaks.
final class LocationServerZoneWriter implements SafeZoneServerWriter {
  const LocationServerZoneWriter(this.authority);

  final LocationServerAuthority authority;

  @override
  Future<void> createZone(SafeZoneDraft draft) => authority.createZone(draft);

  @override
  Future<void> updateAlerts(
    String zoneId, {
    bool? alertEnter,
    bool? alertExit,
  }) => authority.updateAlerts(
    zoneId,
    alertEnter: alertEnter,
    alertExit: alertExit,
  );
}

/// The safe-zone list, read from the server.
///
/// [storesNoShowAlert] answers false because the server's zone model records entering and
/// leaving, and the missed-deadline alert is neither. Saying true here would let the screen
/// offer a switch whose position survives nothing.
final class ServerSafeZonesRepository implements SafeZonesRepository {
  const ServerSafeZonesRepository(this.authority);

  final LocationServerAuthority authority;

  @override
  bool get storesNoShowAlert => false;

  @override
  bool get isRemoteAuthority => true;

  @override
  Future<SafeZonesSnapshot> load() async {
    final zones = await authority.listZones();
    return SafeZonesSnapshot(
      zones: List.unmodifiable(zones.map(_toListZone)),
    );
  }

  @override
  Future<void> setAlertFlag(
    String zoneId, {
    bool? alertEnter,
    bool? alertExit,
    bool? alertNoShow,
  }) async {
    if (alertNoShow != null) {
      throw UnsupportedError(
        'A missed-deadline alert is not part of the server zone model, so this '
        'repository refuses to accept one instead of dropping it.',
      );
    }
    await authority.updateAlerts(
      zoneId,
      alertEnter: alertEnter,
      alertExit: alertExit,
    );
  }

  @override
  Future<void> setAlertsEnabled(String zoneId, bool enabled) =>
      authority.updateAlerts(zoneId, alertEnter: enabled, alertExit: enabled);

  @override
  Future<void> add(SafeZone zone) {
    // The list DTO carries no geometry, and a boundary without a shape is not a boundary.
    // Creation goes through [LocationServerZoneWriter] with a [SafeZoneDraft] instead.
    throw UnsupportedError(
      'A zone needs its geometry to reach the server; use the create screen.',
    );
  }

  static SafeZone _toListZone(FoundationGateLocationZone zone) {
    return SafeZone(
      id: zone.id,
      emoji: zone.emoji,
      name: zone.name,
      description: 'assigned:${zone.childIds.length}',
      alertEnter: zone.alertEnter,
      alertExit: zone.alertExit,
      alertNoShow: false,
      assignedChildIds: List.unmodifiable(zone.childIds),
    );
  }
}

/// The live map, read from the server: the family's own zones, each child's standing
/// relative to them, and the crossings of the last days as the day thread.
///
/// Two honesty rules are structural here rather than described:
///
///   * a pin exists only where a device actually reported a position. A child whose device
///     has never reported gets no pin, because a pin at an invented spot is a location
///     claim nobody made;
///   * the canvas is decorative. Positions are drawn in one fixed local frame around the
///     pack's origin so a family's own boundary and its own child land in the same picture;
///     it is not a geographic map and does not pretend to be one.
final class ServerLocationMapRepository implements LocationMapRepository {
  const ServerLocationMapRepository(this.authority, {this.origin = kLocationCanvasOrigin});

  final LocationServerAuthority authority;

  /// The fixed frame the decorative canvas draws in. One fraction is [canvasFractionDegrees]
  /// degrees, which is why a radius converts to a diameter the same way a position converts
  /// to a point.
  final GeoPoint origin;

  /// One canvas unit spans this many degrees, so it also spans [canvasFractionMeters] on
  /// the ground at the origin's latitude.
  static const double canvasFractionDegrees = 0.02;
  static const double canvasFractionMeters = 2200;

  @override
  Future<LocationMapSnapshot?> load({String? focusChildId}) async {
    final picture = await authority.livePicture();
    final zones = await authority.listZones();
    final crossings = await authority.crossings();

    final zoneNameById = <String, String>{
      for (final zone in zones) zone.id: zone.name,
    };

    final pins = <LocationMapPin>[];
    for (final child in picture.children) {
      final reading = _reportingDevice(child);
      if (reading == null || !reading.hasPosition) continue;
      final point = GeoPoint(
        latitude: reading.latitude!,
        longitude: reading.longitude!,
      );
      pins.add(
        LocationMapPin(
          id: child.childId,
          displayName: child.displayName,
          // The published picture carries a name, not an avatar: the pack's own marker is
          // used rather than inventing one that looks like it came from the family.
          emoji: '📍',
          swatch: DayChildSwatch.purple,
          locationLabel: _coordinateLabel(point),
          lastSeenLabel: _deviceStateLabel(reading.state),
          batteryLabel: '—',
          xFraction: _xFraction(point),
          yFraction: _yFraction(point),
          safeZoneLabel: _containingZoneName(child, zoneNameById) ?? '',
          batteryWarn: false,
          networkClass: LocationNetworkClass.unavailable,
        ),
      );
    }

    final mapZones = <LocationMapZone>[];
    for (final zone in zones) {
      final geometry = zone.geometry;
      if (geometry is! FoundationGateCircleGeometry) continue;
      mapZones.add(
        LocationMapZone(
          id: zone.id,
          xFraction: _xFraction(GeoPoint(
            latitude: geometry.center.latitude,
            longitude: geometry.center.longitude,
          )),
          yFraction: _yFraction(GeoPoint(
            latitude: geometry.center.latitude,
            longitude: geometry.center.longitude,
          )),
          diameterFraction: _clampFraction(
            geometry.radiusMeters / canvasFractionMeters,
            minimum: 0.06,
            maximum: 0.9,
          ),
          purpleTint: zone.alertEnter && zone.alertExit,
        ),
      );
    }

    final threadStops = <LocationThreadStop>[
      for (final row in crossings)
        LocationThreadStop(
          title: zoneNameById[row.zoneId] ?? row.zoneName ?? '—',
          timeLabel: _clockLabel(row.occurredAt),
          isCurrent: false,
        ),
    ];

    final trimmed = focusChildId?.trim();
    final hasFocus = trimmed != null && trimmed.isNotEmpty;
    if (pins.isEmpty) {
      if (hasFocus) return null;
      return LocationMapSnapshot(
        pins: const [],
        zones: List.unmodifiable(mapZones),
        threadStops: List.unmodifiable(threadStops),
      );
    }
    if (hasFocus) {
      final match = pins.where((pin) => pin.id == trimmed).toList();
      if (match.isEmpty) return null;
      final focus = match.first;
      return LocationMapSnapshot(
        pins: List.unmodifiable(pins),
        zones: List.unmodifiable(mapZones),
        focusChildId: focus.id,
        focusDisplayName: focus.displayName,
        threadStops: List.unmodifiable(threadStops),
      );
    }
    final first = pins.first;
    return LocationMapSnapshot(
      pins: List.unmodifiable(pins),
      zones: List.unmodifiable(mapZones),
      focusChildId: first.id,
      focusDisplayName: first.displayName,
      threadStops: List.unmodifiable(threadStops),
    );
  }

  /// The device whose reading this pin draws.
  ///
  /// The most recently reporting device wins, and a device that reported without
  /// coordinates does not outrank one that reported with them: "acquiring" is a fresher
  /// answer about the device, not a position.
  static FoundationGateDeviceReading? _reportingDevice(
    FoundationGateChildLocation child,
  ) {
    FoundationGateDeviceReading? positioned;
    for (final device in child.devices) {
      if (!device.hasPosition) continue;
      if (positioned == null) {
        positioned = device;
        continue;
      }
      final a = device.recordedAt;
      final b = positioned.recordedAt;
      if (a != null && (b == null || a.isAfter(b))) {
        positioned = device;
      }
    }
    return positioned;
  }

  static String? _containingZoneName(
    FoundationGateChildLocation child,
    Map<String, String> zoneNameById,
  ) {
    for (final standing in child.zones) {
      if (!standing.inside) continue;
      return zoneNameById[standing.zoneId];
    }
    return null;
  }

  static String _deviceStateLabel(FoundationGateDeviceState state) {
    return switch (state) {
      FoundationGateDeviceState.live => 'LIVE',
      FoundationGateDeviceState.silent => 'SILENT',
      FoundationGateDeviceState.never => 'NEVER',
    };
  }

  static String _coordinateLabel(GeoPoint point) =>
      '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';

  static String _clockLabel(DateTime at) {
    final utc = at.toUtc();
    return '${utc.day.toString().padLeft(2, '0')}/'
        '${utc.month.toString().padLeft(2, '0')} '
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}';
  }

  double _xFraction(GeoPoint point) => _clampFraction(
    0.5 + (point.longitude - origin.longitude) / canvasFractionDegrees,
  );

  double _yFraction(GeoPoint point) => _clampFraction(
    0.5 - (point.latitude - origin.latitude) / canvasFractionDegrees,
  );

  static double _clampFraction(
    double value, {
    double minimum = 0.02,
    double maximum = 0.98,
  }) {
    if (value.isNaN) return 0.5;
    if (value < minimum) return minimum;
    if (value > maximum) return maximum;
    return value;
  }
}

/// The decorative frame's origin: the same point the drawing tools project from, so a zone
/// drawn on this device and a position reported by another land in one picture.
const GeoPoint kLocationCanvasOrigin = GeoPoint(
  latitude: 24.7136,
  longitude: 46.6753,
);

/// The wire shape of a drawn boundary.
///
/// The version is the server's to assign: sending one would let a handset claim which
/// revision of a boundary a crossing was judged against, which is a claim only the server
/// can make.
FoundationGateZoneGeometry serverGeometryOf(ZoneGeometry geometry) {
  switch (geometry) {
    case CircleGeometry():
      return FoundationGateCircleGeometry(
        version: geometry.version,
        center: FoundationGateGeoPoint(
          latitude: geometry.center.latitude,
          longitude: geometry.center.longitude,
        ),
        radiusMeters: geometry.radiusMeters,
      );
    case PolygonGeometry():
      return FoundationGatePolygonGeometry(
        version: geometry.version,
        vertices: [
          for (final vertex in geometry.vertices)
            FoundationGateGeoPoint(
              latitude: vertex.latitude,
              longitude: vertex.longitude,
            ),
        ],
      );
  }
}

/// Binds the server authority for the location pack, or clears it when there is none.
///
/// Called from the composition root once the session knows which family this device is
/// looking at. Binding is idempotent and lives in exactly one place, so a screen can never
/// be looking at two different authorities.
void bindLocationServerAuthority(LocationServerAuthority? authority) {
  if (authority == null || !authority.isReady) {
    // Clearing the server authority leaves the local Stage-1 bindings exactly as the boot
    // sequence set them: this function decides who is authoritative, and it is not allowed
    // to also decide what the local fallback is.
    activeSafeZoneServerWriter = null;
    return;
  }
  activeSafeZoneServerWriter = LocationServerZoneWriter(authority);
  rebindStage1SafeZonesRepository(ServerSafeZonesRepository(authority));
  rebindStage1LocationMapRepository(ServerLocationMapRepository(authority));
}
