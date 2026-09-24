import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_repository.dart';
import 'package:family_os/features/n03_screen_time/stage1_child_scope.dart';

void main() {
  test(
    'default child scope uses canonical runtime active child',
    () async {
      final previous = stage1IdentityRuntime.activeChildId;
      addTearDown(() {
        stage1IdentityRuntime.setActiveChild(previous);
      });

      stage1IdentityRuntime.setActiveChild(ChildId('child_b'));

      final repo = InMemoryTimeRequestRepository();
      final service = TimeRequestService(repository: repo);
      addTearDown(service.dispose);

      final childRepo = ServiceChildTimeRequestRepository(
        service: service,
        repository: repo,
      );

      await childRepo.selectMinutes(30);
      await childRepo.submit();

      final all = await repo.loadAll();
      expect(all, hasLength(1));
      expect(
        all.first.childId,
        familyScopedChildId(
          familyId: stage1IdentityRuntime.activeFamilyId,
          childId: ChildId('child_b'),
        ),
      );
    },
  );
}
