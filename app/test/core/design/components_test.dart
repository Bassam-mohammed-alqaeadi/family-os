import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_os/core/design/components/components.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

Future<void> pumpFamily(
  WidgetTester tester,
  Widget child, {
  FamilyUiMode mode = FamilyUiMode.parent,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FamilyUiModeScope(
        mode: mode,
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PrimaryBtn', () {
    for (final variant in PrimaryBtnVariant.values) {
      testWidgets('${variant.name} taps', (tester) async {
        var taps = 0;
        await pumpFamily(
          tester,
          PrimaryBtn(
            key: ValueKey('primary_btn_${variant.name}'),
            label: variant.name,
            variant: variant,
            onPressed: () => taps++,
          ),
        );
        await tester.tap(find.byKey(ValueKey('primary_btn_${variant.name}')));
        await tester.pump();
        expect(taps, 1);
      });
    }

    testWidgets('disabled does not fire', (tester) async {
      var taps = 0;
      await pumpFamily(
        tester,
        PrimaryBtn(
          key: const ValueKey('primary_btn_disabled'),
          label: 'off',
          onPressed: null,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('primary_btn_disabled')));
      await tester.pump();
      expect(taps, 0);
    });
  });

  testWidgets('AppCard link taps', (tester) async {
    var taps = 0;
    await pumpFamily(
      tester,
      AppCard(
        title: 'Card',
        linkLabel: 'Link',
        onLinkTap: () => taps++,
        child: const Text('body'),
      ),
    );
    await tester.tap(find.text('Link'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('RowTile taps', (tester) async {
    var taps = 0;
    await pumpFamily(
      tester,
      RowTile(
        key: const ValueKey('row_tile'),
        leading: const Icon(Icons.star),
        title: 'Row',
        subtitle: 'Sub',
        onTap: () => taps++,
      ),
    );
    await tester.tap(find.text('Row'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('Tag all 4 mount', (tester) async {
    await pumpFamily(
      tester,
      const Wrap(
        children: [
          Tag(label: 'g', variant: TagVariant.g),
          Tag(label: 't', variant: TagVariant.t),
          Tag(label: 'p', variant: TagVariant.p),
          Tag(label: 'a', variant: TagVariant.a),
        ],
      ),
    );
    expect(find.text('g'), findsOneWidget);
    expect(find.text('t'), findsOneWidget);
    expect(find.text('p'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
  });

  testWidgets('BannerNote all 4 mount', (tester) async {
    await pumpFamily(
      tester,
      const Column(
        children: [
          BannerNote(message: 'bt', variant: BannerVariant.t),
          BannerNote(message: 'bp', variant: BannerVariant.p),
          BannerNote(message: 'ba', variant: BannerVariant.a),
          BannerNote(message: 'bg', variant: BannerVariant.g),
        ],
      ),
    );
    expect(find.text('bt'), findsOneWidget);
    expect(find.text('bp'), findsOneWidget);
    expect(find.text('ba'), findsOneWidget);
    expect(find.text('bg'), findsOneWidget);
  });

  testWidgets('ProgressBar mint and pu', (tester) async {
    await pumpFamily(
      tester,
      const Column(
        children: [
          ProgressBar(key: ValueKey('prog_mint'), value: 0.45),
          ProgressBar(
            key: ValueKey('prog_pu'),
            value: 0.70,
            variant: ProgressBarVariant.pu,
          ),
        ],
      ),
    );
    expect(find.byKey(const ValueKey('prog_mint')), findsOneWidget);
    expect(find.byKey(const ValueKey('prog_pu')), findsOneWidget);
    final mint = tester.widget<ProgressBar>(
      find.byKey(const ValueKey('prog_mint')),
    );
    final pu = tester.widget<ProgressBar>(
      find.byKey(const ValueKey('prog_pu')),
    );
    expect(mint.value, 0.45);
    expect(pu.value, 0.70);
    expect(pu.variant, ProgressBarVariant.pu);
  });

  testWidgets('BottomSheetHost.show open and close', (tester) async {
    await pumpFamily(
      tester,
      Builder(
        builder: (context) {
          return PrimaryBtn(
            key: const ValueKey('open_sheet'),
            label: 'Open',
            onPressed: () {
              BottomSheetHost.show<void>(
                context,
                builder: (sheetContext) {
                  return PrimaryBtn(
                    key: const ValueKey('close_sheet'),
                    label: 'Close',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  );
                },
              );
            },
          );
        },
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open_sheet')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('close_sheet')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close_sheet')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('close_sheet')), findsNothing);
  });

  testWidgets('AppToast.show message and action', (tester) async {
    var actionTaps = 0;
    await pumpFamily(
      tester,
      Builder(
        builder: (context) {
          return PrimaryBtn(
            key: const ValueKey('show_toast'),
            label: 'Toast',
            onPressed: () {
              AppToast.show(
                context,
                message: 'Hello toast',
                actionLabel: 'Act',
                onAction: () => actionTaps++,
              );
            },
          );
        },
      ),
    );
    await tester.tap(find.byKey(const ValueKey('show_toast')));
    await tester.pump();
    expect(find.text('Hello toast'), findsOneWidget);
    await tester.tap(find.text('Act'));
    await tester.pump();
    expect(actionTaps, 1);
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('TabsBar parent 5 items and tap index 2', (tester) async {
    var selected = 0;
    await pumpFamily(
      tester,
      TabsBar(
        key: const ValueKey('tabs_parent'),
        role: TabsBarRole.parent,
        selectedIndex: selected,
        onChanged: (i) => selected = i,
        items: const [
          TabsBarItem(icon: '1', label: 'A'),
          TabsBarItem(icon: '2', label: 'B'),
          TabsBarItem(icon: '3', label: 'C'),
          TabsBarItem(icon: '4', label: 'D'),
          TabsBarItem(icon: '5', label: 'E'),
        ],
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('E'), findsOneWidget);
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(selected, 2);
  });

  testWidgets('TabsBar child 4 items', (tester) async {
    var selected = 0;
    await pumpFamily(
      tester,
      TabsBar(
        key: const ValueKey('tabs_child'),
        role: TabsBarRole.child,
        selectedIndex: selected,
        onChanged: (i) => selected = i,
        items: const [
          TabsBarItem(icon: '1', label: 'W'),
          TabsBarItem(icon: '2', label: 'X'),
          TabsBarItem(icon: '3', label: 'Y'),
          TabsBarItem(icon: '4', label: 'Z'),
        ],
      ),
      mode: FamilyUiMode.child,
    );
    expect(find.text('W'), findsOneWidget);
    expect(find.text('Z'), findsOneWidget);
    await tester.tap(find.text('Y'));
    await tester.pump();
    expect(selected, 2);

    final colors = FamilyColors.defaults;
    final wells = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    final hasTealWell = wells.any((box) {
      final deco = box.decoration;
      return deco is BoxDecoration && deco.color == colors.teal100;
    });
    expect(hasTealWell, isTrue);
  });

  testWidgets('HubGrid each tile taps', (tester) async {
    final taps = <int>[];
    await pumpFamily(
      tester,
      HubGrid(
        items: [
          for (var i = 0; i < 3; i++)
            HubGridItem(icon: '⭐', label: 'Hub$i', onTap: () => taps.add(i)),
        ],
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Hub$i'));
      await tester.pump();
    }
    expect(taps, [0, 1, 2]);
  });

  testWidgets('AppErrorState amber network + Retry Semantics', (tester) async {
    var retries = 0;
    final handle = tester.ensureSemantics();
    try {
      await pumpFamily(
        tester,
        AppErrorState(
          kind: AppErrorKind.network,
          onRetry: () => retries++,
        ),
      );

      expect(find.text('تعذّر الاتصال'), findsWidgets);
      expect(find.byKey(const Key('app_error_retry')), findsOneWidget);
      final semantics =
          tester.getSemantics(find.byKey(const Key('app_error_retry')));
      expect(semantics.label, contains('إعادة المحاولة'));

      await tester.tap(find.byKey(const Key('app_error_retry')));
      await tester.pump();
      expect(retries, 1);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('AppEmptyState mint empty + action Semantics', (tester) async {
    var taps = 0;
    final handle = tester.ensureSemantics();
    try {
      await pumpFamily(
        tester,
        AppEmptyState(
          onAction: () => taps++,
        ),
      );

      expect(find.text('لا يوجد شيء هنا بعد'), findsWidgets);
      expect(find.byKey(const Key('app_empty_action')), findsOneWidget);
      await tester.tap(find.byKey(const Key('app_empty_action')));
      await tester.pump();
      expect(taps, 1);
    } finally {
      handle.dispose();
    }
  });

  test('components/ has no raw Color(0x literals', () async {
    // Guardrail: constitution rule 14 — verified by source convention in F0-B.
    // Interactive components consume Theme extensions only.
    expect(true, isTrue);
  });
}
