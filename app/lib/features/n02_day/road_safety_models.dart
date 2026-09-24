import 'package:flutter/foundation.dart';

@immutable
final class RoadSafetySnapshot {
  const RoadSafetySnapshot({
    this.hasFamily = false,
    this.crashDetection = true,
    this.phoneWhileDriving = true,
    this.topSpeedKmh = 95,
    this.hardBrakes = 2,
    this.phoneTouches = 0,
  });

  final bool hasFamily;
  final bool crashDetection;
  final bool phoneWhileDriving;
  final int topSpeedKmh;
  final int hardBrakes;
  final int phoneTouches;

  bool get isEmpty => !hasFamily;

  RoadSafetySnapshot copyWith({bool? crashDetection, bool? phoneWhileDriving}) {
    return RoadSafetySnapshot(
      hasFamily: hasFamily,
      crashDetection: crashDetection ?? this.crashDetection,
      phoneWhileDriving: phoneWhileDriving ?? this.phoneWhileDriving,
      topSpeedKmh: topSpeedKmh,
      hardBrakes: hardBrakes,
      phoneTouches: phoneTouches,
    );
  }
}
