import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Character emoji options (prototype FAT-003 picker).
const List<String> kAddChildCharacters = ['🦁', '🐱', '🐼', '🦊', '🐰'];

/// Ages offered on SCR-FAT-003 (inclusive).
const List<int> kAddChildAges = [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];

/// Mock-only anonymous analytics alias: `child_` + 4 hex chars.
String generateMockChildAlias([Random? random]) {
  final r = random ?? Random();
  final hex = List.generate(
    4,
    (_) => r.nextInt(16).toRadixString(16),
  ).join();
  return 'child_$hex';
}

/// Eastern Arabic digits for AR labels (prototype numerals).
String toEasternDigits(int value) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((ch) {
    final i = western.indexOf(ch);
    return i < 0 ? ch : eastern[i];
  }).join();
}

/// SCR-FAT-003 — إضافة ابن (bare parent onboarding, mock-first).
///
/// Parametric / Rule 23: name field starts empty — no default person name.
/// No Firebase / backend on this card.
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({
    super.key,
    this.onContinue,
    this.mockAlias,
  });

  /// Test seam — when null, navigates to `/scr-fat-004`.
  final VoidCallback? onContinue;

  /// Optional stable alias for tests; otherwise a local mock is generated.
  final String? mockAlias;

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _nameController = TextEditingController();
  late final String _alias;

  int _age = 14;
  int _characterIndex = 0;
  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();
    _alias = widget.mockAlias ?? generateMockChildAlias();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onNameChanged)
      ..dispose();
    super.dispose();
  }

  void _onNameChanged() => setState(() {});

  bool get _canContinue => _nameController.text.trim().isNotEmpty;

  void _continue() {
    if (!_canContinue) return;
    if (widget.onContinue != null) {
      widget.onContinue!();
      return;
    }
    context.go('/scr-fat-004');
  }

  List<Color> _kidColors(FamilyColors colors) => [
        colors.p500,
        colors.sky,
        colors.amber,
        colors.coral,
        colors.mint,
        colors.teal600,
      ];

  String _ageLabel(AppLocalizations l10n, int age) {
    final years = l10n.localeName.startsWith('ar')
        ? toEasternDigits(age)
        : '$age';
    return l10n.addChildAgeYears(years);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final kidColors = _kidColors(colors);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.addChildTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.addChildStep,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          children: [
            _LabeledField(
              label: l10n.addChildNameLabel,
              child: Semantics(
                textField: true,
                label: l10n.addChildNameLabel,
                child: TextField(
                  key: const Key('add_child_name'),
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    colors: colors,
                    radii: radii,
                    hint: l10n.addChildNameHint,
                  ),
                ),
              ),
            ),
            _LabeledField(
              label: l10n.addChildAgeLabel,
              child: Semantics(
                button: true,
                label: l10n.addChildAgeLabel,
                child: DropdownButtonFormField<int>(
                  key: const Key('add_child_age'),
                  initialValue: _age,
                  decoration: _inputDecoration(
                    colors: colors,
                    radii: radii,
                    hint: '',
                  ),
                  items: kAddChildAges
                      .map(
                        (age) => DropdownMenuItem(
                          value: age,
                          child: Text(_ageLabel(l10n, age)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _age = v);
                  },
                ),
              ),
            ),
            _LabeledField(
              label: l10n.addChildCharacterLabel,
              child: Semantics(
                label: l10n.addChildCharacterLabel,
                child: Row(
                  key: const Key('add_child_characters'),
                  children: [
                    for (var i = 0; i < kAddChildCharacters.length; i++)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 10),
                        child: Semantics(
                          button: true,
                          selected: _characterIndex == i,
                          label: kAddChildCharacters[i],
                          child: GestureDetector(
                            key: Key('add_child_char_$i'),
                            onTap: () => setState(() => _characterIndex = i),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: _characterIndex == i ? 1 : 0.35,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 150),
                                scale: _characterIndex == i ? 1.15 : 1,
                                child: Text(
                                  kAddChildCharacters[i],
                                  style: const TextStyle(fontSize: 30),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _LabeledField(
              label: l10n.addChildColorLabel,
              child: Semantics(
                label: l10n.addChildColorLabel,
                child: Row(
                  key: const Key('add_child_colors'),
                  children: [
                    for (var i = 0; i < kidColors.length; i++)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 10),
                        child: Semantics(
                          button: true,
                          selected: _colorIndex == i,
                          label: l10n.addChildColorSwatchSemantics(i + 1),
                          child: GestureDetector(
                            key: Key('add_child_color_$i'),
                            onTap: () => setState(() => _colorIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 30,
                              height: 30,
                              transform: Matrix4.diagonal3Values(
                                _colorIndex == i ? 1.1 : 1,
                                _colorIndex == i ? 1.1 : 1,
                                1,
                              ),
                              transformAlignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: kidColors[i],
                                shape: BoxShape.circle,
                                border: _colorIndex == i
                                    ? Border.all(color: colors.ink, width: 3)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            PrimaryBtn(
              key: const Key('add_child_continue'),
              label: l10n.addChildContinue,
              onPressed: _canContinue ? _continue : null,
            ),
            const SizedBox(height: 10),
            Semantics(
              label: l10n.addChildAliasSemantics(_alias),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                  children: [
                    TextSpan(text: l10n.addChildAliasPrefix),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          _alias,
                          key: const Key('add_child_alias_ltr'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(text: l10n.addChildAliasSuffix),
                  ],
                ),
                key: const Key('add_child_alias_footer'),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required FamilyColors colors,
    required FamilyRadii radii,
    required String hint,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.input),
      borderSide: BorderSide(color: colors.border, width: 1.5),
    );
    return InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      hintStyle: TextStyle(color: colors.ink2.withValues(alpha: 0.55)),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.input),
        borderSide: BorderSide(color: colors.p400, width: 1.5),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
