import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:family_os/core/design/tokens.dart';

import 'children_control_centre.dart';
import 'foundation_gate_copy.dart';
import 'foundation_gate_models.dart';
import 'foundation_gate_session_controller.dart';

/// Isolated composition root for the approved Foundation Gate vertical slice.
///
/// It deliberately has no dependency on the legacy mock-first application,
/// local persistence, telemetry or token storage. A configured controller is
/// supplied only by a local ignored bootstrap after separate approval.
class FoundationGateApp extends StatelessWidget {
  const FoundationGateApp({super.key, this.controller});

  final FoundationGateSessionController? controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: buildFamilyTheme(),
      home: controller == null
          ? const _UnconfiguredFoundationGateScreen()
          : _FoundationGateSessionScreen(controller: controller!),
    );
  }
}

class _UnconfiguredFoundationGateScreen extends StatelessWidget {
  const _UnconfiguredFoundationGateScreen();

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            label: copy.unconfigured,
            child: Text(copy.unconfigured, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class _FoundationGateSessionScreen extends StatefulWidget {
  const _FoundationGateSessionScreen({required this.controller});

  final FoundationGateSessionController controller;

  @override
  State<_FoundationGateSessionScreen> createState() => _FoundationGateSessionScreenState();
}

class _FoundationGateSessionScreenState extends State<_FoundationGateSessionScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _clearForm();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    _clearForm();
    await widget.controller.signIn(email: email, password: password);
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
  }

  bool get _mayOfferCreateChild => widget.controller.selectedFamily?.role == 'primary_guardian';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final copy = FoundationGateCopy.of(context);
        final phase = widget.controller.phase;
        return Scaffold(
          appBar: AppBar(title: Text(copy.appTitle)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: switch (phase) {
                FoundationGatePhase.signedOut || FoundationGatePhase.signInFailed => _SignInForm(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  submitting: false,
                  showGenericFailure: phase == FoundationGatePhase.signInFailed,
                  onSubmit: _submit,
                ),
                FoundationGatePhase.signingIn || FoundationGatePhase.loadingFamilies => _LoadingState(
                  label: copy.signingIn,
                ),
                FoundationGatePhase.familiesAvailable => _FamilySelection(
                  families: widget.controller.families,
                  onSelect: widget.controller.selectFamily,
                  onSignOut: widget.controller.signOut,
                ),
                FoundationGatePhase.loadingRoster => ChildrenControlCentre(
                  status: ChildrenControlCentreStatus.loading,
                  family: widget.controller.selectedFamily,
                  onChooseFamily: widget.controller.returnToFamilySelection,
                  onSignOut: widget.controller.signOut,
                ),
                FoundationGatePhase.childrenAvailable || FoundationGatePhase.noChildren => ChildrenControlCentre(
                  status: phase == FoundationGatePhase.childrenAvailable
                      ? ChildrenControlCentreStatus.ready
                      : ChildrenControlCentreStatus.empty,
                  family: widget.controller.selectedFamily,
                  children: widget.controller.children,
                  onChooseFamily: widget.controller.returnToFamilySelection,
                  onSignOut: widget.controller.signOut,
                  onCreateChild: _mayOfferCreateChild ? widget.controller.createChild : null,
                  isCreatingChild: widget.controller.isCreatingChild,
                ),
                FoundationGatePhase.noActiveFamily => _MessageState(
                  message: copy.noActiveFamily,
                  onSignOut: widget.controller.signOut,
                ),
                FoundationGatePhase.sessionInvalid => _MessageState(
                  message: copy.signInAgain,
                  onSignOut: widget.controller.signOut,
                ),
                FoundationGatePhase.accessDenied => _MessageState(
                  message: copy.accessDenied,
                  onSignOut: widget.controller.signOut,
                ),
                FoundationGatePhase.rosterAccessDenied => ChildrenControlCentre(
                  status: ChildrenControlCentreStatus.accessDenied,
                  onChooseFamily: widget.controller.returnToFamilySelection,
                  onSignOut: widget.controller.signOut,
                ),
                FoundationGatePhase.serviceUnavailable => ChildrenControlCentre(
                  status: ChildrenControlCentreStatus.unavailable,
                  family: widget.controller.selectedFamily,
                  onRetry: widget.controller.selectedFamily == null ? null : widget.controller.retryRoster,
                  onChooseFamily: widget.controller.selectedFamily == null
                      ? null
                      : widget.controller.returnToFamilySelection,
                  onSignOut: widget.controller.signOut,
                ),
                FoundationGatePhase.networkUnavailable => ChildrenControlCentre(
                  status: ChildrenControlCentreStatus.networkUnavailable,
                  family: widget.controller.selectedFamily,
                  onRetry: widget.controller.selectedFamily == null ? null : widget.controller.retryRoster,
                  onChooseFamily: widget.controller.selectedFamily == null
                      ? null
                      : widget.controller.returnToFamilySelection,
                  onSignOut: widget.controller.signOut,
                ),
                FoundationGatePhase.unconfigured => const _UnconfiguredFoundationGateScreen(),
              },
            ),
          ),
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label,
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm({
    required this.emailController,
    required this.passwordController,
    required this.submitting,
    required this.showGenericFailure,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool submitting;
  final bool showGenericFailure;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(copy.signInTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(copy.syntheticOnly, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: copy.syntheticEmail),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              autocorrect: false,
              enableSuggestions: false,
              obscureText: true,
              decoration: InputDecoration(labelText: copy.syntheticPassword),
            ),
            if (showGenericFailure) ...[
              const SizedBox(height: 16),
              Semantics(liveRegion: true, child: Text(copy.signInFailure)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: submitting ? null : () => unawaited(onSubmit()),
              child: Text(copy.signIn),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilySelection extends StatelessWidget {
  const _FamilySelection({
    required this.families,
    required this.onSelect,
    required this.onSignOut,
  });

  final List<FoundationGateFamily> families;
  final Future<void> Function(FoundationGateFamily) onSelect;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(copy.chooseFamily, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(copy.chooseFamilyHint, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: families.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final family = families[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: const Icon(Icons.family_restroom_outlined),
                      title: Text(family.displayName),
                      subtitle: Text(copy.displayRole(family.role)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => unawaited(onSelect(family)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => unawaited(onSignOut()),
              child: Text(copy.signOut),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.onSignOut});

  final String message;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationGateCopy.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(liveRegion: true, child: Text(message, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => unawaited(onSignOut()),
            child: Text(copy.signOut),
          ),
        ],
      ),
    );
  }
}
