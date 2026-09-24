import 'package:flutter/foundation.dart';

@immutable
final class HomeRouterFilterSnapshot {
  const HomeRouterFilterSnapshot({
    this.hasFamily = false,
    this.protected = false,
    this.deviceCount = 0,
    this.dnsActive = false,
    this.categoriesSynced = false,
    this.guideOpened = false,
  });

  final bool hasFamily;
  final bool protected;
  final int deviceCount;
  final bool dnsActive;
  final bool categoriesSynced;
  final bool guideOpened;

  bool get isEmpty => !hasFamily;

  HomeRouterFilterSnapshot copyWith({bool? guideOpened}) {
    return HomeRouterFilterSnapshot(
      hasFamily: hasFamily,
      protected: protected,
      deviceCount: deviceCount,
      dnsActive: dnsActive,
      categoriesSynced: categoriesSynced,
      guideOpened: guideOpened ?? this.guideOpened,
    );
  }
}
