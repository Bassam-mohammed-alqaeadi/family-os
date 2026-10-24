// Per-app and per-category guardian decisions, opened on demand (SCR-FAT-032 · polish wave).
//
// This is a sheet rather than more cards on the panel for one reason that is measured, not
// stylistic: the panel's contract is that it loads with exactly one read — `GET …/screen-time`
// — and every test around it counts those calls. An app list is a second read, and a category
// budget is a third. Opening them on demand keeps the panel honest and fast, and it puts the
// work where the parent asked for it.
//
// What the server already answers for is written through the same authority the panel uses;
// what it does not answer for yet — a daily budget per category — travels through
// `ScreenTimePolicyExtensionSource`, and while no route is bound it says so in the sheet's own
// words instead of saving something to memory and calling it a setting.
import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/app_loading_state.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/screen_time_panel_contracts.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';

/// Opens the app-rules surface for one child.
///
/// [authority] null means "no session bound": the sheet still opens, still reads well, and
/// writes nothing — the same rule the panel follows when there is nobody to ask.
Future<void> showScreenTimeAppRulesSheet(
  BuildContext context, {
  required ScreenTimeServerAuthority? authority,
  required String childId,
  required bool canEdit,
  required String Function() idempotencyKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _AppRulesSheet(
      authority: authority,
      childId: childId,
      canEdit: canEdit,
      idempotencyKey: idempotencyKey,
    ),
  );
}

/// The five category names a guardian thinks in, all from the ARB.
///
/// The server's wire string is what decides which of the five an app falls into, and an
/// unknown string becomes `other` rather than a category this build invented — a category a
/// phone does not report is a rule that would never match anything.
String screenTimeCategoryLabel(
  AppLocalizations l10n,
  ScreenTimeAppCategory category,
) => switch (category) {
  ScreenTimeAppCategory.games => l10n.screenTimeServerCategoryGames,
  ScreenTimeAppCategory.social => l10n.screenTimeServerCategorySocial,
  ScreenTimeAppCategory.video => l10n.screenTimeServerCategoryVideo,
  ScreenTimeAppCategory.education => l10n.screenTimeServerCategoryEducation,
  ScreenTimeAppCategory.other => l10n.screenTimeServerCategoryOther,
};

/// The sentence for an extension status, in the panel's own vocabulary.
///
/// Shared with the panel on purpose: an unavailable contract must read the same way twice, or
/// a parent starts wondering which of the two screens is the one that lied.
String screenTimeExtensionStatusLabel(
  AppLocalizations l10n,
  ScreenTimeExtensionStatus status,
) => switch (status) {
  ScreenTimeExtensionStatus.ready => l10n.screenTimeServerCategoryBudgetPending,
  ScreenTimeExtensionStatus.notConfigured =>
    l10n.screenTimeServerCategoryBudgetPending,
  ScreenTimeExtensionStatus.accessDenied => l10n.screenTimeServerAppsDenied,
  ScreenTimeExtensionStatus.unreachable => l10n.screenTimeServerAppsStale,
  ScreenTimeExtensionStatus.refused => l10n.screenTimeServerAppSaveError,
};

class _AppRulesSheet extends StatefulWidget {
  const _AppRulesSheet({
    required this.authority,
    required this.childId,
    required this.canEdit,
    required this.idempotencyKey,
  });

  final ScreenTimeServerAuthority? authority;
  final String childId;
  final bool canEdit;
  final String Function() idempotencyKey;

  @override
  State<_AppRulesSheet> createState() => _AppRulesSheetState();
}

class _AppRulesSheetState extends State<_AppRulesSheet> {
  var _loading = true;
  List<FoundationGateChildApp> _apps = const [];
  ScreenTimeAuthorityStatus? _appsStatus;
  ScreenTimeExtensionStatus? _extensionStatus;
  Map<ScreenTimeAppCategory, ScreenTimeCategoryBudget> _budgets = const {};
  final Map<ScreenTimeAppCategory, TextEditingController> _budgetControllers =
      {};
  final Map<String, TextEditingController> _limitControllers = {};

  /// The app whose expansion is open, so one write cannot silently fold five rows shut.
  String? _openAppId;
  String? _note;
  String? _busyAppId;
  var _busy = false;

  bool get _editable => widget.canEdit && !_busy;

  @override
  void initState() {
    super.initState();
    // Nothing here runs before the parent opens the sheet — that is the whole reason this is
    // a sheet. The read is the first thing, and it is the only one.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final controller in _limitControllers.values) {
      controller.dispose();
    }
    for (final controller in _budgetControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final authority = widget.authority;
    if (authority == null) {
      setState(() {
        _loading = false;
        _appsStatus = ScreenTimeAuthorityStatus.notConfigured;
      });
      return;
    }
    final apps = await authority.apps(widget.childId);
    final extension = await screenTimePolicyExtensionSource.read(
      widget.childId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _appsStatus = apps.status;
      final value = apps.value;
      if (value != null) _apps = value;
      _extensionStatus = extension.status;
      final read = extension.value;
      if (read != null) {
        _budgets = Map<ScreenTimeAppCategory, ScreenTimeCategoryBudget>.of(
          read.categoryBudgets,
        );
        for (final entry in _budgets.entries) {
          _controllerFor(entry.key).text = '${entry.value.minutes}';
        }
      }
    });
  }

  TextEditingController _controllerFor(ScreenTimeAppCategory category) =>
      _budgetControllers.putIfAbsent(
        category,
        () => TextEditingController(),
      );

  TextEditingController _limitControllerFor(String appId) =>
      _limitControllers.putIfAbsent(appId, () => TextEditingController());

  void _say(String message) {
    if (!mounted) return;
    setState(() => _note = message);
  }

  Future<void> _setRule(
    FoundationGateChildApp app, {
    required FoundationGateAppRuleStatus status,
    int? limitMinutes,
    bool unlimited = false,
  }) async {
    final authority = widget.authority;
    if (authority == null || _busy) return;
    setState(() {
      _busy = true;
      _busyAppId = app.appId;
      _note = null;
    });
    final answer = await authority.writeAppRule(
      widget.childId,
      appId: app.appId,
      status: status,
      limitMinutes: limitMinutes,
      unlimited: unlimited,
      idempotencyKey: widget.idempotencyKey,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _busyAppId = null;
      if (!answer.isReady) {
        _note = screenTimeAppRuleFailureLabel(AppLocalizations.of(context), answer.status);
      }
    });
    // The list is re-read rather than edited in place: the row should show the rule the
    // server now stores, at the version it stores it at.
    await _load();
  }

  Future<void> _applyToCategory(
    ScreenTimeAppCategory category, {
    required bool blocked,
  }) async {
    final authority = widget.authority;
    if (authority == null || _busy) return;
    final targets = _apps
        .where((app) => _categoryOf(app) == category)
        .toList(growable: false);
    if (targets.isEmpty) {
      _say(AppLocalizations.of(context).screenTimeServerAppsEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _note = null;
    });
    var written = 0;
    var refused = 0;
    for (final app in targets) {
      final answer = await authority.writeAppRule(
        widget.childId,
        appId: app.appId,
        status: blocked
            ? FoundationGateAppRuleStatus.blocked
            : FoundationGateAppRuleStatus.allowed,
        unlimited: !blocked,
        idempotencyKey: widget.idempotencyKey,
      );
      if (answer.isReady) {
        written++;
      } else {
        refused++;
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      final l10n = AppLocalizations.of(context);
      _note = refused > 0
          ? '${l10n.screenTimeServerAppSaveError} · ${l10n.screenTimeServerCategoryApplied(written)}'
          : l10n.screenTimeServerCategoryApplied(written);
    });
    await _load();
  }

  Future<void> _saveBudget(ScreenTimeAppCategory category) async {
    final l10n = AppLocalizations.of(context);
    final parsed = int.tryParse(_controllerFor(category).text.trim());
    if (parsed == null || parsed < 0 || parsed > 1440) {
      _say(l10n.screenTimeServerExtensionCustomInvalid);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final budgets = Map<ScreenTimeAppCategory, ScreenTimeCategoryBudget>.of(
      _budgets,
    );
    budgets[category] = ScreenTimeCategoryBudget(
      category: category,
      minutes: parsed,
      enabled: true,
    );
    final answer = await screenTimePolicyExtensionSource.write(
      widget.childId,
      policyExtension: ScreenTimePolicyExtension(categoryBudgets: budgets),
      idempotencyKey: widget.idempotencyKey,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _note = answer.isReady
          ? l10n.screenTimeServerCategoryApplied(parsed)
          : screenTimeExtensionStatusLabel(l10n, answer.status);
    });
    await _load();
  }

  ScreenTimeAppCategory _categoryOf(FoundationGateChildApp app) =>
      ScreenTimeAppCategory.fromWire(app.category);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final status = _appsStatus;
    final groups = <ScreenTimeAppCategory, List<FoundationGateChildApp>>{};
    for (final app in _apps) {
      groups.putIfAbsent(_categoryOf(app), () => <FoundationGateChildApp>[]).add(
        app,
      );
    }
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (sheetContext, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
            child: Row(
              children: [
                Icon(Icons.apps, size: 18, color: colors.p600),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.screenTimeServerAppsTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: colors.ink,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.screenTimeServerAppsSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('screen_time_server_apps_close'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: l10n.screenTimeServerAppsClose,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                if (_loading)
                  AppLoadingState(message: l10n.screenTimeServerAppsLoading)
                else if (status == ScreenTimeAuthorityStatus.notConfigured)
                  _Notice(
                    key: const Key('screen_time_server_apps_no_session'),
                    label: l10n.screenTimeServerAppsNoSession,
                    radius: radii.banner,
                  )
                else if (status == ScreenTimeAuthorityStatus.accessDenied)
                  _Notice(
                    key: const Key('screen_time_server_apps_denied'),
                    label: l10n.screenTimeServerAppsDenied,
                    radius: radii.banner,
                  )
                else if (status != null && status != ScreenTimeAuthorityStatus.ready)
                  AppErrorState(
                    key: const Key('screen_time_server_apps_stale'),
                    kind: AppErrorKind.network,
                    message: l10n.screenTimeServerAppsStale,
                    onRetry: _busy ? null : _load,
                  )
                else ...[
                  _CategoryRules(
                    groups: groups,
                    budgets: _budgets,
                    controllers: _budgetControllers,
                    editable: _editable,
                    extensionStatus: _extensionStatus,
                    onBlock: (category) =>
                        _applyToCategory(category, blocked: true),
                    onAllow: (category) =>
                        _applyToCategory(category, blocked: false),
                    onSaveBudget: _saveBudget,
                  ),
                  const SizedBox(height: 12),
                  if (_apps.isEmpty)
                    AppEmptyState(
                      key: const Key('screen_time_server_apps_empty'),
                      title: l10n.screenTimeServerAppsEmpty,
                    )
                  else
                    for (final app in _apps)
                      _AppRuleRow(
                        key: Key('screen_time_server_app_row_${app.appId}'),
                        app: app,
                        categoryLabel: screenTimeCategoryLabel(
                          l10n,
                          _categoryOf(app),
                        ),
                        open: _openAppId == app.appId,
                        busy: _busyAppId == app.appId,
                        editable: _editable,
                        controller: _limitControllerFor(app.appId),
                        onToggleOpen: () => setState(() {
                          _openAppId = _openAppId == app.appId
                              ? null
                              : app.appId;
                        }),
                        onAllow: () => _setRule(
                          app,
                          status: FoundationGateAppRuleStatus.allowed,
                          unlimited: true,
                        ),
                        onBlock: () =>
                            _setRule(app, status: FoundationGateAppRuleStatus.blocked),
                        onLimit: () {
                          final minutes =
                              int.tryParse(
                                _limitControllerFor(app.appId).text.trim(),
                              ) ??
                              0;
                          _setRule(
                            app,
                            status: FoundationGateAppRuleStatus.allowed,
                            limitMinutes: minutes <= 0 ? null : minutes,
                            unlimited: minutes <= 0,
                          );
                        },
                      ),
                ],
                if (_note != null) ...[
                  const SizedBox(height: 12),
                  _Notice(
                    key: const Key('screen_time_server_apps_note'),
                    label: _note!,
                    radius: radii.banner,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The copy for a rejected rule write, shared by the sheet and the panel.
String screenTimeAppRuleFailureLabel(
  AppLocalizations l10n,
  ScreenTimeAuthorityStatus status,
) => switch (status) {
  ScreenTimeAuthorityStatus.accessDenied => l10n.screenTimeServerAppsDenied,
  ScreenTimeAuthorityStatus.refused => l10n.screenTimeServerAppSaveError,
  ScreenTimeAuthorityStatus.unreachable => l10n.screenTimeServerAppsStale,
  ScreenTimeAuthorityStatus.notConfigured ||
  ScreenTimeAuthorityStatus.ready => l10n.screenTimeServerAppSaveError,
};

/// What the family decided about one app, in words a parent reads, not an enum.
String screenTimeAppRuleStatusLabel(
  AppLocalizations l10n,
  FoundationGateChildApp app,
) {
  final rule = app.rule;
  if (rule == null) {
    return app.decision.allowed
        ? l10n.screenTimeServerAppStateAllowed
        : l10n.screenTimeServerAppStateBlocked;
  }
  return switch (rule.status) {
    FoundationGateAppRuleStatus.blocked => l10n.screenTimeServerAppStateBlocked,
    FoundationGateAppRuleStatus.pending => l10n.screenTimeServerAppPending,
    FoundationGateAppRuleStatus.free => l10n.screenTimeServerAppFree,
    FoundationGateAppRuleStatus.allowed =>
      rule.unlimited || (rule.limitMinutes ?? 0) <= 0
      ? l10n.screenTimeServerAppFree
      : l10n.screenTimeServerAppLimitValue(rule.limitMinutes!),
  };
}

class _CategoryRules extends StatelessWidget {
  const _CategoryRules({
    required this.groups,
    required this.budgets,
    required this.controllers,
    required this.editable,
    required this.extensionStatus,
    required this.onBlock,
    required this.onAllow,
    required this.onSaveBudget,
  });

  final Map<ScreenTimeAppCategory, List<FoundationGateChildApp>> groups;
  final Map<ScreenTimeAppCategory, ScreenTimeCategoryBudget> budgets;
  final Map<ScreenTimeAppCategory, TextEditingController> controllers;
  final bool editable;
  final ScreenTimeExtensionStatus? extensionStatus;
  final void Function(ScreenTimeAppCategory category) onBlock;
  final void Function(ScreenTimeAppCategory category) onAllow;
  final void Function(ScreenTimeAppCategory category) onSaveBudget;

  static const _order = [
    ScreenTimeAppCategory.games,
    ScreenTimeAppCategory.social,
    ScreenTimeAppCategory.video,
    ScreenTimeAppCategory.education,
    ScreenTimeAppCategory.other,
  ];

  ScreenTimeCategoryBudget? _stored(ScreenTimeAppCategory category) {
    final budget = budgets[category];
    if (budget == null) return null;
    // The server storing a budget and the server answering with it are the same thing here:
    // `extensionStatus` is the proof, and without it a number in a field is not a limit.
    return extensionStatus == ScreenTimeExtensionStatus.ready ? budget : null;
  }

  String _budgetLine(AppLocalizations l10n, ScreenTimeAppCategory category) {
    final stored = _stored(category);
    if (stored == null) return l10n.screenTimeServerCategoryBudgetPending;
    return l10n.screenTimeServerCategoryApplied(stored.minutes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final category in _order)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.tcard),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            screenTimeCategoryLabel(l10n, category),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: colors.ink,
                              height: 1.3,
                            ),
                          ),
                        ),
                        Text(
                          '${groups[category]?.length ?? 0}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: colors.ink2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: [
                        OutlinedButton(
                          key: Key(
                            'screen_time_server_category_block_${category.wire}',
                          ),
                          onPressed: editable ? () => onBlock(category) : null,
                          child: Text(l10n.screenTimeServerCategoryBlockAll),
                        ),
                        OutlinedButton(
                          key: Key(
                            'screen_time_server_category_allow_${category.wire}',
                          ),
                          onPressed: editable ? () => onAllow(category) : null,
                          child: Text(l10n.screenTimeServerCategoryAllowAll),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            key: Key(
                              'screen_time_server_category_budget_${category.wire}',
                            ),
                            controller: controllers[category],
                            enabled: editable,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.screenTimeServerCategoryBudget,
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        PrimaryBtn(
                          key: Key(
                            'screen_time_server_category_budget_save_${category.wire}',
                          ),
                          fullWidth: false,
                          label: l10n.screenTimeServerSave,
                          variant: PrimaryBtnVariant.sec,
                          onPressed: editable
                              ? () => onSaveBudget(category)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _budgetLine(l10n, category),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _stored(category) != null
                            ? colors.tealDeep
                            : colors.amberDeep,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AppRuleRow extends StatelessWidget {
  const _AppRuleRow({
    super.key,
    required this.app,
    required this.categoryLabel,
    required this.open,
    required this.busy,
    required this.editable,
    required this.controller,
    required this.onToggleOpen,
    required this.onAllow,
    required this.onBlock,
    required this.onLimit,
  });

  final FoundationGateChildApp app;
  final String categoryLabel;
  final bool open;
  final bool busy;
  final bool editable;
  final TextEditingController controller;
  final VoidCallback onToggleOpen;
  final VoidCallback onAllow;
  final VoidCallback onBlock;
  final VoidCallback onLimit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final state = screenTimeAppRuleStatusLabel(l10n, app);
    final blocked = !app.decision.allowed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: blocked ? colors.coral100 : colors.surface,
          borderRadius: BorderRadius.circular(radii.tcard),
          border: Border.all(
            color: blocked ? colors.coral : colors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                key: Key('screen_time_server_app_expand_${app.appId}'),
                onTap: onToggleOpen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        blocked ? Icons.do_not_disturb_on : Icons.check_circle,
                        size: 18,
                        color: blocked ? colors.coral : colors.mintInk,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.displayName.isEmpty ? app.appId : app.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: colors.ink,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$categoryLabel · $state',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colors.ink2,
                                height: 1.4,
                              ),
                            ),
                            if (!app.knownOnDevice)
                              Text(
                                l10n.screenTimeServerAppUnknown,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: colors.amberDeep,
                                  height: 1.4,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.screenTimeServerAppUsed(app.usedMinutes),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: colors.ink2,
                          height: 1.3,
                        ),
                      ),
                      Icon(
                        open
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: colors.ink2,
                      ),
                    ],
                  ),
                ),
              ),
              if (open) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        key: Key('screen_time_server_app_limit_field_${app.appId}'),
                        controller: controller,
                        enabled: editable,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.screenTimeServerAppLimitSet,
                          helperText: l10n.screenTimeServerAppUnlimited,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PrimaryBtn(
                      key: Key('screen_time_server_app_limit_save_${app.appId}'),
                      fullWidth: false,
                      label: l10n.screenTimeServerSave,
                      variant: PrimaryBtnVariant.sec,
                      onPressed: editable && !busy ? onLimit : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: Key('screen_time_server_app_allow_${app.appId}'),
                      onPressed: editable && !busy ? onAllow : null,
                      child: Text(l10n.screenTimeServerAppAllow),
                    ),
                    OutlinedButton(
                      key: Key('screen_time_server_app_block_${app.appId}'),
                      onPressed: editable && !busy ? onBlock : null,
                      child: Text(l10n.screenTimeServerAppBlock),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.label,
    required this.radius,
  });

  final String label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.amber100,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: colors.amberDeep),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colors.amberDeep,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
