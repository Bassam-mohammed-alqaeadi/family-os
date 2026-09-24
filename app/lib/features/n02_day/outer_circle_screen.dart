import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/outer_circle_models.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';

/// Widget keys for SCR-FAT-070 acceptance.
abstract final class OuterCircleKeys {
  static const screen = Key('outer_circle_screen');
  static const loading = Key('outer_circle_loading');
  static const empty = Key('outer_circle_empty');
  static const body = Key('outer_circle_body');
  static const strangersBanner = Key('outer_circle_strangers');
  static const relativesCard = Key('outer_circle_relatives');
  static const friendsCard = Key('outer_circle_friends');
  static const scheduleCard = Key('outer_circle_schedule');
  static const childLean = Key('outer_circle_child_lean');
  static const sosIconCta = Key('outer_circle_sos_icon');

  static Key member(String id) => Key('outer_circle_member_$id');
  static Key pending(String id) => Key('outer_circle_pending_$id');
}

/// SCR-FAT-070 — الدائرة الخارجية (trusted outer circle).
///
/// Prototype FAT-070 · strangers blocked · relatives + friends · pending →071 ·
/// Rule 12/23 · mother levels (view) · P-4 SOS · empty → FAT-003.
class OuterCircleScreen extends StatefulWidget {
  const OuterCircleScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final OuterCircleRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<OuterCircleScreen> createState() => _OuterCircleScreenState();
}

class _OuterCircleScreenState extends State<OuterCircleScreen> {
  late OuterCircleRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  OuterCircleSnapshot _snap = const OuterCircleSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1OuterCircleRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await _repo.load();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _loading = false;
    });
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    await _sos.fire(childId: 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-FAT-018'));
  }

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  String _name(AppLocalizations l10n, String key) {
    return switch (key) {
      'grandpa' => l10n.outerCircleNameGrandpa,
      'aunt' => l10n.outerCircleNameAunt,
      'friendOne' => l10n.outerCircleNameFriendOne,
      'pendingFriend' => l10n.outerCircleNamePendingFriend,
      _ => l10n.outerCircleNameFriendOne,
    };
  }

  String _meta(AppLocalizations l10n, String key) {
    return switch (key) {
      'callsAnytime' => l10n.outerCircleMetaCallsAnytime,
      'messagesCalls' => l10n.outerCircleMetaMessagesCalls,
      'classmateSlot' => l10n.outerCircleMetaClassmateSlot,
      'classmatePending' => l10n.outerCircleMetaClassmatePending,
      _ => l10n.outerCircleMetaClassmateSlot,
    };
  }

  String _status(AppLocalizations l10n, String key) {
    return switch (key) {
      'approved' => l10n.outerCircleStatusApproved,
      'alwaysApproved' => l10n.outerCircleStatusAlwaysApproved,
      'pending' => l10n.outerCircleStatusPending,
      _ => l10n.outerCircleStatusApproved,
    };
  }

  String _scheduleNote(AppLocalizations l10n) {
    return switch (_snap.scheduleNoteKey) {
      'friendsEvening' => l10n.outerCircleScheduleFriendsEvening,
      _ => l10n.outerCircleScheduleFriendsEvening,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: OuterCircleKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.outerCircleTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: OuterCircleKeys.sosIconCta,
            tooltip: l10n.spineCtaSosSemantics,
            onPressed: _sosBusy ? null : _openSos,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: WidgetStatePropertyAll(Size(48, 48)),
            ),
            icon: Icon(Icons.sos, color: colors.coral),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, l10n, colors)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    if (_isChild || !_isParent) {
      return AppEmptyState(
        key: OuterCircleKeys.childLean,
        title: l10n.outerCircleChildLeanTitle,
        message: l10n.outerCircleChildLeanMessage,
        actionLabel: l10n.outerCircleSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: OuterCircleKeys.loading,
        child: Semantics(
          label: l10n.outerCircleLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: OuterCircleKeys.empty,
        title: l10n.outerCircleEmptyTitle,
        message: l10n.outerCircleEmptyMessage,
        actionLabel: l10n.outerCircleEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: OuterCircleKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: OuterCircleKeys.strangersBanner,
            variant: BannerVariant.t,
            message: l10n.outerCircleStrangersBanner,
          ),
          const SizedBox(height: 10),
          _MembersCard(
            key: OuterCircleKeys.relativesCard,
            colors: colors,
            radii: radii,
            heading: l10n.outerCircleRelativesHeading,
            members: _snap.relatives,
            nameOf: (m) => _name(l10n, m.nameKey),
            metaOf: (m) => _meta(l10n, m.metaKey),
            statusOf: (m) => m.nameKey == 'grandpa'
                ? l10n.outerCircleStatusAlwaysApproved
                : _status(l10n, m.statusKey),
          ),
          const SizedBox(height: 10),
          _FriendsCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            friends: _snap.friends,
            pending: _snap.pending,
            nameOf: (m) => _name(l10n, m.nameKey),
            metaOf: (m) => _meta(l10n, m.metaKey),
            statusOf: (m) => _status(l10n, m.statusKey),
            onPending: () => _go('SCR-FAT-071'),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: OuterCircleKeys.scheduleCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.outerCircleScheduleHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _scheduleNote(l10n),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({
    super.key,
    required this.colors,
    required this.radii,
    required this.heading,
    required this.members,
    required this.nameOf,
    required this.metaOf,
    required this.statusOf,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final String heading;
  final List<OuterCircleMember> members;
  final String Function(OuterCircleMember) nameOf;
  final String Function(OuterCircleMember) metaOf;
  final String Function(OuterCircleMember) statusOf;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              heading,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            for (final m in members)
              Padding(
                key: OuterCircleKeys.member(m.id),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Semantics(
                  label: '${nameOf(m)}. ${metaOf(m)}. ${statusOf(m)}',
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.p500,
                        child: Text(
                          _initial(nameOf(m)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameOf(m),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colors.ink,
                              ),
                            ),
                            Text(
                              metaOf(m),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tag(label: statusOf(m), variant: TagVariant.g),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _initial(String name) => name.isNotEmpty ? name.substring(0, 1) : '?';

class _FriendsCard extends StatelessWidget {
  const _FriendsCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.friends,
    required this.pending,
    required this.nameOf,
    required this.metaOf,
    required this.statusOf,
    required this.onPending,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final List<OuterCircleMember> friends;
  final List<OuterCircleMember> pending;
  final String Function(OuterCircleMember) nameOf;
  final String Function(OuterCircleMember) metaOf;
  final String Function(OuterCircleMember) statusOf;
  final VoidCallback onPending;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: OuterCircleKeys.friendsCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.outerCircleFriendsHeading,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            for (final m in friends)
              Padding(
                key: OuterCircleKeys.member(m.id),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Semantics(
                  label: '${nameOf(m)}. ${metaOf(m)}. ${statusOf(m)}',
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.mint,
                        child: Text(
                          _initial(nameOf(m)),
                          style: TextStyle(
                            color: colors.mintInk,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameOf(m),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colors.ink,
                              ),
                            ),
                            Text(
                              metaOf(m),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tag(label: statusOf(m), variant: TagVariant.g),
                    ],
                  ),
                ),
              ),
            for (final m in pending)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    key: OuterCircleKeys.pending(m.id),
                    borderRadius: BorderRadius.circular(12),
                    onTap: onPending,
                    child: Semantics(
                      button: true,
                      label: l10n.outerCirclePendingSemantics(nameOf(m)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: colors.amber,
                              child: Text(
                                _initial(nameOf(m)),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.outerCirclePendingTitle(nameOf(m)),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: colors.ink,
                                    ),
                                  ),
                                  Text(
                                    metaOf(m),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.amberInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tag(
                              label: l10n.outerCirclePendingCta,
                              variant: TagVariant.a,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
