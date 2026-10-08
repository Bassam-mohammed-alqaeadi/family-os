import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n16_tasks/tasks_server_authority.dart';
import 'package:family_os/features/n02_day/family_chat_server_authority.dart';
import 'package:family_os/foundation_gate/family_chat_api_client.dart';
import 'package:family_os/foundation_gate/family_tasks_api_client.dart';

/// W7 — the server's tasks and points, rendered for the guardian who is responsible for them.
///
/// Four cards, and every one of them says only what the server said:
///
///   * the balance, WITH the entries that produced it - because a number a family cannot
///     account for is the beginning of an argument, not a reward;
///   * the tasks, each with the cycle currently open on it: nothing said yet, the child's word
///     waiting for an answer, confirmed with the number it was confirmed as, or not confirmed
///     with the door still open;
///   * the guardian's answer, which is the moment points become real - and a note that a child
///     reads when the answer is a refusal;
///   * a place to state a new task, with its number of points stated once and by a person.
///
/// What this panel deliberately does not do: it does not draw points for a pending claim, it
/// does not offer to change a number after the fact, and it does not hide a refusal. Those
/// three are the ways a reward screen lies, and each one is refused here by construction
/// rather than by care.
class TasksServerPanel extends StatefulWidget {
  const TasksServerPanel({
    super.key,
    required this.childId,
    this.authority,
    this.canEdit = true,
    this.idempotencyKey,
  });

  final ChildId childId;

  /// Bound at boot in the real app; passed explicitly by tests.
  final TasksServerAuthority? authority;

  final bool canEdit;

  /// A key per write. In production it is derived from the action and the row so a retried
  /// tap is the same request; a screen that invented a new key per attempt would be asking
  /// the server to do the work twice.
  final String Function()? idempotencyKey;

  @override
  State<TasksServerPanel> createState() => _TasksServerPanelState();
}

class _TasksServerPanelState extends State<TasksServerPanel> {
  TasksAuthorityStatus? _status;
  List<FoundationGateTask> _tasks = const <FoundationGateTask>[];
  List<FamilyChatThread> _collaborationThreads = const <FamilyChatThread>[];
  String? _createAudienceThreadId;
  FoundationGateChildPoints? _points;
  bool _busy = false;

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _pointsCtrl = TextEditingController(text: '10');
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _decisionNoteCtrl = TextEditingController();

  TasksServerAuthority? get _authority =>
      widget.authority ?? activeTasksServerAuthority;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCollaborationThreads();
  }

  @override
  void didUpdateWidget(covariant TasksServerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The screen this panel lives in can stay open while the family switches child. Reading
    // again is the only honest reaction: the previous child's tasks must not remain on screen
    // under the new child's name, not even for the frame it takes to ask.
    if (oldWidget.childId != widget.childId ||
        oldWidget.authority != widget.authority) {
      _load();
      _loadCollaborationThreads();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pointsCtrl.dispose();
    _noteCtrl.dispose();
    _decisionNoteCtrl.dispose();
    super.dispose();
  }

  String _key(String scope) =>
      widget.idempotencyKey?.call() ??
      'w7-$scope-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _load() async {
    final authority = _authority;
    if (authority == null) {
      setState(() => _status = TasksAuthorityStatus.notConfigured);
      return;
    }
    setState(() => _busy = true);
    // Two reads, because they are two questions a family asks in either order: what is to be
    // done, and what has been earned. One failure does not erase the other.
    final tasks = await authority.listTasks(widget.childId.value);
    final points = await authority.readPoints(widget.childId.value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = tasks.isReady ? tasks.status : points.status;
      if (tasks.isReady) _tasks = tasks.value!;
      if (points.isReady) _points = points.value;
    });
  }

  Future<void> _loadCollaborationThreads() async {
    final chatAuthority = activeFamilyChatServerAuthority;
    if (chatAuthority == null) return;
    final answer = await chatAuthority.listGuardianThreads();
    if (!mounted || !answer.isReady) return;
    setState(() {
      _collaborationThreads = answer.value!.threads.where((thread) {
        final supportedKind = thread.kind == FamilyChatThreadKind.direct ||
            thread.kind == FamilyChatThreadKind.group;
        final childIsParticipant = thread.participants.any((participant) =>
            participant.kind == FamilyChatParticipantKind.child &&
            participant.id == widget.childId.value);
        return supportedKind && childIsParticipant;
      }).toList(growable: false);
      if (!_collaborationThreads.any((thread) => thread.id == _createAudienceThreadId)) {
        _createAudienceThreadId = null;
      }
    });
  }

  Future<void> _create() async {
    final authority = _authority;
    if (authority == null || !widget.canEdit) return;
    final title = _titleCtrl.text.trim();
    final points = int.tryParse(_pointsCtrl.text.trim());
    if (title.isEmpty || points == null) return;
    setState(() => _busy = true);
    final answer = await authority.createTask(
      widget.childId.value,
      title: title,
      note: _noteCtrl.text.trim(),
      points: points,
      audienceThreadId: _createAudienceThreadId,
      idempotencyKey: () => _key('create'),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
      if (answer.isReady) {
        _titleCtrl.clear();
        _createAudienceThreadId = null;
      }
    });
    if (answer.isReady) await _load();
  }

  Future<void> _claimOnBehalf(FoundationGateTask task) async {
    final authority = _authority;
    if (authority == null || !widget.canEdit) return;
    setState(() => _busy = true);
    final answer = await authority.claimTask(
      widget.childId.value,
      taskId: task.id,
      idempotencyKey: () => _key('claim-${task.id}'),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
    });
    if (answer.isReady) await _load();
  }

  Future<void> _decide(FoundationGateTask task, {required bool confirm}) async {
    final authority = _authority;
    if (authority == null || !widget.canEdit) return;
    setState(() => _busy = true);
    final answer = await authority.decideTask(
      widget.childId.value,
      taskId: task.id,
      confirm: confirm,
      note: _decisionNoteCtrl.text.trim(),
      idempotencyKey: () => _key('decide-${task.id}-${confirm ? 'yes' : 'no'}'),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
      if (answer.isReady) {
        // The decision's own answer carries the balance afterwards, so the screen does not
        // have to ask again - and cannot show a total that predates the confirmation.
        _points = answer.value!.points;
      }
    });
    if (answer.isReady) {
      _decisionNoteCtrl.clear();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final status = _status;
    if (status == null) {
      return const SizedBox.shrink();
    }
    final banner = _statusBanner(l10n, status);
    return Column(
      key: const Key('tasks_server_panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (banner != null) ...[banner, const SizedBox(height: 12)],
        if (_points != null) ...[
          _balanceCard(l10n, colors, _points!),
          const SizedBox(height: 12),
        ],
        if (_tasks.isNotEmpty) ...[
          _tasksCard(l10n, colors),
          const SizedBox(height: 12),
        ],
        // A form that writes is offered only when there is a server to write to. A build
        // with no session says so instead of collecting a task it cannot record.
        if (widget.canEdit && status == TasksAuthorityStatus.ready)
          _createCard(l10n, colors),
      ],
    );
  }

  Widget? _statusBanner(AppLocalizations l10n, TasksAuthorityStatus status) {
    // The same honest four as the waves before it. There is deliberately no "we will count
    // locally for now": a family reading a points total needs to know whether a person
    // confirmed it, not how hard the app is trying.
    final (String? message, BannerVariant variant) = switch (status) {
      TasksAuthorityStatus.ready => (null, BannerVariant.g),
      TasksAuthorityStatus.notConfigured => (
        l10n.tasksServerNoSession,
        BannerVariant.t,
      ),
      TasksAuthorityStatus.accessDenied => (
        l10n.tasksServerDenied,
        BannerVariant.a,
      ),
      // A refusal keeps the last true reading on screen and says that it is the last one: a
      // screen that emptied itself on a 409 would look like a child who earned nothing.
      TasksAuthorityStatus.refused => (
        l10n.tasksServerRefused,
        BannerVariant.a,
      ),
      TasksAuthorityStatus.unreachable => (
        l10n.tasksServerUnreachable,
        BannerVariant.a,
      ),
    };
    if (message == null) return null;
    return BannerNote(
      key: Key('tasks_server_${status.name}'),
      variant: variant,
      message: message,
    );
  }

  Widget _balanceCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateChildPoints points,
  ) {
    return Card(
      key: const Key('tasks_server_points_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tasksServerBalanceHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${points.points}',
              key: const Key('tasks_server_points_total'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colors.mintInk,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tasksServerBalanceNote,
              style: TextStyle(fontSize: 12, color: colors.ink2),
            ),
            const SizedBox(height: 6),
            if (points.entries.isEmpty)
              Text(
                l10n.tasksServerBalanceEmpty,
                key: const Key('tasks_server_points_empty'),
                style: TextStyle(fontSize: 12, color: colors.ink2),
              )
            else
              for (final entry in points.entries)
                Padding(
                  key: Key('tasks_server_points_entry_${entry.id}'),
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    l10n.tasksServerBalanceEntry(entry.points),
                    style: TextStyle(fontSize: 12, color: colors.ink),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _tasksCard(AppLocalizations l10n, FamilyColors colors) {
    return Card(
      key: const Key('tasks_server_tasks_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tasksServerTasksHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            for (final task in _tasks) _taskRow(l10n, colors, task),
          ],
        ),
      ),
    );
  }

  Widget _taskRow(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateTask task,
  ) {
    final claim = task.claim;
    // What the row says about the cycle, chosen by the SERVER's status and by nothing else.
    final state = switch (task.status) {
      FoundationGateTaskStatus.archived => l10n.tasksServerTaskArchived,
      FoundationGateTaskStatus.open => switch (claim?.status) {
        null => l10n.tasksServerTaskWaiting,
        FoundationGateTaskClaimStatus.pending => l10n.tasksServerTaskClaimed,
        FoundationGateTaskClaimStatus.confirmed => l10n.tasksServerTaskConfirmed(
          claim!.pointsAwarded ?? task.points,
        ),
        FoundationGateTaskClaimStatus.declined => l10n.tasksServerTaskDeclined,
      },
    };
    final open = task.status == FoundationGateTaskStatus.open;
    final editable = widget.canEdit && !_busy && open;
    return Padding(
      key: Key('tasks_server_task_${task.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          Text(
            l10n.tasksServerTaskPoints(task.points),
            style: TextStyle(fontSize: 12, color: colors.ink2),
          ),
          const SizedBox(height: 2),
          Text(
            state,
            key: Key('tasks_server_task_state_${task.id}'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: claim?.status == FoundationGateTaskClaimStatus.confirmed
                  ? colors.mintInk
                  : colors.ink2,
            ),
          ),
          if (claim?.note.isNotEmpty ?? false)
            Text(
              claim!.note,
              style: TextStyle(fontSize: 12, color: colors.ink2),
            ),
          if (claim?.decisionNote.isNotEmpty ?? false)
            Text(
              claim!.decisionNote,
              style: TextStyle(fontSize: 12, color: colors.coral),
            ),
          // A column of lines with the actions in a Wrap: the Arabic sentences on this
          // surface are long, and a Row holding them beside two buttons runs off a phone.
          if (editable) ...[
            const SizedBox(height: 4),
            if (claim == null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: Key('tasks_server_claim_${task.id}'),
                  onPressed: _busy ? null : () => _claimOnBehalf(task),
                  child: Text(l10n.tasksServerRecordClaim),
                ),
              )
            else if (claim.status == FoundationGateTaskClaimStatus.pending) ...[
              TextField(
                key: Key('tasks_server_note_${task.id}'),
                controller: _decisionNoteCtrl,
                decoration: InputDecoration(hintText: l10n.tasksServerNoteHint),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    key: Key('tasks_server_confirm_${task.id}'),
                    onPressed: _busy
                        ? null
                        : () => _decide(task, confirm: true),
                    child: Text(l10n.tasksServerConfirm),
                  ),
                  TextButton(
                    key: Key('tasks_server_decline_${task.id}'),
                    onPressed: _busy
                        ? null
                        : () => _decide(task, confirm: false),
                    child: Text(l10n.tasksServerDecline),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _createCard(AppLocalizations l10n, FamilyColors colors) {
    return Card(
      key: const Key('tasks_server_create_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tasksServerCreateHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('tasks_server_create_title'),
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: l10n.tasksServerCreateTitle,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('tasks_server_create_points'),
              controller: _pointsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.tasksServerCreatePoints,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('tasks_server_create_note'),
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: l10n.tasksServerCreateNote,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const Key('tasks_server_create_audience_thread'),
              initialValue: _createAudienceThreadId ?? '',
              decoration: InputDecoration(
                labelText: l10n.tasksServerAudienceScopeLabel,
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(l10n.tasksServerAudienceScopeChildOnly),
                ),
                for (final thread in _collaborationThreads)
                  DropdownMenuItem<String>(
                    value: thread.id,
                    child: Text(
                      thread.title.trim().isNotEmpty
                          ? thread.title
                          : thread.kind == FamilyChatThreadKind.direct
                              ? l10n.familyChatDirectThread
                              : l10n.familyChatGroupThread,
                    ),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _createAudienceThreadId = value == null || value.isEmpty
                          ? null
                          : value;
                    }),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const Key('tasks_server_create_button'),
                onPressed: _busy ? null : _create,
                child: Text(l10n.tasksServerCreateButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
