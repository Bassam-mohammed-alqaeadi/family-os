import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/policy/web_filter_evaluator.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';
import 'package:family_os/core/policy/web_filter_policy_repository.dart';
import 'package:family_os/core/policy/web_unlock_request.dart';
import 'package:family_os/core/policy/web_unlock_request_repository.dart';
import 'package:family_os/core/policy/web_unlock_service.dart';

void main() {
  late ChildId child;
  late InMemoryWebFilterPolicyRepository policyRepo;
  late InMemoryWebUnlockRequestRepository requestRepo;
  late AuditAppend audit;
  late WebUnlockDecisionBus bus;
  late WebUnlockService service;
  var idSeq = 0;

  WebFilterPolicy adultsBlockPolicy() => WebFilterPolicy(
        level: WebFilterLevel.open,
        categories: {
          for (final k in WebFilterCategories.known) k: false,
          WebFilterCategories.adults: true,
        },
        allowList: const {},
        policyVersion: 1,
      );

  setUp(() {
    child = ChildId('set006-child');
    policyRepo = InMemoryWebFilterPolicyRepository({
      child.value: adultsBlockPolicy(),
    });
    requestRepo = InMemoryWebUnlockRequestRepository();
    audit = AuditAppend();
    bus = WebUnlockDecisionBus();
    idSeq = 0;
    service = WebUnlockService(
      requestRepository: requestRepo,
      policyRepository: policyRepo,
      audit: audit,
      decisionBus: bus,
      idFactory: () {
        idSeq += 1;
        return 'req-$idSeq';
      },
      clock: () => DateTime.utc(2026, 9, 20, 12),
    );
  });

  test('request → partner approve → evaluator allows host', () async {
    final url = 'https://adult.example/page';
    final blocked = WebFilterEvaluator.decide(
      Uri.parse(url),
      await policyRepo.load(child),
    );
    expect(blocked.isDenied, isTrue);

    final created = await service.requestUnlock(child, url);
    expect(created.throttled, isFalse);
    expect(created.request.status, WebUnlockRequestStatus.pending);

    final approved = await service.approve(
      created.request.id,
      const WebUnlockActor.mother(MotherLevel.partner),
    );
    expect(approved.status, WebUnlockRequestStatus.approved);
    expect(approved.decidedBy, 'mother:partner');

    final policy = await policyRepo.load(child);
    expect(policy.allowList, contains('adult.example'));
    final allowed = WebFilterEvaluator.decide(Uri.parse(url), policy);
    expect(allowed.isDenied, isFalse);

    expect(bus.lastDecision?.id, approved.id);
    expect(
      audit.entries.any((e) => e.contains('approved') && e.contains('partner')),
      isTrue,
    );
  });

  test('request → father approve → evaluator allows host', () async {
    final url = 'https://adult.example/other';
    final created = await service.requestUnlock(child, url);
    await service.approve(created.request.id, const WebUnlockActor.father());

    final policy = await policyRepo.load(child);
    expect(
      WebFilterEvaluator.decide(Uri.parse(url), policy).isDenied,
      isFalse,
    );
  });

  test('mother observer cannot approve', () async {
    final created =
        await service.requestUnlock(child, 'https://adult.example/x');
    expect(
      () => service.approve(
        created.request.id,
        const WebUnlockActor.mother(MotherLevel.observer),
      ),
      throwsA(isA<WebUnlockNotAllowedException>()),
    );
    final policy = await policyRepo.load(child);
    expect(policy.allowList, isEmpty);
    expect(
      audit.entries.any((e) => e.contains('approve rejected')),
      isTrue,
    );
  });

  test('duplicate pending same host is throttled', () async {
    final a = await service.requestUnlock(child, 'https://Adult.Example/a');
    final b = await service.requestUnlock(child, 'https://adult.example/b');
    expect(a.throttled, isFalse);
    expect(b.throttled, isTrue);
    expect(b.request.id, a.request.id);
    final pending = await service.listPending(childId: child);
    expect(pending, hasLength(1));
  });

  test('father wins conflict after mother approve', () async {
    final created =
        await service.requestUnlock(child, 'https://adult.example/conflict');
    await service.approve(
      created.request.id,
      const WebUnlockActor.mother(MotherLevel.full),
    );
    var policy = await policyRepo.load(child);
    expect(policy.allowList, contains('adult.example'));

    final denied = await service.deny(
      created.request.id,
      const WebUnlockActor.father(),
      reason: 'not_appropriate',
    );
    expect(denied.status, WebUnlockRequestStatus.denied);
    expect(denied.decidedBy, 'father');

    policy = await policyRepo.load(child);
    expect(policy.allowList, isNot(contains('adult.example')));
    expect(
      WebFilterEvaluator.decide(
        Uri.parse('https://adult.example/conflict'),
        policy,
      ).isDenied,
      isTrue,
    );
    expect(
      audit.entries.any((e) => e.contains('father_wins')),
      isTrue,
    );

    // Mother cannot re-approve after father deny.
    expect(
      () => service.approve(
        created.request.id,
        const WebUnlockActor.mother(MotherLevel.partner),
      ),
      throwsA(isA<WebUnlockNotAllowedException>()),
    );
  });

  test('PrefsWebUnlockRequestRepository survives restart map', () async {
    final shared = <String, String>{};
    final store = MemoryWebUnlockPrefsStore(shared);
    final repo1 = PrefsWebUnlockRequestRepository(store);
    final svc1 = WebUnlockService(
      requestRepository: repo1,
      policyRepository: policyRepo,
      idFactory: () => 'prefs-1',
    );
    await svc1.requestUnlock(child, 'https://adult.example/prefs');

    final repo2 = PrefsWebUnlockRequestRepository(
      MemoryWebUnlockPrefsStore(shared),
    );
    final loaded = await repo2.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.first.host, 'adult.example');
    expect(loaded.first.status, WebUnlockRequestStatus.pending);
  });
}
