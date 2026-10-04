import 'package:flutter/widgets.dart';

import 'package:family_os/core/runtime/app_runtime.dart';

/// Typed dependency boundary for normal Family OS application routes.
///
/// Screens obtain runtime ports from this scope; production feature code must
/// not silently fall back to a mutable `stage1*` singleton when the scope is
/// absent. Test and development hosts inject an explicit [AppRuntime].
final class AppScope extends InheritedNotifier<AppRuntime> {
  const AppScope({super.key, required AppRuntime runtime, required super.child})
    : super(notifier: runtime);

  static AppRuntime of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in tree');
    return scope!.notifier!;
  }

  static AppRuntime? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()?.notifier;
}
