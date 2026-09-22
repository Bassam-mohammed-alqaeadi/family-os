import 'package:flutter/material.dart';

/// Parent vs child chrome (prototype `.child-ui`).
enum FamilyUiMode { parent, child }

/// Provides [FamilyUiMode] to descendants (AppCard radius, TabsBar accents).
class FamilyUiModeScope extends InheritedWidget {
  const FamilyUiModeScope({
    super.key,
    required this.mode,
    required super.child,
  });

  final FamilyUiMode mode;

  static FamilyUiMode of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FamilyUiModeScope>();
    return scope?.mode ?? FamilyUiMode.parent;
  }

  static FamilyUiMode? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FamilyUiModeScope>()
        ?.mode;
  }

  @override
  bool updateShouldNotify(FamilyUiModeScope oldWidget) =>
      mode != oldWidget.mode;
}
