import 'package:family_os/features/n08_platform/smart_alert_detail_models.dart';

abstract class SmartAlertDetailRepository {
  Future<SmartAlertDetailSnapshot> load();
}

final class InMemorySmartAlertDetailRepository
    implements SmartAlertDetailRepository {
  InMemorySmartAlertDetailRepository({SmartAlertDetailSnapshot? seed})
    : _snap = seed ?? smartAlertDetailPrototypeFixture();

  SmartAlertDetailSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<SmartAlertDetailSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return SmartAlertDetailSnapshot(
      alertId: _snap.alertId,
      titleKey: _snap.titleKey,
      changes: List<SmartAlertDetailChange>.from(_snap.changes),
      dialogueQuoteKey: _snap.dialogueQuoteKey,
      dialogueHintKey: _snap.dialogueHintKey,
    );
  }

  void seed(SmartAlertDetailSnapshot snap) => _snap = snap;
}

final InMemorySmartAlertDetailRepository stage1SmartAlertDetailRepository =
    InMemorySmartAlertDetailRepository();

SmartAlertDetailSnapshot smartAlertDetailEmptyFixture() =>
    const SmartAlertDetailSnapshot();

SmartAlertDetailSnapshot smartAlertDetailOneFixture() {
  return const SmartAlertDetailSnapshot(
    alertId: 'a1',
    titleKey: 'withdrawal',
    changes: [
      SmartAlertDetailChange(
        id: 'c1',
        titleKey: 'shorterReplies',
        subtitleKey: 'shorterRepliesSub',
      ),
    ],
  );
}

SmartAlertDetailSnapshot smartAlertDetailPrototypeFixture() {
  return const SmartAlertDetailSnapshot(
    alertId: 'a1',
    titleKey: 'withdrawal',
    changes: [
      SmartAlertDetailChange(
        id: 'c1',
        titleKey: 'shorterReplies',
        subtitleKey: 'shorterRepliesSub',
      ),
      SmartAlertDetailChange(
        id: 'c2',
        titleKey: 'lateNights',
        subtitleKey: 'lateNightsSub',
      ),
      SmartAlertDetailChange(
        id: 'c3',
        titleKey: 'sadWords',
        subtitleKey: 'sadWordsSub',
      ),
    ],
    dialogueQuoteKey: 'walkTalk',
    dialogueHintKey: 'careNotInterrogate',
  );
}
