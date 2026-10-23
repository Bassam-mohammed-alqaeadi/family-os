// S3 polish — the guardian's app list is the server's list.
//
// These are plain Dart tests on purpose: the seam this file guards is not a widget, it is
// the promise that a row on screen came from the server and a tap only counts once the
// server took it. A widget test would hide that promise behind a painted box.
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/features/n03_screen_time/child_apps_models.dart';
import 'package:family_os/features/n03_screen_time/child_apps_repository.dart';
import 'package:family_os/features/n03_screen_time/child_apps_server_sync.dart';
import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';

final _child = ChildId('child-sync-a');

ChildAppEntry _entry(
  String id, {
  String name = 'App',
  ChildAppCategory category = ChildAppCategory.games,
  ChildAppStatus status = ChildAppStatus.pending,
  int usedMins = 0,
  int limitMins = 0,
  bool unlimited = false,
}) {
  return ChildAppEntry(
    id: id,
    name: name,
    category: category,
    status: status,
    usedMins: usedMins,
    limitMins: limitMins,
    unlimited: unlimited,
  );
}

InMemoryChildAppsRepository _repositoryWith(List<ChildAppEntry> apps) {
  return InMemoryChildAppsRepository(
    seed: <String, List<ChildAppEntry>>{
      _child.value: List<ChildAppEntry>.from(apps),
    },
  );
}

void main() {
  test('a synced list is the server list and not a merge', () async {
    final repository = _repositoryWith(<ChildAppEntry>[
      _entry('com.old.game'),
      _entry('com.kept.app'),
      _entry('com.also.old'),
    ]);
    final sync = ChildAppsServerSync(
      repository: repository,
      read: (childId) async => <ChildAppEntry>[
        _entry('com.kept.app'),
        _entry('com.new.from.server'),
      ],
      write: (childId, app) async {},
    );

    expect(sync.status, ChildAppsSyncStatus.neverSynced);

    await sync.sync(_child);

    final ids = repository.appsFor(_child).map((app) => app.id).toList();
    expect(ids, <String>['com.kept.app', 'com.new.from.server']);
    expect(
      ids.contains('com.old.game'),
      isFalse,
      reason: 'an app the family removed must not come back from a merge',
    );
    expect(sync.status, ChildAppsSyncStatus.synced);
    expect(sync.isSynced, isTrue);
  });

  test('an app the family never decided is pending and never allowed', () {
    final row = FoundationGateChildApp(
      appId: 'com.undecided.app',
      displayName: 'Undecided',
      category: 'games',
      ageRating: '',
      knownOnDevice: true,
      countable: true,
      usedMinutes: 12,
      remainingMinutes: null,
      rule: null,
      decision: const FoundationGateAppDecision(allowed: false, reason: null),
    );

    final entry = childAppEntryFromServer(row);

    expect(entry.status, ChildAppStatus.pending);
    expect(entry.status, isNot(ChildAppStatus.allowed));
    expect(entry.usedMins, 12);
    expect(entry.limitMins, 0);
  });

  test('an unknown category is tools and never games', () {
    expect(childAppCategoryFromWire('games'), ChildAppCategory.games);
    expect(childAppCategoryFromWire('social'), ChildAppCategory.social);
    expect(childAppCategoryFromWire('education'), ChildAppCategory.edu);
    expect(
      childAppCategoryFromWire('quran_reader'),
      ChildAppCategory.tools,
      reason: 'the server counts an unknown category; the screen must not widen it',
    );
    expect(childAppCategoryFromWire(''), ChildAppCategory.tools);
  });

  test('a failed read after a good one keeps the answer and says it is stale',
      () async {
    var failNext = false;
    final repository = _repositoryWith(<ChildAppEntry>[_entry('com.before')]);
    final sync = ChildAppsServerSync(
      repository: repository,
      read: (childId) async {
        if (failNext) throw StateError('server is down');
        return <ChildAppEntry>[_entry('com.after')];
      },
      write: (childId, app) async {},
    );

    await sync.sync(_child);
    expect(sync.status, ChildAppsSyncStatus.synced);
    expect(repository.appsFor(_child).single.id, 'com.after');

    failNext = true;
    await sync.sync(_child);

    expect(sync.status, ChildAppsSyncStatus.stale);
    expect(sync.isStale, isTrue);
    expect(
      repository.appsFor(_child).single.id,
      'com.after',
      reason: 'a failed read must not blank the list a guardian is looking at',
    );
  });

  test('a first read that fails claims nothing at all', () async {
    final repository = _repositoryWith(<ChildAppEntry>[_entry('com.local.only')]);
    final sync = ChildAppsServerSync(
      repository: repository,
      read: (childId) async => throw StateError('no session'),
      write: (childId, app) async {},
    );

    await sync.sync(_child);

    expect(
      sync.status,
      ChildAppsSyncStatus.neverSynced,
      reason: 'there is no earlier answer, so there is nothing to call stale',
    );
  });

  test('a refused decision is reported as not taken and never as done',
      () async {
    final repository = _repositoryWith(<ChildAppEntry>[
      _entry('com.game', status: ChildAppStatus.blocked, limitMins: 45),
    ]);

    final refused = ChildAppsServerSync(
      repository: repository,
      read: (childId) async => repository.appsFor(childId),
      write: (childId, app) async => throw StateError('refused'),
    );
    expect(await refused.push(_child, 'com.game'), isFalse);

    String? written;
    final accepted = ChildAppsServerSync(
      repository: repository,
      read: (childId) async => repository.appsFor(childId),
      write: (childId, app) async {
        written = '${app.id}:${app.status.name}:${app.limitMins}';
      },
    );
    expect(await accepted.push(_child, 'com.game'), isTrue);
    expect(written, 'com.game:blocked:45');

    expect(
      await accepted.push(_child, 'com.not.in.inventory'),
      isFalse,
      reason: 'an app this child does not have cannot be decided by accident',
    );
  });

  test('one decision is one key, so a retry is not a second rule', () {
    expect(
      appRuleStatusToWire(ChildAppStatus.blocked),
      FoundationGateAppRuleStatus.blocked,
    );
    expect(
      appRuleStatusToWire(ChildAppStatus.free),
      FoundationGateAppRuleStatus.free,
    );
  });
}
