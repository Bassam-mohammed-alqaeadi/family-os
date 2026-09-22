import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n01_linking/camera_permission_seam.dart';

/// Widget keys for SCR-FAT-042 acceptance.
abstract final class StudioCameraCaptureKeys {
  static const screen = Key('studio_camera_screen');
  static const body = Key('studio_camera_body');
  static const loading = Key('studio_camera_loading');
  static const viewfinder = Key('studio_camera_viewfinder');
  static const captureCta = Key('studio_camera_capture');
  static const repairPanel = Key('studio_camera_repair');
  static const openSettings = Key('studio_camera_open_settings');
  static const retryPermission = Key('studio_camera_retry');
  static const permanentPanel = Key('studio_camera_permanent');
  static const observerHint = Key('studio_camera_observer');
  static const childLean = Key('studio_camera_child_lean');
  static const sosCta = Key('studio_camera_sos');
  static const sosIconCta = Key('studio_camera_sos_icon');
}

/// SCR-FAT-042 — التقاط من الكاميرا (studio camera capture / book page).
///
/// Prototype FAT-042 · S-EDU-048 · mock camera seam (UI-003 pattern) ·
/// Rule 12/23 · mother levels · ARB · P-4 SOS · continue → FAT-043.
class StudioCameraCaptureScreen extends StatefulWidget {
  const StudioCameraCaptureScreen({
    super.key,
    this.permissionSeam,
    this.initialStatus,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
    this.onOpenSettingsToast = true,
  });

  /// Injectable camera permission — null → [FakeCameraPermissionSeam] granted.
  final CameraPermissionSeam? permissionSeam;

  /// Optional override used before first [CameraPermissionSeam.check].
  final CameraPermissionStatus? initialStatus;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full capture like father.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  /// Show toast when settings deep-link is invoked (demo honesty).
  final bool onOpenSettingsToast;

  @override
  State<StudioCameraCaptureScreen> createState() =>
      _StudioCameraCaptureScreenState();
}

class _StudioCameraCaptureScreenState extends State<StudioCameraCaptureScreen> {
  late final CameraPermissionSeam _seam;
  late final SosFireService _sos;
  CameraPermissionStatus? _status;
  var _loading = true;
  var _sosBusy = false;
  var _capturing = false;

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full (prototype §7 — mother can create).
  bool get _canCapture {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.partner ||
          widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _sos = widget.sosFire ?? stage1SosFireService;
    _seam = widget.permissionSeam ?? FakeCameraPermissionSeam();
    final initial = widget.initialStatus;
    if (initial != null) {
      final seam = _seam;
      if (seam is FakeCameraPermissionSeam) {
        seam.status = initial;
      }
    }
    _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    setState(() => _loading = true);
    final next = await _seam.check();
    if (!mounted) return;
    setState(() {
      _status = next;
      _loading = false;
    });
  }

  Future<void> _onOpenSettings() async {
    final l10n = AppLocalizations.of(context);
    await _seam.openSettings();
    if (widget.onOpenSettingsToast && mounted) {
      AppToast.show(context, message: l10n.studioCameraOpenSettingsToast);
    }
    await _refreshPermission();
  }

  Future<void> _onRequestThenRefresh() async {
    await _seam.request();
    await _refreshPermission();
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    await _sos.fire(childId: 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-FAT-018'));
  }

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  void _onCapture() {
    if (_capturing) return;
    final l10n = AppLocalizations.of(context);
    if (!_canCapture) {
      AppToast.show(context, message: l10n.studioCameraObserverBlocked);
      return;
    }
    setState(() => _capturing = true);
    AppToast.show(context, message: l10n.studioCameraAnalyzedToast);
    _go('SCR-FAT-043');
    if (mounted) {
      setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: StudioCameraCaptureKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.studioCameraTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: StudioCameraCaptureKeys.sosIconCta,
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
        key: StudioCameraCaptureKeys.childLean,
        title: l10n.studioCameraChildLeanTitle,
        message: l10n.studioCameraChildLeanMessage,
        actionLabel: l10n.studioCameraSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: StudioCameraCaptureKeys.childLean,
        title: l10n.studioCameraChildLeanTitle,
        message: l10n.studioCameraChildLeanMessage,
      );
    }

    if (_loading || _status == null) {
      return Center(
        key: StudioCameraCaptureKeys.loading,
        child: Semantics(
          label: l10n.studioCameraLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    return switch (_status!) {
      CameraPermissionStatus.granted => _CaptureBody(
          capturing: _capturing,
          isObserver: _isObserverMother,
          onCapture: _onCapture,
        ),
      CameraPermissionStatus.denied => _RepairBody(
          onOpenSettings: _onOpenSettings,
          onRetryRequest: _onRequestThenRefresh,
        ),
      CameraPermissionStatus.permanentlyDenied => _PermanentBody(
          onOpenSettings: _onOpenSettings,
        ),
    };
  }
}

class _CaptureBody extends StatelessWidget {
  const _CaptureBody({
    required this.capturing,
    required this.isObserver,
    required this.onCapture,
  });

  final bool capturing;
  final bool isObserver;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return ListView(
      key: StudioCameraCaptureKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (isObserver) ...[
          BannerNote(
            key: StudioCameraCaptureKeys.observerHint,
            variant: BannerVariant.a,
            message: l10n.studioCameraObserverHint,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          l10n.studioCameraInstruction,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Semantics(
            label: l10n.studioCameraFrameSemantics,
            child: Container(
              key: StudioCameraCaptureKeys.viewfinder,
              width: 250,
              height: 320,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D2E),
                borderRadius: BorderRadius.circular(radii.card),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: 20,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colors.p400.withValues(alpha: 0.75),
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 40,
                            color: colors.ink2.withValues(alpha: 0.65),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.studioCameraFrameLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.ink2.withValues(alpha: 0.85),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.studioCameraFrameMeta,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.ink2.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 150,
                    child: Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: colors.p400.withValues(alpha: 0.85),
                        boxShadow: [
                          BoxShadow(
                            color: colors.p400.withValues(alpha: 0.55),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        PrimaryBtn(
          key: StudioCameraCaptureKeys.captureCta,
          label: l10n.studioCameraCaptureCta,
          onPressed: capturing ? null : onCapture,
        ),
      ],
    );
  }
}

class _RepairBody extends StatelessWidget {
  const _RepairBody({
    required this.onOpenSettings,
    required this.onRetryRequest,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onRetryRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        DecoratedBox(
          key: StudioCameraCaptureKeys.repairPanel,
          decoration: BoxDecoration(
            color: colors.amber100,
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(
              color: colors.amber.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
            child: Column(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: 44,
                  color: colors.amberDeep,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.studioCameraRepairTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.amberDeep,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.studioCameraRepairBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.amberInk,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryBtn(
                  key: StudioCameraCaptureKeys.openSettings,
                  label: l10n.studioCameraOpenSettings,
                  variant: PrimaryBtnVariant.sec,
                  onPressed: onOpenSettings,
                ),
                const SizedBox(height: 8),
                PrimaryBtn(
                  key: StudioCameraCaptureKeys.retryPermission,
                  label: l10n.studioCameraRetryPermission,
                  variant: PrimaryBtnVariant.ghost,
                  onPressed: onRetryRequest,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PermanentBody extends StatelessWidget {
  const _PermanentBody({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        DecoratedBox(
          key: StudioCameraCaptureKeys.permanentPanel,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
            child: Column(
              children: [
                Icon(
                  Icons.no_photography_outlined,
                  size: 44,
                  color: colors.coral,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.studioCameraPermanentTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.studioCameraPermanentBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryBtn(
                  key: StudioCameraCaptureKeys.openSettings,
                  label: l10n.studioCameraOpenSettings,
                  variant: PrimaryBtnVariant.sec,
                  onPressed: onOpenSettings,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
