import 'package:family_os/features/n07_advisor/agent_action_log_models.dart';

abstract class AgentActionLogRepository {
  Future<AgentActionLogSnapshot> load();
  Future<AgentActionLogSnapshot> bless();
  Future<AgentActionLogSnapshot> gentleUndo();
}

final class InMemoryAgentActionLogRepository
    implements AgentActionLogRepository {
  InMemoryAgentActionLogRepository({AgentActionLogSnapshot? seed})
    : _snap = seed ?? agentActionLogPrototypeFixture();

  AgentActionLogSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<AgentActionLogSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<AgentActionLogSnapshot> bless() async {
    _snap = _snap.copyWith(state: AgentActionState.blessed);
    return _snap.copyWith();
  }

  @override
  Future<AgentActionLogSnapshot> gentleUndo() async {
    _snap = _snap.copyWith(state: AgentActionState.undone);
    return _snap.copyWith();
  }

  void seed(AgentActionLogSnapshot snap) => _snap = snap;
}

final InMemoryAgentActionLogRepository stage1AgentActionLogRepository =
    InMemoryAgentActionLogRepository();

AgentActionLogSnapshot agentActionLogEmptyFixture() =>
    const AgentActionLogSnapshot();

AgentActionLogSnapshot agentActionLogOneFixture() {
  return const AgentActionLogSnapshot(
    hasFamily: true,
    hasLiveAction: true,
    minutesGranted: 10,
    taskKeys: ['mathHw'],
  );
}

AgentActionLogSnapshot agentActionLogPrototypeFixture() {
  return const AgentActionLogSnapshot(
    hasFamily: true,
    hasLiveAction: true,
    minutesGranted: 15,
    weekly: [
      AgentWeeklyStat(
        id: 'w1',
        titleKey: 'sleepMode',
        metaKey: 'sleepMeta',
        ruleKey: 'rule3',
      ),
      AgentWeeklyStat(
        id: 'w2',
        titleKey: 'reviewRemind',
        metaKey: 'reviewMeta',
        ruleKey: 'rule2',
      ),
    ],
  );
}
