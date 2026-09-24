import 'package:family_os/features/n07_advisor/weekly_report_models.dart';

abstract class WeeklyReportRepository {
  Future<WeeklyReportSnapshot> load();
  Future<WeeklyReportSnapshot> toggleWhen();
  Future<WeeklyReportSnapshot> toggleStyle();
  Future<WeeklyReportSnapshot> toggleInclude(String section);
  Future<WeeklyReportSnapshot> applyRecommendation();
  Future<WeeklyReportSnapshot> deferRecommendation();
}

final class InMemoryWeeklyReportRepository implements WeeklyReportRepository {
  InMemoryWeeklyReportRepository({WeeklyReportSnapshot? seed})
    : _snap = seed ?? weeklyReportPrototypeFixture();

  WeeklyReportSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<WeeklyReportSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<WeeklyReportSnapshot> toggleWhen() async {
    final next = _snap.whenKey == 'fridayMorning'
        ? 'saturdayEvening'
        : 'fridayMorning';
    _snap = _snap.copyWith(whenKey: next);
    return _snap.copyWith();
  }

  @override
  Future<WeeklyReportSnapshot> toggleStyle() async {
    final next = _snap.styleKey == 'detailed' ? 'brief' : 'detailed';
    _snap = _snap.copyWith(styleKey: next);
    return _snap.copyWith();
  }

  @override
  Future<WeeklyReportSnapshot> toggleInclude(String section) async {
    final i = _snap.include;
    final next = switch (section) {
      'screen' => i.copyWith(screen: !i.screen),
      'places' => i.copyWith(places: !i.places),
      'wins' => i.copyWith(wins: !i.wins),
      'quran' => i.copyWith(quran: !i.quran),
      'watch' => i.copyWith(watch: !i.watch),
      _ => i,
    };
    _snap = _snap.copyWith(include: next);
    return _snap.copyWith();
  }

  @override
  Future<WeeklyReportSnapshot> applyRecommendation() async {
    _snap = _snap.copyWith(
      recommendationApplied: true,
      recommendationDeferred: false,
    );
    return _snap.copyWith();
  }

  @override
  Future<WeeklyReportSnapshot> deferRecommendation() async {
    _snap = _snap.copyWith(
      recommendationDeferred: true,
      recommendationApplied: false,
    );
    return _snap.copyWith();
  }

  void seed(WeeklyReportSnapshot snap) => _snap = snap;
}

final InMemoryWeeklyReportRepository stage1WeeklyReportRepository =
    InMemoryWeeklyReportRepository();

WeeklyReportSnapshot weeklyReportEmptyFixture() => const WeeklyReportSnapshot();

WeeklyReportSnapshot weeklyReportOneFixture() {
  return const WeeklyReportSnapshot(
    hasFamily: true,
    include: WeeklyReportInclude(
      screen: true,
      places: false,
      wins: false,
      quran: false,
      watch: false,
    ),
  );
}

WeeklyReportSnapshot weeklyReportPrototypeFixture() {
  return const WeeklyReportSnapshot(hasFamily: true);
}
