import 'package:flutter/widgets.dart';

import 'foundation_gate_app.dart';

/// Separate entry point for the synthetic, read-only Foundation Gate only.
///
/// This must not be replaced with the default application entry point: that
/// bootstrap intentionally initializes unrelated mock-first local domains.
void main() {
  runApp(const FoundationGateApp());
}
