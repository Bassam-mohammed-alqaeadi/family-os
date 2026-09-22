import 'package:flutter/widgets.dart';
import 'package:family_os/core/domain/role.dart';

/// Mutable current role for [GoRouter.refreshListenable] + RoleGuard.
///
/// Default: [AppRole.father]. Gallery/tests may switch to [AppRole.child].
class RoleController extends ValueNotifier<AppRole> {
  RoleController([super.value = AppRole.father]);
}

/// Inherited lookup for widgets that need the current [AppRole].
class CurrentRole extends InheritedNotifier<ValueNotifier<AppRole>> {
  const CurrentRole({
    required ValueNotifier<AppRole> notifier,
    required super.child,
    super.key,
  }) : super(notifier: notifier);

  static AppRole of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<CurrentRole>();
    assert(inherited != null, 'CurrentRole not found in tree');
    return inherited!.notifier!.value;
  }

  static ValueNotifier<AppRole>? maybeNotifierOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CurrentRole>()?.notifier;
  }
}
