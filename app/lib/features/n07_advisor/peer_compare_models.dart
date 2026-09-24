import 'package:flutter/foundation.dart';

@immutable
final class PeerMetric {
  const PeerMetric({
    required this.id,
    required this.titleKey,
    required this.detailKey,
    this.positive = true,
  });
  final String id;
  final String titleKey;
  final String detailKey;
  final bool positive;
}

@immutable
final class PeerCompareSnapshot {
  const PeerCompareSnapshot({
    this.hasFamily = false,
    this.childLabelKey = 'childOne',
    this.ageYears = 11,
    this.metrics = const [],
  });

  final bool hasFamily;
  final String childLabelKey;
  final int ageYears;
  final List<PeerMetric> metrics;

  bool get isEmpty => !hasFamily;
}
