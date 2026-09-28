import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/identity/adult_invite_repository.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/features/n02_day/child_call_play_repository.dart';
import 'package:family_os/features/n02_day/road_safety_repository.dart';
import 'package:family_os/features/n07_advisor/advisor_voice_repository.dart';
import 'package:family_os/features/n07_advisor/agent_action_log_repository.dart';
import 'package:family_os/features/n07_advisor/family_advisor_hub_repository.dart';
import 'package:family_os/features/n07_advisor/family_patterns_repository.dart';
import 'package:family_os/features/n07_advisor/individual_timeline_repository.dart';
import 'package:family_os/features/n07_advisor/knowledge_maps_repository.dart';
import 'package:family_os/features/n07_advisor/mother_ai_feed_repository.dart';
import 'package:family_os/features/n07_advisor/weekly_report_repository.dart';
import 'package:family_os/features/n08_platform/smart_alert_detail_repository.dart';
import 'package:family_os/features/n14_studio/generation_outputs_repository.dart';
import 'package:family_os/features/n14_studio/preview_approve_repository.dart';
import 'package:family_os/features/n17_child_learn/child_tutor_repository.dart';

void main() {
  test('LDR-B7 adult invite stage1 starts empty (no planted tokens)', () {
    stage1AdultInviteRepository.resetForTests();
    expect(stage1AdultInviteRepository.auditLog(), isEmpty);
  });

  test('LDR-B7 child device management stage1 is Runtime (local-owned)', () {
    expect(
      stage1ChildDeviceManagementRepository,
      isA<RuntimeChildDeviceManagementRepository>(),
    );
  });

  test('LDR-B7 advisor hub / insights stage1 defaults empty-honest', () async {
    expect(
      (await stage1FamilyAdvisorHubRepository.load()).suggestions,
      isEmpty,
    );
    expect((await stage1WeeklyReportRepository.load()).isEmpty, isTrue);
    expect((await stage1FamilyPatternsRepository.load()).isEmpty, isTrue);
    expect((await stage1IndividualTimelineRepository.load()).isEmpty, isTrue);
    expect((await stage1KnowledgeMapsRepository.load()).isEmpty, isTrue);
    expect((await stage1MotherAiFeedRepository.load()).isEmpty, isTrue);
    expect((await stage1AdvisorVoiceRepository.load()).isEmpty, isTrue);
    expect((await stage1AgentActionLogRepository.load()).isEmpty, isTrue);
    expect((await stage1SmartAlertDetailRepository.load()).isEmpty, isTrue);
  });

  test('LDR-B7 call-play / road-safety / AI studio defaults empty', () async {
    expect((await stage1ChildCallPlayRepository.load()).isEmpty, isTrue);
    expect((await stage1RoadSafetyRepository.load()).isEmpty, isTrue);
    expect(
      (await InMemoryPreviewApproveRepository().load()).isEmpty,
      isTrue,
    );
    expect(
      (await InMemoryGenerationOutputsRepository().load()).outputs,
      isEmpty,
    );
    expect((await InMemoryChildTutorRepository().load()).isEmpty, isTrue);
  });
}
