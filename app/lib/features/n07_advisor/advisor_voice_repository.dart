import 'package:family_os/features/n07_advisor/advisor_voice_models.dart';

abstract class AdvisorVoiceRepository {
  Future<AdvisorVoiceSnapshot> load();
  Future<AdvisorVoiceSnapshot> pressTalk();
}

final class InMemoryAdvisorVoiceRepository implements AdvisorVoiceRepository {
  InMemoryAdvisorVoiceRepository({AdvisorVoiceSnapshot? seed})
    : _snap = seed ?? advisorVoicePrototypeFixture();

  AdvisorVoiceSnapshot _snap;
  Future<void> Function()? loadGate;
  var talkCount = 0;

  @override
  Future<AdvisorVoiceSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<AdvisorVoiceSnapshot> pressTalk() async {
    talkCount++;
    _snap = _snap.copyWith(listening: true);
    return _snap.copyWith();
  }

  void seed(AdvisorVoiceSnapshot snap) => _snap = snap;
}

final InMemoryAdvisorVoiceRepository stage1AdvisorVoiceRepository =
    InMemoryAdvisorVoiceRepository();

AdvisorVoiceSnapshot advisorVoiceEmptyFixture() => const AdvisorVoiceSnapshot();

AdvisorVoiceSnapshot advisorVoiceOneFixture() {
  return const AdvisorVoiceSnapshot(
    hasFamily: true,
    lastTurns: [
      AdvisorVoiceTurn(id: 't1', userKey: 'qHomework', replyKey: 'aHomework'),
    ],
  );
}

AdvisorVoiceSnapshot advisorVoicePrototypeFixture() {
  return const AdvisorVoiceSnapshot(
    hasFamily: true,
    lastTurns: [
      AdvisorVoiceTurn(id: 't1', userKey: 'qHomework', replyKey: 'aHomework'),
    ],
  );
}
