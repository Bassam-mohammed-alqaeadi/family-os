import 'package:flutter/foundation.dart';

@immutable
final class ChildComingLink {
  const ChildComingLink({
    required this.id,
    required this.titleKey,
    required this.subKey,
    required this.navigateTo,
  });
  final String id;
  final String titleKey;
  final String subKey;
  final String navigateTo;
}

@immutable
final class ChildComingGiftsSnapshot {
  const ChildComingGiftsSnapshot({this.ready = false, this.links = const []});

  final bool ready;
  final List<ChildComingLink> links;

  bool get isEmpty => !ready;
}
