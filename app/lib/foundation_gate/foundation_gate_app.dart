import 'package:flutter/material.dart';

/// Isolated composition root for the approved synthetic Foundation Gate.
///
/// It deliberately has no dependency on the legacy mock-first application,
/// Firebase, local persistence, networking, telemetry or token storage. Those
/// dependencies require separate gate entry-criteria acceptance.
class FoundationGateApp extends StatelessWidget {
  const FoundationGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('Foundation Gate is not configured.'),
        ),
      ),
    );
  }
}
