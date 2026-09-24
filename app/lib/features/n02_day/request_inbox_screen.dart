import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';

/// Widget keys for SCR-FAT-033 / UI-006 acceptance.
abstract final class RequestInboxKeys {
  static const screen = Key('request_inbox_screen');
  static const emptyState = Key('request_inbox_empty');
  static const list = Key('request_inbox_list');
  static const offlineBanner = Key('request_inbox_offline_banner');
  static const backButton = Key('request_inbox_back');
  static Key row(String id) => Key('request_inbox_row_$id');
  static Key grantChip(int minutes) => Key('request_inbox_grant_$minutes');
  static Key approve(String id) => Key('request_inbox_approve_$id');
  static Key reject(String id) => Key('request_inbox_reject_$id');
  static Key rejectReason(String id) => Key('request_inbox_reject_reason_$id');
  static const observerHint = Key('request_inbox_observer_hint');
}

/// SCR-FAT-033 — طلبات الوقت الإضافي (UI-006 / UF-05 / ADR-039).
///
/// Empty → SHR-006 [AppEmptyState]. Mother grant chips clamp ≤ active ceiling
/// (over-ceiling hidden). Reject stores child-visible reason. Offline queues.
class RequestInboxScreen extends StatefulWidget {
  const RequestInboxScreen({
    super.key,
    this.service,
    this.role,
    this.motherLevel = MotherLevel.partner,
    this.onBack,
  });

  /// Injectable repo-backed service; null → stage-1 prefs singleton.
  final TimeRequestService? service;
  final AppRole? role;
  final MotherLevel motherLevel;
  final VoidCallback? onBack;

  @override
  State<RequestInboxScreen> createState() => _RequestInboxScreenState();
}

class _RequestInboxScreenState extends State<RequestInboxScreen> {
  late TimeRequestService _service;
  var _ownsService = false;
  List<TimeRequest> _pending = const [];
  var _loading = true;
  final Map<String, int> _selectedGrant = {};
  final Map<String, TextEditingController> _reasonControllers = {};

  AppRole get _effectiveRole =>
      widget.role ??
      resolveAuthorizationContext(
        context,
        fallbackRole: AppRole.father,
        fallbackMotherLevel: widget.motherLevel,
      ).role;

  TimeRequestActor get _actor => TimeRequestService.actorFor(
    role: _effectiveRole,
    motherLevel: widget.motherLevel,
  );

  bool get _canDecide => _actor.canDecide;

  int get _ceiling => _service.activeCeilingMinutes;

  List<int> get _visibleGrantOptions {
    if (!_canDecide) return const [];
    if (_effectiveRole == AppRole.father) {
      return kTimeGrantOptionMinutes;
    }
    // Mother: hide over-ceiling controls (ADR-039 / UI-006 edge).
    return [
      for (final m in kTimeGrantOptionMinutes)
        if (m <= _ceiling) m,
    ];
  }

  @override
  void initState() {
    super.initState();
    _bindService(widget.service);
    _reload();
  }

  void _bindService(TimeRequestService? injected) {
    if (injected != null) {
      _service = injected;
      _ownsService = false;
    } else {
      _service = TimeRequestService(
        repository: PrefsTimeRequestRepository(stage1TimeRequestPrefsStore),
        decisionBus: stage1TimeRequestDecisionBus,
      );
      _ownsService = true;
    }
    _service.addListener(_onService);
  }

  @override
  void didUpdateWidget(covariant RequestInboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _service.removeListener(_onService);
      if (_ownsService) {
        _service.dispose();
      }
      _bindService(widget.service);
      _reload();
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onService);
    if (_ownsService) {
      _service.dispose();
    }
    for (final c in _reasonControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onService() => _reload();

  Future<void> _reload() async {
    final familyId = CurrentIdentity.maybeOf(context)?.activeFamilyId.value;
    final allPending = await _service.listPending();
    final pending = familyId == null
        ? allPending
        : allPending
              .where((r) {
                final value = r.childId.value;
                if (value.startsWith('$familyId::')) return true;
                // Backward-compat for stage-1 data not yet family-scoped.
                return !value.contains('::');
              })
              .toList(growable: false);
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _loading = false;
      for (final r in pending) {
        _selectedGrant.putIfAbsent(
          r.id,
          () => _defaultGrantFor(r.requestedMinutes),
        );
        _reasonControllers.putIfAbsent(r.id, TextEditingController.new);
      }
    });
  }

  int _defaultGrantFor(int requested) {
    final options = _visibleGrantOptions;
    if (options.isEmpty) return _ceiling;
    if (options.contains(requested)) return requested;
    final under = options.where((m) => m <= requested).toList();
    if (under.isNotEmpty) return under.last;
    return options.first;
  }

  Future<void> _approve(TimeRequest request) async {
    if (!_canDecide) return;
    final minutes =
        _selectedGrant[request.id] ??
        _defaultGrantFor(request.requestedMinutes);
    try {
      await _service.approve(request.id, _actor, grantMinutes: minutes);
    } on TimeRequestNotAllowedException {
      // Ceiling / role — button absent or disabled.
    }
  }

  Future<void> _reject(TimeRequest request) async {
    if (!_canDecide) return;
    final reason = _reasonControllers[request.id]?.text ?? '';
    try {
      await _service.reject(request.id, _actor, reason: reason);
    } on TimeRequestReasonRequiredException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).requestInboxReasonRequired,
          ),
        ),
      );
    } on TimeRequestNotAllowedException {
      // no-op
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: RequestInboxKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(l10n.requestInboxTitle),
        leading: widget.onBack == null
            ? null
            : IconButton(
                key: RequestInboxKeys.backButton,
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.requestInboxBackSemantics,
                onPressed: widget.onBack,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.padded,
                  minimumSize: WidgetStatePropertyAll(Size(48, 48)),
                ),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_service.offline)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: BannerNote(
                      key: RequestInboxKeys.offlineBanner,
                      variant: BannerVariant.a,
                      message:
                          '${l10n.requestInboxOfflineBanner} ${l10n.requestInboxOfflineQueued}',
                    ),
                  ),
                Expanded(
                  child: _pending.isEmpty
                      ? AppEmptyState(
                          key: RequestInboxKeys.emptyState,
                          contextName: l10n.requestInboxEmptyContext,
                        )
                      : ListView.separated(
                          key: RequestInboxKeys.list,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _pending.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final request = _pending[index];
                            return _RequestRow(
                              request: request,
                              canDecide: _canDecide,
                              grantOptions: _visibleGrantOptions,
                              selectedGrant:
                                  _selectedGrant[request.id] ??
                                  _defaultGrantFor(request.requestedMinutes),
                              reasonController: _reasonControllers[request.id]!,
                              onSelectGrant: (m) {
                                setState(() => _selectedGrant[request.id] = m);
                              },
                              onApprove: () => _approve(request),
                              onReject: () => _reject(request),
                              ceiling: _ceiling,
                              isMother: widget.role == AppRole.mother,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.canDecide,
    required this.grantOptions,
    required this.selectedGrant,
    required this.reasonController,
    required this.onSelectGrant,
    required this.onApprove,
    required this.onReject,
    required this.ceiling,
    required this.isMother,
  });

  final TimeRequest request;
  final bool canDecide;
  final List<int> grantOptions;
  final int selectedGrant;
  final TextEditingController reasonController;
  final ValueChanged<int> onSelectGrant;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final int ceiling;
  final bool isMother;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return DecoratedBox(
      key: RequestInboxKeys.row(request.id),
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
              l10n.requestInboxRequestedMinutes(request.requestedMinutes),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            if (request.childReason != null &&
                request.childReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                request.childReason!,
                style: TextStyle(fontSize: 13, color: colors.ink2, height: 1.4),
              ),
            ],
            if (!canDecide) ...[
              const SizedBox(height: 10),
              Text(
                key: RequestInboxKeys.observerHint,
                l10n.requestInboxObserverHint,
                style: TextStyle(fontSize: 12, color: colors.ink2),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                l10n.requestInboxGrantLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.ink2,
                ),
              ),
              if (isMother) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.requestInboxCeilingHint(ceiling),
                  style: TextStyle(fontSize: 11, color: colors.ink2),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in grantOptions)
                    Semantics(
                      button: true,
                      selected: selectedGrant == m,
                      label: l10n.spineCtaGrantMinutesSemantics(m),
                      excludeSemantics: true,
                      child: ConstrainedBox(
                        key: RequestInboxKeys.grantChip(m),
                        // UI-015 / Rule 16 — dense Wrap must stay ≥48×48.
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        child: ChoiceChip(
                          label: Text(l10n.requestInboxGrantMinutes(m)),
                          selected: selectedGrant == m,
                          onSelected: (_) => onSelectGrant(m),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          visualDensity: VisualDensity.standard,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: RequestInboxKeys.rejectReason(request.id),
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: l10n.requestInboxRejectReasonLabel,
                  hintText: l10n.requestInboxRejectReasonHint,
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryBtn(
                      key: RequestInboxKeys.approve(request.id),
                      label: l10n.requestInboxApprove,
                      semanticsLabel: l10n.spineCtaApproveSemantics,
                      onPressed: onApprove,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryBtn(
                      key: RequestInboxKeys.reject(request.id),
                      label: l10n.requestInboxReject,
                      semanticsLabel: l10n.spineCtaRejectSemantics,
                      variant: PrimaryBtnVariant.ghost,
                      onPressed: onReject,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Child-visible decision seam — proves reject reason reaches the child (AC3).
class ChildTimeDecisionSeam extends StatelessWidget {
  const ChildTimeDecisionSeam({
    super.key,
    required this.decisionBus,
    this.childId,
  });

  final TimeRequestDecisionBus decisionBus;
  final String? childId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: decisionBus,
      builder: (context, _) {
        final d = decisionBus.lastDecision;
        if (d == null) {
          return const SizedBox.shrink(key: Key('child_time_decision_empty'));
        }
        if (childId != null && d.childId.value != childId) {
          return const SizedBox.shrink();
        }
        if (d.status == TimeRequestStatus.rejected) {
          return Text(
            key: const Key('child_time_decision_rejected'),
            l10n.requestInboxChildRejectedReason(d.decisionReason ?? ''),
          );
        }
        if (d.status == TimeRequestStatus.approved) {
          return Text(
            key: const Key('child_time_decision_approved'),
            l10n.requestInboxChildApproved(d.grantedMinutes ?? 0),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
