import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
import 'package:family_os/features/education/learning_result_repository.dart';
import 'package:family_os/features/n02_day/alert_detail_mock.dart';
import 'package:family_os/features/n02_day/alert_detail_repository.dart';
import 'package:family_os/features/n02_day/alerts_hub_mock.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n02_day/child_friends_repository.dart';
import 'package:family_os/features/n02_day/friend_approval_repository.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/features/n03_screen_time/child_apps_real_local_seed_mock.dart';
import 'package:family_os/features/n03_screen_time/child_apps_repository.dart';
import 'package:family_os/features/n03_screen_time/child_usage_report_repository.dart';
import 'package:family_os/features/n03_screen_time/stage1_child_scope.dart';
import 'package:family_os/features/n05_lock/tamper_alerts_repository.dart';
import 'package:family_os/features/n07_advisor/advisor_voice_repository.dart';
import 'package:family_os/features/n07_advisor/agent_action_log_repository.dart';
import 'package:family_os/features/n07_advisor/family_advisor_hub_repository.dart';
import 'package:family_os/features/n07_advisor/family_moments_repository.dart';
import 'package:family_os/features/n07_advisor/family_patterns_repository.dart';
import 'package:family_os/features/n07_advisor/individual_timeline_repository.dart';
import 'package:family_os/features/n07_advisor/knowledge_maps_repository.dart';
import 'package:family_os/features/n07_advisor/mother_ai_feed_repository.dart';
import 'package:family_os/features/n08_platform/smart_alerts_repository.dart';
import 'package:family_os/features/n14_studio/attribution_reward_repository.dart';
import 'package:family_os/features/n14_studio/community_library_repository.dart';
import 'package:family_os/features/n14_studio/create_assignment_repository.dart';
import 'package:family_os/features/n14_studio/focus_report_repository.dart';
import 'package:family_os/features/n14_studio/generation_outputs_repository.dart';
import 'package:family_os/features/n14_studio/learning_path_repository.dart';
import 'package:family_os/features/n14_studio/materials_lessons_repository.dart';
import 'package:family_os/features/n14_studio/preview_approve_repository.dart';
import 'package:family_os/features/n14_studio/quran_progress_repository.dart';
import 'package:family_os/features/n14_studio/results_followup_repository.dart';
import 'package:family_os/features/n14_studio/staged_project_repository.dart';
import 'package:family_os/features/n14_studio/studio_board_repository.dart';
import 'package:family_os/features/n15_calendar/add_event_repository.dart';
import 'package:family_os/features/n15_calendar/family_calendar_repository.dart';
import 'package:family_os/features/n16_tasks/child_tasks_repository.dart';
import 'package:family_os/features/n16_tasks/create_task_repository.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';
import 'package:family_os/features/n16_tasks/smart_chore_distributor_repository.dart';
import 'package:family_os/features/n17_child_learn/child_athkar_repository.dart';
import 'package:family_os/features/n17_child_learn/child_coming_gifts_repository.dart';
import 'package:family_os/features/n17_child_learn/child_daily_review_repository.dart';
import 'package:family_os/features/n17_child_learn/child_family_challenges_repository.dart';
import 'package:family_os/features/n17_child_learn/child_flashcards_repository.dart';
import 'package:family_os/features/n17_child_learn/child_focus_repository.dart';
import 'package:family_os/features/n17_child_learn/child_focus_sounds_repository.dart';
import 'package:family_os/features/n17_child_learn/child_interactive_stories_repository.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_repository.dart';
import 'package:family_os/features/n17_child_learn/child_lesson_repository.dart';
import 'package:family_os/features/n17_child_learn/child_memorization_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quiz_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_repository.dart';
import 'package:family_os/features/n17_child_learn/child_result_repository.dart';
import 'package:family_os/features/n17_child_learn/child_smart_plan_repository.dart';
import 'package:family_os/features/n17_child_learn/child_smart_tilawah_repository.dart';
import 'package:family_os/features/n17_child_learn/child_tutor_repository.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_repository.dart';
import 'package:family_os/features/quran/quran_ward_plan_repository.dart';

/// Debug compile flag. Release builds ignore it.
///
/// Default **true** in debug/profile so Stage-1 UX boots look populated.
/// Disable: `flutter run --dart-define=AUDIT_POPULATED=false`
/// Explicit on: `flutter run --dart-define=AUDIT_POPULATED=true`
const bool kAuditPopulated = bool.fromEnvironment(
  'AUDIT_POPULATED',
  defaultValue: true,
);

/// Set from [resolveAuditPopulated] before [runApp]. Shell reads this.
bool auditHostActive = false;

/// Identity id already used by Stage-1. Not a display name.
const String kAuditChildIdValue = 'demo-child';

/// Matches [AlertDetailMock] / [AlertsHubMock] so FAT-020 opens a row.
const String kAuditAlertId = 'a_stranger';

/// True only outside release, from the compile flag or `audit=populated`
/// on the platform initial route (`flutter_audit` intent).
///
/// Populates fixtures only — does **not** hide the father/child bottom tabs.
/// For chrome-free screen tour use [resolveAuditVisionHost].
bool resolveAuditPopulated({String? platformRoute}) {
  if (kReleaseMode) return false;
  if (kAuditPopulated) return true;
  final route =
      platformRoute ??
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  return route.contains('audit=populated');
}

/// Chrome-free QA host (no bottom [TabsBar]). Opt-in only.
///
/// `flutter run` route / intent containing `audit=vision` or open `/dev-screens`.
bool resolveAuditVisionHost({String? platformRoute}) {
  if (kReleaseMode) return false;
  final route =
      platformRoute ??
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  if (route.startsWith('/dev-screens') || route.contains('/dev-screens?')) {
    return true;
  }
  return route.contains('audit=vision');
}

/// Gallery cold-open role. Child screens must not stay on the father default.
AppRole galleryRoleForScreen(String screenId) {
  if (screenId.startsWith('SCR-CHD-')) return AppRole.child;
  if (screenId == 'SCR-FAT-076') return AppRole.mother;
  return AppRole.father;
}

/// Path plus active child. Alert detail also gets [kAuditAlertId].
String galleryLocationForScreen(String screenId) {
  final params = <String, String>{'childId': kAuditChildIdValue};
  if (screenId == 'SCR-FAT-020') {
    params['alertId'] = kAuditAlertId;
  }
  final query = params.entries
      .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
  return '${screenPath(screenId)}?$query';
}

/// Seeds Stage-1 in-memory singletons with their existing one-item fixtures.
///
/// Local KV repositories are left alone (they already ran `ensureRealLocalSeeded`).
/// Returns how many in-memory singletons received a fixture.
Future<int> applyAuditPopulation({required bool enabled}) async {
  if (!enabled || kReleaseMode) return 0;
  var n = 0;
  n += _seed<InMemoryFamilyTasksRepository>(
    stage1FamilyTasksRepository,
    (r) => r.seed(familyTasksOneFixture()),
  );
  n += _seed<InMemoryChildTasksRepository>(
    stage1ChildTasksRepository,
    (r) => r.seed(childTasksOneFixture()),
  );
  n += _seed<InMemoryCreateTaskRepository>(
    stage1CreateTaskRepository,
    (r) => r.seed(createTaskOneFixture()),
  );
  n += _seed<InMemorySmartChoreDistributorRepository>(
    stage1SmartChoreDistributorRepository,
    (r) => r.seed(smartChoreDistributorOneFixture()),
  );
  n += _seed<InMemoryFamilyCalendarRepository>(
    stage1FamilyCalendarRepository,
    (r) => r.seed(familyCalendarOneFixture()),
  );
  n += _seed<InMemoryAddEventRepository>(
    stage1AddEventRepository,
    (r) => r.seed(addEventOneFixture()),
  );
  n += _seed<InMemoryOuterCircleRepository>(
    stage1OuterCircleRepository,
    (r) => r.seed(outerCircleOneFixture()),
  );
  n += _seed<InMemoryChildFriendsRepository>(
    stage1ChildFriendsRepository,
    (r) => r.seed(childFriendsOneFixture()),
  );
  n += _seed<InMemoryFriendApprovalRepository>(
    stage1FriendApprovalRepository,
    (r) => r.seed(friendApprovalOneFixture()),
  );
  n += _seed<InMemoryStudioBoardRepository>(
    stage1StudioBoardRepository,
    (r) => r.seed(studioBoardOneFixture()),
  );
  n += _seed<InMemoryGenerationOutputsRepository>(
    stage1GenerationOutputsRepository,
    (r) => r.seed(generationOutputsPrototypeFixture()),
  );
  n += _seed<InMemoryPreviewApproveRepository>(
    stage1PreviewApproveRepository,
    (r) => r.seed(previewApprovePrototypeFixture()),
  );
  n += _seed<InMemoryAttributionRewardRepository>(
    stage1AttributionRewardRepository,
    (r) => r.seed(attributionRewardPrototypeFixture()),
  );
  n += _seed<InMemoryCommunityLibraryRepository>(
    stage1CommunityLibraryRepository,
    (r) => r.seed(communityLibraryOneFixture()),
  );
  n += _seed<InMemoryLearningPathRepository>(
    stage1LearningPathRepository,
    (r) => r.seed(learningPathOneFixture()),
  );
  n += _seed<InMemoryMaterialsLessonsRepository>(
    stage1MaterialsLessonsRepository,
    (r) => r.seed(materialsLessonsOneFixture()),
  );
  n += _seed<InMemoryCreateAssignmentRepository>(
    stage1CreateAssignmentRepository,
    (r) => r.seed(createAssignmentOneFixture()),
  );
  n += _seed<InMemoryLearningAssignmentRepository>(
    stage1LearningAssignmentRepository,
    (r) => r.seed([learningAssignmentFixture(childKey: kAuditChildIdValue)]),
  );
  n += _seed<InMemoryLearningResultRepository>(
    stage1LearningResultRepository,
    (r) => r.seed([learningResultFixture(childKey: kAuditChildIdValue)]),
  );
  n += _seed<InMemoryResultsFollowupRepository>(
    stage1ResultsFollowupRepository,
    (r) => r.seed(resultsFollowupOneFixture()),
  );
  n += _seed<InMemoryFocusReportRepository>(
    stage1FocusReportRepository,
    (r) => r.seed(focusReportOneFixture()),
  );
  // FAT-013 KIDTOOLS destinations that were empty by default.
  n += _seedProfileKidToolFixtures();
  n += _seed<InMemoryStagedProjectRepository>(
    stage1StagedProjectRepository,
    (r) => r.seed(stagedProjectOneFixture()),
  );
  n += _seed<InMemoryChildLearnHomeRepository>(
    stage1ChildLearnHomeRepository,
    (r) => r.seed(childLearnHomeOneFixture()),
  );
  n += _seed<InMemoryChildLessonRepository>(
    stage1ChildLessonRepository,
    (r) => r.seed(childLessonOneFixture()),
  );
  n += _seed<InMemoryChildFlashcardsRepository>(
    stage1ChildFlashcardsRepository,
    (r) => r.seed(childFlashcardsOneFixture()),
  );
  n += _seed<InMemoryChildQuizRepository>(
    stage1ChildQuizRepository,
    (r) => r.seed(childQuizOneFixture()),
  );
  n += _seed<InMemoryChildResultRepository>(
    stage1ChildResultRepository,
    (r) => r.seed(childResultOneFixture()),
  );
  n += _seed<InMemoryChildTutorRepository>(
    stage1ChildTutorRepository,
    (r) => r.seed(childTutorOneFixture()),
  );
  n += _seed<InMemoryChildFocusRepository>(
    stage1ChildFocusRepository,
    (r) => r.seed(childFocusOneFixture()),
  );
  n += _seed<InMemoryChildFocusSoundsRepository>(
    stage1ChildFocusSoundsRepository,
    (r) => r.seed(childFocusSoundsOneFixture()),
  );
  n += _seed<InMemoryQuranProgressRepository>(
    stage1QuranProgressRepository,
    (r) => r.seed(quranProgressOneFixture()),
  );
  stage1QuranWardPlanRepository.seed([
    quranWardPlanFixture(childKey: kAuditChildIdValue),
  ]);
  n += 1;
  n += _seed<InMemoryChildQuranWardRepository>(
    stage1ChildQuranWardRepository,
    (r) => r.seed(childQuranWardOneFixture()),
  );
  n += _seed<InMemoryChildMemorizationRepository>(
    stage1ChildMemorizationRepository,
    (r) => r.seed(childMemorizationOneFixture()),
  );
  n += _seed<InMemoryChildAthkarRepository>(
    stage1ChildAthkarRepository,
    (r) => r.seed(childAthkarOneFixture()),
  );
  n += _seed<InMemoryChildSmartTilawahRepository>(
    stage1ChildSmartTilawahRepository,
    (r) => r.seed(childSmartTilawahOneFixture()),
  );
  n += _seed<InMemoryChildSmartPlanRepository>(
    stage1ChildSmartPlanRepository,
    (r) => r.seed(childSmartPlanOneFixture()),
  );
  n += _seed<InMemoryChildDailyReviewRepository>(
    stage1ChildDailyReviewRepository,
    (r) => r.seed(childDailyReviewOneFixture()),
  );
  n += _seed<InMemoryChildInteractiveStoriesRepository>(
    stage1ChildInteractiveStoriesRepository,
    (r) => r.seed(childInteractiveStoriesOneFixture()),
  );
  n += _seed<InMemoryChildFamilyChallengesRepository>(
    stage1ChildFamilyChallengesRepository,
    (r) => r.seed(childFamilyChallengesOneFixture()),
  );
  n += _seed<InMemoryChildComingGiftsRepository>(
    stage1ChildComingGiftsRepository,
    (r) => r.seed(childComingGiftsOneFixture()),
  );
  n += _seed<InMemoryAlertsHubRepository>(
    stage1AlertsHubRepository,
    (r) => r.seed(AlertsHubMock.seeded),
  );
  n += _seed<InMemoryAlertDetailRepository>(
    stage1AlertDetailRepository,
    (r) => r.seed(AlertDetailMock.seeded),
  );
  n += _seed<InMemoryFamilyPatternsRepository>(
    stage1FamilyPatternsRepository,
    (r) => r.seed(familyPatternsOneFixture()),
  );
  n += _seed<InMemoryIndividualTimelineRepository>(
    stage1IndividualTimelineRepository,
    (r) => r.seed(individualTimelineOneFixture()),
  );
  n += _seed<InMemoryKnowledgeMapsRepository>(
    stage1KnowledgeMapsRepository,
    (r) => r.seed(knowledgeMapsOneFixture()),
  );
  n += _seed<InMemoryFamilyMomentsRepository>(
    stage1FamilyMomentsRepository,
    (r) => r.seed(familyMomentsOneFixture()),
  );
  n += _seed<InMemoryFamilyAdvisorHubRepository>(
    stage1FamilyAdvisorHubRepository,
    (r) => r.seed(familyAdvisorHubOneFixture()),
  );
  n += _seed<InMemoryAdvisorVoiceRepository>(
    stage1AdvisorVoiceRepository,
    (r) => r.seed(advisorVoiceOneFixture()),
  );
  n += _seed<InMemoryAgentActionLogRepository>(
    stage1AgentActionLogRepository,
    (r) => r.seed(agentActionLogOneFixture()),
  );
  n += _seed<InMemoryMotherAiFeedRepository>(
    stage1MotherAiFeedRepository,
    (r) => r.seed(motherAiFeedOneFixture()),
  );
  n += _seed<InMemoryChildWalletRepository>(
    stage1ChildWalletRepository,
    (r) => r.seed(childWalletOneFixture()),
  );
  if (stage1ChildWalletRepository is PolicyChildWalletRepository) {
    await _depositAuditWalletMinutes();
  }
  return n;
}

int _seed<T>(Object repo, void Function(T repo) apply) {
  if (repo is T) {
    apply(repo as T);
    return 1;
  }
  return 0;
}

/// Populate FAT-013 tool targets: apps · tamper · smart alerts · usage.
/// Focus (051) + Quran (072) are seeded above/elsewhere in this file.
int _seedProfileKidToolFixtures() {
  var n = 0;
  final kids = [
    ChildId(kAuditChildIdValue),
    ChildId('child_b'),
    ChildId('child_c'),
  ];

  // Apps — fill only when LDR bind left a child empty.
  for (final id in kids) {
    if (stage1ChildAppsRepository.appsFor(id).isEmpty) {
      stage1ChildAppsRepository.seed(
        id,
        ChildAppsRealLocalSeedMock.managedCatalog,
      );
      n++;
    }
  }

  n += _seed<InMemoryTamperAlertsRepository>(stage1TamperAlertsRepository, (r) {
    for (final id in kids) {
      r.seed(id, tamperAlertsManyFixture(childId: id));
    }
  });

  n += _seed<InMemorySmartAlertsRepository>(
    stage1SmartAlertsRepository,
    (r) => r.seed(smartAlertsPrototypeFixture()),
  );

  n += _seed<InMemoryChildUsageReportRepository>(
    stage1ChildUsageReportRepository,
    (r) => r.seed(childUsageReportOneFixture()),
  );

  return n;
}

/// Father-set reward deposited for the active child. No raw balance write.
Future<void> _depositAuditWalletMinutes() async {
  try {
    final policyRepo = await ScreenTimeLocalPersistence.openPolicyRepository();
    final childId = activeScopedChildId();
    final policy = await policyRepo.load(childId);
    final appId = policy.wallets.isEmpty
        ? 'youtube'
        : policy.wallets.first.appId;
    await WalletLedger(policyRepo).earn(
      childId: childId,
      appId: appId,
      assignee: AppRole.child,
      fatherSetReward: Minutes(15),
    );
  } catch (e, st) {
    debugPrint('audit wallet earn skipped: $e\n$st');
  }
}

/// Strip a query before GoRouter path checks. Audit flag is read separately.
String auditRoutePath(String platformRoute) {
  final q = platformRoute.indexOf('?');
  if (q < 0) return platformRoute;
  return platformRoute.substring(0, q);
}
