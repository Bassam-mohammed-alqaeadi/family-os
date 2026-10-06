import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
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
    final copy = _ChildContextCopy.of(context);
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        key: RemoteChildContextKeys.screen,
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Text(copy.title),
        ),
        body: SafeArea(child: _body(copy)),
      ),
    );
  }

  Widget _body(_ChildContextCopy copy) {
    if (_loading) {
      return Center(
        key: RemoteChildContextKeys.loading,
        child: Semantics(
          label: copy.loading,
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

  Widget _ready(_ChildContextCopy copy, FamilyChildContext value) {
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
                  label: '${value.displayName}, ${copy.age(value.ageYears)}',
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
                                  copy.age(value.ageYears),
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
                    label: Text(copy.pairDevice),
                  )
                else
                  Semantics(
                    key: RemoteChildContextKeys.readOnly,
                    container: true,
                    label: copy.readOnly,
                    child: Card(
                      elevation: 0,
                      color: colors.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_outlined),
                            const SizedBox(width: 12),
                            Expanded(child: Text(copy.readOnly)),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  copy.authorityNote,
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

  Widget _failure(_ChildContextCopy copy, FamilyChildContextFailure failure) {
    final presentation = copy.failure(failure);
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
                        child: Text(copy.backToChildren),
                      )
                    else if (failure == FamilyChildContextFailure.sessionInvalid)
                      FilledButton(
                        onPressed: () => context.go('/launch'),
                        child: Text(copy.signInAgain),
                      )
                    else
                      FilledButton.icon(
                        key: RemoteChildContextKeys.retry,
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(copy.retry),
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

  final _ChildContextCopy copy;
  final FamilyChildContext value;

  @override
  Widget build(BuildContext context) {
    final stateText = switch (value.deviceState) {
      FamilyChildDeviceSetupState.notLinked => copy.notLinked,
      FamilyChildDeviceSetupState.linkedAwaitingTelemetry =>
        copy.linkedAwaitingTelemetry,
      FamilyChildDeviceSetupState.linked => copy.linked,
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
              copy.setupTitle,
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
            Text(copy.deviceCount(value.deviceCount)),
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

/// Bounded bilingual copy for the authoritative route. Keeping this contract's
/// states together prevents nearby prototype copy from leaking into production,
/// while still following the active locale and platform Directionality.
final class _ChildContextCopy {
  const _ChildContextCopy(this.arabic);

  factory _ChildContextCopy.of(BuildContext context) => _ChildContextCopy(
    Localizations.localeOf(context).languageCode.toLowerCase() == 'ar',
  );

  final bool arabic;

  String get title => arabic ? 'ملف الابن' : 'Child profile';
  String get loading => arabic ? 'جارٍ تحميل ملف الابن' : 'Loading child profile';
  String age(int value) => arabic ? 'العمر $value سنوات' : 'Age $value years';
  String get setupTitle => arabic ? 'إعداد الجهاز' : 'Device setup';
  String get notLinked => arabic ? 'لم يتم ربط جهاز بعد' : 'No device linked yet';
  String get linkedAwaitingTelemetry => arabic
      ? 'تم ربط الجهاز وينتظر أول تحديث'
      : 'Device linked, awaiting its first update';
  String get linked => arabic ? 'تم ربط الجهاز' : 'Device linked';
  String deviceCount(int value) => arabic
      ? 'عدد الأجهزة المرتبطة: $value'
      : 'Linked devices: $value';
  String get pairDevice => arabic ? 'ربط جهاز' : 'Pair a device';
  String get readOnly => arabic
      ? 'يمكنك عرض هذا الملف فقط. يتطلب ربط جهاز إذن المالك.'
      : 'You can view this profile. Pairing a device requires owner permission.';
  String get authorityNote => arabic
      ? 'هذه المعلومات مؤكدة من الخادم. تُراجع الصلاحيات عند تنفيذ كل إجراء.'
      : 'This information is confirmed by the server. Every action is authorized again.';
  String get retry => arabic ? 'إعادة المحاولة' : 'Try again';
  String get backToChildren => arabic ? 'العودة إلى الأبناء' : 'Back to children';
  String get signInAgain => arabic ? 'تسجيل الدخول مجدداً' : 'Sign in again';

  _FailurePresentation failure(FamilyChildContextFailure failure) =>
      switch (failure) {
        FamilyChildContextFailure.notFound => _FailurePresentation(
          arabic ? 'الابن غير موجود' : 'Child not found',
          arabic
              ? 'لم يعد هذا الملف متاحاً في هذه العائلة. ارجع إلى قائمة الأبناء.'
              : 'This profile is not available in this family. Return to the children list.',
          Icons.person_off_outlined,
        ),
        FamilyChildContextFailure.accessDenied => _FailurePresentation(
          arabic ? 'لا يمكنك عرض هذا الملف' : 'Access denied',
          arabic
              ? 'لا يملك حسابك صلاحية عرض ملف هذا الابن.'
              : 'Your account is not allowed to view this child profile.',
          Icons.lock_outline_rounded,
        ),
        FamilyChildContextFailure.sessionInvalid => _FailurePresentation(
          arabic ? 'انتهت الجلسة' : 'Session ended',
          arabic
              ? 'سجّل الدخول مجدداً للتحقق من صلاحيات العائلة.'
              : 'Sign in again so family access can be verified.',
          Icons.logout_rounded,
        ),
        FamilyChildContextFailure.networkUnavailable => _FailurePresentation(
          arabic ? 'لا يوجد اتصال' : 'No connection',
          arabic
              ? 'تحقق من اتصالك بالإنترنت ثم حاول مجدداً.'
              : 'Check your internet connection and try again.',
          Icons.wifi_off_rounded,
        ),
        FamilyChildContextFailure.serviceUnavailable => _FailurePresentation(
          arabic ? 'الخدمة غير متاحة مؤقتاً' : 'Service temporarily unavailable',
          arabic
              ? 'لم نتمكن من تأكيد أحدث المعلومات الآن. حاول مجدداً.'
              : 'We could not confirm the latest information. Try again.',
          Icons.cloud_off_outlined,
        ),
        FamilyChildContextFailure.invalidResponse => _FailurePresentation(
          arabic ? 'تعذر التحقق من المعلومات' : 'Information could not be verified',
          arabic
              ? 'وصلت استجابة غير متوقعة، لذلك لم نعرض بيانات غير مؤكدة.'
              : 'The response was unexpected, so no unverified data is shown.',
          Icons.shield_outlined,
        ),
        FamilyChildContextFailure.unavailable => _FailurePresentation(
          arabic ? 'ملف الابن غير متاح' : 'Child profile unavailable',
          arabic
              ? 'مصدر البيانات الموثوق غير مهيأ حالياً.'
              : 'The authoritative data source is not configured right now.',
          Icons.sync_problem_rounded,
        ),
      };
}
