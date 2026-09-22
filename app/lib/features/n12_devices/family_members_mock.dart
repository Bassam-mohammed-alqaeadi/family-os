import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';

/// Test / demo fixtures for SCR-FAT-027 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic role labels only. Never the screen default (Rule 23).
abstract final class FamilyMembersMock {
  const FamilyMembersMock._();

  static const List<FamilyMemberEntry> fullFixture = [
    FamilyMemberEntry(
      id: 'member_owner',
      displayName: 'وليّ الأمر',
      kind: FamilyMemberKind.owner,
      monogram: 'و',
      swatch: DayChildSwatch.purple,
      isSelf: true,
    ),
    FamilyMemberEntry(
      id: 'member_mother',
      displayName: 'وليّة أمر',
      kind: FamilyMemberKind.mother,
      monogram: 'أ',
      swatch: DayChildSwatch.sky,
      motherLevel: MotherLevel.partner,
    ),
    FamilyMemberEntry(
      id: 'member_guardian',
      displayName: 'وصيّ إضافي',
      kind: FamilyMemberKind.guardian,
      monogram: 'و',
      swatch: DayChildSwatch.amber,
      motherLevel: MotherLevel.observer,
      levelLocked: true,
    ),
    FamilyMemberEntry(
      id: 'child_a',
      displayName: 'ابن ١',
      kind: FamilyMemberKind.child,
      monogram: '🦁',
      swatch: DayChildSwatch.purple,
    ),
    FamilyMemberEntry(
      id: 'child_b',
      displayName: 'ابن ٢',
      kind: FamilyMemberKind.child,
      monogram: '🐱',
      swatch: DayChildSwatch.sky,
    ),
  ];

  /// Owner-only family (invite CTA still available).
  static const List<FamilyMemberEntry> ownerOnlyFixture = [
    FamilyMemberEntry(
      id: 'member_owner',
      displayName: 'وليّ الأمر',
      kind: FamilyMemberKind.owner,
      monogram: 'و',
      swatch: DayChildSwatch.purple,
      isSelf: true,
    ),
  ];
}
