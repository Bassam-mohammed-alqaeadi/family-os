import 'package:family_os/features/n03_screen_time/child_usage_report_models.dart';

abstract class ChildUsageReportRepository {
  Future<ChildUsageReportSnapshot> load();
}

final class InMemoryChildUsageReportRepository
    implements ChildUsageReportRepository {
  InMemoryChildUsageReportRepository({ChildUsageReportSnapshot? seed})
    : _snap = seed ?? childUsageReportPrototypeFixture();

  ChildUsageReportSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildUsageReportSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return ChildUsageReportSnapshot(
      childNameKey: _snap.childNameKey,
      weekHours: _snap.weekHours,
      weekMinutes: _snap.weekMinutes,
      dayHeights: List<int>.from(_snap.dayHeights),
      categories: List<UsageCategoryRow>.from(_snap.categories),
      retentionDays: _snap.retentionDays,
    );
  }

  void seed(ChildUsageReportSnapshot snap) => _snap = snap;
}

final InMemoryChildUsageReportRepository stage1ChildUsageReportRepository =
    InMemoryChildUsageReportRepository();

ChildUsageReportSnapshot childUsageReportEmptyFixture() =>
    const ChildUsageReportSnapshot();

ChildUsageReportSnapshot childUsageReportOneFixture() {
  return const ChildUsageReportSnapshot(
    childNameKey: 'childOne',
    weekHours: 10,
    weekMinutes: 0,
    dayHeights: [40, 50, 45, 55, 40, 60, 50],
    categories: [
      UsageCategoryRow(
        id: 'learn',
        labelKey: 'learning',
        hours: 4,
        progress: 0.7,
        giftMinutes: true,
      ),
    ],
  );
}

ChildUsageReportSnapshot childUsageReportPrototypeFixture() {
  return const ChildUsageReportSnapshot(
    childNameKey: 'childOne',
    weekHours: 18,
    weekMinutes: 40,
    dayHeights: [35, 55, 40, 70, 45, 90, 60],
    categories: [
      UsageCategoryRow(
        id: 'learn',
        labelKey: 'learning',
        hours: 6,
        progress: 0.8,
        giftMinutes: true,
      ),
      UsageCategoryRow(id: 'games', labelKey: 'games', hours: 7, progress: 0.6),
      UsageCategoryRow(id: 'chat', labelKey: 'chat', hours: 3, progress: 0.3),
    ],
  );
}
