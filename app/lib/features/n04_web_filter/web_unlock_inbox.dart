import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/web_unlock_request.dart';
import 'package:family_os/core/policy/web_unlock_service.dart';

/// Parent inbox MVP for pending web unlock requests (SET-006 / FAT-036 panel).
///
/// Family Link–style Approve / Deny. Mother observer sees the list but Approve
/// is absent; Deny also blocked for observer.
class WebUnlockInbox extends StatefulWidget {
  const WebUnlockInbox({
    super.key,
    required this.service,
    this.actor = const WebUnlockActor.father(),
    this.role,
    this.motherLevel,
  });

  final WebUnlockService service;

  /// Explicit actor for decide actions. When nullish fields below are set,
  /// they rebuild the actor.
  final WebUnlockActor actor;

  /// Optional: derive actor from [role] + [motherLevel] when provided.
  final AppRole? role;
  final MotherLevel? motherLevel;

  @override
  State<WebUnlockInbox> createState() => _WebUnlockInboxState();
}

class _WebUnlockInboxState extends State<WebUnlockInbox> {
  List<WebUnlockRequest> _pending = const [];
  var _loading = true;

  WebUnlockActor get _actor {
    final role = widget.role;
    if (role == null) return widget.actor;
    return switch (role) {
      AppRole.father => const WebUnlockActor.father(),
      AppRole.mother => WebUnlockActor.mother(
          widget.motherLevel ?? MotherLevel.partner,
        ),
      AppRole.child => const WebUnlockActor.child(),
    };
  }

  bool get _canDecide => _actor.canApproveUnlock;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onService);
    _reload();
  }

  @override
  void didUpdateWidget(covariant WebUnlockInbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      oldWidget.service.removeListener(_onService);
      widget.service.addListener(_onService);
      _reload();
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onService);
    super.dispose();
  }

  void _onService() => _reload();

  Future<void> _reload() async {
    final pending = await widget.service.listPending();
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _loading = false;
    });
  }

  Future<void> _approve(WebUnlockRequest request) async {
    if (!_canDecide) return;
    try {
      await widget.service.approve(request.id, _actor);
    } on WebUnlockNotAllowedException {
      // Observer / unauthorized — ignore at UI (button absent).
    }
  }

  Future<void> _deny(WebUnlockRequest request) async {
    if (!_canDecide && _actor.role == AppRole.mother) return;
    if (_actor.role == AppRole.child) return;
    // Father and mother partner/full may deny.
    if (_actor.role == AppRole.mother &&
        _actor.motherLevel == MotherLevel.observer) {
      return;
    }
    try {
      await widget.service.deny(request.id, _actor, reason: 'denied');
    } on WebUnlockNotAllowedException {
      // no-op
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Column(
      key: const Key('web_unlock_inbox'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.webUnlockInboxTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.webUnlockInboxSubtitle,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: colors.ink2,
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_pending.isEmpty)
          Text(
            key: const Key('web_unlock_inbox_empty'),
            l10n.webUnlockInboxEmpty,
            style: TextStyle(fontSize: 13, color: colors.ink2),
          )
        else
          for (final request in _pending) ...[
            _UnlockRow(
              request: request,
              canApprove: _canDecide,
              colors: colors,
              radii: radii,
              approveLabel: l10n.webUnlockApprove,
              denyLabel: l10n.webUnlockDeny,
              onApprove: () => _approve(request),
              onDeny: () => _deny(request),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _UnlockRow extends StatelessWidget {
  const _UnlockRow({
    required this.request,
    required this.canApprove,
    required this.colors,
    required this.radii,
    required this.approveLabel,
    required this.denyLabel,
    required this.onApprove,
    required this.onDeny,
  });

  final WebUnlockRequest request;
  final bool canApprove;
  final FamilyColors colors;
  final FamilyRadii radii;
  final String approveLabel;
  final String denyLabel;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('web_unlock_row_${request.id}'),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              key: Key('web_unlock_host_${request.id}'),
              request.host.isEmpty ? request.url : request.host,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 10),
            if (canApprove)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: Key('web_unlock_approve_${request.id}'),
                      onPressed: onApprove,
                      child: Text(approveLabel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: Key('web_unlock_deny_${request.id}'),
                      onPressed: onDeny,
                      child: Text(denyLabel),
                    ),
                  ),
                ],
              )
            else
              Text(
                key: Key('web_unlock_observer_only_${request.id}'),
                // Observer: list visible, decide controls absent (ADR-035 ①).
                AppLocalizations.of(context).webUnlockObserverHint,
                style: TextStyle(fontSize: 12, color: colors.ink2),
              ),
          ],
        ),
      ),
    );
  }
}
