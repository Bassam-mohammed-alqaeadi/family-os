import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_smart_tilawah_models.dart';
import 'package:family_os/features/n17_child_learn/child_smart_tilawah_repository.dart';

abstract final class ChildSmartTilawahKeys {
  static const screen = Key('child_smart_tilawah_screen');
  static const loading = Key('child_smart_tilawah_loading');
  static const empty = Key('child_smart_tilawah_empty');
  static const body = Key('child_smart_tilawah_body');
  static const ayahCard = Key('child_smart_tilawah_ayah');
  static const listenCta = Key('child_smart_tilawah_listen');
  static const tipCard = Key('child_smart_tilawah_tip');
  static const sheikhCta = Key('child_smart_tilawah_sheikh');
  static const parentLean = Key('child_smart_tilawah_parent_lean');
  static const sosIconCta = Key('child_smart_tilawah_sos_icon');
}

/// SCR-CHD-032 — تلاوتي الذكية (licensed mushaf tip · one note).
class ChildSmartTilawahScreen extends StatefulWidget {
  const ChildSmartTilawahScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildSmartTilawahRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildSmartTilawahScreen> createState() =>
      _ChildSmartTilawahScreenState();
}

class _ChildSmartTilawahScreenState extends State<ChildSmartTilawahScreen> {
  late ChildSmartTilawahRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildSmartTilawahSnapshot _snap = const ChildSmartTilawahSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildSmartTilawahRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await _repo.load();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _loading = false;
    });
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    await _sos.fire(childId: 'self');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-CHD-005'));
  }

  void _go(String id) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(id);
      return;
    }
    context.push(screenPath(id));
  }

  Future<void> _listen() async {
    final snap = await _repo.startListening();
    if (!mounted) return;
    setState(() => _snap = snap);
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.childSmartTilawahListenToast);
  }

  Future<void> _sheikh() async {
    final snap = await _repo.playSheikh();
    if (!mounted) return;
    setState(() => _snap = snap);
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.childSmartTilawahSheikhToast);
  }

  String _surah(AppLocalizations l10n) => switch (_snap.surahKey) {
    'mulk' => l10n.childSmartTilawahSurahMulk,
    _ => l10n.childSmartTilawahSurahMulk,
  };

  String _ayah(AppLocalizations l10n) => switch (_snap.ayahKey) {
    'mulk16' => l10n.childSmartTilawahAyahMulk16,
    _ => l10n.childSmartTilawahAyahMulk16,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildSmartTilawahKeys.screen,
      backgroundColor: colors.childBg,
      appBar: AppBar(
        backgroundColor: colors.childBg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childSmartTilawahTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildSmartTilawahKeys.sosIconCta,
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
      body: SafeArea(child: _body(l10n, colors)),
    );
  }

  Widget _body(AppLocalizations l10n, FamilyColors colors) {
    if (!_isChild) {
      return AppEmptyState(
        key: ChildSmartTilawahKeys.parentLean,
        title: l10n.childSmartTilawahParentLeanTitle,
        message: l10n.childSmartTilawahParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildSmartTilawahKeys.loading,
        child: Semantics(
          label: l10n.childSmartTilawahLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildSmartTilawahKeys.empty,
        title: l10n.childSmartTilawahEmptyTitle,
        message: l10n.childSmartTilawahEmptyMessage,
        actionLabel: l10n.childSmartTilawahEmptyCta,
        onAction: () => _go('SCR-CHD-014'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildSmartTilawahKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: ChildSmartTilawahKeys.ayahCard,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.teal, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  l10n.childSmartTilawahAyahMeta(
                    _surah(l10n),
                    _snap.ayahNumber,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.ink2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _ayah(l10n),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 17,
                    height: 2.2,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryBtn(
                  key: ChildSmartTilawahKeys.listenCta,
                  label: l10n.childSmartTilawahListenCta,
                  onPressed: _listen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: ChildSmartTilawahKeys.tipCard,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.childSmartTilawahTipTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.childSmartTilawahTipMadd,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: colors.ink,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            l10n.childSmartTilawahTipMaddBody,
                            style: TextStyle(color: colors.ink2, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      key: ChildSmartTilawahKeys.sheikhCta,
                      onPressed: _sheikh,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: colors.teal,
                        side: BorderSide(color: colors.teal),
                      ),
                      child: Text(l10n.childSmartTilawahSheikhCta),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.childSmartTilawahPraise,
                  style: TextStyle(fontSize: 12, color: colors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BannerNote(
            message: l10n.childSmartTilawahBanner,
            variant: BannerVariant.t,
          ),
        ],
      ),
    );
  }
}
