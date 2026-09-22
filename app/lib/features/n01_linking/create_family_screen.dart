import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/create_family_create.dart';

/// How many children the father plans to follow (mock UX only).
enum ChildCountChoice {
  one,
  two,
  three,
  fourPlus,
}

/// SCR-FAT-001 — إنشاء العائلة (bare parent onboarding, mock-first).
///
/// Creator becomes OWNER — product note only (one_owner_per_family).
/// No Firebase / backend on this card. Create failures surface SHR-005
/// ([AppErrorState]) with Retry — UI-001.
class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({
    super.key,
    this.onCreated,
    this.createFamily,
  });

  /// Test seam — when null after successful create, navigates to `/scr-fat-002`.
  final VoidCallback? onCreated;

  /// Injectable create (Rule 23/25). Defaults to [mockCreateFamilySuccess].
  /// Throw [CreateFamilyException] to force SHR-005 variants in tests.
  final CreateFamilyFn? createFamily;

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final _nameController = TextEditingController();
  ChildCountChoice _childCount = ChildCountChoice.three;
  AppErrorKind? _errorKind;
  bool _submitting = false;

  CreateFamilyFn get _create =>
      widget.createFamily ?? mockCreateFamilySuccess;

  @override
  void initState() {
    super.initState();
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

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty && !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final name = _nameController.text.trim();
    setState(() {
      _submitting = true;
      _errorKind = null;
    });
    try {
      await _create(name);
      if (!mounted) return;
      if (widget.onCreated != null) {
        widget.onCreated!();
        return;
      }
      // Mock-only: creator is OWNER (no persistence this card).
      context.go('/scr-fat-002');
    } on CreateFamilyException catch (e) {
      if (!mounted) return;
      setState(() => _errorKind = e.kind);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorKind = AppErrorKind.network);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _childCountLabel(AppLocalizations l10n, ChildCountChoice choice) {
    return switch (choice) {
      ChildCountChoice.one => l10n.createFamilyChildCountOne,
      ChildCountChoice.two => l10n.createFamilyChildCountTwo,
      ChildCountChoice.three => l10n.createFamilyChildCountThree,
      ChildCountChoice.fourPlus => l10n.createFamilyChildCountFourPlus,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.createFamilyTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.createFamilySubtitle,
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
        child: _errorKind != null
            ? AppErrorState(
                key: const Key('create_family_error'),
                kind: _errorKind!,
                onRetry: _submitting ? null : _submit,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                children: [
                  _LabeledField(
                    label: l10n.createFamilyNameLabel,
                    child: Semantics(
                      textField: true,
                      label: l10n.createFamilyNameLabel,
                      child: TextField(
                        key: const Key('create_family_name'),
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        enabled: !_submitting,
                        decoration: _inputDecoration(
                          colors: colors,
                          radii: radii,
                          hint: l10n.createFamilyNameHint,
                        ),
                      ),
                    ),
                  ),
                  _LabeledField(
                    label: l10n.createFamilyChildCountLabel,
                    child: Semantics(
                      button: true,
                      label: l10n.createFamilyChildCountLabel,
                      child: DropdownButtonFormField<ChildCountChoice>(
                        key: const Key('create_family_child_count'),
                        initialValue: _childCount,
                        decoration: _inputDecoration(
                          colors: colors,
                          radii: radii,
                          hint: '',
                        ),
                        items: ChildCountChoice.values
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(_childCountLabel(l10n, c)),
                              ),
                            )
                            .toList(),
                        onChanged: _submitting
                            ? null
                            : (v) {
                                if (v == null) return;
                                setState(() => _childCount = v);
                              },
                      ),
                    ),
                  ),
                  BannerNote(
                    key: const Key('create_family_trial_banner'),
                    variant: BannerVariant.g,
                    leading: Text(
                      l10n.createFamilyBannerLeading,
                      style: TextStyle(fontSize: 14, color: colors.mintInk),
                    ),
                    message: l10n.createFamilyTrialBanner,
                  ),
                  const SizedBox(height: 16),
                  if (_submitting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  else
                    PrimaryBtn(
                      key: const Key('create_family_submit'),
                      label: l10n.createFamilySubmit,
                      onPressed: _canSubmit ? _submit : null,
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
