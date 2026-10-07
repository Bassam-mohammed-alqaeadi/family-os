import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// W7 — the guardian's tasks and points, or the honest statement that there was no answer.
///
/// The statuses are the five this codebase settled on in waves 4, 5 and 6, and they mean the
/// same thing here: nothing is invented to fill a gap, and there is no `localFallback`. The
/// reason is sharper in this wave than in the ones before it: a point total is a promise to a
/// child, and a screen that drew a balance it made up would be teaching a household that this
/// app says things that are not so.
enum TasksAuthorityStatus {
  /// The answer came from the server and means what it says.
  ready,

  /// This build has no server session. Nothing was asked, because there is nobody to ask.
  notConfigured,

  /// The server refused: this account may not read or change this child's tasks.
  accessDenied,

  /// The server is configured but did not answer. Nothing on the screen may move.
  unreachable,

  /// The server answered with a refusal that has a reason - a claim already waiting, a claim
  /// already answered, a task that was withdrawn - which the screen shows as it is.
  refused,
}

/// One answer from the server, or the honest statement that there was none.
class TasksAuthorityAnswer<T> {
  const TasksAuthorityAnswer._({required this.status, required this.value});

  const TasksAuthorityAnswer.ready(T value)
    : this._(status: TasksAuthorityStatus.ready, value: value);

  const TasksAuthorityAnswer.unavailable(TasksAuthorityStatus status)
    : this._(status: status, value: null);

  final TasksAuthorityStatus status;
  final T? value;

  bool get isReady => status == TasksAuthorityStatus.ready && value != null;
}

/// The tasks surface's one connection to the server.
///
/// Six operations, and every one of them is a question a family actually asks: what has this
/// child to do, what did they say they did, what did a guardian answer, and what have they
/// earned. What is NOT here is a method that awards points - no such method could exist,
/// because the server awards them and this class only reads the consequence.
final class TasksServerAuthority {
  TasksServerAuthority({
    required this.api,
    required this.idToken,
    required this.familyId,
  });

  final FamilyTasksApiClient api;
  final Future<String> Function() idToken;
  final String? Function() familyId;

  Future<TasksAuthorityAnswer<List<FoundationGateTask>>> listTasks(
    String childId,
  ) => _ask(
    (family, token) => api.listTasks(
      familyId: family,
      childId: childId,
      idToken: token,
    ),
  );

  Future<TasksAuthorityAnswer<FoundationGateTask>> createTask(
    String childId, {
    required String title,
    required int points,
    String note = '',
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.createTask(
      familyId: family,
      childId: childId,
      title: title,
      note: note,
      points: points,
      idempotencyKey: idempotencyKey(),
      idToken: token,
    ),
  );

  /// A guardian records the child's word. The caller cannot ask this method to award points:
  /// the return type carries a claim, and a claim has no number on it.
  Future<TasksAuthorityAnswer<FoundationGateTaskClaim>> claimTask(
    String childId, {
    required String taskId,
    String note = '',
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.claimTask(
      familyId: family,
      childId: childId,
      taskId: taskId,
      note: note,
      idempotencyKey: idempotencyKey(),
      idToken: token,
    ),
  );

  /// The guardian's word. `confirm: true` makes the points real; `false` awards nothing.
  Future<TasksAuthorityAnswer<FoundationGateTaskDecision>> decideTask(
    String childId, {
    required String taskId,
    required bool confirm,
    String note = '',
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.decideTask(
      familyId: family,
      childId: childId,
      taskId: taskId,
      confirm: confirm,
      note: note,
      idempotencyKey: idempotencyKey(),
      idToken: token,
    ),
  );

  /// The balance, with the entries that produced it.
  Future<TasksAuthorityAnswer<FoundationGateChildPoints>> readPoints(
    String childId,
  ) => _ask(
    (family, token) => api.readPoints(
      familyId: family,
      childId: childId,
      idToken: token,
    ),
  );

  Future<TasksAuthorityAnswer<T>> _ask<T>(
    Future<T> Function(String family, String token) run,
  ) async {
    final family = familyId();
    if (family == null || family.trim().isEmpty) {
      // Nothing is asked, because there is nobody to ask: a screen bound without a session
      // is a screen that says so.
      return const TasksAuthorityAnswer.unavailable(
        TasksAuthorityStatus.notConfigured,
      );
    }
    String token;
    try {
      token = await idToken();
    } on Object {
      return const TasksAuthorityAnswer.unavailable(
        TasksAuthorityStatus.notConfigured,
      );
    }
    if (token.trim().isEmpty) {
      return const TasksAuthorityAnswer.unavailable(
        TasksAuthorityStatus.notConfigured,
      );
    }
    try {
      return TasksAuthorityAnswer.ready(await run(family, token));
    } on FoundationGateApiException catch (exception) {
      return TasksAuthorityAnswer.unavailable(
        switch (exception.failure) {
          FoundationGateApiFailure.unauthenticated ||
          FoundationGateApiFailure.accessDenied =>
            TasksAuthorityStatus.accessDenied,
          FoundationGateApiFailure.networkUnavailable =>
            TasksAuthorityStatus.unreachable,
          _ => TasksAuthorityStatus.refused,
        },
      );
    } on Object {
      return const TasksAuthorityAnswer.unavailable(
        TasksAuthorityStatus.unreachable,
      );
    }
  }
}

TasksServerAuthority? _activeTasksAuthority;

/// The authority the tasks screens read, or null when no server session is bound.
TasksServerAuthority? get activeTasksServerAuthority => _activeTasksAuthority;

/// Binds every tasks surface to one server session, or clears them all.
///
/// One call site, at boot: the tasks a guardian reads, the claim they record on a child's
/// behalf, the answer they give and the balance that follows all move together - a build that
/// rewarded through one path while reading the balance through another would be two products
/// wearing one screen.
void bindTasksServerAuthority(TasksServerAuthority? authority) {
  _activeTasksAuthority = authority;
}
