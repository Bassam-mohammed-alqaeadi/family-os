import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff205b4f)),
        useMaterial3: true,
      ),
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
    final copy = _GateCopy.of(context);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final copy = _GateCopy.of(context);
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
                FoundationGatePhase.loadingRoster => _LoadingState(label: copy.loadingRoster),
                FoundationGatePhase.childrenAvailable || FoundationGatePhase.noChildren => _ChildrenRoster(
                  family: widget.controller.selectedFamily!,
                  children: widget.controller.children,
                  isEmpty: phase == FoundationGatePhase.noChildren,
                  onChooseFamily: widget.controller.returnToFamilySelection,
                  onSignOut: widget.controller.signOut,
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
                FoundationGatePhase.rosterAccessDenied => _RosterIssueState(
                  message: copy.rosterAccessDenied,
                  onChooseFamily: widget.controller.returnToFamilySelection,
                  onSignOut: widget.controller.signOut,
                ),
                FoundationGatePhase.serviceUnavailable => _RosterIssueState(
                  message: copy.serviceUnavailable,
                  onRetry: widget.controller.selectedFamily == null ? null : widget.controller.retryRoster,
                  onChooseFamily: widget.controller.selectedFamily == null
                      ? null
                      : widget.controller.returnToFamilySelection,
                  onSignOut: widget.controller.signOut,
                ),
                FoundationGatePhase.networkUnavailable => _RosterIssueState(
                  message: copy.networkUnavailable,
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
    final copy = _GateCopy.of(context);
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
    final copy = _GateCopy.of(context);
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

class _ChildrenRoster extends StatelessWidget {
  const _ChildrenRoster({
    required this.family,
    required this.children,
    required this.isEmpty,
    required this.onChooseFamily,
    required this.onSignOut,
  });

  final FoundationGateFamily family;
  final List<FoundationGateChild> children;
  final bool isEmpty;
  final VoidCallback onChooseFamily;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final copy = _GateCopy.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          children: [
            _RosterContextCard(family: family),
            const SizedBox(height: 16),
            Text(copy.childrenTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(copy.rosterBoundary, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (isEmpty)
              _EmptyRosterCard()
            else
              ...children.map(
                (child) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ChildRosterCard(child: child),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onChooseFamily,
              icon: const Icon(Icons.swap_horiz),
              label: Text(copy.chooseAnotherFamily),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => unawaited(onSignOut()),
              child: Text(copy.signOut),
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterContextCard extends StatelessWidget {
  const _RosterContextCard({required this.family});

  final FoundationGateFamily family;

  @override
  Widget build(BuildContext context) {
    final copy = _GateCopy.of(context);
    final isCoGuardian = family.role == 'co_guardian';
    return Semantics(
      container: true,
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(copy.serverRosterCurrentSession, style: Theme.of(context).textTheme.labelLarge),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(family.displayName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(isCoGuardian ? copy.coGuardianReadOnly : copy.primaryGuardianRosterOnly),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildRosterCard extends StatelessWidget {
  const _ChildRosterCard({required this.child});

  final FoundationGateChild child;

  @override
  Widget build(BuildContext context) {
    final copy = _GateCopy.of(context);
    return Semantics(
      label: '${child.displayName}, ${copy.age(child.ageYears)}',
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            child: Icon(Icons.child_care_outlined, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(child.displayName),
          subtitle: Text(copy.age(child.ageYears)),
        ),
      ),
    );
  }
}

class _EmptyRosterCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final copy = _GateCopy.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.people_outline),
            const SizedBox(height: 12),
            Text(copy.emptyRosterTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(copy.emptyRosterBody),
          ],
        ),
      ),
    );
  }
}

class _RosterIssueState extends StatelessWidget {
  const _RosterIssueState({
    required this.message,
    required this.onSignOut,
    this.onRetry,
    this.onChooseFamily,
  });

  final String message;
  final Future<void> Function() onSignOut;
  final Future<void> Function()? onRetry;
  final VoidCallback? onChooseFamily;

  @override
  Widget build(BuildContext context) {
    final copy = _GateCopy.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(liveRegion: true, child: Text(message, textAlign: TextAlign.center)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => unawaited(onRetry!()),
                child: Text(copy.retry),
              ),
            ],
            if (onChooseFamily != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onChooseFamily,
                child: Text(copy.chooseAnotherFamily),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
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
    final copy = _GateCopy.of(context);
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

class _GateCopy {
  const _GateCopy._(this.isArabic);

  factory _GateCopy.of(BuildContext context) {
    return _GateCopy._(Localizations.localeOf(context).languageCode.toLowerCase() == 'ar');
  }

  final bool isArabic;

  String get appTitle => isArabic ? 'بوابة العائلة' : 'Family Gate';
  String get unconfigured => isArabic ? 'بوابة الأساس غير مهيأة.' : 'Foundation Gate is not configured.';
  String get signingIn => isArabic ? 'جارٍ التحقق من الوصول…' : 'Checking access…';
  String get loadingRoster => isArabic ? 'جارٍ تحميل سجل الأطفال من الخادم…' : 'Loading the server roster…';
  String get signInTitle => isArabic ? 'تسجيل دخول تجريبي' : 'Synthetic sign-in';
  String get syntheticOnly => isArabic
      ? 'هذا المسار مخصص لبيئة الاختبار الاصطناعية فقط.'
      : 'This flow is available only in the synthetic staging environment.';
  String get syntheticEmail => isArabic ? 'البريد التجريبي' : 'Synthetic email';
  String get syntheticPassword => isArabic ? 'كلمة المرور التجريبية' : 'Synthetic password';
  String get signInFailure => isArabic ? 'تعذر تسجيل الدخول.' : 'Sign-in is unavailable.';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'Sign in';
  String get signOut => isArabic ? 'تسجيل الخروج' : 'Sign out';
  String get chooseFamily => isArabic ? 'اختر العائلة' : 'Choose a family';
  String get chooseFamilyHint => isArabic
      ? 'يتم التحقق من الوصول من الخادم قبل عرض سجل الأطفال.'
      : 'The server verifies access before any children roster is shown.';
  String get childrenTitle => isArabic ? 'سجل الأطفال' : 'Children roster';
  String get serverRosterCurrentSession => isArabic
      ? 'سجل الخادم · الجلسة الحالية'
      : 'Server roster · current session';
  String get rosterBoundary => isArabic
      ? 'يعرض هذا السجل ملفات الأطفال فقط. حالة الأجهزة والسياسات غير متصلة في هذه الخطوة.'
      : 'This view shows child profiles only. Device and policy states are not connected in this slice.';
  String get primaryGuardianRosterOnly => isArabic
      ? 'عرض سجل فقط؛ الإضافة والتعديل غير متاحين هنا.'
      : 'Roster view only; creating or editing is not available here.';
  String get coGuardianReadOnly => isArabic
      ? 'عرض وصفي للوصي المشارك؛ لا يمنح هذا العرض صلاحية تعديل.'
      : 'Co-guardian read-only view; viewing does not grant edit authority.';
  String get noActiveFamily => isArabic ? 'لا توجد عائلة نشطة متاحة.' : 'No active family is available.';
  String get signInAgain => isArabic ? 'يرجى تسجيل الدخول مرة أخرى.' : 'Please sign in again.';
  String get accessDenied => isArabic ? 'الوصول غير متاح.' : 'Access is not available.';
  String get rosterAccessDenied => isArabic
      ? 'مركز تحكم الأطفال غير متاح لهذا الحساب.'
      : 'The children control centre is not available for this account.';
  String get serviceUnavailable => isArabic ? 'الخدمة غير متاحة مؤقتًا.' : 'Service is temporarily unavailable.';
  String get networkUnavailable => isArabic ? 'الاتصال غير متاح.' : 'Connection is unavailable.';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get chooseAnotherFamily => isArabic ? 'اختيار عائلة أخرى' : 'Choose another family';
  String get emptyRosterTitle => isArabic ? 'لم تُضف ملفات أطفال بعد' : 'No child profiles are set up yet';
  String get emptyRosterBody => isArabic
      ? 'لا تتوفر أي عملية إضافة من هذا المسار التجريبي للقراءة فقط.'
      : 'This read-only synthetic flow does not offer a child-creation action.';

  String displayRole(String role) {
    return switch (role) {
      'primary_guardian' => isArabic ? 'الوصي الأساسي' : 'Primary guardian',
      'co_guardian' => isArabic ? 'وصي مشارك' : 'Co-guardian',
      'child' => isArabic ? 'طفل' : 'Child',
      _ => isArabic ? 'دور غير متاح' : 'Role unavailable',
    };
  }

  String age(int ageYears) => isArabic ? 'العمر: $ageYears' : 'Age: $ageYears';
}
