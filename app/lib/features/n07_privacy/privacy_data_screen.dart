import 'package:flutter/material.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/collection_scope.dart';
import 'package:family_os/core/policy/family_data_lifecycle.dart';
import 'package:family_os/core/policy/privacy_collection_policy.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';
import 'package:family_os/core/policy/privacy_collection_sync_bus.dart';
import 'package:family_os/features/n07_privacy/audit_log_panel.dart';

/// Widget keys for SCR-FAT-059 / SET-012 + SET-013 acceptance.
abstract final class PrivacyDataKeys {
  static const retentionBanner = Key('privacy_retention_banner');
  static const save = Key('privacy_collection_save');
  static const readOnlyBanner = Key('privacy_collection_readonly_banner');
  static const forgetButton = Key('privacy_forget_button');
  static const wipeButton = Key('privacy_wipe_button');
  static const wipeCancelButton = Key('privacy_wipe_cancel_button');
  static const wipePendingBanner = Key('privacy_wipe_pending_banner');
  static const forgetConfirmDialog = Key('privacy_forget_confirm_dialog');
  static const forgetConfirmAction = Key('privacy_forget_confirm_action');
  static const wipeStep1Dialog = Key('privacy_wipe_step1_dialog');
  static const wipeStep1Continue = Key('privacy_wipe_step1_continue');
  static const wipeStep2Dialog = Key('privacy_wipe_step2_dialog');
  static const wipeStep2Field = Key('privacy_wipe_step2_field');
  static const wipeStep2Action = Key('privacy_wipe_step2_action');

  static Key scopeSwitch(CollectionScope scope) =>
      Key('privacy_scope_switch_${scope.key}');
}

/// SCR-FAT-059 — الخصوصية والبيانات (SET-012 scopes + SET-013 forget≠wipe).
///
/// Father OWNER toggles lean scopes; mother may view read-only; child blocked
/// by RoleGuard. Forget = advisor memory only (single confirm). Wipe = two-step
/// + 7-day regret (R10 audit never wiped).
class PrivacyDataScreen extends StatefulWidget {
  const PrivacyDataScreen({
    super.key,
    this.childId,
    this.repository,
    this.syncBus,
    this.canEditOverride,
    this.lifecycle,
    this.canLifecycleOverride,
  });

  /// Stage-1 demo child when null.
  final ChildId? childId;

  /// Rule 25 seam — null → prefs-backed Stage-1 store.
  final PrivacyCollectionRepository? repository;

  /// P12 sync — null → [stage1PrivacyCollectionSyncBus].
  final PrivacyCollectionSyncBus? syncBus;

  /// Test seam — when null, only father may edit scopes.
  final bool? canEditOverride;

  /// SET-013 lifecycle seam — null → [stage1FamilyDataLifecycle].
  final FamilyDataLifecycleService? lifecycle;

  /// Test seam — when null, only father may forget/wipe.
  final bool? canLifecycleOverride;

  @override
  State<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends State<PrivacyDataScreen> {
  late final ChildId _childId;
  late final PrivacyCollectionRepository _repository;
  late final PrivacyCollectionSyncBus _syncBus;
  late final FamilyDataLifecycleService _lifecycle;
  late PrivacyCollectionPolicy _policy;
  var _loading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _childId = widget.childId ?? ChildId('demo-child');
    _repository = widget.repository ??
        PrefsPrivacyCollectionRepository(
          stage1PrivacyCollectionPrefsStore,
          audit: stage1PrivacyCollectionAudit,
        );
    _syncBus = widget.syncBus ?? stage1PrivacyCollectionSyncBus;
    _lifecycle = widget.lifecycle ?? stage1FamilyDataLifecycle;
    _lifecycle.addListener(_onLifecycle);
    _policy = PrivacyCollectionPolicy.defaults(childId: _childId.value);
    _load();
  }

  @override
  void dispose() {
    _lifecycle.removeListener(_onLifecycle);
    super.dispose();
  }

  void _onLifecycle() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final loaded = await _repository.load(_childId.value);
    if (!mounted) return;
    _syncBus.hydrate(loaded);
    setState(() {
      _policy = loaded;
      _loading = false;
    });
  }

  AppRole get _role =>
      CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;

  bool get _canEdit {
    if (widget.canEditOverride != null) return widget.canEditOverride!;
    return canEditPrivacyCollection(_role);
  }

  bool get _canLifecycle {
    if (widget.canLifecycleOverride != null) {
      return widget.canLifecycleOverride!;
    }
    return canRunFamilyDataLifecycle(_role);
  }

  bool get _canSave => _canEdit && !_saving && !_loading;

  void _onToggle(CollectionScope scope, bool enabled) {
    if (!_canEdit) return;
    setState(() => _policy = _policy.withScope(scope, enabled));
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final result = await _repository.save(
      _policy.copyWith(updatedAt: DateTime.now().toUtc()),
      actor: _role,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case PrivacyCollectionWriteOk(:final policy):
        setState(() => _policy = policy);
        _syncBus.publish(policy);
        AppToast.show(
          context,
          message: AppLocalizations.of(context).privacyDataSaveToast,
        );
      case PrivacyCollectionWriteDenied():
        AppToast.show(
          context,
          message: AppLocalizations.of(context).privacyDataWriteDenied,
        );
    }
  }

  String _scopeLabel(AppLocalizations l10n, CollectionScope scope) {
    return switch (scope) {
      CollectionScope.location => l10n.privacyScopeLocation,
      CollectionScope.screenTime => l10n.privacyScopeScreenTime,
      CollectionScope.webActivity => l10n.privacyScopeWebActivity,
      CollectionScope.communications => l10n.privacyScopeCommunications,
    };
  }

  Future<void> _onForgetPressed() async {
    if (!_canLifecycle) {
      AppToast.show(
        context,
        message: AppLocalizations.of(context).privacyLifecycleDeniedToast,
      );
      return;
    }
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: PrivacyDataKeys.forgetConfirmDialog,
        title: Text(l10n.privacyForgetConfirmTitle),
        content: Text(l10n.privacyForgetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.privacyDialogCancel),
          ),
          TextButton(
            key: PrivacyDataKeys.forgetConfirmAction,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.privacyForgetConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await _lifecycle.forgetAdvisorMemory(actor: _role);
    if (!mounted) return;
    switch (result) {
      case ForgetOk():
        AppToast.show(context, message: l10n.privacyForgetToast);
      case ForgetDenied():
        AppToast.show(context, message: l10n.privacyLifecycleDeniedToast);
    }
  }

  Future<void> _onWipePressed() async {
    if (!_canLifecycle) {
      AppToast.show(
        context,
        message: AppLocalizations.of(context).privacyLifecycleDeniedToast,
      );
      return;
    }
    final l10n = AppLocalizations.of(context);

    // Step 1 — explain regret window.
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: PrivacyDataKeys.wipeStep1Dialog,
        title: Text(l10n.privacyWipeStep1Title),
        content: Text(l10n.privacyWipeStep1Body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.privacyDialogCancel),
          ),
          TextButton(
            key: PrivacyDataKeys.wipeStep1Continue,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.privacyWipeStep1Continue),
          ),
        ],
      ),
    );
    if (step1 != true || !mounted) return;

    // Step 2 — type confirm phrase.
    final phrase = l10n.privacyWipeConfirmPhrase;
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => _WipeStep2Dialog(
        phrase: phrase,
        title: l10n.privacyWipeStep2Title,
        body: l10n.privacyWipeStep2Body(phrase),
        cancelLabel: l10n.privacyDialogCancel,
        confirmLabel: l10n.privacyWipeStep2Action,
      ),
    );
    if (step2 != true || !mounted) return;

    final result = await _lifecycle.scheduleWipe(actor: _role);
    if (!mounted) return;
    switch (result) {
      case WipeScheduleOk():
      case WipeAlreadyPending():
        AppToast.show(context, message: l10n.privacyWipeScheduledToast);
      case WipeScheduleDenied():
        AppToast.show(context, message: l10n.privacyLifecycleDeniedToast);
    }
  }

  Future<void> _onCancelWipe() async {
    if (!_canLifecycle) {
      AppToast.show(
        context,
        message: AppLocalizations.of(context).privacyLifecycleDeniedToast,
      );
      return;
    }
    final l10n = AppLocalizations.of(context);
    final result = await _lifecycle.cancelWipe(actor: _role);
    if (!mounted) return;
    switch (result) {
      case WipeCancelOk():
        AppToast.show(context, message: l10n.privacyWipeCancelledToast);
      case WipeCancelDenied():
        AppToast.show(context, message: l10n.privacyLifecycleDeniedToast);
      case WipeCancelNone():
      case WipeCancelWindowExpired():
        break;
    }
  }

  String _formatPendingUntil(DateTime when) {
    final local = when.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final pending = _lifecycle.pendingWipe;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.privacyDataTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Text(
                    l10n.privacyDataSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.ink2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  BannerNote(
                    key: PrivacyDataKeys.retentionBanner,
                    message: l10n.privacyDataRetentionNote,
                    variant: BannerVariant.a,
                  ),
                  if (!_canEdit) ...[
                    const SizedBox(height: 12),
                    BannerNote(
                      key: PrivacyDataKeys.readOnlyBanner,
                      message: l10n.privacyDataReadOnlyNote,
                      variant: BannerVariant.t,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    l10n.privacyDataScopesHeading,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final scope in kLeanCollectionScopes)
                    SwitchListTile(
                      key: PrivacyDataKeys.scopeSwitch(scope),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _scopeLabel(l10n, scope),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                        ),
                      ),
                      value: _policy.isEnabled(scope),
                      onChanged: _canEdit
                          ? (v) => _onToggle(scope, v)
                          : null,
                    ),
                  const SizedBox(height: 24),
                  if (_canEdit)
                    PrimaryBtn(
                      key: PrivacyDataKeys.save,
                      label: l10n.privacyDataSave,
                      onPressed: _canSave ? _save : null,
                    ),
                  if (_canLifecycle) ...[
                    const SizedBox(height: 28),
                    Text(
                      l10n.privacyLifecycleHeading,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryBtn(
                      key: PrivacyDataKeys.forgetButton,
                      label: l10n.privacyForgetButton,
                      variant: PrimaryBtnVariant.sec,
                      onPressed: _onForgetPressed,
                    ),
                    const SizedBox(height: 10),
                    PrimaryBtn(
                      key: PrivacyDataKeys.wipeButton,
                      label: l10n.privacyWipeButton,
                      variant: PrimaryBtnVariant.coral,
                      onPressed: pending == null ? _onWipePressed : null,
                    ),
                    if (pending != null) ...[
                      const SizedBox(height: 12),
                      BannerNote(
                        key: PrivacyDataKeys.wipePendingBanner,
                        message: l10n.privacyWipePendingBanner(
                          _formatPendingUntil(pending.pendingUntil),
                        ),
                        variant: BannerVariant.t,
                      ),
                      const SizedBox(height: 10),
                      PrimaryBtn(
                        key: PrivacyDataKeys.wipeCancelButton,
                        label: l10n.privacyWipeCancelButton,
                        variant: PrimaryBtnVariant.ghost,
                        onPressed: _onCancelWipe,
                      ),
                    ],
                  ],
                  const SizedBox(height: 28),
                  AuditLogPanel(audit: _lifecycle.audit),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Step-2 wipe confirm — owns [TextEditingController] for safe dispose.
class _WipeStep2Dialog extends StatefulWidget {
  const _WipeStep2Dialog({
    required this.phrase,
    required this.title,
    required this.body,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final String phrase;
  final String title;
  final String body;
  final String cancelLabel;
  final String confirmLabel;

  @override
  State<_WipeStep2Dialog> createState() => _WipeStep2DialogState();
}

class _WipeStep2DialogState extends State<_WipeStep2Dialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _matches => _controller.text.trim() == widget.phrase;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: PrivacyDataKeys.wipeStep2Dialog,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.body),
          const SizedBox(height: 12),
          TextField(
            key: PrivacyDataKeys.wipeStep2Field,
            controller: _controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: widget.phrase,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel),
        ),
        TextButton(
          key: PrivacyDataKeys.wipeStep2Action,
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
