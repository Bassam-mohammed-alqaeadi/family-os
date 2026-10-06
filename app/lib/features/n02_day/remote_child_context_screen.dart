import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_child_context_source.dart';

abstract final class RemoteChildContextKeys {
  static const screen = Key('remote_child_context_screen');
  static const loading = Key('remote_child_context_loading');
  static const ready = Key('remote_child_context_ready');
  static const error = Key('remote_child_context_error');
  static const retry = Key('remote_child_context_retry');
  static const pairDevice = Key('remote_child_context_pair_device');
  static const readOnly = Key('remote_child_context_read_only');
}

/// Production SCR-FAT-013.
///
/// This surface renders only the identity, setup and short-lived permissions in
/// the server response. It deliberately does not consult the legacy child
/// profile, device telemetry, location, health, policy or tools repositories.
final class RemoteChildContextScreen extends StatefulWidget {
  const RemoteChildContextScreen({
    super.key,
    required this.childId,
    this.source,
    this.familyIdOverride,
    this.onBack,
    this.onPairDevice,
  });

  final String? childId;

  /// Explicit seams are for isolated widget hosts. Product routes resolve both
  /// dependencies from [AppScope].
  final FamilyChildContextSource? source;
  final FamilyId? familyIdOverride;
  final VoidCallback? onBack;
  final VoidCallback? onPairDevice;

  @override
  State<RemoteChildContextScreen> createState() =>
      _RemoteChildContextScreenState();
}

final class _RemoteChildContextScreenState
    extends State<RemoteChildContextScreen> {
  FamilyChildContextResult? _result;
  var _loading = true;
  var _started = false;
  Timer? _expiryTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      unawaited(_load());
    }
  }

  @override
  void didUpdateWidget(RemoteChildContextScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId ||
        oldWidget.source != widget.source ||
        oldWidget.familyIdOverride != widget.familyIdOverride) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _expiryTimer?.cancel();
    final rawChildId = widget.childId?.trim() ?? '';
    if (rawChildId.isEmpty) {
      _publish(
        const FamilyChildContextResult.failed(
          FamilyChildContextFailure.notFound,
        ),
      );
      return;
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _result = null;
      });
    }
    final runtime = AppScope.maybeOf(context);
    final source = widget.source ?? runtime?.childContext;
    final familyId = widget.familyIdOverride ?? runtime?.identity.value.familyId;
    if (source == null || familyId == null) {
      _publish(
        const FamilyChildContextResult.failed(
          FamilyChildContextFailure.unavailable,
        ),
      );
      return;
    }

    final result = await source.load(
      familyId: familyId,
      childId: ChildId(rawChildId),
    );
    if (!mounted) return;
    _publish(result);
    final expiresAt = result.context?.permissionSnapshot.expiresAt;
    if (expiresAt != null) {
      final untilExpiry = expiresAt.difference(DateTime.now().toUtc());
      if (untilExpiry > Duration.zero) {
        _expiryTimer = Timer(untilExpiry, () {
          if (mounted) unawaited(_load());
        });
      }
    }
  }

  void _publish(FamilyChildContextResult result) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = result;
    });
  }

  void _back() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/scr-fat-012');
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context);
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        key: RemoteChildContextKeys.screen,
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Text(copy.childContextTitle),
        ),
        body: SafeArea(child: _body(copy)),
      ),
    );
  }

  Widget _body(AppLocalizations copy) {
    if (_loading) {
      return Center(
        key: RemoteChildContextKeys.loading,
        child: Semantics(
          label: copy.childContextLoading,
          liveRegion: true,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    final contextValue = _result?.context;
    if (contextValue != null) return _ready(copy, contextValue);
    return _failure(
      copy,
      _result?.failure ?? FamilyChildContextFailure.unavailable,
    );
  }

  Widget _ready(AppLocalizations copy, FamilyChildContext value) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canPair = value.permissionSnapshot.allows(
      FamilyChildPermissionScope.createDevicePairing,
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: RemoteChildContextKeys.ready,
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth >= 700 ? 40 : 20,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  label: '${value.displayName}, ${copy.childContextAge(value.ageYears)}',
                  child: Card(
                    elevation: 0,
                    color: colors.primaryContainer.withValues(alpha: 0.62),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: Center(
                                child: Text(
                                  value.avatarEmoji,
                                  style: const TextStyle(fontSize: 38),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  value.displayName,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  copy.childContextAge(value.ageYears),
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _SetupCard(copy: copy, value: value),
                const SizedBox(height: 18),
                if (canPair)
                  FilledButton.icon(
                    key: RemoteChildContextKeys.pairDevice,
                    onPressed: () {
                      if (widget.onPairDevice != null) {
                        widget.onPairDevice!();
                      } else {
                        context.go(
                          '/scr-fat-004?childId=${Uri.encodeQueryComponent(value.childId.value)}',
                        );
                      }
                    },
                    icon: const Icon(Icons.add_link_rounded),
                    label: Text(copy.childContextPairDevice),
                  )
                else
                  Semantics(
                    key: RemoteChildContextKeys.readOnly,
                    container: true,
                    label: copy.childContextReadOnly,
                    child: Card(
                      elevation: 0,
                      color: colors.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_outlined),
                            const SizedBox(width: 12),
                            Expanded(child: Text(copy.childContextReadOnly)),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  copy.childContextAuthorityNote,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _failure(AppLocalizations copy, FamilyChildContextFailure failure) {
    final presentation = _failureFor(copy, failure);
    return Center(
      key: RemoteChildContextKeys.error,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Semantics(
            container: true,
            liveRegion: true,
            label: '${presentation.title}. ${presentation.message}',
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(presentation.icon, size: 48),
                    const SizedBox(height: 14),
                    Text(
                      presentation.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(presentation.message, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    if (failure == FamilyChildContextFailure.notFound ||
                        failure == FamilyChildContextFailure.accessDenied)
                      OutlinedButton(
                        onPressed: _back,
                        child: Text(copy.childContextBackToChildren),
                      )
                    else if (failure == FamilyChildContextFailure.sessionInvalid)
                      FilledButton(
                        onPressed: () => context.go('/launch'),
                        child: Text(copy.childContextSignInAgain),
                      )
                    else
                      FilledButton.icon(
                        key: RemoteChildContextKeys.retry,
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(copy.childContextRetry),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.copy, required this.value});

  final AppLocalizations copy;
  final FamilyChildContext value;

  @override
  Widget build(BuildContext context) {
    final stateText = switch (value.deviceState) {
      FamilyChildDeviceSetupState.notLinked => copy.childContextNotLinked,
      FamilyChildDeviceSetupState.linkedAwaitingTelemetry =>
        copy.childContextLinkedAwaitingTelemetry,
      FamilyChildDeviceSetupState.linked => copy.childContextLinked,
    };
    final icon = switch (value.deviceState) {
      FamilyChildDeviceSetupState.notLinked => Icons.phonelink_off_rounded,
      FamilyChildDeviceSetupState.linkedAwaitingTelemetry =>
        Icons.phonelink_setup_rounded,
      FamilyChildDeviceSetupState.linked => Icons.phonelink_ring_rounded,
    };
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.childContextSetupTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stateText,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(copy.childContextDeviceCount(value.deviceCount)),
          ],
        ),
      ),
    );
  }
}

final class _FailurePresentation {
  const _FailurePresentation(this.title, this.message, this.icon);

  final String title;
  final String message;
  final IconData icon;
}

_FailurePresentation _failureFor(
  AppLocalizations copy,
  FamilyChildContextFailure failure,
) => switch (failure) {
  FamilyChildContextFailure.notFound => _FailurePresentation(
    copy.childContextNotFoundTitle,
    copy.childContextNotFoundMessage,
    Icons.person_off_outlined,
  ),
  FamilyChildContextFailure.accessDenied => _FailurePresentation(
    copy.childContextDeniedTitle,
    copy.childContextDeniedMessage,
    Icons.lock_outline_rounded,
  ),
  FamilyChildContextFailure.sessionInvalid => _FailurePresentation(
    copy.childContextSessionTitle,
    copy.childContextSessionMessage,
    Icons.logout_rounded,
  ),
  FamilyChildContextFailure.networkUnavailable => _FailurePresentation(
    copy.childContextNetworkTitle,
    copy.childContextNetworkMessage,
    Icons.wifi_off_rounded,
  ),
  FamilyChildContextFailure.serviceUnavailable => _FailurePresentation(
    copy.childContextServiceTitle,
    copy.childContextServiceMessage,
    Icons.cloud_off_outlined,
  ),
  FamilyChildContextFailure.invalidResponse => _FailurePresentation(
    copy.childContextInvalidResponseTitle,
    copy.childContextInvalidResponseMessage,
    Icons.shield_outlined,
  ),
  FamilyChildContextFailure.unavailable => _FailurePresentation(
    copy.childContextUnavailableTitle,
    copy.childContextUnavailableMessage,
    Icons.sync_problem_rounded,
  ),
};
