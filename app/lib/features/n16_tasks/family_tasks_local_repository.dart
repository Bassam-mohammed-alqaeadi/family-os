import 'dart:convert';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';
import 'package:family_os/features/n03_screen_time/stage1_child_scope.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';

/// Durable Family Tasks store via `kv_store` (CE-B1 / CE-G012–015).
final class LocalFamilyTasksRepository implements FamilyTasksRepository {
  LocalFamilyTasksRepository(
    this._db, {
    this.namespace = kvNamespace,
    WalletLedger? walletLedger,
    ChildId Function(String assigneeNameKey)? resolveChildId,
    DateTime Function()? clock,
  }) : _walletLedger = walletLedger,
       _resolveChildId = resolveChildId,
       _clock = clock ?? DateTime.now;

  static const kvNamespace = 'family_tasks';
  static const _snapKey = 'snapshot';
  static const _table = 'kv_store';

  final FamilyLocalDatabase _db;
  final String namespace;
  final WalletLedger? _walletLedger;
  final ChildId Function(String assigneeNameKey)? _resolveChildId;
  final DateTime Function() _clock;

  Future<FamilyTasksSnapshot> _read() async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, _snapKey],
      limit: 1,
    );
    if (rows.isEmpty) return familyTasksEmptyFixture();
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return familyTasksEmptyFixture();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return familyTasksEmptyFixture();
    return FamilyTasksSnapshot.fromJson(
      decoded.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  Future<void> _write(FamilyTasksSnapshot snap) async {
    await _db.insert(_table, {
      'namespace': namespace,
      'key': _snapKey,
      'value': jsonEncode(snap.toJson()),
      'updated_at': _clock().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: LocalConflictAlgorithm.replace);
  }

  @override
  Future<FamilyTasksSnapshot> load() => _read();

  @override
  Future<void> approveTask(String taskId) async {
    final snap = await _read();
    final tasks = List<FamilyChildTask>.from(snap.childTasks);
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = tasks[idx];
    if (task.status == FamilyTaskStatus.completed) return;
    tasks[idx] = task.copyWith(status: FamilyTaskStatus.completed);
    await _write(
      FamilyTasksSnapshot(
        childTasks: tasks,
        motherHelpTasks: snap.motherHelpTasks,
      ),
    );
    await _depositReward(task);
  }

  @override
  Future<void> submitProof(String taskId) async {
    final snap = await _read();
    final tasks = List<FamilyChildTask>.from(snap.childTasks);
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final current = tasks[idx];
    if (current.status != FamilyTaskStatus.assigned) return;
    tasks[idx] = current.copyWith(
      status: FamilyTaskStatus.pendingApproval,
      proofKey: 'photoAttached',
    );
    await _write(
      FamilyTasksSnapshot(
        childTasks: tasks,
        motherHelpTasks: snap.motherHelpTasks,
      ),
    );
  }

  @override
  Future<void> applyChoreAssignments(List<FamilyChildTask> assignments) async {
    final snap = await _read();
    final kept = snap.childTasks
        .where((t) => !t.id.startsWith('chore-'))
        .toList();
    await _write(
      FamilyTasksSnapshot(
        childTasks: [...kept, ...assignments],
        motherHelpTasks: snap.motherHelpTasks,
      ),
    );
  }

  @override
  Future<void> addTask(FamilyChildTask task) async {
    final snap = await _read();
    await _write(
      FamilyTasksSnapshot(
        childTasks: [...snap.childTasks, task],
        motherHelpTasks: snap.motherHelpTasks,
      ),
    );
  }

  /// LDR-B3 — one open + one pending task when store empty (Minutes VO).
  Future<void> ensureRealLocalSeeded() async {
    final snap = await _read();
    if (!snap.isEmpty) return;
    await _write(
      FamilyTasksSnapshot(
        childTasks: [
          FamilyChildTask(
            id: 'task_tidy_real_local',
            titleKey: 'tidyRoom',
            assigneeNameKey: 'childOne',
            avatarKey: 'lion',
            reward: Minutes(15),
            status: FamilyTaskStatus.assigned,
            timeKey: 'today',
          ),
          FamilyChildTask(
            id: 'task_math_real_local',
            titleKey: 'mathStudy',
            assigneeNameKey: 'childTwo',
            avatarKey: 'cat',
            reward: Minutes(20),
            status: FamilyTaskStatus.pendingApproval,
            proofKey: 'photoAttached',
            timeKey: 'tenMinAgo',
          ),
        ],
      ),
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
      // Soft-fail deposit — task already completed in Local store.
    }
  }
}
