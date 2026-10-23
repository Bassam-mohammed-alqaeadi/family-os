import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/features/n03_screen_time/child_apps_models.dart';
import 'package:family_os/features/n03_screen_time/child_apps_repository.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';

/// How a guardian's app list relates to what the server holds.
///
/// There is no fourth value on purpose: "we will try to fix it locally" is not a state a
/// family can read, and a screen that invents one is a screen that lies.
enum ChildAppsSyncStatus {
  /// Nothing has been asked yet, so nothing is claimed.
  neverSynced,

  /// The list on screen is the server's answer.
  synced,

  /// The list on screen is the last server answer, and a later read failed.
  stale,
}

/// Reads one child's app inventory from the server.
typedef ChildAppsFromServer =
    Future<List<ChildAppEntry>> Function(ChildId childId);

/// Writes one app decision back to the server.
typedef ChildAppsRuleWriter =
    Future<void> Function(ChildId childId, ChildAppEntry app);

/// Keeps [InMemoryChildAppsRepository] honest about where its rows came from.
///
/// The screen's repository interface is synchronous because a list is drawn synchronously.
/// A server is not. Rather than change that interface — and every screen and test that
/// depends on it — this class holds the seam: reads fill the cache before the list is
/// drawn, and writes reach the server without blocking the tap.
///
/// Two rules it exists to keep:
///
///   * a row the guardian changed is only "changed" once the server took it; and
///   * a failed read never silently passes yesterday's list off as today's — it says
///     [ChildAppsSyncStatus.stale] instead.
final class ChildAppsServerSync extends ChangeNotifier {
  ChildAppsServerSync({
    required InMemoryChildAppsRepository repository,
    required ChildAppsFromServer read,
    required ChildAppsRuleWriter write,
  }) : _repository = repository,
       _read = read,
       _write = write;

  final InMemoryChildAppsRepository _repository;
  final ChildAppsFromServer _read;
  final ChildAppsRuleWriter _write;

  ChildAppsSyncStatus _status = ChildAppsSyncStatus.neverSynced;
  ChildAppsSyncStatus get status => _status;

  /// True when what is on screen is a real earlier answer and the last read failed.
  bool get isStale => _status == ChildAppsSyncStatus.stale;

  /// True when the list on screen is the server's answer.
  bool get isSynced => _status == ChildAppsSyncStatus.synced;

  /// One failed read is not one failed screen: an unbound family and an unreachable
  /// server both leave the previous answer alone and say only that it is the previous one.
  Future<void> sync(ChildId childId) async {
    try {
      final apps = await _read(childId);
      _repository.replaceFromServer(childId, apps);
      _setStatus(ChildAppsSyncStatus.synced);
    } on Object {
      // Never synced: there is nothing to be stale about, so claim nothing.
      if (_status != ChildAppsSyncStatus.neverSynced) {
        _setStatus(ChildAppsSyncStatus.stale);
      }
    }
  }

  /// Sends one decision and reports whether the server took it.
  ///
  /// The local row is not moved here: a tap is an intent, and the screen must draw the
  /// server's answer rather than the tap. Returns false when the write did not land.
  Future<bool> push(ChildId childId, String appId) async {
    final app = _repository.appOf(childId, appId);
    if (app == null) return false;
    try {
      await _write(childId, app);
      return true;
    } on Object {
      return false;
    }
  }

  void _setStatus(ChildAppsSyncStatus next) {
    if (_status == next) return;
    _status = next;
    notifyListeners();
  }
}

/// The server's app row as the screen's row. No field is invented and none is dropped.
ChildAppEntry childAppEntryFromServer(FoundationGateChildApp app) {
  final rule = app.rule;
  return ChildAppEntry(
    id: app.appId,
    name: app.displayName.trim().isEmpty ? app.appId : app.displayName,
    category: childAppCategoryFromWire(app.category),
    status: childAppStatusFromWire(rule?.status),
    usedMins: app.usedMinutes,
    limitMins: rule?.limitMinutes ?? 0,
    unlimited: rule?.unlimited ?? false,
    ageRating: app.ageRating,
  );
}

/// The server speaks a category string, the screen speaks four buckets.
///
/// An unknown category is [ChildAppCategory.tools] and **not** games: the server already
/// treats an unknown category as countable (`screen-time.js` → `effectiveCategory`), and a
/// bucket chosen for display must not also decide how many minutes a child loses.
ChildAppCategory childAppCategoryFromWire(String category) {
  return switch (category.trim().toLowerCase()) {
    'games' || 'game' => ChildAppCategory.games,
    'social' => ChildAppCategory.social,
    'education' || 'edu' || 'learning' => ChildAppCategory.edu,
    _ => ChildAppCategory.tools,
  };
}

/// A row with no rule has not been decided yet, which is [ChildAppStatus.pending] — never
/// "allowed", because nobody allowed it.
ChildAppStatus childAppStatusFromWire(FoundationGateAppRuleStatus? status) {
  if (status == null) return ChildAppStatus.pending;
  return switch (status) {
    FoundationGateAppRuleStatus.allowed => ChildAppStatus.allowed,
    FoundationGateAppRuleStatus.free => ChildAppStatus.free,
    FoundationGateAppRuleStatus.blocked => ChildAppStatus.blocked,
    FoundationGateAppRuleStatus.pending => ChildAppStatus.pending,
  };
}

/// The screen's status as the server's vocabulary. Used when a decision is written back.
FoundationGateAppRuleStatus appRuleStatusToWire(ChildAppStatus status) {
  return switch (status) {
    ChildAppStatus.allowed => FoundationGateAppRuleStatus.allowed,
    ChildAppStatus.free => FoundationGateAppRuleStatus.free,
    ChildAppStatus.blocked => FoundationGateAppRuleStatus.blocked,
    ChildAppStatus.pending => FoundationGateAppRuleStatus.pending,
  };
}

/// The production wiring: a guardian's app list read from, and written to, the server.
///
/// Nothing is added to [ScreenTimeServerAuthority]: its client, its family and its token
/// are already public, so this reads them and leaves the authority untouched — the one
/// class every screen-time surface already depends on.
ChildAppsServerSync childAppsServerSyncForAuthority({
  required ScreenTimeServerAuthority authority,
  required InMemoryChildAppsRepository repository,
}) {
  Future<({String family, String token})> session() async {
    final family = authority.familyId();
    if (family == null || family.trim().isEmpty) {
      throw const _NoSession();
    }
    final token = await authority.idToken();
    if (token.trim().isEmpty) {
      throw const _NoSession();
    }
    return (family: family, token: token);
  }

  return ChildAppsServerSync(
    repository: repository,
    read: (childId) async {
      final open = await session();
      final apps = await authority.api.listApps(
        familyId: open.family,
        childId: childId.value,
        idToken: open.token,
      );
      return apps.map(childAppEntryFromServer).toList(growable: false);
    },
    write: (childId, app) async {
      final open = await session();
      await authority.api.setAppRule(
        familyId: open.family,
        childId: childId.value,
        appId: app.id,
        status: appRuleStatusToWire(app.status),
        idempotencyKey: _decisionKey(childId, app),
        idToken: open.token,
        limitMinutes: app.limitMins > 0 ? app.limitMins : null,
        unlimited: app.unlimited,
      );
    },
  );
}

/// One key per decision, not one per attempt.
///
/// A retry of the same decision must be the same request, or a flaky network turns one
/// guardian's tap into two rules. The key is derived from what is being decided, so it is
/// identical on every retry and different for any other decision.
String _decisionKey(ChildId childId, ChildAppEntry app) {
  final limit = app.limitMins > 0 ? '${app.limitMins}' : 'none';
  return 'app-rule-${childId.value}-${app.id}-${app.status.name}-$limit-'
      '${app.unlimited}';
}

/// A build with no family session. Private: it exists to leave the previous answer alone,
/// not to be shown to anyone.
final class _NoSession implements Exception {
  const _NoSession();
}
