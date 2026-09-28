import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_grid_tile.dart';
import 'package:family_os/core/design/components/elevated_gradient_card.dart';
import 'package:family_os/core/design/components/mint_progress_bar.dart';
import 'package:family_os/core/design/components/status_pulse_avatar.dart';
import 'package:family_os/core/design/tokens.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: buildFamilyTheme(),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  testWidgets('MintProgressBar renders', (tester) async {
    await tester.pumpWidget(
      wrap(
        const MintProgressBar(
          value: 0.42,
          semanticsLabel: 'Remaining screen time',
        ),
      ),
    );
    expect(find.byType(MintProgressBar), findsOneWidget);
  });

  testWidgets('StatusPulseAvatar is tappable with ring', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        StatusPulseAvatar(
          emoji: '🦁',
          fillColor: const Color(0xFF8B6FF0),
          semanticsLabel: 'Child A',
          status: StatusPulseKind.attention,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(StatusPulseAvatar));
    expect(taps, 1);
  });

  testWidgets('ElevatedGradientCard invokes onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        ElevatedGradientCard(
          semanticsLabel: 'Active child',
          onTap: () => taps++,
          child: const Text('body'),
        ),
      ),
    );
    await tester.tap(find.text('body'));
    expect(taps, 1);
  });

  testWidgets('AppGridTile renders label and tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 96,
          child: AppGridTile(icon: '📱', label: 'Apps', onTap: () => taps++),
        ),
      ),
    );
    expect(find.text('Apps'), findsOneWidget);
    await tester.tap(find.byType(AppGridTile));
    expect(taps, 1);
  });
}
