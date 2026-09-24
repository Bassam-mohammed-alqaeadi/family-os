import 'package:family_os/features/n04_web_filter/home_router_filter_models.dart';

abstract class HomeRouterFilterRepository {
  Future<HomeRouterFilterSnapshot> load();
  Future<HomeRouterFilterSnapshot> openGuide();
  Future<HomeRouterFilterSnapshot> runProtectionCheck();
}

final class InMemoryHomeRouterFilterRepository
    implements HomeRouterFilterRepository {
  InMemoryHomeRouterFilterRepository({HomeRouterFilterSnapshot? seed})
    : _snap = seed ?? homeRouterFilterPrototypeFixture();

  HomeRouterFilterSnapshot _snap;
  Future<void> Function()? loadGate;
  var checkCount = 0;

  @override
  Future<HomeRouterFilterSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<HomeRouterFilterSnapshot> openGuide() async {
    _snap = _snap.copyWith(guideOpened: true);
    return _snap.copyWith();
  }

  @override
  Future<HomeRouterFilterSnapshot> runProtectionCheck() async {
    checkCount++;
    return _snap.copyWith();
  }

  void seed(HomeRouterFilterSnapshot snap) => _snap = snap;
}

final InMemoryHomeRouterFilterRepository stage1HomeRouterFilterRepository =
    InMemoryHomeRouterFilterRepository();

HomeRouterFilterSnapshot homeRouterFilterEmptyFixture() =>
    const HomeRouterFilterSnapshot();

HomeRouterFilterSnapshot homeRouterFilterOneFixture() {
  return const HomeRouterFilterSnapshot(
    hasFamily: true,
    protected: true,
    deviceCount: 1,
    dnsActive: true,
    categoriesSynced: true,
  );
}

HomeRouterFilterSnapshot homeRouterFilterPrototypeFixture() {
  return const HomeRouterFilterSnapshot(
    hasFamily: true,
    protected: true,
    deviceCount: 12,
    dnsActive: true,
    categoriesSynced: true,
  );
}
