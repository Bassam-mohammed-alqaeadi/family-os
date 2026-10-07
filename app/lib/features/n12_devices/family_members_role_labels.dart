import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';

/// The words a membership row is shown with, and the one place they are decided.
///
/// These are role labels, not person names: the server publishes a role and never a name,
/// so the screen must show whom a row refers to by the part they play in the family. The
/// previous home for these constants was a `*mock*.dart` file, which meant production code
/// could not name a role without importing a fixture module - the tail wagging the dog.
abstract final class FamilyMembersRoleLabels {
  static const owner = 'وليّ الأمر'; // rule12-allow: a role word, resolved before any BuildContext exists
  static const mother = 'وليّة أمر'; // rule12-allow: a role word, resolved before any BuildContext exists
  static const guardian = 'وصيّ إضافي'; // rule12-allow: a role word, resolved before any BuildContext exists
  static const child = 'ابن'; // rule12-allow: a row label for an invitation with no profile yet
  static const ownerMonogram = 'و'; // rule12-allow: a monogram, one letter drawn in a swatch
  static const motherMonogram = 'أ'; // rule12-allow: a monogram, one letter drawn in a swatch
  static const guardianMonogram = 'و'; // rule12-allow: a monogram, one letter drawn in a swatch

  /// The swatch and monogram a role is drawn with, so two callers cannot disagree about
  /// what the mother's row looks like.
  static (String, DayChildSwatch) appearanceFor(FamilyMemberKind kind) =>
      switch (kind) {
        FamilyMemberKind.owner => (ownerMonogram, DayChildSwatch.purple),
        FamilyMemberKind.mother => (motherMonogram, DayChildSwatch.sky),
        FamilyMemberKind.guardian => (guardianMonogram, DayChildSwatch.amber),
        FamilyMemberKind.child => ('👦', DayChildSwatch.purple),
      };

  /// The label for one of the server's membership roles, or null for a role this client
  /// does not know how to show. Null is the honest answer: a guardian role with no words
  /// yet must not be rendered under the nearest-looking label.
  static (FamilyMemberKind, String)? forRole(String role) => switch (role) {
    'primary_guardian' => (FamilyMemberKind.owner, owner),
    'co_guardian' => (FamilyMemberKind.mother, mother),
    // A child is not a co-parent. An active child's row is drawn from the children roster
    // and never uses this label; a pending child invitation has no profile yet, and the one
    // honest thing to write beside it is that it is a child's invitation.
    'child' => (FamilyMemberKind.child, child),
    _ => null,
  };
}
