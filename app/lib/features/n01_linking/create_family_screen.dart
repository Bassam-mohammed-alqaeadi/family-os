import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/premium_journey_states.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_creation_source.dart';
import 'package:family_os/features/n01_linking/create_family_create.dart';
import 'package:family_os/foundation_gate/onboarding_copy.dart';
import 'package:family_os/features/shared_onboarding/onboarding_form.dart';
import 'package:family_os/features/shared_onboarding/session_recovery.dart';
import 'package:family_os/foundation_gate/foundation_gate_copy.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// Widget keys for SCR-FAT-001.
abstract final class CreateFamilyKeys {
  static const name = Key('create_family_name');
  static const submit = Key('create_family_submit');
  static const error = Key('create_family_error');
  static const retry = Key('app_error_retry');
}

/// SCR-FAT-001 — create the family on the server.
///
/// The form holds exactly what the server stores: the family display name.
/// The creator becomes OWNER — server-assigned after a confirmed 201.
/// Failures are shown inline (title + reason + Retry); the form stays on
/// screen so the user can correct the name without losing it.
///
/// The production route resolves the real [FamilyCreationSource] from
/// [AppScope]. When none is configured the screen fails closed with an honest
/// "not configured" notice — it never manufactures a family. The injectable
/// [CreateFamilyFn] seam remains for tests.
class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({super.key, this.onCreated, this.createFamily});

  /// Test seam — when null after successful create, navigates to `/scr-fat-002`.
  final VoidCallback? onCreated;

  /// Injectable create. When null the screen resolves the real
  /// [FamilyCreationSource] from [AppScope]. Throw [CreateFamilyException] to
  /// force error variants in tests.
  final CreateFamilyFn? createFamily;

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  static const _maxNameLength = 120;

  final _name = TextEditingController();
  final _scroll = ScrollController();
  var _touched = false;
  var _submitting = false;
  var _celebrating = false;
  CreateFamilyException? _error;
  String? _idempotencyKey;
  String? _submittedName;

  CreateFamilyFn get _create => widget.createFamily ?? _createWithSource;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _trimmedName => _name.text.trim();

  String? _nameProblem(OnboardingCopy copy) {
    if (_trimmedName.isEmpty) return copy.familyNameRequired;
    if (_trimmedName.runes.length > _maxNameLength) {
      return copy.familyNameTooLong;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final copy = OnboardingCopy.of(context);
    setState(() => _touched = true);
    if (_nameProblem(copy) != null) return;

    FocusScope.of(context).unfocus();
    final name = _trimmedName;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _create(name);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _celebrating = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      if (widget.onCreated != null) {
        widget.onCreated!();
        return;
      }
      // The server confirmed the family; continue after a bounded celebration.
      context.go('/scr-fat-002');
    } on CreateFamilyException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      revealOnboardingNotice(_scroll);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = const CreateFamilyException(AppErrorKind.network),
      );
      revealOnboardingNotice(_scroll);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Real-engine default: resolves the typed family-creation source from the
  /// app scope and fails closed when no real source is composed.
  Future<void> _createWithSource(String name) async {
    final copy = FoundationGateCopy.of(context);
    final source =
        AppScope.maybeOf(context)?.familyCreation ??
        const UnavailableFamilyCreationSource();
    if (_idempotencyKey == null || _submittedName != name) {
      _idempotencyKey = newFoundationGateIdempotencyKey();
      _submittedName = name;
    }
    final result = await source.create(
      displayName: name,
      idempotencyKey: _idempotencyKey!,
    );
    final failure = _failureFor(result, copy);
    if (failure != null) throw failure;
  }

  static CreateFamilyException? _failureFor(
    FamilyCreationResult result,
    FoundationGateCopy copy,
  ) {
    if (result.isCreated) return null;
    return switch (result.outcome) {
      FamilyCreationOutcome.created => throw StateError(
        'a created family is not a failure',
      ),
      FamilyCreationOutcome.validation => const CreateFamilyException(
        AppErrorKind.validation,
      ),
      FamilyCreationOutcome.networkUnavailable => const CreateFamilyException(
        AppErrorKind.network,
      ),
      FamilyCreationOutcome.unauthenticated => CreateFamilyException(
        AppErrorKind.network,
        title: copy.familyCreationSessionExpiredTitle,
        message: copy.familyCreationSessionExpiredMessage,
        requiresSignIn: true,
      ),
      FamilyCreationOutcome.denied => CreateFamilyException(
        AppErrorKind.network,
        title: copy.familyCreationDeniedTitle,
        message: copy.familyCreationDeniedMessage,
      ),
      FamilyCreationOutcome.conflict => CreateFamilyException(
        AppErrorKind.network,
        title: copy.familyCreationConflictTitle,
        message: copy.familyCreationConflictMessage,
      ),
      FamilyCreationOutcome.serviceUnavailable => CreateFamilyException(
        AppErrorKind.network,
        title: copy.familyCreationServiceUnavailableTitle,
        message: copy.familyCreationServiceUnavailableMessage,
      ),
      FamilyCreationOutcome.invalidResponse => CreateFamilyException(
        AppErrorKind.network,
        title: copy.familyCreationUnexpectedTitle,
        message: copy.familyCreationUnexpectedMessage,
      ),
      FamilyCreationOutcome.unavailable => CreateFamilyException(
        AppErrorKind.network,
        title: copy.familyCreationUnavailableTitle,
        message: copy.familyCreationUnavailableMessage,
      ),
    };
  }

  Future<void> _recoverSession() async {
    final recovered = await pushGuardianSessionRecovery(context);
    if (!mounted || recovered != true) return;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final copy = OnboardingCopy.of(context);
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final error = _error;

    if (_celebrating) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: PremiumCelebrationPanel(
            key: const Key('create_family_celebration'),
            title: copy.familyCreatedTitle,
            body: copy.familyCreatedBody,
            icon: Icons.family_restroom_rounded,
          ),
        ),
      );
    }

    return OnboardingScaffold(
      controller: _scroll,
      appBarTitle: '1 / 3',
      children: [
        OnboardingHeader(
          icon: Icons.family_restroom_rounded,
          title: copy.familyTitle,
          subtitle: copy.familySubtitle,
        ),
        if (error != null)
          OnboardingNotice(
            key: CreateFamilyKeys.error,
            tone: OnboardingNoticeTone.error,
            title: error.title ?? _kindTitle(l10n, error.kind),
            message: error.message ?? _kindMessage(l10n, error.kind),
            actionLabel: error.requiresSignIn
                ? copy.signInAgain
                : l10n.errorRetryCta,
            actionKey: CreateFamilyKeys.retry,
            onAction: _submitting
                ? null
                : (error.requiresSignIn ? _recoverSession : _submit),
          ),
        OnboardingTextField(
          fieldKey: CreateFamilyKeys.name,
          label: copy.familyNameLabel,
          controller: _name,
          hint: copy.familyNameHint,
          enabled: !_submitting,
          autofocus: true,
          maxLength: _maxNameLength,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          errorText: _touched ? _nameProblem(copy) : null,
          onChanged: (_) {
            if (!_touched && _trimmedName.isNotEmpty) _touched = true;
          },
          onSubmitted: (_) => _submit(),
        ),
        _WhatNextCard(
          title: copy.familyWhatNextTitle,
          items: [
            copy.familyWhatNext1,
            copy.familyWhatNext2,
            copy.familyWhatNext3,
          ],
          colors: colors,
        ),
        const SizedBox(height: 18),
        OnboardingSubmitButton(
          label: copy.familySubmit,
          busyLabel: copy.creatingFamily,
          busy: _submitting,
          onPressed: _nameProblem(copy) == null ? _submit : null,
          buttonKey: CreateFamilyKeys.submit,
        ),
      ],
    );
  }

  static String _kindTitle(AppLocalizations l10n, AppErrorKind kind) =>
      switch (kind) {
        AppErrorKind.network => l10n.errorNetworkTitle,
        AppErrorKind.timeout => l10n.errorTimeoutTitle,
        AppErrorKind.validation => l10n.errorValidationTitle,
        AppErrorKind.offline => l10n.errorOfflineTitle,
      };

  static String _kindMessage(AppLocalizations l10n, AppErrorKind kind) =>
      switch (kind) {
        AppErrorKind.network => l10n.errorNetworkMessage,
        AppErrorKind.timeout => l10n.errorTimeoutMessage,
        AppErrorKind.validation => l10n.errorValidationMessage,
        AppErrorKind.offline => l10n.errorOfflineMessage,
      };
}

class _WhatNextCard extends StatelessWidget {
  const _WhatNextCard({
    required this.title,
    required this.items,
    required this.colors,
  });

  final String title;
  final List<String> items;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.p100,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: colors.p700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[i],
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
