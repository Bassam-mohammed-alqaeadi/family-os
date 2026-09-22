import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Widget keys for SCR-FAT-075 / UI-013 acceptance.
abstract final class ComingSoonKeys {
  static const screen = Key('coming_soon_screen');
  static const honestyBanner = Key('coming_soon_honesty_banner');
  static const featureList = Key('coming_soon_feature_list');
  static const notSettingsBanner = Key('coming_soon_not_settings_banner');
  static Key featureRow(String id) => Key('coming_soon_feature_$id');
}

/// Catalog entry for a Wave-3B feature that is not shipped as working settings.
class ComingSoonFeature {
  const ComingSoonFeature({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

/// SCR-FAT-075 — ميزات قادمة ✨ (UI-013 / Rule 23 / G-3).
///
/// Honest coming-soon catalog: no ship-date literals, no Switch / pretend
/// toggles, and copy that makes clear these are not working settings.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  /// Stable feature ids used by tests and widget keys.
  static const featureIds = <String>[
    'router_filter',
    'road_safety',
    'peer_compare',
    'chore_ai',
    'voice_advisor',
    'phased_project',
    'smart_recitation',
    'delegated_agent',
  ];

  static List<ComingSoonFeature> featuresFor(AppLocalizations l10n) => [
        ComingSoonFeature(
          id: 'router_filter',
          title: l10n.comingSoonFeatureRouterFilter,
          subtitle: l10n.comingSoonFeatureRouterFilterSub,
        ),
        ComingSoonFeature(
          id: 'road_safety',
          title: l10n.comingSoonFeatureRoadSafety,
          subtitle: l10n.comingSoonFeatureRoadSafetySub,
        ),
        ComingSoonFeature(
          id: 'peer_compare',
          title: l10n.comingSoonFeaturePeerCompare,
          subtitle: l10n.comingSoonFeaturePeerCompareSub,
        ),
        ComingSoonFeature(
          id: 'chore_ai',
          title: l10n.comingSoonFeatureChoreAi,
          subtitle: l10n.comingSoonFeatureChoreAiSub,
        ),
        ComingSoonFeature(
          id: 'voice_advisor',
          title: l10n.comingSoonFeatureVoiceAdvisor,
          subtitle: l10n.comingSoonFeatureVoiceAdvisorSub,
        ),
        ComingSoonFeature(
          id: 'phased_project',
          title: l10n.comingSoonFeaturePhasedProject,
          subtitle: l10n.comingSoonFeaturePhasedProjectSub,
        ),
        ComingSoonFeature(
          id: 'smart_recitation',
          title: l10n.comingSoonFeatureSmartRecitation,
          subtitle: l10n.comingSoonFeatureSmartRecitationSub,
        ),
        ComingSoonFeature(
          id: 'delegated_agent',
          title: l10n.comingSoonFeatureDelegatedAgent,
          subtitle: l10n.comingSoonFeatureDelegatedAgentSub,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final features = featuresFor(l10n);

    return Scaffold(
      key: ComingSoonKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.comingSoonTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BannerNote(
                key: ComingSoonKeys.honestyBanner,
                variant: BannerVariant.t,
                message: l10n.comingSoonHonestyBanner,
              ),
              const SizedBox(height: 14),
              Text(
                l10n.comingSoonSectionHeading,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.comingSoonSectionHint,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.ink2,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                key: ComingSoonKeys.featureList,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(radii.card),
                  border: Border.all(color: colors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < features.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, thickness: 1, color: colors.border),
                      _FeatureRow(
                        feature: features[i],
                        comingSoonLabel: l10n.comingSoonTag,
                        colors: colors,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              BannerNote(
                key: ComingSoonKeys.notSettingsBanner,
                variant: BannerVariant.a,
                message: l10n.comingSoonNotSettingsBanner,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.feature,
    required this.comingSoonLabel,
    required this.colors,
  });

  final ComingSoonFeature feature;
  final String comingSoonLabel;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${feature.title}. $comingSoonLabel. ${feature.subtitle}',
      child: Padding(
        key: ComingSoonKeys.featureRow(feature.id),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feature.subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.ink2,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Tag(label: comingSoonLabel, variant: TagVariant.a),
          ],
        ),
      ),
    );
  }
}
