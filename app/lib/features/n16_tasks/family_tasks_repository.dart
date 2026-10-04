import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';
import 'package:family_os/features/n03_screen_time/stage1_child_scope.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';

/// Rule 25 seam — Stage-1 local family tasks authority (no backend).
///
/// Single store for FAT-054 approve + CHD-022 submitProof + FAT-082 ChoreAI
/// + FAT-055 create (CE-B1).
abstract class FamilyTasksRepository {
  Future<FamilyTasksSnapshot> load();

  /// Local approve — pending → completed (FAT-054).
  ///
  /// Deposits [FamilyChildTask.reward] via [WalletLedger.earn] / PolicyEngine
  /// when assignee is a child (Q-CEX-003 / Rule 5).
  Future<void> approveTask(String taskId);

  /// Child proof submit — assigned → pendingApproval (CHD-022).
  Future<void> submitProof(String taskId);

  /// Father-approved ChoreAI distribution → assigned tasks (FAT-082 · Rule 7).
  Future<void> applyChoreAssignments(List<FamilyChildTask> assignments);

  /// Father create task (FAT-055) → shared store.
  Future<void> addTask(FamilyChildTask task);
}

/// In-memory mock — empty-first (Rule 23). Tests/fixtures seed explicitly.
final class InMemoryFamilyTasksRepository implements FamilyTasksRepository {
  InMemoryFamilyTasksRepository({
    FamilyTasksSnapshot? seed,
    WalletLedger? walletLedger,
    ChildId Function(String assigneeNameKey)? resolveChildId,
  }) : _snap = seed ?? familyTasksEmptyFixture(),
       _walletLedger = walletLedger,
       _resolveChildId = resolveChildId;

  FamilyTasksSnapshot _snap;
  final WalletLedger? _walletLedger;
  final ChildId Function(String assigneeNameKey)? _resolveChildId;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<FamilyTasksSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return FamilyTasksSnapshot(
      childTasks: List<FamilyChildTask>.from(_snap.childTasks),
      motherHelpTasks: List<MotherHelpTask>.from(_snap.motherHelpTasks),
    );
  }

  @override
  Future<void> approveTask(String taskId) async {
    final tasks = List<FamilyChildTask>.from(_snap.childTasks);
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = tasks[idx];
    if (task.status == FamilyTaskStatus.completed) return;
    tasks[idx] = task.copyWith(status: FamilyTaskStatus.completed);
    _snap = FamilyTasksSnapshot(
      childTasks: tasks,
      motherHelpTasks: _snap.motherHelpTasks,
    );
    await _depositReward(task);
  }

  @override
  Future<void> submitProof(String taskId) async {
    final tasks = List<FamilyChildTask>.from(_snap.childTasks);
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final current = tasks[idx];
    if (current.status != FamilyTaskStatus.assigned) return;
    tasks[idx] = current.copyWith(
      status: FamilyTaskStatus.pendingApproval,
      proofKey: 'photoAttached',
    );
    _snap = FamilyTasksSnapshot(
      childTasks: tasks,
      motherHelpTasks: _snap.motherHelpTasks,
    );
  }

  @override
  Future<void> applyChoreAssignments(List<FamilyChildTask> assignments) async {
    final kept = _snap.childTasks
        .where((t) => !t.id.startsWith('chore-'))
        .toList();
    _snap = FamilyTasksSnapshot(
      childTasks: [...kept, ...assignments],
      motherHelpTasks: _snap.motherHelpTasks,
    );
  }

  @override
  Future<void> addTask(FamilyChildTask task) async {
    _snap = FamilyTasksSnapshot(
      childTasks: [..._snap.childTasks, task],
      motherHelpTasks: _snap.motherHelpTasks,
    );
  }

  Future<void> _depositReward(FamilyChildTask task) async {
    if (task.reward.isZero) return;
    if (task.assigneeNameKey == 'mother') return;
    try {
      final ledger =
          _walletLedger ??
          WalletLedger(await ScreenTimeLocalPersistence.openPolicyRepository());
      final childId =
          _resolveChildId?.call(task.assigneeNameKey) ?? activeScopedChildId();
      await ledger.earn(
        childId: childId,
        appId: 'family_tasks',
        assignee: AppRole.child,
        fatherSetReward: task.reward,
      );
    } catch (_) {
      // Soft-fail deposit — task status already completed locally.
    }
  }

  void seed(FamilyTasksSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton — empty until Local bind or test seed (CE-B1).
FamilyTasksRepository stage1FamilyTasksRepository =
    InMemoryFamilyTasksRepository(seed: familyTasksEmptyFixture());

void rebindStage1FamilyTasksRepository(FamilyTasksRepository repository) {
  stage1FamilyTasksRepository = repository;
}

/// Empty — Rule 23 empty-state coverage → SCR-FAT-003.
FamilyTasksSnapshot familyTasksEmptyFixture() {
  return const FamilyTasksSnapshot();
}

/// One pending task — Rule 23 one-item coverage.
FamilyTasksSnapshot familyTasksOneFixture() {
  return FamilyTasksSnapshot(
    childTasks: [
      FamilyChildTask(
        id: 't-pending',
        titleKey: 'tidyRoom',
        assigneeNameKey: 'childThree',
        avatarKey: 'panda',
        reward: Minutes(15),
        status: FamilyTaskStatus.pendingApproval,
        proofKey: 'photoAttached',
        timeKey: 'tenMinAgo',
      ),
    ],
  );
}

/// Prototype FAT-054 — three child tasks + one mother help request.
///
/// Rule 23: titleKey / assigneeNameKey / timeKey only (no planted person names).
/// LOCAL_DEMO / tests only — not production stage1 default.
FamilyTasksSnapshot familyTasksPrototypeFixture() {
  return FamilyTasksSnapshot(
    childTasks: [
      FamilyChildTask(
        id: 't1',
        titleKey: 'tidyRoom',
        assigneeNameKey: 'childThree',
        avatarKey: 'panda',
        reward: Minutes(15),
        status: FamilyTaskStatus.pendingApproval,
        proofKey: 'photoAttached',
        timeKey: 'tenMinAgo',
      ),
      FamilyChildTask(
        id: 't2',
        titleKey: 'washDishes',
        assigneeNameKey: 'childOne',
        avatarKey: 'lion',
        reward: Minutes(15),
        status: FamilyTaskStatus.assigned,
        timeKey: 'today',
      ),
      FamilyChildTask(
        id: 't3',
        titleKey: 'mathStudy',
        assigneeNameKey: 'childOne',
        avatarKey: 'lion',
        reward: Minutes(30),
        status: FamilyTaskStatus.completed,
        timeKey: 'yesterday',
      ),
    ],
    motherHelpTasks: const [
      MotherHelpTask(
        id: 'm1',
        titleKey: 'schoolReturnList',
        status: MotherHelpTaskStatus.open,
        timeKey: 'today',
      ),
    ],
  );
}
