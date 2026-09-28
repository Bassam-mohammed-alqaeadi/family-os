import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';

/// Generic AR role labels for Identity projection (Rule 23 — not person names).
///
/// Rule 12 allowlisted (`*mock*.dart`). Used by fixtures and the Identity
/// family-members repository.
abstract final class FamilyMembersIdentityLabels {
  static const owner = 'وليّ الأمر';
  static const mother = 'وليّة أمر';
  static const guardian = 'وصيّ إضافي';
  static const ownerMonogram = 'و';
  static const motherMonogram = 'أ';
  static const guardianMonogram = 'و';
}

/// Test / demo fixtures for SCR-FAT-027 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic role labels only. Never the screen default (Rule 23).
abstract final class FamilyMembersMock {
  const FamilyMembersMock._();

  static const List<FamilyMemberEntry> fullFixture = [
    FamilyMemberEntry(
      id: 'member_owner',
      familyId: 'fam_stage1',
      displayName: FamilyMembersIdentityLabels.owner,
      kind: FamilyMemberKind.owner,
      monogram: FamilyMembersIdentityLabels.ownerMonogram,
      swatch: DayChildSwatch.purple,
      isSelf: true,
    ),
    FamilyMemberEntry(
      id: 'member_mother',
      familyId: 'fam_stage1',
      displayName: FamilyMembersIdentityLabels.mother,
      kind: FamilyMemberKind.mother,
      monogram: FamilyMembersIdentityLabels.motherMonogram,
      swatch: DayChildSwatch.sky,
      motherLevel: MotherLevel.partner,
    ),
    FamilyMemberEntry(
      id: 'member_guardian',
      familyId: 'fam_stage1',
      displayName: FamilyMembersIdentityLabels.guardian,
      kind: FamilyMemberKind.guardian,
      monogram: FamilyMembersIdentityLabels.guardianMonogram,
      swatch: DayChildSwatch.amber,
      motherLevel: MotherLevel.observer,
      levelLocked: true,
    ),
    FamilyMemberEntry(
      id: 'child_a',
      familyId: 'fam_stage1',
      displayName: 'ابن 1',
      kind: FamilyMemberKind.child,
      monogram: '🦁',
      swatch: DayChildSwatch.purple,
    ),
    FamilyMemberEntry(
      id: 'child_b',
      familyId: 'fam_stage1',
      displayName: 'ابن 2',
      kind: FamilyMemberKind.child,
      monogram: '🐱',
      swatch: DayChildSwatch.sky,
    ),
  ];

  /// Owner-only family (invite CTA still available).
  static const List<FamilyMemberEntry> ownerOnlyFixture = [
    FamilyMemberEntry(
      id: 'member_owner',
      familyId: 'fam_stage1',
      displayName: FamilyMembersIdentityLabels.owner,
      kind: FamilyMemberKind.owner,
      monogram: FamilyMembersIdentityLabels.ownerMonogram,
      swatch: DayChildSwatch.purple,
      isSelf: true,
    ),
  ];
}
