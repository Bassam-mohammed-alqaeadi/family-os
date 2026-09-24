import 'package:family_os/features/n07_advisor/family_advisor_hub_models.dart';

abstract class FamilyAdvisorHubRepository {
  Future<FamilyAdvisorHubSnapshot> load();
  Future<void> askFreeText(String text);
}

final class InMemoryFamilyAdvisorHubRepository
    implements FamilyAdvisorHubRepository {
  InMemoryFamilyAdvisorHubRepository({FamilyAdvisorHubSnapshot? seed})
    : _snap = seed ?? familyAdvisorHubPrototypeFixture();

  FamilyAdvisorHubSnapshot _snap;
  Future<void> Function()? loadGate;
  final List<String> asks = [];

  @override
  Future<FamilyAdvisorHubSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return FamilyAdvisorHubSnapshot(
      hasFamily: _snap.hasFamily,
      greetingKey: _snap.greetingKey,
      suggestions: List<AdvisorSuggestionChip>.from(_snap.suggestions),
      capabilities: List<AdvisorCapabilityRow>.from(_snap.capabilities),
      sovereigntyRows: List<AdvisorCapabilityRow>.from(_snap.sovereigntyRows),
      honestyShown: _snap.honestyShown,
    );
  }

  @override
  Future<void> askFreeText(String text) async {
    asks.add(text);
  }

  void seed(FamilyAdvisorHubSnapshot snap) => _snap = snap;
}

final InMemoryFamilyAdvisorHubRepository stage1FamilyAdvisorHubRepository =
    InMemoryFamilyAdvisorHubRepository();

FamilyAdvisorHubSnapshot familyAdvisorHubEmptyFixture() =>
    const FamilyAdvisorHubSnapshot();

FamilyAdvisorHubSnapshot familyAdvisorHubOneFixture() {
  return const FamilyAdvisorHubSnapshot(
    hasFamily: true,
    suggestions: [
      AdvisorSuggestionChip(
        id: 'weekly',
        labelKey: 'weeklyReport',
        navigateTo: 'SCR-FAT-073',
      ),
    ],
  );
}

FamilyAdvisorHubSnapshot familyAdvisorHubPrototypeFixture() {
  return const FamilyAdvisorHubSnapshot(
    hasFamily: true,
    suggestions: [
      AdvisorSuggestionChip(
        id: 'daySummary',
        labelKey: 'daySummary',
        sheetKey: 'daySummary',
      ),
      AdvisorSuggestionChip(
        id: 'weekly',
        labelKey: 'weeklyReport',
        navigateTo: 'SCR-FAT-073',
      ),
      AdvisorSuggestionChip(
        id: 'activity',
        labelKey: 'familyActivity',
        sheetKey: 'activity',
      ),
      AdvisorSuggestionChip(
        id: 'patterns',
        labelKey: 'patterns',
        navigateTo: 'SCR-FAT-062',
      ),
    ],
    capabilities: [
      AdvisorCapabilityRow(
        id: 'voice',
        titleKey: 'voice',
        subKey: 'voiceSub',
        navigateTo: 'SCR-FAT-083',
      ),
      AdvisorCapabilityRow(
        id: 'delegate',
        titleKey: 'delegate',
        subKey: 'delegateSub',
        navigateTo: 'SCR-FAT-079',
      ),
      AdvisorCapabilityRow(
        id: 'maps',
        titleKey: 'maps',
        subKey: 'mapsSub',
        navigateTo: 'SCR-FAT-064',
      ),
      AdvisorCapabilityRow(
        id: 'motherFeed',
        titleKey: 'motherFeed',
        subKey: 'motherFeedSub',
        navigateTo: 'SCR-FAT-076',
      ),
    ],
    sovereigntyRows: [
      AdvisorCapabilityRow(
        id: 'limits',
        titleKey: 'limits',
        subKey: 'limitsSub',
        navigateTo: 'SCR-FAT-029',
      ),
      AdvisorCapabilityRow(
        id: 'agentLog',
        titleKey: 'agentLog',
        subKey: 'agentLogSub',
        navigateTo: 'SCR-FAT-080',
      ),
    ],
  );
}
