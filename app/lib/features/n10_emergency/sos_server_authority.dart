import 'package:family_os/core/policy/notification_delivery.dart';
import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_ladder_repository.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';
import 'package:family_os/core/sos_final/sos_prefs_local_persistence.dart';
import 'package:family_os/foundation_gate/family_sos_api_client.dart';

/// The emergency surface's one server connection.
///
/// It holds the client, the bearer token and the selected family, and it is the only place
/// that knows how a server incident becomes the shape a screen renders. Nothing here
/// invents state: a value that is not on the server is absent, and an absence is rendered
/// as an absence.
///
/// **What this build can and cannot do, stated once and plainly:**
///
///   * A GUARDIAN can raise an incident for a child, read the family's incidents, read and
///     change the escalation ladder, acknowledge, escalate and resolve. All of that is the
///     live contract, not a preview.
///   * The CHILD'S OWN handset cannot raise a server alarm from this Flutter build. The
///     contract has a route for exactly that (`POST /v1/devices/{deviceId}/sos-alerts`),
///     covered by the real-PostgreSQL journey, and it authenticates with the device
///     credential the app hands to the native layer at pairing and does not keep. The
///     family route, which this app does hold a session for, is guardians-only by design -
///     so a child's press is recorded on the handset and reported as NOT having reached a
///     server (`SosFireResult.reachedServer` false) rather than being dressed up as one
///     that did. Closing that needs credential persistence in the native layer, and it is
///     declared rather than hidden.
///
/// The alternative - letting a child's press look successful - is the exact failure this
/// wave exists to delete.
final class SosServerAuthority {
  SosServerAuthority({
    required this.api,
    required this.idToken,
    required this.familyId,
    this.memberLabels,
    this.memberLabelSource,
    this.childNameOf,
    this.childEmojiOf,
    this.panicQuiet = false,
  });

  final FamilySosApiClient api;
  final Future<String> Function() idToken;
  final String? Function() familyId;

  /// Membership id → the name a screen may show. Unknown ids stay as they are: a UUID is
  /// worse-looking than a name and better than a name nobody gave us.
  final Map<String, String> Function()? memberLabels;

  /// A live list of membership id → role words, read from the server.
  ///
  /// The membership contract publishes a role and never a person's name, so the most a
  /// screen may honestly print for a recipient is the part they play in this family. This
  /// source is consulted when an incident is read, and a failed refresh keeps the names the
  /// last read produced instead of blanking them.
  final Future<Map<String, String>> Function()? memberLabelSource;

  Map<String, String> _labelCache = const {};
  DateTime? _labelCacheAt;

  /// Child id → display name / avatar, from the roster the session already holds.
  final String Function(String childId)? childNameOf;
  final String Function(String childId)? childEmojiOf;

  /// The preference captured at press time (OD-15), read once by the caller.
  final bool panicQuiet;

  /// Names as fresh as the last read that needed them.
  ///
  /// A refresh is skipped for [_labelCacheTtl] so that a board refreshing itself does not
  /// turn every repaint into a roster request.
  static const _labelCacheTtl = Duration(seconds: 30);

  Future<void> _refreshMemberLabels({bool force = false}) async {
    final source = memberLabelSource;
    if (source == null) return;
    final at = _labelCacheAt;
    if (!force &&
        at != null &&
        DateTime.now().difference(at) < _labelCacheTtl) {
      return;
    }
    try {
      _labelCache = await source();
      _labelCacheAt = DateTime.now();
    } on Object {
      // Keep the last known names: a name already read is not a false claim, and an
      // emergency board must not lose its labels because a roster read failed.
    }
  }

  Map<String, String> _labels() {
    final fromServer = _labelCache;
    final local = memberLabels?.call();
    if (fromServer.isEmpty) return local ?? const {};
    if (local == null || local.isEmpty) return fromServer;
    return {...fromServer, ...local};
  }

  bool get isReady {
    final id = familyId();
    return id != null && id.isNotEmpty;
  }

  /// Open incidents, newest first, as every member of the family reads them.
  Future<List<FoundationGateSosAlert>> openAlerts() async {
    await _refreshMemberLabels();
    return api.listAlerts(
      familyId: _requireFamilyId(),
      idToken: _token(),
    );
  }

  Future<List<FoundationGateSosAlert>> allAlerts() async {
    await _refreshMemberLabels();
    return api.listAlerts(
      familyId: _requireFamilyId(),
      idToken: _token(),
      status: 'all',
    );
  }

  Future<FoundationGateSosAlert> read(String alertId) async {
    await _refreshMemberLabels();
    return api.readAlert(
      familyId: _requireFamilyId(),
      alertId: alertId,
      idToken: _token(),
    );
  }

  /// A guardian raising an incident for a child.
  ///
  /// The key is derived from the press rather than from the clock: pressing the same
  /// intent twice is the same press, and a network retry must replay it rather than open
  /// a second incident.
  Future<FoundationGateSosFireOutcome> raiseForChild({
    required String childId,
    required FoundationGateSosLocationClass locationClass,
    required FoundationGateSosConnectionClass connectionClass,
    required DateTime pressedAt,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    int? batteryPercent,
    String? placeLabel,
    String? fixId,
  }) async {
    final family = _requireFamilyId();
    return api.raiseForChild(
      familyId: family,
      childId: childId,
      locationClass: locationClass,
      connectionClass: connectionClass,
      idempotencyKey: 'sos-fire-$family-$childId-${pressedAt.toUtc().microsecondsSinceEpoch}',
      idToken: await idToken(),
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      batteryPercent: batteryPercent,
      placeLabel: placeLabel,
      panicQuiet: panicQuiet,
      fixId: fixId,
      pressedAt: pressedAt,
    );
  }

  Future<FoundationGateSosAlert> acknowledge(String alertId) async {
    return api.acknowledge(
      familyId: _requireFamilyId(),
      alertId: alertId,
      idempotencyKey: 'sos-ack-$alertId',
      idToken: await idToken(),
    );
  }

  Future<FoundationGateSosEscalationReceipt> escalate(String alertId) async {
    return api.escalate(
      familyId: _requireFamilyId(),
      alertId: alertId,
      idempotencyKey: 'sos-escalate-$alertId',
      idToken: await idToken(),
    );
  }

  Future<FoundationGateSosAlert> resolve(
    String alertId, {
    required FoundationGateSosTerminalReason reason,
  }) async {
    return api.resolve(
      familyId: _requireFamilyId(),
      alertId: alertId,
      reason: reason,
      idempotencyKey: 'sos-resolve-$alertId-${reason.wireValue}',
      idToken: await idToken(),
    );
  }

  Future<List<FoundationGateSosBackupContact>> contacts() {
    return api.listBackupContacts(
      familyId: _requireFamilyId(),
      idToken: _token(),
    );
  }

  Future<FoundationGateSosBackupContact> addContact({
    required String name,
    required String phoneE164,
    required String idempotencyKey,
    String? relation,
    int? priority,
  }) async {
    return api.createBackupContact(
      familyId: _requireFamilyId(),
      name: name,
      phoneE164: phoneE164,
      relation: relation,
      priority: priority,
      idempotencyKey: idempotencyKey,
      idToken: await idToken(),
    );
  }

  Future<FoundationGateSosBackupContact> updateContact({
    required String contactId,
    required String idempotencyKey,
    String? name,
    String? relation,
    String? phoneE164,
    FoundationGateSosBackupVerification? verification,
    bool? enabled,
    int? priority,
    bool? archived,
  }) async {
    return api.updateBackupContact(
      familyId: _requireFamilyId(),
      contactId: contactId,
      name: name,
      relation: relation,
      phoneE164: phoneE164,
      verification: verification,
      enabled: enabled,
      priority: priority,
      archived: archived,
      idempotencyKey: idempotencyKey,
      idToken: await idToken(),
    );
  }

  String _requireFamilyId() {
    final id = familyId();
    if (id == null || id.isEmpty) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    return id;
  }

  Future<String> _token() => idToken();

  /// A server incident, in the shape the board renders.
  SosAlert toAlert(FoundationGateSosAlert alert) {
    return SosAlert(
      id: alert.id,
      childId: alert.childId,
      raisedByActorId: alert.raisedByMembershipId ?? alert.childId,
      childDisplayName: childNameOf?.call(alert.childId) ?? '',
      childEmoji: childEmojiOf?.call(alert.childId) ?? '',
      pressedAt: alert.pressedAt ?? DateTime.now().toUtc(),
      locationLabel: alert.picture.placeLabel ?? '',
      batteryPercent: alert.picture.batteryPercent,
      movementLabel: '',
      accuracyMeters: alert.picture.accuracyMeters?.round(),
      recipientLabels: _recipientLabels(alert),
      status: _statusOf(alert.status),
      terminalReason: _terminalReasonOf(alert.terminalReason),
      locationClass: _locationClassOf(alert.picture.locationClass),
      connectionClass: _connectionClassOf(alert.picture.connectionClass),
      deliveries: [
        for (final delivery in alert.deliveries)
          SosDeliveryRow(
            recipientId: _recipientLabel(delivery),
            channel: delivery.channel,
            // `recorded` means a durable payload is waiting for the in-app pipe, and that
            // is a fact about the queue rather than about anyone's phone. It is rendered
            // as pending, which is what it is; `delivered` is reserved for a device that
            // has it, and no server answer claims that today.
            status: delivery.deliveryState ==
                    FoundationGateSosDeliveryState.notConfigured
                ? SosDeliveryClass.notConfigured
                : SosDeliveryClass.pending,
          ),
      ],
      acknowledgedAt: alert.acknowledgedAt,
      // The pin is drawn only from a position the server actually stored. The board's map
      // is decoration; a pin placed without a measurement points at a door nobody chose.
      pinFracX: alert.picture.hasPosition ? _pinFraction(alert.picture.longitude!, 44.191, 0.12) : null,
      pinFracY: alert.picture.hasPosition ? _pinFraction(alert.picture.latitude!, 15.3694, 0.12) : null,
      panicQuietAtTrigger: alert.picture.panicQuiet,
    );
  }

  /// Maps a coordinate to a fraction of the board map around Sanaa, clamped to the canvas.
  ///
  /// Deliberately crude and deliberately bounded: the board's map is a decorative canvas,
  /// not a projection, and a position far outside it pins to the edge instead of being
  /// drawn somewhere it is not.
  static double _pinFraction(double value, double origin, double span) {
    final fraction = 0.5 + ((value - origin) / span) * 0.5;
    if (fraction < 0) return 0;
    if (fraction > 1) return 1;
    return fraction;
  }

  /// The names the family's footer may show, and only the names it actually has.
  ///
  /// A membership id is not a name: the roster read does not carry one, so an unknown
  /// recipient is left out of the summary rather than printed as a UUID. Every recipient is
  /// still named row by row in the delivery list right below it.
  List<String> _recipientLabels(FoundationGateSosAlert alert) {
    final known = _labels();
    final labels = <String>[];
    for (final delivery in alert.deliveries) {
      final membershipId = delivery.recipientMembershipId;
      final label = membershipId == null ? null : known[membershipId];
      if (label != null && label.isNotEmpty && !labels.contains(label)) {
        labels.add(label);
      }
    }
    return labels;
  }

  String _recipientLabel(FoundationGateSosDelivery delivery) {
    final membershipId = delivery.recipientMembershipId;
    if (membershipId != null) {
      return _labels()[membershipId] ?? membershipId;
    }
    return delivery.recipientContactId ?? '';
  }

  static SosAlertStatus _statusOf(FoundationGateSosAlertStatus status) {
    return switch (status) {
      FoundationGateSosAlertStatus.active => SosAlertStatus.active,
      FoundationGateSosAlertStatus.acknowledged => SosAlertStatus.acknowledged,
      FoundationGateSosAlertStatus.escalating => SosAlertStatus.escalating,
      FoundationGateSosAlertStatus.resolved => SosAlertStatus.resolved,
    };
  }

  static SosTerminalReason? _terminalReasonOf(
    FoundationGateSosTerminalReason? reason,
  ) {
    return switch (reason) {
      FoundationGateSosTerminalReason.helped => SosTerminalReason.helped,
      FoundationGateSosTerminalReason.falseAlarm => SosTerminalReason.falseAlarm,
      FoundationGateSosTerminalReason.other => SosTerminalReason.other,
      null => null,
    };
  }

  static SosLocationClass _locationClassOf(
    FoundationGateSosLocationClass locationClass,
  ) {
    return switch (locationClass) {
      FoundationGateSosLocationClass.ready => SosLocationClass.ready,
      FoundationGateSosLocationClass.acquiring => SosLocationClass.acquiring,
      FoundationGateSosLocationClass.staleLastKnown => SosLocationClass.stale,
      FoundationGateSosLocationClass.unavailable => SosLocationClass.unavailable,
    };
  }

  static SosConnectionClass _connectionClassOf(
    FoundationGateSosConnectionClass connectionClass,
  ) {
    return switch (connectionClass) {
      FoundationGateSosConnectionClass.online => SosConnectionClass.online,
      FoundationGateSosConnectionClass.degraded => SosConnectionClass.degraded,
      FoundationGateSosConnectionClass.offline => SosConnectionClass.offline,
    };
  }
}

/// The live fire path: what the family's buttons call once a server session exists.
///
/// It answers from the server's own incident - id, picture and delivery rows - and it never
/// reports a delivery nobody made. A press from a child's own account is reported as not
/// having reached a server (see [SosServerAuthority]); a press that the server refused is
/// reported the same way, because a failure this app cannot fix must not look like a
/// success.
final class ServerSosFireService implements SosFireService {
  const ServerSosFireService(this.authority);

  final SosServerAuthority authority;

  @override
  Future<SosFireResult> fire({
    required String childId,
    String? actorId,
    List<String> recipients = const ['father', 'mother'],
    DateTime? at,
    TimeOfDay? clock,
  }) async {
    final actor = (actorId == null || actorId.isEmpty) ? childId : actorId;
    final pressedAt = (at ?? DateTime.now()).toUtc();
    if (!authority.isReady) {
      return _notReached(childId: childId, actorId: actor, at: pressedAt);
    }
    try {
      final outcome = await authority.raiseForChild(
        childId: childId,
        // The app has not measured a position for this press, and it says so rather than
        // borrowing one: `acquiring` is the honest state of a device that has not looked.
        locationClass: FoundationGateSosLocationClass.acquiring,
        connectionClass: FoundationGateSosConnectionClass.online,
        pressedAt: pressedAt,
      );
      if (outcome.alert != null) {
        return _reached(childId: childId, actorId: actor, alert: outcome.alert!);
      }
      // The child already has an incident, and that incident IS the answer to this press.
      final existing = await authority.read(outcome.existingAlertId!);
      return _reached(
        childId: childId,
        actorId: actor,
        alert: existing,
        duplicate: true,
      );
    } on FoundationGateApiException catch (failure) {
      if (failure.failure == FoundationGateApiFailure.accessDenied ||
          failure.failure == FoundationGateApiFailure.unauthenticated ||
          failure.failure == FoundationGateApiFailure.serviceUnavailable ||
          failure.failure == FoundationGateApiFailure.networkUnavailable ||
          failure.failure == FoundationGateApiFailure.notFound) {
        // No authority answered for this press, and saying otherwise would be the whole
        // defect this wave removes.
        return _notReached(childId: childId, actorId: actor, at: pressedAt);
      }
      rethrow;
    }
  }

  SosFireResult _reached({
    required String childId,
    required String actorId,
    required FoundationGateSosAlert alert,
    bool duplicate = false,
  }) {
    return SosFireResult(
      fired: true,
      at: alert.pressedAt ?? DateTime.now().toUtc(),
      recipientDeliveries: [
        for (final delivery in alert.deliveries)
          NotificationDeliveryResult(
            recipientId:
                delivery.recipientMembershipId ??
                delivery.recipientContactId ??
                '',
            tier: NotificationTier.critical,
            // True only when the recipient's device has it. A row that is durably recorded
            // for the in-app pipe has not been handed to anyone yet, and this build has no
            // transport that would change that.
            delivered: false,
          ),
      ],
      childId: childId,
      actorId: actorId,
      alertId: alert.id,
      reachedServer: true,
      duplicate: duplicate,
    );
  }

  SosFireResult _notReached({
    required String childId,
    required String actorId,
    required DateTime at,
  }) {
    return SosFireResult(
      fired: false,
      at: at,
      recipientDeliveries: const <NotificationDeliveryResult>[],
      childId: childId,
      actorId: actorId,
    );
  }
}

/// The board's read path, against the server.
///
/// Which incident it loads follows the same rule the local domain path followed: the one
/// the route named, or the family's open one. It does not look at local rows first - a
/// board that showed a device's own copy while the server held a newer one would be showing
/// a stale alarm during the minutes that matter.
final class ServerSosAlertRepository implements SosAlertRepository {
  const ServerSosAlertRepository(this.authority);

  final SosServerAuthority authority;

  @override
  Future<SosAlert?> loadActive({String? alertId}) async {
    final trimmed = alertId?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      final alert = await authority.read(trimmed);
      if (!alert.isOpen) return null;
      return authority.toAlert(alert);
    }
    final open = await authority.openAlerts();
    if (open.isEmpty) return null;
    return authority.toAlert(open.first);
  }

  @override
  Future<SosAlert> acknowledge(String alertId, {required SosActor actor}) async {
    if (!SosRoleActions.canAcknowledge(actor)) {
      throw StateError('acknowledge denied for actor');
    }
    return authority.toAlert(await authority.acknowledge(alertId));
  }

  @override
  Future<SosAlert> resolve(
    String alertId, {
    required SosActor actor,
    SosTerminalReason reason = SosTerminalReason.helped,
  }) async {
    final isChildFalseAlarm =
        actor.role == AppRole.child &&
        SosRoleActions.canCancelOwnSos(actor) &&
        reason == SosTerminalReason.falseAlarm;
    if (!isChildFalseAlarm && !SosRoleActions.canResolve(actor)) {
      throw StateError('resolve denied for actor');
    }
    if (isChildFalseAlarm) {
      // The server closes a child's incident from the handset that raised it, with the
      // device credential - and this app does not hold one. Refusing here keeps the
      // refusal where a screen can explain it, instead of sending a request the server
      // would answer with 403 and turning a real limitation into a mysterious failure.
      throw const SosFireUnavailable();
    }
    return authority.toAlert(
      await authority.resolve(alertId, reason: _reasonOf(reason)),
    );
  }

  @override
  Future<SosAlert> escalateEmergencyContacts(
    String alertId, {
    required SosActor actor,
  }) async {
    if (!SosRoleActions.canEscalate(actor)) {
      throw StateError('escalate denied for actor');
    }
    final receipt = await authority.escalate(alertId);
    return authority.toAlert(receipt.alert);
  }

  static FoundationGateSosTerminalReason _reasonOf(SosTerminalReason reason) {
    return switch (reason) {
      SosTerminalReason.helped => FoundationGateSosTerminalReason.helped,
      SosTerminalReason.falseAlarm => FoundationGateSosTerminalReason.falseAlarm,
      SosTerminalReason.other => FoundationGateSosTerminalReason.other,
    };
  }
}

/// The family's ladder, against the server.
///
/// Rung 1 is the family's guardians and stays where it is: it is not a row anyone edits, so
/// the immovability rules the local repository enforced by convention are structurally true
/// here. Rung 2 and below are the server's contacts, in the server's order.
final class ServerSosLadderRepository implements SosLadderRepository {
  ServerSosLadderRepository(this.authority);

  final SosServerAuthority authority;

  @override
  Future<SosLadder> load([String familyId = SosLadder.defaultFamilyId]) async {
    final contacts = await authority.contacts();
    return SosLadder(
      familyId: familyId,
      presentParentIds: kSosLadderFixedParentIds.toSet(),
      backups: [
        for (final contact in contacts)
          SosBackupContact(
            id: contact.id,
            name: contact.name,
            relation: contact.relation,
            delaySeconds: 60,
            enabled: contact.enabled,
            phoneE164: contact.phoneE164,
            priority: contact.priority,
            verification: _verificationOf(contact.verification),
          ),
      ],
    );
  }

  @override
  Future<void> save(SosLadder ladder) async {
    final existing = await authority.contacts();
    final known = {for (final contact in existing) contact.id};
    for (final backup in ladder.backups) {
      if (known.contains(backup.id)) {
        await authority.updateContact(
          contactId: backup.id,
          idempotencyKey: 'sos-ladder-${backup.id}-${backup.priority}',
          priority: backup.priority,
          enabled: backup.enabled,
        );
      } else {
        await authority.addContact(
          name: backup.name,
          phoneE164: backup.phoneE164,
          relation: backup.relation,
          priority: backup.priority,
          idempotencyKey: 'sos-ladder-add-${backup.id}',
        );
      }
    }
  }

  @override
  Future<SosLadder> removeFromRung1(
    String memberId, {
    String familyId = SosLadder.defaultFamilyId,
  }) {
    // Rung 1 is not a row. There is nothing to remove, and the refusal is the answer.
    throw SosLadderValidationException(
      SosLadderValidationCode.rung1ParentImmovable,
      memberId: memberId,
    );
  }

  @override
  Future<SosLadder> setEmergencyContactEnabled(
    String memberId,
    bool enabled, {
    String familyId = SosLadder.defaultFamilyId,
  }) {
    throw SosLadderValidationException(
      SosLadderValidationCode.rung1ParentDisableForbidden,
      memberId: memberId,
    );
  }

  @override
  Future<SosLadder> removeBackup(
    String backupId, {
    String familyId = SosLadder.defaultFamilyId,
  }) async {
    await authority.updateContact(
      contactId: backupId,
      idempotencyKey: 'sos-ladder-archive-$backupId',
      archived: true,
    );
    return load(familyId);
  }

  @override
  Future<SosLadder> upsertBackup(
    SosBackupContact contact, {
    String familyId = SosLadder.defaultFamilyId,
  }) async {
    final existing = await authority.contacts();
    final known = {for (final row in existing) row.id};
    if (known.contains(contact.id)) {
      await authority.updateContact(
        contactId: contact.id,
        idempotencyKey: 'sos-ladder-save-${contact.id}-${contact.priority}',
        name: contact.name,
        relation: contact.relation,
        phoneE164: contact.phoneE164,
        enabled: contact.enabled,
        priority: contact.priority,
      );
    } else {
      await authority.addContact(
        name: contact.name,
        phoneE164: contact.phoneE164,
        relation: contact.relation,
        priority: contact.priority,
        idempotencyKey: 'sos-ladder-new-${contact.id}',
      );
    }
    return load(familyId);
  }

  @override
  Future<SosLadder> moveBackupPriority(
    String backupId,
    int delta, {
    String familyId = SosLadder.defaultFamilyId,
  }) async {
    final ladder = await load(familyId);
    final ordered = ladder.backupsByPriority;
    final index = ordered.indexWhere((backup) => backup.id == backupId);
    if (index < 0) return ladder;
    final target = (index + delta).clamp(0, ordered.length - 1);
    if (target == index) return ladder;
    final moved = ordered[index];
    final displaced = ordered[target];
    await authority.updateContact(
      contactId: moved.id,
      idempotencyKey: 'sos-ladder-move-${moved.id}-${displaced.priority}',
      priority: displaced.priority,
    );
    await authority.updateContact(
      contactId: displaced.id,
      idempotencyKey: 'sos-ladder-move-${displaced.id}-${moved.priority}',
      priority: moved.priority,
    );
    return load(familyId);
  }

  static SosVerificationStatus _verificationOf(
    FoundationGateSosBackupVerification verification,
  ) {
    return switch (verification) {
      FoundationGateSosBackupVerification.unverified =>
        SosVerificationStatus.unverified,
      FoundationGateSosBackupVerification.verified =>
        SosVerificationStatus.verified,
      FoundationGateSosBackupVerification.revoked =>
        SosVerificationStatus.revoked,
    };
  }
}

SosServerAuthority? _activeSosAuthority;

/// The authority the emergency screens read, or null when no server session is bound.
SosServerAuthority? get activeSosServerAuthority => _activeSosAuthority;

/// Binds every emergency surface to one server session, or clears them all.
///
/// One call site, at boot, next to the location authority: the fire path, the board's read
/// path and the ladder all move together, so a build can never end up raising alarms
/// through one path while reading them through another.
void bindSosServerAuthority(SosServerAuthority? authority) {
  _activeSosAuthority = authority;
  if (authority == null) {
    bindSosFireService(null);
    bindActiveSosAlertRepository(null);
    bindActiveSosLadderRepository(null);
    SosPrefsRuntime.bindServerLadder(null);
    return;
  }
  bindSosFireService(ServerSosFireService(authority));
  bindActiveSosAlertRepository(ServerSosAlertRepository(authority));
  final ladder = ServerSosLadderRepository(authority);
  bindActiveSosLadderRepository(ladder);
  // The setup screen reads the ladder through SosPrefsRuntime, so the same binding has to
  // reach it: a rung the mother added has to escalate for the father, or it is not a ladder.
  SosPrefsRuntime.bindServerLadder(ladder);
}
