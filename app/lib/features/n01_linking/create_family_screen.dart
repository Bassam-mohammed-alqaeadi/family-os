import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_creation_source.dart';
import 'package:family_os/features/n01_linking/create_family_create.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// How many children the father plans to follow (presentation only — the
/// server family-creation contract carries the name alone).
enum ChildCountChoice { one, two, three, fourPlus }

/// SCR-FAT-001 — إنشاء العائلة (server-backed since safety-phase Slice 0).
///
/// Creator becomes OWNER — product note only (one_owner_per_family).
///
/// The normal application path creates the family on the server through the
/// Foundation Gate typed client ([FamilyCreationSource]) with the authenticated
/// session, keeps the server-issued family id selected so add-child can address
/// it, and renders honest loading/error/offline states. Failures surface
/// SHR-005 ([AppErrorState]) with Retry — UI-001.
///
/// [CreateFamilyScreen.createFamily] remains a test seam only; the mocks live in
/// test code (`create_family_mocks.dart`) and tests inject them explicitly. With
/// no seam and no configured server session the screen says so and saves
/// nothing locally — it never reports success the server did not confirm.
class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({super.key, this.onCreated, this.createFamily});

  /// Test seam — when null after successful create, navigates to `/scr-fat-002`.
  final VoidCallback? onCreated;

  /// Injectable create (Rule 23/25) — tests only. Defaults to the real
  /// [FamilyCreationSource] from [AppScope]. Throw [CreateFamilyException] to
  /// force SHR-005 variants in tests.
  final CreateFamilyFn? createFamily;

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final _nameController = TextEditingController();
  ChildCountChoice _childCount = ChildCountChoice.three;
  AppErrorKind? _errorKind;
  String? _errorTitle;
  bool _submitting = false;
  String? _idempotencyKey;
  String? _submittedName;
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

  int get _nameLength => _nameController.text.trim().runes.length;

  // Server contract allows max 120 chars; gate submit instead of failing late.
  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _nameLength <= 120 &&
      !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final name = _nameController.text.trim();
    setState(() {
      _submitting = true;
      _errorKind = null;
      _errorTitle = null;
    });
    try {
      final seam = widget.createFamily;
      if (seam != null) {
        // Test/preview seam — the mock lives in tests only.
        await seam(name);
      } else if (!await _createOnServer(name)) {
        return;
      }
      if (!mounted) return;
      if (widget.onCreated != null) {
        widget.onCreated!();
        return;
      }
      // The server-issued family id is selected by the runtime before this
      // navigation, so SCR-FAT-003 (add child) addresses the real family.
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

  /// Real path: create the family on the server through [FamilyCreationSource].
  ///
  /// Returns true only after the server confirmed creation. With no configured
  /// server session the screen says so and saves nothing locally — the same
  /// honest shape SCR-FAT-003 uses for the same missing capability.
  Future<bool> _createOnServer(String name) async {
    final source = AppScope.maybeOf(context)?.familyCreation;
    if (source == null) {
      AppToast.show(
        context,
        message: AppLocalizations.of(context).settingsPersistError,
      );
      return false;
    }
    // The same idempotency key accompanies retries of the same name, so a
    // dropped connection cannot create two families.
    if (_idempotencyKey == null || _submittedName != name) {
      _idempotencyKey = newFoundationGateIdempotencyKey();
      _submittedName = name;
    }
    final result = await source.createFamily(
      displayName: name,
      idempotencyKey: _idempotencyKey!,
    );
    if (!result.isCreated) {
      if (mounted) _showFailure(result.failure);
      return false;
    }
    return true;
  }

  void _showFailure(FamilyCreateFailure? failure) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      switch (failure) {
        case FamilyCreateFailure.invalidInput:
        case FamilyCreateFailure.conflict:
        case FamilyCreateFailure.accessDenied:
          _errorKind = AppErrorKind.validation;
          _errorTitle = null;
        case FamilyCreateFailure.serviceUnavailable:
          _errorKind = AppErrorKind.timeout;
          _errorTitle = null;
        case FamilyCreateFailure.networkUnavailable:
          _errorKind = AppErrorKind.network;
          _errorTitle = null;
        case FamilyCreateFailure.sessionInvalid:
          _errorKind = AppErrorKind.network;
          _errorTitle = l10n.loginSessionExpired;
        case FamilyCreateFailure.unavailable:
        case null:
          _errorKind = AppErrorKind.network;
          _errorTitle = l10n.settingsPersistError;
      }
    });
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
                title: _errorTitle,
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
                        maxLength: 120,
                        buildCounter: (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) {
                          final counterColors = Theme.of(
                            context,
                          ).extension<FamilyColors>()!;
                          return Semantics(
                            liveRegion: true,
                            label: '$currentLength / 120',
                            child: Text(
                              '$currentLength / 120',
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: currentLength > 120
                                    ? counterColors.coral
                                    : counterColors.ink2,
                              ),
                            ),
                          );
                        },
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
                      key: Key('create_family_submitting'),
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
