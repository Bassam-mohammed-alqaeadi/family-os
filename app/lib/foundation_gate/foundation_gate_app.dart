import 'package:flutter/material.dart';

import 'foundation_gate_models.dart';
import 'foundation_gate_session_controller.dart';

/// Isolated composition root for the approved synthetic Foundation Gate.
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
    return const Scaffold(
      body: Center(
        child: Text('Foundation Gate is not configured.'),
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final phase = widget.controller.phase;
        return Scaffold(
          appBar: AppBar(title: const Text('Foundation Gate')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (phase) {
              FoundationGatePhase.signedOut || FoundationGatePhase.signInFailed => _SignInForm(
                emailController: _emailController,
                passwordController: _passwordController,
                submitting: false,
                showGenericFailure: phase == FoundationGatePhase.signInFailed,
                onSubmit: _submit,
              ),
              FoundationGatePhase.signingIn || FoundationGatePhase.loadingFamilies => const Center(
                child: CircularProgressIndicator(),
              ),
              FoundationGatePhase.familiesAvailable => _FamilySelection(
                families: widget.controller.families,
                selectedFamily: widget.controller.selectedFamily,
                onSelect: widget.controller.selectFamily,
                onSignOut: widget.controller.signOut,
              ),
              FoundationGatePhase.noActiveFamily => _MessageState(
                message: 'No active family is available.',
                onSignOut: widget.controller.signOut,
              ),
              FoundationGatePhase.sessionInvalid => _MessageState(
                message: 'Please sign in again.',
                onSignOut: widget.controller.signOut,
              ),
              FoundationGatePhase.accessDenied => _MessageState(
                message: 'Access is not available.',
                onSignOut: widget.controller.signOut,
              ),
              FoundationGatePhase.serviceUnavailable => _MessageState(
                message: 'Service is temporarily unavailable.',
                onSignOut: widget.controller.signOut,
              ),
              FoundationGatePhase.networkUnavailable => _MessageState(
                message: 'Connection is unavailable.',
                onSignOut: widget.controller.signOut,
              ),
              FoundationGatePhase.unconfigured => const _UnconfiguredFoundationGateScreen(),
            },
          ),
        );
      },
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: emailController,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Synthetic email'),
        ),
        TextField(
          controller: passwordController,
          autocorrect: false,
          enableSuggestions: false,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Synthetic password'),
        ),
        if (showGenericFailure) const Text('Sign-in is unavailable.'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: submitting ? null : onSubmit,
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}

class _FamilySelection extends StatelessWidget {
  const _FamilySelection({
    required this.families,
    required this.selectedFamily,
    required this.onSelect,
    required this.onSignOut,
  });

  final List<FoundationGateFamily> families;
  final FoundationGateFamily? selectedFamily;
  final ValueChanged<FoundationGateFamily> onSelect;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: families.length,
            itemBuilder: (context, index) {
              final family = families[index];
              return ListTile(
                title: Text(family.displayName),
                subtitle: Text(family.role),
                selected: selectedFamily?.id == family.id,
                onTap: () => onSelect(family),
              );
            },
          ),
        ),
        FilledButton.tonal(
          onPressed: onSignOut,
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.onSignOut});

  final String message;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onSignOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
