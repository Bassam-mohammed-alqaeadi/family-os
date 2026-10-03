import 'dart:async';

import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';

import 'foundation_gate_copy.dart';
import 'foundation_gate_models.dart';

/// Presentation-only states for the refined, isolated Children Control Centre.
///
/// The controller owns identity, authorization and networking. This widget only
/// renders the already-classified state, so visual work cannot become a hidden
/// second API client or local-authority fallback.
enum ChildrenControlCentreStatus {
  loading,
  ready,
  empty,
  accessDenied,
  unavailable,
  networkUnavailable,
}

/// Reusable read-only Children Control Centre surface for the narrow roster
/// slice. It intentionally has no mutation callback or device/policy model.
class ChildrenControlCentre extends StatelessWidget {
  const ChildrenControlCentre({
    super.key,
    required this.status,
    this.family,
    this.children = const [],
    required this.onSignOut,
    this.onRetry,
    this.onChooseFamily,
  });

  final ChildrenControlCentreStatus status;
  final FoundationGateFamily? family;
  final List<FoundationGateChild> children;
  final Future<void> Function() onSignOut;
  final Future<void> Function()? onRetry;
  final VoidCallback? onChooseFamily;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return ColoredBox(
      color: colors.bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 720 ? 32.0 : 20.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
                children: [
                  if (status != ChildrenControlCentreStatus.accessDenied && family != null) ...[
                    _FamilyContextHeader(family: family!, childCount: children.length),
                    const SizedBox(height: 20),
                  ],
                  switch (status) {
                    ChildrenControlCentreStatus.loading => const _RosterLoading(),
                    ChildrenControlCentreStatus.ready => _RosterReady(children: children),
                    ChildrenControlCentreStatus.empty => const _RosterEmpty(),
                    ChildrenControlCentreStatus.accessDenied => _RosterIssue(
                      icon: Icons.lock_outline,
                      title: copy.rosterAccessDenied,
                      body: copy.accessDeniedBody,
                      onChooseFamily: onChooseFamily,
                      onSignOut: onSignOut,
                    ),
                    ChildrenControlCentreStatus.unavailable => _RosterIssue(
                      icon: Icons.cloud_off_outlined,
                      title: copy.rosterUnavailableTitle,
                      body: copy.rosterUnavailableBody,
                      onRetry: onRetry,
                      onChooseFamily: onChooseFamily,
                      onSignOut: onSignOut,
                    ),
                    ChildrenControlCentreStatus.networkUnavailable => _RosterIssue(
                      icon: Icons.wifi_off_outlined,
                      title: copy.networkUnavailable,
                      body: copy.rosterUnavailableBody,
                      onRetry: onRetry,
                      onChooseFamily: onChooseFamily,
                      onSignOut: onSignOut,
                    ),
                  },
                  const SizedBox(height: 20),
                  if (status != ChildrenControlCentreStatus.accessDenied) const _TruthBoundaryCard(),
                  const SizedBox(height: 16),
                  _CentreActions(
                    onChooseFamily: onChooseFamily,
                    onSignOut: onSignOut,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FamilyContextHeader extends StatelessWidget {
  const _FamilyContextHeader({required this.family, required this.childCount});

  final FoundationGateFamily family;
  final int childCount;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final isCoGuardian = family.role == 'co_guardian';

    return Semantics(
      container: true,
      label: '${copy.familyContext}: ${family.displayName}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radii.card),
          boxShadow: [shadows.shCard],
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.familyContext,
                    style: TextStyle(
                      color: colors.ink2,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    family.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    childCount == 1 ? copy.childCountOne : copy.childCount(childCount),
                    style: TextStyle(
                      color: colors.ink2,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
              final source = _SourceContext(
                roleText: copy.displayRole(family.role),
                roleDescription: isCoGuardian ? copy.coGuardianReadOnly : copy.primaryGuardianRosterOnly,
              );

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [details, const SizedBox(height: 16), source],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: details), const SizedBox(width: 20), source],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SourceContext extends StatelessWidget {
  const _SourceContext({required this.roleText, required this.roleDescription});

  final String roleText;
  final String roleDescription;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.mint100,
              borderRadius: BorderRadius.circular(radii.pill),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 10, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: colors.mintInk),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      copy.serverRosterCurrentSession,
                      style: TextStyle(color: colors.mintInk, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(roleText, style: TextStyle(color: colors.ink, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(roleDescription, style: TextStyle(color: colors.ink2, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}

class _RosterLoading extends StatelessWidget {
  const _RosterLoading();

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return Semantics(
      label: copy.loadingRoster,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.childrenTitle, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(copy.childrenSubtitle, style: TextStyle(color: colors.ink2)),
          const SizedBox(height: 20),
          for (var index = 0; index < 2; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(radii.card),
                  border: Border.all(color: colors.border),
                ),
                child: const SizedBox(height: 92),
              ),
            ),
          const SizedBox(height: 8),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _RosterReady extends StatelessWidget {
  const _RosterReady({required this.children});

  final List<FoundationGateChild> children;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 640 ? 2 : 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.childrenTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(copy.childrenSubtitle, style: TextStyle(color: colors.ink2)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: children
                  .map(
                    (child) => SizedBox(
                      width: columnCount == 2 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                      child: _ChildProfileCard(child: child),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        );
      },
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  const _ChildProfileCard({required this.child});

  final FoundationGateChild child;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final initial = child.displayName.trim().isEmpty ? '?' : String.fromCharCode(child.displayName.trim().runes.first);
    return Semantics(
      container: true,
      label: '${child.displayName}, ${copy.age(child.ageYears)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radii.card),
          boxShadow: [shadows.shCard],
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.p100,
                foregroundColor: colors.p700,
                child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.ink, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(copy.age(child.ageYears), style: TextStyle(color: colors.ink2, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RosterEmpty extends StatelessWidget {
  const _RosterEmpty();

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.people_outline, color: colors.p600, size: 32),
            const SizedBox(height: 14),
            Text(copy.emptyRosterTitle, style: TextStyle(color: colors.ink, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(copy.emptyRosterBody, style: TextStyle(color: colors.ink2, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _RosterIssue extends StatelessWidget {
  const _RosterIssue({
    required this.icon,
    required this.title,
    required this.body,
    required this.onSignOut,
    this.onRetry,
    this.onChooseFamily,
  });

  final IconData icon;
  final String title;
  final String body;
  final Future<void> Function() onSignOut;
  final Future<void> Function()? onRetry;
  final VoidCallback? onChooseFamily;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radii.card),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.coral, size: 32),
              const SizedBox(height: 14),
              Text(title, style: TextStyle(color: colors.ink, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(body, style: TextStyle(color: colors.ink2, height: 1.5)),
              if (onRetry != null || onChooseFamily != null) const SizedBox(height: 18),
              if (onRetry != null)
                FilledButton(
                  onPressed: () => unawaited(onRetry!()),
                  child: Text(copy.retry),
                ),
              if (onChooseFamily != null) ...[
                if (onRetry != null) const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onChooseFamily,
                  child: Text(copy.chooseAnotherFamily),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TruthBoundaryCard extends StatelessWidget {
  const _TruthBoundaryCard();

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.p50,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.p100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: colors.p600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.noDevicePolicyTitle, style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(copy.rosterBoundary, style: TextStyle(color: colors.ink2, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CentreActions extends StatelessWidget {
  const _CentreActions({required this.onSignOut, this.onChooseFamily});

  final Future<void> Function() onSignOut;
  final VoidCallback? onChooseFamily;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onChooseFamily != null)
          OutlinedButton.icon(
            onPressed: onChooseFamily,
            icon: const Icon(Icons.swap_horiz),
            label: Text(copy.chooseAnotherFamily),
          ),
        TextButton(
          onPressed: () => unawaited(onSignOut()),
          child: Text(copy.signOut),
        ),
      ],
    );
  }
}
