import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';

void main() {
  final child = ChildId('demo-child');

  test('createRequest blocks duplicate pending per child', () async {
    final service = TimeRequestService(
      repository: InMemoryTimeRequestRepository(),
      clock: () => DateTime.utc(2026, 9, 23, 9, 0),
    );
    addTearDown(service.dispose);

    await service.createRequest(childId: child, requestedMinutes: 15);
    await expectLater(
      service.createRequest(childId: child, requestedMinutes: 30),
      throwsA(isA<TimeRequestNotAllowedException>()),
    );
  });

  test('approve creates active temporary grant (G-A), not wallet earn', () async {
    final repo = InMemoryTimeRequestRepository();
    final service = TimeRequestService(
      repository: repo,
      clock: () => DateTime.utc(2026, 9, 23, 9, 0),
    );
    addTearDown(service.dispose);

    final req = await service.createRequest(childId: child, requestedMinutes: 20);
    await service.approve(req.id, const TimeRequestActor.father(), grantMinutes: 15);

    final grants = await repo.loadGrants();
    expect(grants, hasLength(1));
    expect(grants.first.minutes, 15);
    expect(grants.first.activeRemaining, 15);
    expect(grants.first.status, TimeGrantStatus.active);
    expect(await service.activeGrantRemaining(child), 15);
  });

  test('mother ceiling still enforced for partner/full', () async {
    final repo = InMemoryTimeRequestRepository();
    final service = TimeRequestService(
      repository: repo,
      activeCeilingMinutes: 30,
      clock: () => DateTime.utc(2026, 9, 23, 9, 0),
    );
    addTearDown(service.dispose);

    final req = await service.createRequest(childId: child, requestedMinutes: 60);
    await expectLater(
      service.approve(
        req.id,
        const TimeRequestActor.mother(MotherLevel.full),
        grantMinutes: 45,
      ),
      throwsA(isA<TimeRequestNotAllowedException>()),
    );
  });

  test('pending requests expire at min(12h, end-of-day)', () async {
    final repo = InMemoryTimeRequestRepository();
    final service = TimeRequestService(
      repository: repo,
      clock: () => DateTime.utc(2026, 9, 23, 9, 0),
    );
    addTearDown(service.dispose);

    await service.createRequest(childId: child, requestedMinutes: 20);
    await service.expireStaleRequests();
    final pending = await service.listPending();
    expect(pending, hasLength(1));

    final lateService = TimeRequestService(
      repository: repo,
      clock: () => DateTime.utc(2026, 9, 23, 22, 0),
    );
    addTearDown(lateService.dispose);
    await lateService.expireStaleRequests();
    final all = await repo.loadAll();
    expect(all.first.status, TimeRequestStatus.expired);
  });
}
