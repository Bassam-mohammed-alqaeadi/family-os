/// App roles matching Family OS product (father / mother / child).
///
/// For RoleGuard (constitution rule 8): [child] is the restricted role;
/// [father] and [mother] are parent roles and may open owner surfaces.
enum AppRole { father, mother, child }

extension AppRoleX on AppRole {
  bool get isChild => this == AppRole.child;

  bool get isParent => this == AppRole.father || this == AppRole.mother;
}
