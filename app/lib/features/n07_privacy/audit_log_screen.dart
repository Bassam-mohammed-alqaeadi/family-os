import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n07_privacy/audit_log_models.dart';
import 'package:family_os/features/n07_privacy/audit_log_repository.dart';

/// Widget keys for SCR-FAT-060 acceptance.
abstract final class AuditLogKeys {
  static const screen = Key('audit_log_screen');
  static const loading = Key('audit_log_loading');
  static const empty = Key('audit_log_empty');
  static const body = Key('audit_log_body');
  static const appendBanner = Key('audit_log_append_banner');
  static const list = Key('audit_log_list');
  static const observerHint = Key('audit_log_observer');
  static const childLean = Key('audit_log_child_lean');
  static const sosIconCta = Key('audit_log_sos_icon');
  static const backButton = Key('audit_log_back');

  static Key entry(String id) => Key('audit_log_entry_$id');
}

/// SCR-FAT-060 — سجل التدقيق (audit log).
///
/// Prototype FAT-060 · Rule 12/23 · father-owner typically · mother may view
/// per levels · mock-first · ARB · P-4 SOS · R10 append-only (no delete UI).
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onBack,
    this.onSos,
  });

  /// Rule 25 seam — null → [stage1AuditLogRepository].
  final AuditLogRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — all levels may view (read-only screen).
  final MotherLevel motherLevel;

  final VoidCallback? onBack;
  final VoidCallback? onSos;

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  late AuditLogRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  List<AuditLogEntry> _entries = const [];

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1AuditLogRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant AuditLogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1AuditLogRepository;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.load();
    if (!mounted) return;
    setState(() {
      _entries = list;
      _loading = false;
    });
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (context.canPop()) context.pop();
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    await _sos.fire(childId: 'demo-child');
    if (mounted) setState(() => _sosBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: AuditLogKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        leading: IconButton(
          key: AuditLogKeys.backButton,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: _goBack,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          style: const ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.padded,
            minimumSize: WidgetStatePropertyAll(Size(48, 48)),
          ),
          icon: Icon(Icons.arrow_back, color: colors.ink),
        ),
        title: Text(
          l10n.auditLogTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: AuditLogKeys.sosIconCta,
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
    if (_isChild) {
      return AppEmptyState(
        key: AuditLogKeys.childLean,
        title: l10n.auditLogChildLeanTitle,
        message: l10n.auditLogChildLeanMessage,
        actionLabel: l10n.auditLogSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: AuditLogKeys.childLean,
        title: l10n.auditLogChildLeanTitle,
        message: l10n.auditLogChildLeanMessage,
      );
    }

    if (_loading) {
      return Semantics(
        key: AuditLogKeys.loading,
        label: l10n.auditLogLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_entries.isEmpty) {
      return _EmptyBody(l10n: l10n);
    }

    return SingleChildScrollView(
      key: AuditLogKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: AuditLogKeys.appendBanner,
            variant: BannerVariant.p,
            message: l10n.auditLogAppendBanner,
          ),
          if (_isObserverMother) ...[
            const SizedBox(height: 10),
            BannerNote(
              key: AuditLogKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.auditLogObserverHint,
            ),
          ],
          const SizedBox(height: 14),
          DecoratedBox(
            key: AuditLogKeys.list,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Column(
                children: [
                  for (var i = 0; i < _entries.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: colors.border),
                    _AuditRow(
                      entry: _entries[i],
                      l10n: l10n,
                      colors: colors,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: AuditLogKeys.appendBanner,
            variant: BannerVariant.p,
            message: l10n.auditLogAppendBanner,
          ),
          const SizedBox(height: 16),
          AppEmptyState(
            key: AuditLogKeys.empty,
            title: l10n.auditLogEmptyTitle,
            message: l10n.auditLogEmptyMessage,
          ),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({
    required this.entry,
    required this.l10n,
    required this.colors,
  });

  final AuditLogEntry entry;
  final AppLocalizations l10n;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${_title()} · ${_subtitle()}',
      child: Padding(
        key: AuditLogKeys.entry(entry.id),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon(), size: 22, color: colors.p700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtitle(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon() {
    return switch (entry.kind) {
      AuditLogEntryKind.sosAlert => Icons.sos,
      AuditLogEntryKind.motherLevelUpgrade => Icons.tune,
      AuditLogEntryKind.parentModeUnlockAttempt => Icons.lock_open,
      AuditLogEntryKind.forgetUsed => Icons.cleaning_services_outlined,
      AuditLogEntryKind.parentalConsentPair => Icons.verified_outlined,
    };
  }

  String _title() {
    final subject = _subjectLabel();
    return switch (entry.kind) {
      AuditLogEntryKind.sosAlert => l10n.auditLogEntrySosTitle(subject),
      AuditLogEntryKind.motherLevelUpgrade =>
        l10n.auditLogEntryMotherLevelTitle,
      AuditLogEntryKind.parentModeUnlockAttempt =>
        l10n.auditLogEntryUnlockTitle,
      AuditLogEntryKind.forgetUsed => l10n.auditLogEntryForgetTitle,
      AuditLogEntryKind.parentalConsentPair =>
        l10n.auditLogEntryConsentTitle(subject),
    };
  }

  String _subtitle() {
    final when = _formatWhen(entry.at);
    final actor = _actorLabel();
    final detail = _detailLabel();
    final parts = <String>[when];
    if (actor.isNotEmpty) parts.add(actor);
    if (detail.isNotEmpty) parts.add(detail);
    return parts.join(' · ');
  }

  String _subjectLabel() {
    return switch (entry.subjectKey) {
      'childOne' => l10n.auditLogSubjectChildOne,
      'childTwo' => l10n.auditLogSubjectChildTwo,
      'childThree' => l10n.auditLogSubjectChildThree,
      'mother' => l10n.auditLogSubjectMother,
      _ => l10n.auditLogSubjectChildOne,
    };
  }

  String _actorLabel() {
    return switch (entry.actor) {
      AuditLogActor.father => l10n.auditLogActorFather,
      AuditLogActor.mother => l10n.auditLogActorMother,
      AuditLogActor.system => l10n.auditLogActorSystem,
      AuditLogActor.childDevice => l10n.auditLogActorChildDevice(
          _subjectLabel(),
        ),
    };
  }

  String _detailLabel() {
    return switch (entry.detailKey) {
      'closedAfter6m' => l10n.auditLogDetailClosedAfter6m,
      'observerToPartner' => l10n.auditLogDetailObserverToPartner,
      'rejectedX2' => l10n.auditLogDetailRejectedX2,
      'friday' => l10n.auditLogDetailFriday,
      'timestamped' => l10n.auditLogDetailTimestamped,
      'notified' => l10n.auditLogDetailNotified,
      _ => '',
    };
  }

  String _formatWhen(DateTime at) {
    final d = at.day.toString().padLeft(2, '0');
    final m = at.month.toString().padLeft(2, '0');
    final h = at.hour.toString().padLeft(2, '0');
    final min = at.minute.toString().padLeft(2, '0');
    return l10n.auditLogWhenStamp('$d/$m/${at.year}', '$h:$min');
  }
}
