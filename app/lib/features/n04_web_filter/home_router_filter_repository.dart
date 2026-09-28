import 'package:family_os/features/n04_web_filter/home_router_filter_models.dart';

abstract class HomeRouterFilterRepository {
  Future<HomeRouterFilterSnapshot> load();
  Future<HomeRouterFilterSnapshot> openGuide();
  Future<HomeRouterFilterSnapshot> runProtectionCheck();
}

final class InMemoryHomeRouterFilterRepository
    implements HomeRouterFilterRepository {
  InMemoryHomeRouterFilterRepository({HomeRouterFilterSnapshot? seed})
    : _snap = seed ?? homeRouterFilterEmptyFixture();

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
    // CE-B0 / CE-G004 — VPN/DNS Native CLOSED; do not fake a successful check.
    checkCount++;
    return _snap.copyWith();
  }

  void seed(HomeRouterFilterSnapshot snap) => _snap = snap;
}

final InMemoryHomeRouterFilterRepository stage1HomeRouterFilterRepository =
    InMemoryHomeRouterFilterRepository(
      // CE-B0 — honest Local baseline (no Synced / DNS-on / deviceCount=12).
      seed: homeRouterFilterOneFixture(),
    );

HomeRouterFilterSnapshot homeRouterFilterEmptyFixture() =>
    const HomeRouterFilterSnapshot();

/// Honest Local UI sample — no live DNS / Synced / device-count claims (CE-B0).
HomeRouterFilterSnapshot homeRouterFilterOneFixture() {
  return const HomeRouterFilterSnapshot(
    hasFamily: true,
    protected: false,
    deviceCount: 0,
    dnsActive: false,
    categoriesSynced: false,
  );
}

/// Former prototype numerals removed — same honest Local baseline as [homeRouterFilterOneFixture].
HomeRouterFilterSnapshot homeRouterFilterPrototypeFixture() =>
    homeRouterFilterOneFixture();
