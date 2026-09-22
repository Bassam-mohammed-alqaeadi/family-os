import 'package:flutter/material.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/web_filter_evaluator.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';
import 'package:family_os/core/policy/web_filter_policy_repository.dart';
import 'package:family_os/core/policy/web_unlock_request.dart';
import 'package:family_os/core/policy/web_unlock_request_repository.dart';
import 'package:family_os/core/policy/web_unlock_service.dart';
import 'package:family_os/features/n04_web_filter/web_block_page.dart';
import 'package:family_os/features/n04_web_filter/web_unlock_inbox.dart';

/// Shared Stage-1 prefs store (survives within process; Rule 25 seam).
final MemoryWebFilterPrefsStore stage1WebFilterPrefsStore =
    MemoryWebFilterPrefsStore();

/// Default father-preview fixture (Net Nanny / Qustodio “what child sees”).
const String kWebFilterPreviewFixtureUrl = 'https://adult.example/page';

/// SCR-FAT-036 — فلترة الإنترنت (SET-004/005/006 + UI-009 WebFilterPolicy + unlock).
///
/// ControlFit: category toggles persist + feed [WebFilterEvaluator], not CSS-only.
/// SET-005 / UI-009: father preview reuses [WebFilterDecisionSnapshot.evaluate] +
/// [WebBlockPage] (Qustodio/Net Nanny “what child sees” — same URL → same verdict).
/// SET-006: WebUnlockInbox Approve/Deny (Family Link–style) + P12 child notify.
///
/// Policy refresh (UI-009 stale→refresh): preview captures the in-memory policy
/// **at open**. If the father edits categories while a sheet is closed, the next
/// open re-evaluates against the new `policy_version` snapshot.
class WebFilterScreen extends StatefulWidget {
  const WebFilterScreen({
    super.key,
    this.childId,
    this.repository,
    this.unlockService,
    this.canEditOverride,
    this.onRequestUnlock,
    this.motherLevel = MotherLevel.partner,
  });

  /// Stage-1 demo child when null.
  final ChildId? childId;

  /// Rule 25 seam — null → prefs-backed memory store.
  final WebFilterPolicyRepository? repository;

  /// SET-006 unlock service — null → prefs-backed Stage-1 singleton.
  final WebUnlockService? unlockService;

  /// Test seam — when null, father may edit; mother/child read-only.
  final bool? canEditOverride;

  /// SET-006 unlock seam forwarded into preview [WebBlockPage].
  /// When null, default creates a pending [WebUnlockRequest] + toast.
  final VoidCallback? onRequestUnlock;

  /// Mother authority for inbox Approve visibility (Stage-1 mock).
  final MotherLevel motherLevel;

  @override
  State<WebFilterScreen> createState() => _WebFilterScreenState();
}

class _WebFilterScreenState extends State<WebFilterScreen> {
  late final ChildId _childId;
  late final WebFilterPolicyRepository _repository;
  late final WebUnlockService _unlockService;
  late WebFilterPolicy _policy;
  late final TextEditingController _previewUrlController;
  var _loading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _childId = widget.childId ?? ChildId('demo-child');
    _repository = widget.repository ??
        PrefsWebFilterPolicyRepository(stage1WebFilterPrefsStore);
    _unlockService = widget.unlockService ??
        WebUnlockService(
          requestRepository: PrefsWebUnlockRequestRepository(
            stage1WebUnlockPrefsStore,
          ),
          policyRepository: _repository,
          audit: stage1WebUnlockAudit,
          decisionBus: stage1WebUnlockDecisionBus,
        );
    _policy = WebFilterPolicy.defaults();
    _previewUrlController =
        TextEditingController(text: kWebFilterPreviewFixtureUrl);
    _unlockService.decisionBus.addListener(_onUnlockDecision);
    _load();
  }

  @override
  void dispose() {
    _unlockService.decisionBus.removeListener(_onUnlockDecision);
    _previewUrlController.dispose();
    super.dispose();
  }

  void _onUnlockDecision() {
    final decided = _unlockService.decisionBus.lastDecision;
    if (decided == null || !mounted) return;
    final role = CurrentRole.maybeNotifierOf(context)?.value;
    // Child surfaces toast when decision arrives (same-process P12 bus).
    if (role != AppRole.child) return;
    final l10n = AppLocalizations.of(context);
    final message = decided.status == WebUnlockRequestStatus.approved
        ? l10n.webUnlockApprovedToast
        : l10n.webUnlockDeniedToast;
    AppToast.show(context, message: message);
  }

  Future<void> _load() async {
    final loaded = await _repository.load(_childId);
    if (!mounted) return;
    setState(() {
      _policy = loaded;
      _loading = false;
    });
  }

  bool get _canEdit {
    if (widget.canEditOverride != null) return widget.canEditOverride!;
    final role = CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
    return role == AppRole.father;
  }

  bool get _canSave => _canEdit && !_saving && !_loading;

  void _onLevelChanged(WebFilterLevel level) {
    if (!_canEdit) return;
    setState(() {
      _policy = _policy.copyWith(level: level, applyLevelPreset: true);
    });
  }

  void _onCategoryChanged(String key, bool enabled) {
    if (!_canEdit) return;
    setState(() {
      _policy = _policy.withCategory(key, enabled);
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final stamp = DateTime.now().toUtc();
    final toSave = _policy.copyWith(
      policyVersion: _policy.policyVersion + 1,
      updatedAt: stamp,
    );
    await _repository.save(_childId, toSave);
    if (!mounted) return;
    setState(() {
      _policy = toSave;
      _saving = false;
    });
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.webFilterSaveToast);
  }

  String _levelLabel(AppLocalizations l10n, WebFilterLevel level) {
    return switch (level) {
      WebFilterLevel.strict => l10n.webFilterLevelStrict,
      WebFilterLevel.balanced => l10n.webFilterLevelBalanced,
      WebFilterLevel.open => l10n.webFilterLevelOpen,
    };
  }

  String _categoryLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      WebFilterCategories.adults => l10n.webFilterCategoryAdults,
      WebFilterCategories.gambling => l10n.webFilterCategoryGambling,
      WebFilterCategories.violence => l10n.webFilterCategoryViolence,
      WebFilterCategories.social => l10n.webFilterCategorySocial,
      WebFilterCategories.games => l10n.webFilterCategoryGames,
      WebFilterCategories.streaming => l10n.webFilterCategoryStreaming,
      _ => key,
    };
  }

  Uri _parsePreviewUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return Uri.parse(kWebFilterPreviewFixtureUrl);
    final withScheme =
        trimmed.contains('://') ? trimmed : 'https://$trimmed';
    return Uri.tryParse(withScheme) ?? Uri.parse(kWebFilterPreviewFixtureUrl);
  }

  VoidCallback? _previewUnlockHandler(Uri url) {
    if (widget.onRequestUnlock != null) return widget.onRequestUnlock;
    return () {
      defaultWebUnlockRequest(
        context: context,
        service: _unlockService,
        childId: _childId,
        url: url,
      );
    };
  }

  /// Opens child block UI with the **current** policy snapshot (UI-009 AC2).
  ///
  /// Re-eval on every open so edits after dismiss invalidate a stale preview.
  Future<void> _openChildPreview() async {
    final url = _parsePreviewUrl(_previewUrlController.text);
    // Identical evaluator path to child WebBlockPage (UI-009 AC1 / SET-005).
    final snapshot = WebFilterDecisionSnapshot.evaluate(url, _policy);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.72,
          child: WebBlockPage(
            key: const Key('web_filter_preview_block'),
            snapshot: snapshot,
            isPreview: true,
            childId: _childId,
            unlockService: _unlockService,
            onRequestUnlock: _previewUnlockHandler(url),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final canEdit = _canEdit;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.webFilterTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      children: [
                        Text(
                          l10n.webFilterSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: colors.ink2,
                          ),
                        ),
                        if (!canEdit) ...[
                          const SizedBox(height: 12),
                          Text(
                            key: const Key('web_filter_read_only'),
                            l10n.webFilterReadOnly,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.ink2,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          l10n.webFilterLevelHeading,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<WebFilterLevel>(
                          key: const Key('web_filter_level'),
                          segments: [
                            for (final level in WebFilterLevel.values)
                              ButtonSegment<WebFilterLevel>(
                                value: level,
                                label: Text(_levelLabel(l10n, level)),
                                enabled: canEdit,
                              ),
                          ],
                          selected: {_policy.level},
                          onSelectionChanged: canEdit
                              ? (next) {
                                  if (next.isEmpty) return;
                                  _onLevelChanged(next.first);
                                }
                              : null,
                          style: ButtonStyle(
                            visualDensity: VisualDensity.comfortable,
                            minimumSize: const WidgetStatePropertyAll(
                              Size(48, 48),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.webFilterCategoriesHeading,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final key in WebFilterCategories.known) ...[
                          _CategoryRow(
                            categoryKey: key,
                            label: _categoryLabel(l10n, key),
                            enabled: _policy.isCategoryEnabled(key),
                            canEdit: canEdit,
                            colors: colors,
                            radii: radii,
                            onChanged: (v) => _onCategoryChanged(key, v),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          l10n.webFilterPreviewHeading,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.webFilterPreviewHint,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: colors.ink2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const Key('web_filter_preview_url'),
                          controller: _previewUrlController,
                          decoration: InputDecoration(
                            hintText: l10n.webFilterPreviewUrlHint,
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(radii.card),
                            ),
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _openChildPreview(),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            key: const Key('web_filter_preview_fixture'),
                            onPressed: () {
                              _previewUrlController.text =
                                  kWebFilterPreviewFixtureUrl;
                            },
                            child: Text(l10n.webFilterPreviewUseFixture),
                          ),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          key: const Key('web_filter_preview_open'),
                          onPressed: _loading ? null : _openChildPreview,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(l10n.webFilterPreviewButton),
                        ),
                        const SizedBox(height: 24),
                        WebUnlockInbox(
                          service: _unlockService,
                          role: CurrentRole.maybeNotifierOf(context)?.value ??
                              AppRole.father,
                          motherLevel: widget.motherLevel,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: PrimaryBtn(
                      key: const Key('web_filter_save'),
                      label: l10n.webFilterSave,
                      onPressed: _canSave ? _save : null,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categoryKey,
    required this.label,
    required this.enabled,
    required this.canEdit,
    required this.colors,
    required this.radii,
    required this.onChanged,
  });

  final String categoryKey;
  final String label;
  final bool enabled;
  final bool canEdit;
  final FamilyColors colors;
  final FamilyRadii radii;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
            ),
            Semantics(
              label: label,
              toggled: enabled,
              enabled: canEdit,
              excludeSemantics: true,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Switch.adaptive(
                    key: Key('web_filter_switch_$categoryKey'),
                    value: enabled,
                    onChanged: canEdit ? onChanged : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
