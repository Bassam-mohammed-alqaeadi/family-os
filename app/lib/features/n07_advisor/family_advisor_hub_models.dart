import 'package:flutter/foundation.dart';

@immutable
final class AdvisorSuggestionChip {
  const AdvisorSuggestionChip({
    required this.id,
    required this.labelKey,
    this.navigateTo,
    this.sheetKey,
  });

  final String id;
  final String labelKey;
  final String? navigateTo;
  final String? sheetKey;
}

@immutable
final class AdvisorCapabilityRow {
  const AdvisorCapabilityRow({
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
final class FamilyAdvisorHubSnapshot {
  const FamilyAdvisorHubSnapshot({
    this.hasFamily = false,
    this.greetingKey = 'evening',
    this.suggestions = const [],
    this.capabilities = const [],
    this.sovereigntyRows = const [],
    this.honestyShown = true,
  });

  final bool hasFamily;
  final String greetingKey;
  final List<AdvisorSuggestionChip> suggestions;
  final List<AdvisorCapabilityRow> capabilities;
  final List<AdvisorCapabilityRow> sovereigntyRows;
  final bool honestyShown;

  bool get isEmpty => !hasFamily;
}
