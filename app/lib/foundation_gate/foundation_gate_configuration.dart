final _foundationGateUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isFoundationGateUuid(String value) => _foundationGateUuid.hasMatch(value);

class FoundationGateConfiguration {
  FoundationGateConfiguration._(this.stagingApiOrigin);

  factory FoundationGateConfiguration.fromStagingApiOrigin(Uri origin) {
    if (!_isPermittedStagingOrigin(origin) ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw ArgumentError.value(
        origin,
        'origin',
        'A canonical HTTPS staging origin is required. Cleartext HTTP is '
            'accepted only for loopback or private development hosts.',
      );
    }
    return FoundationGateConfiguration._(origin.replace(path: ''));
  }

  /// A public staging origin must be HTTPS: a bearer token and child data
  /// never cross cleartext. HTTP therefore survives only where a real device
  /// reaches a developer machine, and the decision is made before any
  /// networking happens.
  static bool _isPermittedStagingOrigin(Uri origin) {
    if (origin.scheme == 'https') {
      return true;
    }
    if (origin.scheme != 'http') {
      return false;
    }
    return _isLoopbackOrPrivateHost(origin.host);
  }

  /// Loopback, mDNS `.local` and RFC 1918 private ranges are the only hosts
  /// allowed to serve cleartext, because only they are under the developer's
  /// own control.
  static bool _isLoopbackOrPrivateHost(String host) {
    final normalized = host.toLowerCase();
    if (normalized == 'localhost' || normalized.endsWith('.localhost')) {
      return true;
    }
    if (normalized.endsWith('.local')) {
      return true;
    }
    if (normalized == '::1') {
      return true;
    }
    final match = RegExp(
      r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
    ).firstMatch(normalized);
    if (match == null) {
      return false;
    }
    final octets = <int>[];
    for (var index = 1; index <= 4; index++) {
      final value = int.tryParse(match.group(index) ?? '');
      if (value == null || value > 255) {
        return false;
      }
      octets.add(value);
    }
    if (octets[0] == 127) {
      return true;
    }
    if (octets[0] == 10) {
      return true;
    }
    if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) {
      return true;
    }
    if (octets[0] == 192 && octets[1] == 168) {
      return true;
    }
    return false;
  }

  final Uri stagingApiOrigin;

  Uri get familyDiscoveryUri =>
      stagingApiOrigin.replace(path: '/v1/me/families');

  Uri childrenRosterUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/children');
  }

  Uri familyDevicesUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/devices');
  }

  Uri familyChildDevicesUri(String familyId, String childId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw ArgumentError(
        'Server-returned UUID family and child identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/children/$childId/devices',
    );
  }

  Uri deviceTelemetryUri(String deviceId) {
    if (!isFoundationGateUuid(deviceId)) {
      throw ArgumentError.value(
        deviceId,
        'deviceId',
        'A server-returned UUID device identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/devices/$deviceId/telemetry');
  }

  Uri familyChildDevicePairingsUri(String familyId, String childId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw ArgumentError(
        'Server-returned UUID family and child identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/children/$childId/device-pairings',
    );
  }

  Uri get devicePairingClaimUri =>
      stagingApiOrigin.replace(path: '/v1/device-pairings/claim');

  /// The family membership roster: read with GET, invite with POST.
  Uri familyMembershipsUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/memberships');
  }

  /// The zones this family defined. Read with GET, draw with POST.
  Uri familySafeZonesUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/safe-zones');
  }

  /// One zone: the alert flags move with PATCH, nothing else does.
  Uri familySafeZoneUri(String familyId, String zoneId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(zoneId)) {
      throw ArgumentError(
        'Server-returned UUID family and zone identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/safe-zones/$zoneId',
    );
  }

  /// The family's live picture. One read, one visibility rule for every member.
  Uri familyLocationUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/location');
  }

  /// The trail of one child, under the same one-rule-for-everyone promise as the live read.
  Uri familyChildLocationHistoryUri(String familyId, String childId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw ArgumentError(
        'Server-returned UUID family and child identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/children/$childId/location-history',
    );
  }

  /// The arrival and departure feed, newest first.
  Uri familyGeofenceEventsUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/geofence-events',
    );
  }

  /// Where a child device reports its own position. The device id is in the path, so the
  /// device's credential can only ever report for itself.
  Uri deviceLocationFixesUri(String deviceId) {
    if (!isFoundationGateUuid(deviceId)) {
      throw ArgumentError.value(
        deviceId,
        'deviceId',
        'A server-returned UUID device identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/devices/$deviceId/location-fixes');
  }

  /// The family's emergency incidents. `status` is part of the URL rather than of a body
  /// because it selects rows: an open incident is the one that needs answering, and that
  /// is what the default view asks for.
  Uri familySosAlertsUri(String familyId, {String status = 'open'}) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError(
        'Server-returned UUID family identifier is required.',
      );
    }
    if (!const <String>{'open', 'resolved', 'all'}.contains(status)) {
      throw ArgumentError.value(status, 'status', 'open, resolved or all');
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-alerts',
      queryParameters: status == 'open' ? null : <String, String>{'status': status},
    );
  }

  /// A child's screen-time state: the policy, today's minutes and the reason the answer is
  /// what it is. The server computes the state at the moment of the read, so the URL carries
  /// no instant - a screen that asked "is it bedtime at 21:00" would be asking a question the
  /// server can no longer answer by the time the answer arrives.
  Uri familyChildScreenTimeUri(String familyId, String childId) =>
      _familyChildCrumbUri(familyId, childId, 'screen-time');

  /// The instant lock. A URL of its own because it is an act of its own: a lock is a
  /// decision somebody made now, not a rule the family set.
  Uri familyChildScreenLockUri(String familyId, String childId) =>
      _familyChildCrumbUri(familyId, childId, 'screen-time/lock');

  /// Releasing a lock. The answer says whether there was one to release.
  Uri familyChildScreenUnlockUri(String familyId, String childId) =>
      _familyChildCrumbUri(familyId, childId, 'screen-time/unlock');

  /// The apps on the child's phone, each with the family's decision about it.
  Uri familyChildAppsUri(String familyId, String childId) =>
      _familyChildCrumbUri(familyId, childId, 'apps');

  /// One app's rule.
  ///
  /// The app id is a package name, not a UUID, so it is checked against the same shape the
  /// server accepts instead of being pasted into a path and hoped for.
  Uri familyChildAppRuleUri(String familyId, String childId, String appId) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$').hasMatch(appId)) {
      throw ArgumentError.value(appId, 'appId', 'package-style identifier');
    }
    return _familyChildCrumbUri(familyId, childId, 'apps/$appId/rule');
  }

  /// The minutes a child asked for and what the family answered.
  ///
  /// `status` selects rows, so it belongs in the URL rather than in a body - and `all` is
  /// the default because a family opening this list wants the history, not only what waits.
  Uri familyChildTimeRequestsUri(
    String familyId,
    String childId, {
    String status = 'all',
  }) {
    if (!const <String>{'all', 'pending', 'approved', 'denied', 'expired'}
        .contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'all, pending, approved, denied or expired',
      );
    }
    final uri = _familyChildCrumbUri(familyId, childId, 'time-requests');
    return status == 'all'
        ? uri
        : uri.replace(queryParameters: <String, String>{'status': status});
  }

  /// The answer to one question.
  Uri familyChildTimeRequestDecisionUri(
    String familyId,
    String childId,
    String requestId,
  ) {
    if (!isFoundationGateUuid(requestId)) {
      throw ArgumentError(
        'Server-returned UUID request identifier is required.',
      );
    }
    return _familyChildCrumbUri(
      familyId,
      childId,
      'time-requests/$requestId/decision',
    );
  }

  /// The filter a child's phone must apply, with the doors that are open right now.
  ///
  /// The temporary allows travel with the policy because they belong to the same answer: a
  /// handset that fetched only the stored rules would refuse a host a guardian just opened.
  Uri familyChildWebFilterUri(String familyId, String childId) =>
      _familyChildCrumbUri(familyId, childId, 'web-filter');

  /// The father's preview: what this child would get for one host.
  ///
  /// The host is a query parameter rather than a path segment, because a host is data a
  /// person typed and a path segment is a name the server issued.
  Uri familyChildWebFilterEvaluateUri(
    String familyId,
    String childId,
    String host,
  ) {
    final uri = _familyChildCrumbUri(familyId, childId, 'web-filter/evaluate');
    return uri.replace(queryParameters: <String, String>{'host': host});
  }

  /// The doors that were opened for this child, and whether they are still open.
  Uri familyChildWebFilterTempAllowsUri(String familyId, String childId) =>
      _familyChildCrumbUri(familyId, childId, 'web-filter/temp-allows');

  /// The answer to one request for a host.
  Uri familyChildWebFilterTempAllowDecisionUri(
    String familyId,
    String childId,
    String requestId,
  ) {
    if (!isFoundationGateUuid(requestId)) {
      throw ArgumentError(
        'Server-returned UUID request identifier is required.',
      );
    }
    return _familyChildCrumbUri(
      familyId,
      childId,
      'web-filter/temp-allows/$requestId/decision',
    );
  }

  /// Whether protection is actually on, device by device, for one family.
  ///
  /// This one hangs off the family rather than a child, because the question it answers -
  /// is the protection really running - is asked about the family's phones as a set.
  Uri familyProtectionUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError(
        'Server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/protection');
  }
  // ── W7 — family tasks and points ────────────────────────────────────────────────

  /// What this child has to do, and the cycle open on each task.
  Uri familyChildTasksUri(String familyId, String childId) =>
      _familyChildCrumbUri(familyId, childId, 'tasks');

  /// "I did it" for a child who spoke to a guardian instead of tapping their phone.
  Uri familyChildTaskClaimUri(String familyId, String childId, String taskId) =>
      _familyChildTaskCrumbUri(familyId, childId, taskId, 'claim');

  /// The guardian's word on a claim.
  Uri familyChildTaskDecisionUri(String familyId, String childId, String taskId) =>
      _familyChildTaskCrumbUri(familyId, childId, taskId, 'decision');

  /// The balance and the entries that produced it.
  Uri familyChildPointsUri(String familyId, String childId) =>
      _familyChildCrumbUri(familyId, childId, 'points');

  // W9 — chat resources are only addressable by UUIDs the server issued.
  Uri familyChatThreadsUri(String familyId) {
    _requireChatUuids(familyId);
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/chat/threads',
    );
  }

  Uri familyChatParticipantsUri(String familyId) {
    _requireChatUuids(familyId);
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/chat/participants',
    );
  }

  Uri familyCollaborationPolicyUri(String familyId) {
    _requireChatUuids(familyId);
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/collaboration-policy',
    );
  }

  Uri familyChatThreadMembersUri(String familyId, String threadId) {
    _requireChatUuids(familyId, threadId);
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/chat/threads/$threadId/members',
    );
  }

  Uri familyChatMessagesUri(
    String familyId,
    String threadId, {
    int? afterSeq,
    int? limit,
  }) {
    _requireChatUuids(familyId, threadId);
    if (afterSeq == null && limit == null) {
      return stagingApiOrigin.replace(
        path: '/v1/families/$familyId/chat/threads/$threadId/messages',
      );
    }
    final sequence = afterSeq ?? 0;
    final pageSize = limit ?? 50;
    _requireChatPage(sequence, pageSize);
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/chat/threads/$threadId/messages',
      queryParameters: <String, String>{
        'afterSeq': '$sequence',
        'limit': '$pageSize',
      },
    );
  }

  Uri familyChatMessageUri(String familyId, String threadId, String messageId) {
    _requireChatUuids(familyId, threadId, messageId);
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/chat/threads/$threadId/messages/$messageId',
    );
  }

  Uri familyChatMessageDeletionUri(
    String familyId,
    String threadId,
    String messageId,
  ) {
    final base = familyChatMessageUri(familyId, threadId, messageId);
    return base.replace(path: '${base.path}/deletion');
  }

  Uri familyChatReadsUri(String familyId, String threadId) {
    _requireChatUuids(familyId, threadId);
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/chat/threads/$threadId/reads',
    );
  }

  Uri deviceChatThreadsUri(String deviceId) {
    _requireChatUuids(deviceId);
    return stagingApiOrigin.replace(path: '/v1/devices/$deviceId/chat/threads');
  }

  Uri deviceChatParticipantsUri(String deviceId) {
    _requireChatUuids(deviceId);
    return stagingApiOrigin.replace(path: '/v1/devices/$deviceId/chat/participants');
  }

  Uri deviceChatThreadMembersUri(String deviceId, String threadId) {
    _requireChatUuids(deviceId, threadId);
    return stagingApiOrigin.replace(
      path: '/v1/devices/$deviceId/chat/threads/$threadId/members',
    );
  }

  Uri deviceChatMessagesUri(
    String deviceId,
    String threadId, {
    int? afterSeq,
    int? limit,
  }) {
    _requireChatUuids(deviceId, threadId);
    if (afterSeq == null && limit == null) {
      return stagingApiOrigin.replace(
        path: '/v1/devices/$deviceId/chat/threads/$threadId/messages',
      );
    }
    final sequence = afterSeq ?? 0;
    final pageSize = limit ?? 50;
    _requireChatPage(sequence, pageSize);
    return stagingApiOrigin.replace(
      path: '/v1/devices/$deviceId/chat/threads/$threadId/messages',
      queryParameters: <String, String>{
        'afterSeq': '$sequence',
        'limit': '$pageSize',
      },
    );
  }

  Uri deviceChatMessageUri(String deviceId, String threadId, String messageId) {
    _requireChatUuids(deviceId, threadId, messageId);
    return stagingApiOrigin.replace(
      path: '/v1/devices/$deviceId/chat/threads/$threadId/messages/$messageId',
    );
  }

  Uri deviceChatMessageDeletionUri(
    String deviceId,
    String threadId,
    String messageId,
  ) {
    final base = deviceChatMessageUri(deviceId, threadId, messageId);
    return base.replace(path: '${base.path}/deletion');
  }

  Uri deviceChatReadsUri(String deviceId, String threadId) {
    _requireChatUuids(deviceId, threadId);
    return stagingApiOrigin.replace(
      path: '/v1/devices/$deviceId/chat/threads/$threadId/reads',
    );
  }

  void _requireChatUuids(String first, [String? second, String? third]) {
    if (!isFoundationGateUuid(first) ||
        (second != null && !isFoundationGateUuid(second)) ||
        (third != null && !isFoundationGateUuid(third))) {
      throw ArgumentError('Server-issued chat UUIDs are required.');
    }
  }

  void _requireChatPage(int afterSeq, int limit) {
    if (afterSeq < 0 || limit < 1 || limit > 200) {
      throw ArgumentError('Chat paging must use afterSeq >= 0 and limit 1..200.');
    }
  }

  // ── W8 — family calendar ───────────────────────────────────────────────────────────

  /// The family's events. A POST here states one; the read of them carries a window.
  Uri familyEventsUri(String familyId) => _familyCrumbUri(familyId, 'events');

  /// What the family agreed to do together, inside a window.
  ///
  /// The window is not optional decoration: the server refuses a read without `from` and
  /// `to`, because "everything" is not a question a calendar screen gets to ask. A window
  /// of a week is passed in here and stated in the URL - and it is a separate method from
  /// the collection itself, because the write refuses query parameters outright and a
  /// shared builder would have sent them.
  Uri familyEventsWindowUri(
    String familyId, {
    required String from,
    required String to,
  }) =>
      familyEventsUri(familyId).replace(
        queryParameters: <String, String>{'from': from, 'to': to},
      );

  /// One event: where an edit lands, and what an edit must name the version of.
  Uri familyEventUri(String familyId, String eventId) =>
      _familyEventCrumbUri(familyId, eventId, '');

  /// Calling an event off. An act of its own, because a cancellation has an author and a
  /// reason and is not a row that quietly changed shape.
  Uri familyEventCancelUri(String familyId, String eventId) =>
      _familyEventCrumbUri(familyId, eventId, 'cancel');

  /// What actually happened, recorded by a guardian after the event started.
  Uri familyEventAttendanceUri(String familyId, String eventId) =>
      _familyEventCrumbUri(familyId, eventId, 'attendance');

  /// The answer of one child, recorded by a guardian who heard it in words. The child's own
  /// handset has its own route, and that credential is not kept in this class.
  Uri familyChildEventResponseUri(
    String familyId,
    String childId,
    String eventId,
  ) =>
      _familyChildCrumbUri(familyId, childId, 'events/$eventId/response');

  /// One path under the family, with the family identifier checked the way every other
  /// route checks it.
  Uri _familyCrumbUri(String familyId, String crumb) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError('Server-returned UUID family identifier is required.');
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/$crumb');
  }

  /// One event's sub-path. An empty crumb is the event itself rather than a trailing
  /// slash, so the same helper serves the read, the edit, the cancellation and the record.
  Uri _familyEventCrumbUri(String familyId, String eventId, String crumb) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(eventId)) {
      throw ArgumentError(
        'Server-returned UUID family and event identifiers are required.',
      );
    }
    final path = crumb.isEmpty
        ? '/v1/families/$familyId/events/$eventId'
        : '/v1/families/$familyId/events/$eventId/$crumb';
    return stagingApiOrigin.replace(path: path);
  }

  /// One task's sub-path, with the task identifier checked like every other identifier: a
  /// path built from a value the server never issued is a request to somewhere that does
  /// not exist, and this class refuses to build it.
  Uri _familyChildTaskCrumbUri(
    String familyId,
    String childId,
    String taskId,
    String crumb,
  ) {
    if (!isFoundationGateUuid(taskId)) {
      throw ArgumentError('Server-returned UUID task identifier is required.');
    }
    return _familyChildCrumbUri(familyId, childId, 'tasks/$taskId/$crumb');
  }


  /// One path under a child, with both identifiers checked the same way every other route
  /// checks them: this class refuses to build a URL out of an identifier the server never
  /// issued.
  Uri _familyChildCrumbUri(String familyId, String childId, String crumb) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw ArgumentError(
        'Server-returned UUID family and child identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/children/$childId/$crumb',
    );
  }

  /// One incident, read by every member of the family - the child included.
  Uri familySosAlertUri(String familyId, String alertId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(alertId)) {
      throw ArgumentError(
        'Server-returned UUID family and alert identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-alerts/$alertId',
    );
  }

  /// A guardian opening an incident for a child whose handset is not the one in hand.
  Uri familyChildSosAlertsUri(String familyId, String childId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw ArgumentError(
        'Server-returned UUID family and child identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/children/$childId/sos-alerts',
    );
  }

  /// "I have seen this" - deliberately its own path, because it is not closing anything.
  Uri familySosAlertAcknowledgeUri(String familyId, String alertId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(alertId)) {
      throw ArgumentError(
        'Server-returned UUID family and alert identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-alerts/$alertId/acknowledge',
    );
  }

  /// Climbing the family's own ladder.
  Uri familySosAlertEscalateUri(String familyId, String alertId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(alertId)) {
      throw ArgumentError(
        'Server-returned UUID family and alert identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-alerts/$alertId/escalate',
    );
  }

  /// Closing the incident, with the reason stated.
  Uri familySosAlertResolveUri(String familyId, String alertId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(alertId)) {
      throw ArgumentError(
        'Server-returned UUID family and alert identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-alerts/$alertId/resolve',
    );
  }

  /// The ladder rung 2 and below: the people the family itself trusts.
  Uri familySosBackupContactsUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError(
        'Server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-backup-contacts',
    );
  }

  /// One rung: verify it, renumber it, switch it off or archive it.
  Uri familySosBackupContactUri(String familyId, String contactId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(contactId)) {
      throw ArgumentError(
        'Server-returned UUID family and contact identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-backup-contacts/$contactId',
    );
  }

  /// One command on one membership: `accept` or `revoke`.
  Uri membershipCommandUri(String familyId, String membershipId, String command) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(membershipId)) {
      throw ArgumentError(
        'Server-returned UUID family and membership identifiers are required.',
      );
    }
    if (!const <String>{'accept', 'revoke'}.contains(command)) {
      throw ArgumentError.value(command, 'command', 'accept or revoke');
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/memberships/$membershipId/$command',
    );
  }
}
