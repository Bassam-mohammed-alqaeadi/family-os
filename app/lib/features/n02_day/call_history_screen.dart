import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/call_history_repository.dart';

/// Widget keys for SCR-FAT-024 acceptance.
abstract final class CallHistoryKeys {
  static const screen = Key('call_history_screen');
  static const loading = Key('call_history_loading');
  static const empty = Key('call_history_empty');
  static const error = Key('call_history_error');
  static const body = Key('call_history_body');
  static const honestyBanner = Key('call_history_honesty');
  static const sosCta = Key('call_history_sos');
  static const childLean = Key('call_history_child_lean');
  static const title = Key('call_history_title');

  static Key row(String id) => Key('call_history_row_$id');
  static Key redial(String id) => Key('call_history_redial_$id');
}

/// SCR-FAT-024 — سجل المكالمات (parent family-tab call history).
///
/// Incoming / outgoing / missed rows. Redial → FAT-023 with `callId`.
/// P-4 SOS ungated. Mother OK; child lean. Mock-first — Rule 23 empty default.
class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({
    super.key,
    this.repository,
    this.roleOverride,
    this.sosFire,
    this.onSos,
    this.onRedial,
    this.onDial,
  });

  /// Null → [stage1CallHistoryRepository].
  final CallHistoryRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  final VoidCallback? onSos;

  /// Test seam — redial to FAT-023 (active call).
  final void Function(CallLogEntry entry)? onRedial;

  /// Dial seam when [CallLogEntry.callId] is blank (Stage-1 toast / later dialer).
  final void Function(CallLogEntry entry)? onDial;

  @override
  CallHistoryScreenState createState() => CallHistoryScreenState();
}

class CallHistoryScreenState extends State<CallHistoryScreen> {
  late final CallHistoryRepository _repo;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  CallHistorySnapshot? _snapshot;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1CallHistoryRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant CallHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final snap = await _repo.load();
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _snapshot = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    final fire = widget.sosFire ?? stage1SosFireService;
    await fire.fire(childId: 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push('/scr-fat-018');
  }

  void _onEntryAction(CallLogEntry entry) {
    final callId = entry.callId.trim();
    if (callId.isEmpty) {
      if (widget.onDial != null) {
        widget.onDial!(entry);
        return;
      }
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.callHistoryDialToast)),
      );
      return;
    }
    if (widget.onRedial != null) {
      widget.onRedial!(entry);
      return;
    }
    context.push(
      Uri(
        path: '/scr-fat-023',
        queryParameters: {'callId': callId},
      ).toString(),
    );
  }

  String _directionLabel(AppLocalizations l10n, CallLogEntry entry) {
    final base = switch (entry.direction) {
      CallLogDirection.outgoing => l10n.callHistoryDirectionOutgoing,
      CallLogDirection.incoming => l10n.callHistoryDirectionIncoming,
      CallLogDirection.missed => l10n.callHistoryDirectionMissed,
    };
    if (entry.kind == CallLogKind.video &&
        entry.direction == CallLogDirection.outgoing) {
      return l10n.callHistoryDirectionOutgoingVideo;
    }
    return base;
  }

  String _subtitle(AppLocalizations l10n, CallLogEntry entry) {
    final dir = _directionLabel(l10n, entry);
    final duration = entry.durationLabel?.trim();
    if (duration == null || duration.isEmpty) {
      return '$dir · ${entry.whenLabel}';
    }
    return '$dir · $duration · ${entry.whenLabel}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: CallHistoryKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          key: CallHistoryKeys.title,
          l10n.callHistoryTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: CallHistoryKeys.sosCta,
            tooltip: l10n.spineCtaSosSemantics,
            onPressed: _sosBusy ? null : _openSos,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: WidgetStatePropertyAll(Size(48, 48)),
            ),
            icon: Icon(Icons.sos, color: colors.coral),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, l10n, colors)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    if (!_isParent) {
      return AppEmptyState(
        key: CallHistoryKeys.childLean,
        title: l10n.callHistoryChildLeanTitle,
        message: l10n.callHistoryChildLeanMessage,
      );
    }

    if (_loading) {
      return Semantics(
        key: CallHistoryKeys.loading,
        label: l10n.callHistoryLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: CallHistoryKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }

    final snap = _snapshot ?? const CallHistorySnapshot();
    if (snap.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: BannerNote(
              key: CallHistoryKeys.honestyBanner,
              variant: BannerVariant.t,
              message: l10n.callHistoryHonestyBanner,
            ),
          ),
          Expanded(
            child: AppEmptyState(
              key: CallHistoryKeys.empty,
              title: l10n.callHistoryEmptyTitle,
              message: l10n.callHistoryEmptyMessage,
            ),
          ),
        ],
      );
    }

    final entries = snap.entries;
    return SingleChildScrollView(
      key: CallHistoryKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: CallHistoryKeys.honestyBanner,
            variant: BannerVariant.t,
            message: l10n.callHistoryHonestyBanner,
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(
                Theme.of(context).extension<FamilyRadii>()!.card,
              ),
              border: Border.all(color: colors.border.withValues(alpha: 0.85)),
              boxShadow: [Theme.of(context).extension<FamilyShadows>()!.shCard],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    _CallHistoryRow(
                      entry: entries[i],
                      subtitle: _subtitle(l10n, entries[i]),
                      subtitleColor: entries[i].direction == CallLogDirection.missed
                          ? colors.coral
                          : null,
                      redialSemantics: l10n.callHistoryRedialSemantics,
                      showDivider: i < entries.length - 1,
                      onTap: () => _onEntryAction(entries[i]),
                      onRedial: () => _onEntryAction(entries[i]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallHistoryRow extends StatelessWidget {
  const _CallHistoryRow({
    required this.entry,
    required this.subtitle,
    required this.redialSemantics,
    required this.showDivider,
    required this.onTap,
    required this.onRedial,
    this.subtitleColor,
  });

  final CallLogEntry entry;
  final String subtitle;
  final String redialSemantics;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onRedial;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final ink2 = subtitleColor ?? colors.ink2;

    // Custom row (not RowTile) so missed subtitles can use coral.
    return Column(
      key: CallHistoryKeys.row(entry.id),
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: '${entry.peerLabel}. $subtitle',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(entry.avatarColor),
                        child: Text(
                          entry.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.peerLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.ink,
                                height: 1.3,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: ink2,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: CallHistoryKeys.redial(entry.id),
                        tooltip: redialSemantics,
                        onPressed: onRedial,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.padded,
                          minimumSize: WidgetStatePropertyAll(Size(48, 48)),
                        ),
                        icon: Icon(
                          Icons.call,
                          color: colors.tealDeep,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: colors.border.withValues(alpha: 0.7)),
      ],
    );
  }
}
