import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/sos_sender.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';

/// Widget keys for SCR-FAT-027 acceptance.
abstract final class FamilyMembersKeys {
  static const screen = Key('family_members_screen');
  static const title = Key('family_members_title');
  static const loading = Key('family_members_loading');
  static const empty = Key('family_members_empty');
  static const error = Key('family_members_error');
  static const list = Key('family_members_list');
  static const inviteCta = Key('family_members_invite');
  static const inviteDisabled = Key('family_members_invite_disabled');
  static const footer = Key('family_members_footer');
  static const childLean = Key('family_members_child_lean');
  static const sosCta = Key('family_members_sos');
  static const transferOwnership = Key('family_members_transfer_ownership');
  static const familySelector = Key('family_members_family_selector');
  static const leaveFamily = Key('family_members_leave_family');
  static const localDemoBanner = Key('family_members_local_demo_banner');

  static Key memberRow(String id) => Key('family_members_row_$id');
  /// The three membership commands, one key each, so a test taps the exact control the
  /// guardian taps rather than any button with the same words.
  static Key acceptInvitation(String id) => Key('family_members_accept_$id');
  static Key cancelInvitation(String id) => Key('family_members_cancel_$id');
  static Key removeMember(String id) => Key('family_members_revoke_$id');
}

/// SCR-FAT-027 — أعضاء العائلة (roles · levels · invite).
///
/// Prototype FAT-027 · one_owner_per_family · invite → FAT-008 (owner only) ·
/// mother level change → FAT-031 (owner) · GUARDIAN locked مطّلع · children
/// parametric · P-4 SOS · mother OK / child lean · Rule 23 empty default.
class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({
    super.key,
    this.repository,
    this.childrenListRepository,
    this.roleOverride,
    this.sosFire,
    this.onSos,
    this.onInvite,
    this.onOpenMotherLevel,
    this.membershipCommands,
  });

  /// Null → [stage1FamilyMembersRepository].
  final FamilyMembersRepository? repository;

  /// Null → [stage1ChildrenListRepository] (LOCAL_DEMO provenance).
  final ChildrenListRepository? childrenListRepository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  final VoidCallback? onSos;

  /// Test seam — when null, navigates to `/scr-fat-008`.
  final VoidCallback? onInvite;

  /// Test seam — when null, navigates to `/scr-fat-031`.
  final void Function(String memberId)? onOpenMotherLevel;

  /// The three commands that change a membership. Null means this build has no live
  /// server, and then a membership row offers no action at all: a button that cannot reach
  /// a server is a promise the product cannot keep.
  final FamilyMembershipCommands? membershipCommands;

  @override
  State<FamilyMembersScreen> createState() => FamilyMembersScreenState();
}

class FamilyMembersScreenState extends State<FamilyMembersScreen> {
  late FamilyMembersRepository _repo;
  late ChildrenListRepository _childrenListRepo;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  List<FamilyMemberEntry> _members = const [];
  String? _rosterProvenance;
  String? _loadedFamilyId;

  AppRole get _role =>
      widget.roleOverride ??
      resolveAuthorizationContext(context, fallbackRole: AppRole.father).role;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  /// Invite CTA — sole owner (father). Product: one_owner_per_family.
  bool get _isOwner {
    // Test seam: roleOverride wins over Inherited Identity for invite gate.
    if (widget.roleOverride != null) {
      return widget.roleOverride == AppRole.father;
    }
    return resolveAuthorizationContext(
      context,
      fallbackRole: AppRole.father,
    ).canInviteAdults;
  }

  /// The live commands: the screen's own seam first (tests, preview hosts), then the
  /// binding installed at startup by a build that has a server.
  FamilyMembershipCommands? get _commands =>
      widget.membershipCommands ?? stage1MembershipCommands;

  bool get _showFamilySelector {
    final runtime = CurrentIdentity.maybeOf(context);
    if (runtime == null) return false;
    return runtime.needsFamilySelector;
  }

  bool get _canLeaveFamily {
    return resolveAuthorizationContext(
      context,
      fallbackRole: _role,
    ).canLeaveFamily;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1FamilyMembersRepository;
    _childrenListRepo =
        widget.childrenListRepository ?? stage1ChildrenListRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depend on CurrentIdentity (InheritedNotifier) so mother-level writes
    // from FAT-031 refresh the roster tag without a full navigation remount.
    final familyId = CurrentIdentity.maybeOf(context)?.activeFamilyId.value;
    if (familyId != _loadedFamilyId) {
      if (!_loading) _load();
      return;
    }
    if (familyId != null && !_loading && _loadedFamilyId != null) {
      _refreshMembersQuiet();
    }
  }

  /// Where the children rows came from. The repository answers when it can; when it does
  /// not, the children list repository still knows, because that is where the rows live.
  Future<String?> _provenanceFor(String familyId) async {
    // Typed as Object on purpose: a local typed FamilyMembersRepository would not promote
    // to FamilyMembersProvenanceSource, because neither interface is a subtype of the
    // other. Typing the local as Object makes the capability check below decide the type.
    final Object source = _repo;
    if (source is FamilyMembersProvenanceSource) {
      return source.loadProvenance(familyId: FamilyId(familyId));
    }
    return _childrenListRepo.loadProvenance(familyId: FamilyId(familyId));
  }

  /// Soft refresh after Identity notify (same family) — no loading flash.
  Future<void> _refreshMembersQuiet() async {
    final familyId = _loadedFamilyId;
    if (familyId == null) return;
    try {
      final members = await _repo.listMembers(familyId: familyId);
      if (!mounted) return;
      setState(() => _members = members);
    } catch (_) {
      // Keep last good roster.
    }
  }

  /// The three membership commands, each one a server call followed by an honest reload.
  ///
  /// Nothing is written to the roster from the response body: the screen re-reads what the
  /// server now says, so a row can never show a state the server did not confirm. A failure
  /// leaves the roster as it was and says so, rather than optimistically redrawing it.
  Future<void> _acceptInvitation(FamilyMemberEntry member) async {
    final familyId = _loadedFamilyId;
    final commands = _commands;
    if (familyId == null || commands == null) return;
    await _runMembershipCommand(
      () => commands.accept(
        familyId: FamilyId(familyId),
        membershipId: member.id,
        idempotencyKey: newFoundationGateIdempotencyKey(),
      ),
    );
  }

  Future<void> _cancelInvitation(FamilyMemberEntry member) async {
    final familyId = _loadedFamilyId;
    final commands = _commands;
    if (familyId == null || commands == null) return;
    await _runMembershipCommand(
      () => commands.revoke(
        familyId: FamilyId(familyId),
        membershipId: member.id,
        reasonCode: 'invitation_withdrawn',
        idempotencyKey: newFoundationGateIdempotencyKey(),
      ),
    );
  }

  Future<void> _removeMember(FamilyMemberEntry member) async {
    final familyId = _loadedFamilyId;
    final commands = _commands;
    if (familyId == null || commands == null) return;
    await _runMembershipCommand(
      () => commands.revoke(
        familyId: FamilyId(familyId),
        membershipId: member.id,
        reasonCode: 'member_left',
        idempotencyKey: newFoundationGateIdempotencyKey(),
      ),
    );
  }

  /// A pending invitation addressed to the caller is the one thing a person can accept on
  /// this screen, and the server is the one that must confirm it.
  VoidCallback? _acceptFor(FamilyMemberEntry member) {
    if (_commands == null) return null;
    if (!member.isSelf || member.membershipStatus?.isPending != true) return null;
    return () => _acceptInvitation(member);
  }

  /// Withdrawing an invitation that nobody accepted. The owner's call alone.
  VoidCallback? _cancelFor(FamilyMemberEntry member) {
    if (_commands == null || !_isOwner) return null;
    if (member.isSelf || member.membershipStatus?.isPending != true) return null;
    return () => _cancelInvitation(member);
  }

  /// Removing an active adult. The primary guardian cannot be removed here: the server
  /// requires the separate continuity process, and offering a button that must fail is the
  /// same lie as one that leads nowhere.
  VoidCallback? _removeFor(FamilyMemberEntry member) {
    if (_commands == null || !_isOwner) return null;
    if (member.isSelf || member.membershipStatus?.isActive != true) return null;
    if (member.kind == FamilyMemberKind.owner) return null;
    return () => _removeMember(member);
  }

  Future<void> _runMembershipCommand(Future<void> Function() command) async {
    try {
      await command();
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, message: AppLocalizations.of(context).sys3ErrorTitle);
      return;
    }
    if (!mounted) return;
    await _load();
  }

  @override
  void didUpdateWidget(covariant FamilyMembersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1FamilyMembersRepository;
      _load();
    }
    if (oldWidget.childrenListRepository != widget.childrenListRepository) {
      _childrenListRepo =
          widget.childrenListRepository ?? stage1ChildrenListRepository;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final familyId = CurrentIdentity.maybeOf(context)?.activeFamilyId.value;
      // Fail closed without Identity — empty roster, no unscoped leak.
      if (familyId == null || familyId.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          _members = const [];
          _rosterProvenance = null;
          _loadedFamilyId = null;
          _loading = false;
          _loadFailed = false;
        });
        return;
      }
      final members = await _repo.listMembers(familyId: familyId);
      final provenance = await _provenanceFor(familyId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _rosterProvenance = provenance;
        _loadedFamilyId = familyId;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _members = const [];
        _rosterProvenance = null;
        _loadedFamilyId = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    final fire = widget.sosFire ?? stage1SosFireService;
    await parentSosSenderOf(context).fireThrough(fire);
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push('/scr-fat-018');
  }

  void _goInvite() {
    if (!_isOwner) return;
    if (widget.onInvite != null) {
      widget.onInvite!();
      return;
    }
    context.push('/scr-fat-008');
  }

  void _goMotherLevel(FamilyMemberEntry member) {
    if (!_isOwner) return;
    if (member.kind != FamilyMemberKind.mother || member.levelLocked) return;
    if (widget.onOpenMotherLevel != null) {
      widget.onOpenMotherLevel!(member.id);
      return;
    }
    context.push(
      '/scr-fat-031?memberId=${Uri.encodeQueryComponent(member.id)}',
    );
  }

  void _leaveFamily() {
    context.push('/sys3-leave-family');
  }

  Color _swatchColor(FamilyColors colors, DayChildSwatch swatch) {
    return switch (swatch) {
      DayChildSwatch.purple => colors.p500,
      DayChildSwatch.sky => colors.sky,
      DayChildSwatch.amber => colors.amber,
    };
  }

  String _displayTitle(AppLocalizations l10n, FamilyMemberEntry m) {
    if (m.isSelf) return l10n.familyMembersSelfName(m.displayName);
    return m.displayName;
  }

  String _roleSubtitle(AppLocalizations l10n, FamilyMemberEntry m) {
    return switch (m.kind) {
      FamilyMemberKind.owner => l10n.familyMembersRoleOwner,
      FamilyMemberKind.mother => l10n.familyMembersRoleMother,
      FamilyMemberKind.guardian => l10n.familyMembersRoleGuardian,
      FamilyMemberKind.child => l10n.familyMembersRoleChild,
    };
  }

  String _levelLabel(AppLocalizations l10n, MotherLevel level) {
    return switch (level) {
      MotherLevel.observer => l10n.inviteMotherLevelObserverTitle,
      MotherLevel.partner => l10n.inviteMotherLevelPartnerTitle,
      MotherLevel.full => l10n.inviteMotherLevelFullTitle,
    };
  }

  (String label, TagVariant variant) _tagFor(
    AppLocalizations l10n,
    FamilyMemberEntry m,
  ) {
    switch (m.kind) {
      case FamilyMemberKind.owner:
        return (l10n.familyMembersTagOwner, TagVariant.p);
      case FamilyMemberKind.mother:
        final level = m.motherLevel;
        // A roster that came from the server carries no permission level: the level is the
        // owner's choice and the membership endpoint does not publish it. Naming a level
        // this screen was not told would read as a granted privilege, so an unknown level
        // is answered with the role itself and an amber tag.
        if (level == null) {
          return (l10n.familyMembersRoleMother, TagVariant.a);
        }
        final base = _levelLabel(l10n, level);
        final variant = level == MotherLevel.observer
            ? TagVariant.a
            : TagVariant.g;
        final label = _isOwner ? l10n.familyMembersTagMotherChange(base) : base;
        return (label, variant);
      case FamilyMemberKind.guardian:
        return (l10n.familyMembersTagGuardianLocked, TagVariant.a);
      case FamilyMemberKind.child:
        return (l10n.familyMembersTagChild, TagVariant.t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: FamilyMembersKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          key: FamilyMembersKeys.title,
          l10n.familyMembersTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: FamilyMembersKeys.sosCta,
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
    if (!_isParent) {
      return AppEmptyState(
        key: FamilyMembersKeys.childLean,
        title: l10n.familyMembersChildLeanTitle,
        message: l10n.familyMembersChildLeanMessage,
      );
    }

    if (_loading) {
      return const Center(
        key: FamilyMembersKeys.loading,
        child: CircularProgressIndicator(),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: FamilyMembersKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }

    if (_members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AppEmptyState(
                key: FamilyMembersKeys.empty,
                title: l10n.familyMembersEmptyTitle,
                message: l10n.familyMembersEmptyMessage,
              ),
            ),
            _InviteBlock(isOwner: _isOwner, l10n: l10n, onInvite: _goInvite),
            const SizedBox(height: 10),
            Text(
              key: FamilyMembersKeys.footer,
              l10n.familyMembersInviteOnlyNote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      key: FamilyMembersKeys.list,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (_showFamilySelector) ...[
          _FamilySelector(
            activeFamilyId: CurrentIdentity.of(context).activeFamilyId.value,
            families: CurrentIdentity.of(context).families
                .map((f) => (id: f.id.value, name: f.name))
                .toList(growable: false),
            onChanged: (value) async {
              final runtime = CurrentIdentity.of(context);
              runtime.switchActiveFamily(FamilyId(value));
              await _load();
            },
          ),
          const SizedBox(height: 10),
        ],
        if (isChildrenListSeededProvenance(_rosterProvenance)) ...[
          BannerNote(
            key: FamilyMembersKeys.localDemoBanner,
            message: l10n.childrenListLocalDemoBanner,
            variant: BannerVariant.a,
            leading: Text(
              'ℹ',
              style: TextStyle(fontSize: 18, color: colors.ink),
            ),
          ),
          const SizedBox(height: 10),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(
              Theme.of(context).extension<FamilyRadii>()!.card,
            ),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _members.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: colors.border),
                _MemberRow(
                  member: _members[i],
                  title: _displayTitle(l10n, _members[i]),
                  subtitle: _roleSubtitle(l10n, _members[i]),
                  tag: _tagFor(l10n, _members[i]),
                  avatarColor: _swatchColor(colors, _members[i].swatch),
                  canOpenMotherLevel:
                      _isOwner &&
                      _members[i].kind == FamilyMemberKind.mother &&
                      !_members[i].levelLocked &&
                      _members[i].membershipStatus?.isActive == true,
                  onTap: () => _goMotherLevel(_members[i]),
                  onAccept: _acceptFor(_members[i]),
                  onCancelInvitation: _cancelFor(_members[i]),
                  onRemove: _removeFor(_members[i]),
                ),
              ],
            ],
          ),
        ),
        if (_isOwner) ...[
          const SizedBox(height: 8),
          // The remove-adult list that used to sit here read the LOCAL identity projection,
          // so it listed memberships this device had recorded and pushed a screen that
          // changed the same local copy. Removing a member is a server fact now, and each
          // membership row above carries its own remove action with its own key - one list
          // of members, one way to change them.
          PrimaryBtn(
            key: FamilyMembersKeys.transferOwnership,
            label: l10n.sys3FamilyTransferCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: () => context.push('/sys3-ownership-transfer'),
          ),
        ],
        if (_showFamilySelector) ...[
          const SizedBox(height: 8),
          PrimaryBtn(
            key: FamilyMembersKeys.familySelector,
            label: l10n.sys3FamilySelectorCta,
            variant: PrimaryBtnVariant.ghost,
            onPressed: () => context.push('/sys3-family-select'),
          ),
        ],
        const SizedBox(height: 14),
        _InviteBlock(isOwner: _isOwner, l10n: l10n, onInvite: _goInvite),
        if (_canLeaveFamily) ...[
          const SizedBox(height: 8),
          PrimaryBtn(
            key: FamilyMembersKeys.leaveFamily,
            label: l10n.sys3FamilyLeaveCta,
            variant: PrimaryBtnVariant.ghost,
            onPressed: _leaveFamily,
          ),
        ],
        const SizedBox(height: 10),
        Text(
          key: FamilyMembersKeys.footer,
          l10n.familyMembersInviteOnlyNote,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _InviteBlock extends StatelessWidget {
  const _InviteBlock({
    required this.isOwner,
    required this.l10n,
    required this.onInvite,
  });

  final bool isOwner;
  final AppLocalizations l10n;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    if (isOwner) {
      return PrimaryBtn(
        key: FamilyMembersKeys.inviteCta,
        label: l10n.familyMembersInviteCta,
        onPressed: onInvite,
      );
    }
    return PrimaryBtn(
      key: FamilyMembersKeys.inviteDisabled,
      label: l10n.familyMembersInviteOwnerOnly,
      onPressed: null,
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.avatarColor,
    required this.canOpenMotherLevel,
    required this.onTap,
    this.onAccept,
    this.onCancelInvitation,
    this.onRemove,
  });

  final FamilyMemberEntry member;
  final String title;
  final String subtitle;
  final (String, TagVariant) tag;
  final Color avatarColor;
  final bool canOpenMotherLevel;
  final VoidCallback onTap;

  /// The membership commands, each null when it is not this caller's to run. A row shows
  /// only the steps it can actually carry out, which is why they are separate callbacks
  /// rather than one action slot.
  final VoidCallback? onAccept;
  final VoidCallback? onCancelInvitation;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final (tagLabel, tagVariant) = tag;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColor,
            child: Text(
              member.monogram,
              style: TextStyle(
                fontSize: member.monogram.runes.length > 1 ? 16 : 15,
                fontWeight: FontWeight.w800,
                color: colors.surface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Tag(label: tagLabel, variant: tagVariant),
          ),
        ],
      ),
    );

    final hasAction = onAccept != null || onCancelInvitation != null || onRemove != null;
    final row = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        if (onAccept != null)
          _MemberAction(
            key: FamilyMembersKeys.acceptInvitation(member.id),
            label: AppLocalizations.of(context).acceptMotherInviteAccept,
            onPressed: onAccept!,
          ),
        if (onCancelInvitation != null)
          _MemberAction(
            key: FamilyMembersKeys.cancelInvitation(member.id),
            label: AppLocalizations.of(context).sys3RevokeAction,
            onPressed: onCancelInvitation!,
          ),
        if (onRemove != null)
          _MemberAction(
            key: FamilyMembersKeys.removeMember(member.id),
            label: AppLocalizations.of(context).sys3RemoveAdultAction,
            onPressed: onRemove!,
          ),
        if (hasAction) const SizedBox(height: 4),
      ],
    );

    if (!canOpenMotherLevel) {
      return KeyedSubtree(
        key: FamilyMembersKeys.memberRow(member.id),
        child: row,
      );
    }

    return Material(
      key: FamilyMembersKeys.memberRow(member.id),
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

class _FamilySelector extends StatelessWidget {
  const _FamilySelector({
    required this.activeFamilyId,
    required this.families,
    required this.onChanged,
  });

  final String activeFamilyId;
  final List<({String id, String name})> families;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: activeFamilyId,
            isExpanded: true,
            items: [
              for (final family in families)
                DropdownMenuItem<String>(
                  value: family.id,
                  child: Text(
                    family.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}

/// One membership command, drawn under the row it belongs to.
///
/// Its own widget so the keys, the padding and the touch target are decided once, and so a
/// test can address the accept button of one invitation without matching on copy that two
/// rows share.
class _MemberAction extends StatelessWidget {
  const _MemberAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 12, bottom: 4),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: colors.p600),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
