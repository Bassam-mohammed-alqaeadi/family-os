import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';

/// Widget keys for SCR-FAT-013 acceptance.
abstract final class ChildProfileKeys {
  static const screen = Key('child_profile_screen');
  static const loading = Key('child_profile_loading');
  static const missingId = Key('child_profile_missing_id');
  static const notFound = Key('child_profile_not_found');
  static const error = Key('child_profile_error');
  static const body = Key('child_profile_body');
  static const identityCard = Key('child_profile_identity');
  static const toolsGrid = Key('child_profile_tools');
  static const childLean = Key('child_profile_child_lean');

  static Key tool(String id) => Key('child_profile_tool_$id');
}

/// One per-child settings shortcut (real route — not a fake toggle).
@immutable
final class ChildProfileTool {
  const ChildProfileTool({
    required this.id,
    required this.emoji,
    required this.label,
    required this.routePath,
  });

  final String id;
  final String emoji;
  final String label;
  final String routePath;
}

/// SCR-FAT-013 — ملف الابن (parent child-profile hub).
///
/// Parametric [childId] (G-5 / G8). Mock-first Rule 23/25: empty/missing id →
/// honest empty; unknown id → not-found. Tool tiles navigate to existing
/// per-child settings routes (screen time, web filter, lock, …). No Firebase.
class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({
    super.key,
    this.childId,
    this.repository,
    this.roleOverride,
    this.onNavigateTool,
    this.onOpenLocation,
    this.onOpenDeviceHealth,
  });

  /// From route `?childId=`; null/empty → missing-id empty state.
  final String? childId;

  /// Null → [stage1ChildProfileRepository].
  final ChildProfileRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Test seam — when null, [context.push] to tool [ChildProfileTool.routePath].
  final void Function(ChildProfileTool tool)? onNavigateTool;

  /// Test seam — location card → `/scr-fat-014`.
  final VoidCallback? onOpenLocation;

  /// Test seam — connection health → `/scr-fat-026`.
  final VoidCallback? onOpenDeviceHealth;

  @override
  ChildProfileScreenState createState() => ChildProfileScreenState();
}

class ChildProfileScreenState extends State<ChildProfileScreen> {
  late final ChildProfileRepository _repo;
  var _loading = true;
  var _loadFailed = false;
  ChildProfile? _profile;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  String? get _resolvedChildId {
    final raw = widget.childId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildProfileRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant ChildProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  Future<void> _load() async {
    final id = _resolvedChildId;
    if (id == null) {
      setState(() {
        _loading = false;
        _loadFailed = false;
        _profile = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final profile = await _repo.loadById(id);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  List<ChildProfileTool> _tools(AppLocalizations l10n) {
    return [
      ChildProfileTool(
        id: 'screen_time',
        emoji: '⏱',
        label: l10n.childProfileToolScreenTime,
        routePath: '/scr-fat-032',
      ),
      ChildProfileTool(
        id: 'time_requests',
        emoji: '⏳',
        label: l10n.childProfileToolTimeRequests,
        routePath: '/scr-fat-033',
      ),
      ChildProfileTool(
        id: 'web_filter',
        emoji: '🌐',
        label: l10n.childProfileToolWebFilter,
        routePath: '/scr-fat-036',
      ),
      ChildProfileTool(
        id: 'instant_lock',
        emoji: '🔒',
        label: l10n.childProfileToolInstantLock,
        routePath: '/scr-fat-037',
      ),
      ChildProfileTool(
        id: 'smart_supervision',
        emoji: '⚙️',
        label: l10n.childProfileToolSmartSupervision,
        routePath: '/scr-fat-067',
      ),
      ChildProfileTool(
        id: 'device_health',
        emoji: '📱',
        label: l10n.childProfileToolDeviceHealth,
        routePath: '/scr-fat-026',
      ),
    ];
  }

  void _goTool(ChildProfileTool tool) {
    if (widget.onNavigateTool != null) {
      widget.onNavigateTool!(tool);
      return;
    }
    final id = _resolvedChildId;
    final uri = id == null
        ? tool.routePath
        : '${tool.routePath}?childId=${Uri.encodeComponent(id)}';
    context.push(uri);
  }

  void _goLocation() {
    if (widget.onOpenLocation != null) {
      widget.onOpenLocation!();
      return;
    }
    final id = _resolvedChildId;
    final path = id == null
        ? '/scr-fat-014'
        : '/scr-fat-014?childId=${Uri.encodeComponent(id)}';
    context.push(path);
  }

  void _goDeviceHealth() {
    if (widget.onOpenDeviceHealth != null) {
      widget.onOpenDeviceHealth!();
      return;
    }
    final id = _resolvedChildId;
    final path = id == null
        ? '/scr-fat-026'
        : '/scr-fat-026?deviceId=${Uri.encodeComponent(id)}';
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final title = _profile?.displayName ?? l10n.childProfileTitle;

    return Scaffold(
      key: ChildProfileKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: !_isParent
          ? AppEmptyState(
              key: ChildProfileKeys.childLean,
              title: l10n.childProfileChildLeanTitle,
              message: l10n.childProfileChildLeanMessage,
            )
          : _resolvedChildId == null
              ? AppEmptyState(
                  key: ChildProfileKeys.missingId,
                  title: l10n.childProfileMissingIdTitle,
                  message: l10n.childProfileMissingIdMessage,
                )
              : _loading
                  ? Center(
                      key: ChildProfileKeys.loading,
                      child: Semantics(
                        label: l10n.childProfileLoadingSemantics,
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  : _loadFailed
                      ? AppErrorState(
                          key: ChildProfileKeys.error,
                          kind: AppErrorKind.network,
                          onRetry: _load,
                        )
                      : _profile == null
                          ? AppEmptyState(
                              key: ChildProfileKeys.notFound,
                              title: l10n.childProfileNotFoundTitle,
                              message: l10n.childProfileNotFoundMessage,
                            )
                          : _ProfileBody(
                              profile: _profile!,
                              tools: _tools(l10n),
                              onTool: _goTool,
                              onOpenLocation: _goLocation,
                              onOpenDeviceHealth: _goDeviceHealth,
                            ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.tools,
    required this.onTool,
    required this.onOpenLocation,
    required this.onOpenDeviceHealth,
  });

  final ChildProfile profile;
  final List<ChildProfileTool> tools;
  final void Function(ChildProfileTool tool) onTool;
  final VoidCallback onOpenLocation;
  final VoidCallback onOpenDeviceHealth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;
    final ageText = l10n.addChildAgeYears(toEasternDigits(profile.ageYears));
    final statusLabel = switch (profile.health) {
      ChildListHealth.excellent => l10n.childProfileStatusOk,
      ChildListHealth.atRisk => l10n.childProfileStatusAtRisk,
    };
    final connectionLabel = switch (profile.health) {
      ChildListHealth.excellent => l10n.childrenListHealthExcellent,
      ChildListHealth.atRisk => l10n.childrenListHealthAtRisk,
    };
    final healthTag = switch (profile.health) {
      ChildListHealth.excellent => TagVariant.g,
      ChildListHealth.atRisk => TagVariant.a,
    };
    final identitySemantics = l10n.childProfileIdentitySemantics(
      profile.displayName,
      ageText,
      statusLabel,
    );

    return ListView(
      key: ChildProfileKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Semantics(
          container: true,
          label: identitySemantics,
          child: DecoratedBox(
            key: ChildProfileKeys.identityCard,
            decoration: BoxDecoration(
              gradient: gradients.grad,
              borderRadius: BorderRadius.circular(radii.card),
              boxShadow: [
                Theme.of(context).extension<FamilyShadows>()!.shCard,
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _ProfileAvatar(
                        emoji: profile.emoji,
                        warnRing: profile.warnRing,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.childProfileNameAge(
                                profile.displayName,
                                ageText,
                              ),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          emoji: '🔋',
                          value: profile.batteryLabel,
                          label: l10n.childProfileMetricBattery,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MetricTile(
                          emoji: '📶',
                          value: connectionLabel,
                          label: l10n.childProfileMetricConnection,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MetricTile(
                          emoji: '📍',
                          value: profile.locationLabel,
                          label: l10n.childProfileMetricLocation,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MetricTile(
                          emoji: '⏱',
                          value: profile.walletLabel,
                          label: l10n.childProfileMetricWallet,
                        ),
                      ),
                    ],
                  ),
                  if (profile.todayUsedLabel.isNotEmpty &&
                      profile.todayCapLabel.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.childProfileTodayUsage(
                          profile.todayUsedLabel,
                          profile.todayCapLabel,
                        ),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.childProfileToolsTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  Tag(
                    label: l10n.childProfileToolsBadge,
                    variant: TagVariant.t,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.childProfileToolsHint,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                container: true,
                label: l10n.childProfileToolsSemantics,
                child: GridView.count(
                  key: ChildProfileKeys.toolsGrid,
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.05,
                  children: [
                    for (final tool in tools)
                      _ToolTile(
                        tool: tool,
                        onTap: () => onTool(tool),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.childProfileLocationTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.childProfileDetailsLink,
                    child: InkWell(
                      onTap: onOpenLocation,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Text(
                          l10n.childProfileDetailsLink,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.p600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.childProfileLocationSummary(
                  profile.locationLabel,
                  profile.lastSeenLabel,
                  profile.batteryLabel,
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.childProfileConnectionTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  Tag(label: connectionLabel, variant: healthTag),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.childProfileConnectionBody(profile.lastHeartbeatLabel),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  button: true,
                  label: l10n.childProfileDeviceDetailsLink,
                  child: InkWell(
                    onTap: onOpenDeviceHealth,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Text(
                        l10n.childProfileDeviceDetailsLink,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colors.p600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        boxShadow: [Theme.of(context).extension<FamilyShadows>()!.shCard],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: child,
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool, required this.onTap});

  final ChildProfileTool tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Semantics(
      button: true,
      label: tool.label,
      child: Material(
        color: colors.p50,
        borderRadius: BorderRadius.circular(radii.card),
        child: InkWell(
          key: ChildProfileKeys.tool(tool.id),
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.card),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tool.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  tool.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.emoji, required this.warnRing});

  final String emoji;
  final bool warnRing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final ring = warnRing ? colors.amber : Colors.white.withValues(alpha: 0.45);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
        color: Colors.white.withValues(alpha: 0.25),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
