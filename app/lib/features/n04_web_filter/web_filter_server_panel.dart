import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n04_web_filter/web_filter_server_authority.dart';
import 'package:family_os/foundation_gate/family_web_filter_api_client.dart';

/// The web-filter surface, rendered from what the server enforces.
///
/// This panel exists because of one sentence in the master plan: "الحماية التي تبدو فعّالة
/// أسوأ من غيابها" — protection that appears to work is worse than none. Everything a family
/// reads here came from the server, and the one claim a screen must never make on its own is
/// that protection is running. So the panel renders four things and invents none of them:
///
///   * the filter the family owns: the six categories, and the two lists. Each edit sends the
///     single field that changed, with `expectedVersion`, so a stale screen is a refusal
///     instead of a silent overwrite of another guardian's decision;
///   * the preview: a host a father types is decided by the SAME rules the handset applies,
///     with the source of denial stated — a preview produced by different rules would be a
///     screen disagreeing with the phone in the child's hand;
///   * the questions: what a child asked to open, and the two answers a family has. An
///     answered question shows the clock's answer, so an approval whose minute has passed
///     reads expired without anybody having closed it;
///   * the protection state: `protected`, `at_risk`, `unverified` or `unsupported`, computed
///     by the server from each device's newest report and the clock. A device that stopped
///     reporting reads `unverified` WITH the length of its silence — never a green dot, and
///     never a red one it has not earned.
///
/// When the server cannot be reached, the last true answer stays on screen and says that it
/// is the last one. When there was never an answer, no policy is drawn at all.
class WebFilterServerPanel extends StatefulWidget {
  const WebFilterServerPanel({
    super.key,
    required this.childId,
    this.authority,
    this.canEdit = true,
    this.idempotencyKey,
  });

  final ChildId childId;

  /// Test seam. Null means "the authority bound at boot", which is how the app runs.
  final WebFilterServerAuthority? authority;

  /// Role-based: a mother below full level, or a child's own view, may read and not write.
  final bool canEdit;

  /// Test seam for byte-stable idempotency keys.
  final String Function()? idempotencyKey;

  @override
  State<WebFilterServerPanel> createState() => _WebFilterServerPanelState();
}

class _WebFilterServerPanelState extends State<WebFilterServerPanel> {
  WebFilterAuthorityStatus? _status;
  FoundationGateWebFilterPolicy? _policy;
  FoundationGateFamilyProtection? _protection;
  List<FoundationGateTempAllow> _questions = const <FoundationGateTempAllow>[];
  bool _busy = false;
  String _previewHost = '';
  FoundationGateWebDecision? _preview;
  final TextEditingController _previewCtrl = TextEditingController(
    text: 'games.example.com',
  );

  WebFilterServerAuthority? get _authority =>
      widget.authority ?? activeWebFilterServerAuthority;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _previewCtrl.dispose();
    super.dispose();
  }

  String _key(String scope) =>
      widget.idempotencyKey?.call() ??
      'w6-$scope-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _load() async {
    final authority = _authority;
    if (authority == null) {
      setState(() => _status = WebFilterAuthorityStatus.notConfigured);
      return;
    }
    setState(() => _busy = true);
    // Three reads, because they are three questions a family can ask in any order: what the
    // filter is, what is waiting for an answer, and whether the protection is actually
    // running. One failure does not erase the other two.
    final policy = await authority.readPolicy(widget.childId.value);
    final questions = await authority.openQuestions(widget.childId.value);
    final protection = await authority.protection();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = policy.status;
      if (policy.isReady) _policy = policy.value;
      if (questions.isReady) _questions = questions.value!;
      if (protection.isReady) _protection = protection.value;
    });
  }

  Future<void> _toggleCategory(FoundationGateWebFilterCategory category) async {
    final authority = _authority;
    final policy = _policy;
    if (authority == null || policy == null || !widget.canEdit) return;
    final next = Set<FoundationGateWebFilterCategory>.from(
      policy.enabledCategories,
    );
    if (!next.remove(category)) next.add(category);
    setState(() => _busy = true);
    final answer = await authority.writePolicy(
      widget.childId.value,
      categories: next,
      expectedVersion: policy.version,
      idempotencyKey: () => _key('category-${category.wire}'),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
      if (answer.isReady) _policy = answer.value;
    });
  }

  Future<void> _runPreview() async {
    final authority = _authority;
    if (authority == null) return;
    setState(() => _busy = true);
    final answer = await authority.evaluate(
      widget.childId.value,
      host: _previewCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
      if (answer.isReady) {
        _preview = answer.value;
        _previewHost = answer.value!.normalizedHost;
      }
    });
  }

  Future<void> _decide(
    FoundationGateTempAllow request, {
    required bool approve,
  }) async {
    final authority = _authority;
    if (authority == null || !widget.canEdit) return;
    setState(() => _busy = true);
    final answer = await authority.decideHost(
      widget.childId.value,
      requestId: request.id,
      approve: approve,
      idempotencyKey: () => _key('decide-${request.id}'),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
    });
    // Reload after answering, so the list a family looks at is the server's answer rather
    // than the intent this screen just sent.
    if (answer.isReady) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final status = _status;
    if (status == null) {
      return const SizedBox.shrink();
    }
    final banner = _statusBanner(l10n, status);
    final policy = _policy;
    return Column(
      key: const Key('web_filter_server_panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (banner != null) ...[banner, const SizedBox(height: 12)],
        if (policy != null) ...[
          _policyCard(l10n, colors, policy),
          const SizedBox(height: 12),
          _previewCard(l10n, colors),
          const SizedBox(height: 12),
          if (_questions.isNotEmpty) ...[
            _questionsCard(l10n, colors),
            const SizedBox(height: 12),
          ],
        ],
        if (_protection != null) _protectionCard(l10n, colors, _protection!),
      ],
    );
  }

  Widget? _statusBanner(AppLocalizations l10n, WebFilterAuthorityStatus status) {
    // Every status here is one of the honest four, and the sentence says which. There is
    // deliberately no fifth "we will try to work locally": a family reading this needs to
    // know whether the filter is being enforced, not how hard the app is trying.
    final (String? message, BannerVariant variant) = switch (status) {
      WebFilterAuthorityStatus.ready => (null, BannerVariant.g),
      WebFilterAuthorityStatus.notConfigured => (
        l10n.webFilterServerNoSession,
        BannerVariant.t,
      ),
      WebFilterAuthorityStatus.accessDenied => (
        l10n.webFilterServerDenied,
        BannerVariant.a,
      ),
      // A refusal keeps the last true policy on screen and says that it is the last one: a
      // screen that emptied itself on a 409 would look like a family with no filter.
      WebFilterAuthorityStatus.refused => (
        l10n.webFilterServerRefused,
        BannerVariant.a,
      ),
      WebFilterAuthorityStatus.unreachable => (
        l10n.webFilterServerUnreachable,
        BannerVariant.a,
      ),
    };
    if (message == null) return null;
    return BannerNote(
      key: Key('web_filter_server_${status.name}'),
      variant: variant,
      message: message,
    );
  }

  Widget _policyCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateWebFilterPolicy policy,
  ) {
    final editable = widget.canEdit && !_busy;
    return Card(
      key: const Key('web_filter_server_policy_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.webFilterCategoriesHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            for (final category in FoundationGateWebFilterCategory.values)
              SwitchListTile.adaptive(
                key: Key('web_filter_server_category_${category.wire}'),
                contentPadding: EdgeInsets.zero,
                value: policy.isCategoryEnabled(category),
                onChanged: editable ? (_) => _toggleCategory(category) : null,
                title: Text(_categoryLabel(l10n, category)),
              ),
            const SizedBox(height: 8),
            Text(
              l10n.webFilterListsHeading,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            _hostLine(l10n.webFilterBlockListHeading, policy.blockHosts, colors),
            _hostLine(l10n.webFilterAllowListHeading, policy.allowHosts, colors),
            // The doors the SERVER says are open, at this minute. Nothing here decides that
            // one is open, and a family should still see what is currently let through.
            if (policy.activeTempAllows.isNotEmpty)
              Text(
                policy.activeTempAllows.join(' · '),
                key: const Key('web_filter_server_active_allows'),
                style: TextStyle(fontSize: 12, color: colors.ink2),
              ),
            const SizedBox(height: 6),
            Text(
              l10n.webFilterPrecedenceNote,
              style: TextStyle(fontSize: 11, color: colors.ink2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hostLine(String label, List<String> hosts, FamilyColors colors) {
    final l10n = AppLocalizations.of(context);
    final body = hosts.isEmpty ? l10n.webFilterListEmpty : hosts.join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '$label: $body',
        style: TextStyle(fontSize: 12, color: colors.ink),
      ),
    );
  }

  Widget _previewCard(AppLocalizations l10n, FamilyColors colors) {
    final decision = _preview;
    return Card(
      key: const Key('web_filter_server_preview_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.webFilterPreviewHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('web_filter_server_preview_field'),
              controller: _previewCtrl,
              decoration: InputDecoration(
                hintText: l10n.webFilterPreviewUrlHint,
              ),
              onSubmitted: (_) => _runPreview(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const Key('web_filter_server_preview_button'),
                onPressed: _busy ? null : _runPreview,
                child: Text(l10n.webFilterPreviewButton),
              ),
            ),
            if (decision != null) ...[
              Text(
                decision.allowed
                    ? l10n.webBlockAllowedTitle
                    : l10n.webBlockSourceOfDeny(
                        _denySourceLabel(l10n, decision),
                      ),
                key: const Key('web_filter_server_preview_verdict'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: decision.allowed ? colors.mintInk : colors.coral,
                ),
              ),
              if (decision.categoryKey != null)
                Text(
                  _categoryLabel(l10n, decision.categoryKey!),
                  style: TextStyle(fontSize: 12, color: colors.ink2),
                ),
              // The host as the ENGINE read it, not as it was typed: a father who blocks
              // `example.com` and previews `www.example.com` should see the same host the
              // decision was made about.
              Text(
                decision.normalizedHost,
                style: TextStyle(fontSize: 11, color: colors.ink2),
              ),
            ] else if (_previewHost.isNotEmpty)
              Text(
                _previewHost,
                style: TextStyle(fontSize: 11, color: colors.ink2),
              ),
          ],
        ),
      ),
    );
  }

  String _denySourceLabel(
    AppLocalizations l10n,
    FoundationGateWebDecision decision,
  ) => switch (decision.denySource) {
    FoundationGateWebDenySource.blocklist => l10n.webBlockReasonBlocklist,
    FoundationGateWebDenySource.dictionary => l10n.webBlockReasonDictionary,
    FoundationGateWebDenySource.category => decision.categoryKey == null
        ? l10n.webBlockReasonGeneric
        : _categoryLabel(l10n, decision.categoryKey!),
    null => l10n.webBlockReasonGeneric,
  };

  Widget _questionsCard(AppLocalizations l10n, FamilyColors colors) {
    return Card(
      key: const Key('web_filter_server_questions_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.webUnlockInboxTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            for (final request in _questions) _questionRow(l10n, colors, request),
          ],
        ),
      ),
    );
  }

  Widget _questionRow(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateTempAllow request,
  ) {
    final open = request.state == FoundationGateTempAllowState.pending;
    return Padding(
      key: Key('web_filter_server_question_${request.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      // A column of lines, not a row. The host and the state are each a whole line, and the
      // two actions sit in a Wrap - because these are the longest strings on the surface in
      // Arabic, and a Row holding them beside a flexible text ran 196 pixels off the edge of
      // a phone. An overflow is not a cosmetic warning: it is a button a father cannot reach.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The host and the minutes, composed rather than translated: both are data.
          Text(
            '${request.host} · ${request.requestedMinutes}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 2),
          if (open && widget.canEdit)
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  key: Key('web_filter_server_approve_${request.id}'),
                  onPressed: _busy ? null : () => _decide(request, approve: true),
                  child: Text(l10n.webUnlockApprove),
                ),
                TextButton(
                  key: Key('web_filter_server_deny_${request.id}'),
                  onPressed: _busy ? null : () => _decide(request, approve: false),
                  child: Text(l10n.webUnlockDeny),
                ),
              ],
            )
          else
            // An answered question shows the clock's answer, not the stored status: an
            // approval whose minute has passed reads expired because the server computed it.
            //
            // The words are this panel's own. A guardian is not the child who asked, so the
            // child-facing sentences ("waiting for a parent", "try again soon") say the wrong
            // thing here even when they are grammatically true.
            Text(
              _stateLabel(l10n, request.state),
              key: Key('web_filter_server_question_state_${request.id}'),
              style: TextStyle(fontSize: 12, color: colors.ink2),
            ),
        ],
      ),
    );
  }

  String _stateLabel(
    AppLocalizations l10n,
    FoundationGateTempAllowState state,
  ) => switch (state) {
    FoundationGateTempAllowState.pending => l10n.webFilterServerQuestionPending,
    FoundationGateTempAllowState.active => l10n.webFilterServerQuestionOpen,
    FoundationGateTempAllowState.expired => l10n.webBlockFeedbackExpired,
    FoundationGateTempAllowState.denied => l10n.webFilterServerQuestionDenied,
  };

  Widget _protectionCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateFamilyProtection protection,
  ) {
    return Card(
      key: const Key('web_filter_server_protection_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.webFilterProtectionHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            if (protection.devices.isEmpty)
              Text(
                l10n.webFilterListEmpty,
                style: TextStyle(fontSize: 12, color: colors.ink2),
              ),
            for (final device in protection.devices)
              _deviceRow(l10n, colors, device),
          ],
        ),
      ),
    );
  }

  Widget _deviceRow(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateDeviceProtection device,
  ) {
    final (label, tone) = switch (device.state) {
      FoundationGateProtectionState.protected => (
        l10n.webFilterProtectionProtected,
        colors.mintInk,
      ),
      FoundationGateProtectionState.atRisk => (
        l10n.webFilterProtectionAtRisk,
        colors.coral,
      ),
      FoundationGateProtectionState.unsupported => (
        l10n.webFilterProtectionUnsupported,
        colors.ink2,
      ),
      // The honest default: nothing recent said so, and this screen will not fill the gap.
      FoundationGateProtectionState.unverified =>
        device.reason == FoundationGateProtectionReason.neverReported
            ? (l10n.webFilterProtectionNeverReported, colors.ink2)
            : (l10n.webFilterProtectionUnverified, colors.ink2),
    };
    return Padding(
      key: Key('web_filter_server_device_${device.deviceId}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device.deviceLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          Text(
            label,
            key: Key('web_filter_server_device_state_${device.deviceId}'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
          // How long the silence has lasted. "Unverified" with a number is a fact a parent
          // can act on; without one it is a shrug.
          if (device.state == FoundationGateProtectionState.unverified &&
              device.ageMinutes != null)
            Text(
              l10n.webFilterProtectionSilentMinutes(device.ageMinutes!),
              style: TextStyle(fontSize: 11, color: colors.ink2),
            ),
          // What the handset saw, in the family's own pedagogical words: an attempt is
          // information for a conversation, not an indictment.
          if (device.signals.isNotEmpty)
            Text(
              device.signals
                  .map((signal) => _signalLabel(l10n, signal))
                  .join(' · '),
              style: TextStyle(fontSize: 11, color: colors.ink2),
            ),
        ],
      ),
    );
  }

  String _signalLabel(AppLocalizations l10n, String signal) {
    // Only tokens this build can name are labelled; anything else is shown as the handset
    // wrote it rather than guessed into a category it may not belong to.
    return switch (signal) {
      'vpn_active' => l10n.tamperAlertsKindVpn,
      'permission_revoked' => l10n.tamperAlertsKindPermission,
      'dns_bypassed' || 'device_admin_removed' => l10n.tamperAlertsKindBypass,
      _ => signal,
    };
  }

  String _categoryLabel(
    AppLocalizations l10n,
    FoundationGateWebFilterCategory category,
  ) => switch (category) {
    FoundationGateWebFilterCategory.adults => l10n.webFilterCategoryAdults,
    FoundationGateWebFilterCategory.gambling => l10n.webFilterCategoryGambling,
    FoundationGateWebFilterCategory.violence => l10n.webFilterCategoryViolence,
    FoundationGateWebFilterCategory.social => l10n.webFilterCategorySocial,
    FoundationGateWebFilterCategory.games => l10n.webFilterCategoryGames,
    FoundationGateWebFilterCategory.streaming => l10n.webFilterCategoryStreaming,
  };
}
