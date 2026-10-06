import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';
import 'package:family_os/features/n12_devices/family_members_role_labels.dart';
import 'package:family_os/foundation_gate/family_membership_api_client.dart';
import 'package:family_os/foundation_gate/main_app_foundation_runtime.dart';

/// Reads the family's memberships from the server, and writes the three commands that
/// change them.
///
/// **What this replaces.** The screen used to build its roster from a local identity
/// projection, which knows only the memberships this device has recorded - so a co-guardian
/// who accepted an invitation on another phone was invisible here, a pending invitation
/// could not be seen or cancelled, and `isSelf` was inferred locally. The server publishes
/// all of that now, and this repository is the only place the two are translated.
///
/// **What it refuses to do.** It does not invent a member. A row whose role the client
/// cannot label is dropped rather than rendered under a neighbouring label, and a level the
/// server did not send stays null instead of defaulting to a privilege the guardian never
/// granted.
///
/// The roster is server-authoritative: an API failure throws, so the screen shows its
/// failure state. Returning an empty list would be the worst possible answer - it reads as
/// "your family has no members".
typedef MembershipRosterLoader =
    Future<List<FoundationGateMembership>> Function(FamilyId familyId);

/// The three writes the members screen performs, as one seam.
///
/// Returning the server's membership rather than a bool keeps the screen honest: what it
/// shows after a command is what the server said the membership became, not what the screen
/// hoped it became.
abstract class FamilyMembershipCommands {
  Future<FoundationGateMembership> invite({
    required FamilyId familyId,
    required String role,
    required String targetSubject,
    required String idempotencyKey,
  });

  Future<FoundationGateMembership> accept({
    required FamilyId familyId,
    required String membershipId,
    required String idempotencyKey,
  });

  Future<FoundationGateMembership> revoke({
    required FamilyId familyId,
    required String membershipId,
    required String reasonCode,
    required String idempotencyKey,
  });
}

final class RemoteFamilyMembersRepository
    implements FamilyMembersRepository, FamilyMembersProvenanceSource {
  RemoteFamilyMembersRepository({
    required MembershipRosterLoader loadMemberships,
    ChildrenListRepository? children,
  }) : _loadMemberships = loadMemberships,
       _children = children;

  final MembershipRosterLoader _loadMemberships;
  final ChildrenListRepository? _children;

  ChildrenListRepository get _roster =>
      _children ?? stage1ChildrenListRepository;

  @override
  Future<List<FamilyMemberEntry>> listMembers({String? familyId}) async {
    final id = familyId?.trim();
    if (id == null || id.isEmpty) return const [];
    final family = FamilyId(id);

    // Throws on failure on purpose: the caller distinguishes "no members" from "could not
    // ask". A caught error returning [] would tell a guardian their family is empty.
    final memberships = await _loadMemberships(family);

    final rows = <FamilyMemberEntry>[];
    for (final membership in memberships) {
      final label = FamilyMembersRoleLabels.forRole(membership.role);
      if (label == null) {
        // A role this client cannot name. Dropping it keeps the screen from inventing one,
        // and the gap is visible in the roster rather than hidden behind a wrong word.
        continue;
      }
      if (membership.role == 'child' && !membership.isPending) {
        // An active child membership is represented by the child's own profile row from
        // the children roster below; listing it twice would show one person twice. A
        // pending one has no profile yet, so it is the only way to see the invitation.
        continue;
      }
      final status = FamilyMembershipStatus.parse(membership.status);
      if (status == null) continue;
      final (kind, name) = label;
      final (monogram, swatch) = FamilyMembersRoleLabels.appearanceFor(kind);
      rows.add(
        FamilyMemberEntry(
          id: membership.id,
          familyId: id,
          displayName: name,
          kind: kind,
          monogram: monogram,
          swatch: swatch,
          isSelf: membership.isSelf,
          levelLocked: kind == FamilyMemberKind.guardian,
          membershipStatus: status,
        ),
      );
    }

    final children = await _roster.listChildren(familyId: family);
    for (final child in children) {
      rows.add(
        FamilyMemberEntry(
          id: child.id,
          familyId: id,
          displayName: child.displayName,
          kind: FamilyMemberKind.child,
          monogram: child.emoji,
          swatch: child.swatch,
        ),
      );
    }

    return List.unmodifiable(rows);
  }

  /// The children roster's provenance, which is the one part of this screen that can still
  /// be locally seeded. The memberships themselves came from the server.
  @override
  Future<String?> loadProvenance({FamilyId? familyId}) =>
      _roster.loadProvenance(familyId: familyId);
}

/// The three commands, backed by the runtime that owns the session and the token.
///
/// The screen depends on three operations rather than on the whole foundation runtime: a
/// screen that could reach the runtime could reach anything in it.
final class RemoteFamilyMembershipCommands implements FamilyMembershipCommands {
  RemoteFamilyMembershipCommands(this._runtime);

  final MainAppFoundationRuntime _runtime;

  @override
  Future<FoundationGateMembership> invite({
    required FamilyId familyId,
    required String role,
    required String targetSubject,
    required String idempotencyKey,
  }) => _runtime.inviteMembership(
    familyId: familyId,
    role: role,
    targetSubject: targetSubject,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<FoundationGateMembership> accept({
    required FamilyId familyId,
    required String membershipId,
    required String idempotencyKey,
  }) => _runtime.acceptMembership(
    familyId: familyId,
    membershipId: membershipId,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<FoundationGateMembership> revoke({
    required FamilyId familyId,
    required String membershipId,
    required String reasonCode,
    required String idempotencyKey,
  }) => _runtime.revokeMembership(
    familyId: familyId,
    membershipId: membershipId,
    reasonCode: reasonCode,
    idempotencyKey: idempotencyKey,
  );
}
