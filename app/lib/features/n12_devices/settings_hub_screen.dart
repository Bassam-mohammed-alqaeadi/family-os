import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n12_devices/device_health_list_screen.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';

/// Widget keys for SCR-FAT-025 settings hub acceptance.
abstract final class SettingsHubKeys {
  static const screen = Key('settings_hub_screen');
  static const title = Key('settings_hub_title');
  static const body = Key('settings_hub_body');
  static const childLean = Key('settings_hub_child_lean');
  static const sosCta = Key('settings_hub_sos');
  static const familySection = Key('settings_hub_family');
  static const devicesSection = Key('settings_hub_devices');
  static const emergencySection = Key('settings_hub_emergency');
  static const privacySection = Key('settings_hub_privacy');
  static const generalSection = Key('settings_hub_general');
  static const comingSoonSection = Key('settings_hub_coming_soon');
  static const linkDeviceRow = Key('settings_hub_link_device');
  static const motherShareRow = Key('settings_hub_mother_share');
  static const brainRow = Key('settings_hub_brain');
  static const billingRow = Key('settings_hub_billing');
  static const logoutRow = Key('settings_hub_logout');
  static const adultSessionsRow = Key('settings_hub_adult_sessions');
  static const childSessionsRow = Key('settings_hub_child_sessions');
  static const recoveryRow = Key('settings_hub_account_recovery');
  static const deactivateRow = Key('settings_hub_account_deactivate');
  static const familySelectorRow = Key('settings_hub_family_selector');

  static Key navRow(String screenId) => Key('settings_hub_nav_$screenId');
}

/// SCR-FAT-025 — الإعدادات · فهرس أقسام (F-08 / prototype).
///
/// Six human-language sections. Device health cards stay visible in the
/// devices card (UI-012) and open FAT-026 detail. Father-only rows
/// (mother share / brain / billing) omit for mother. Child lean. P-4 SOS.
class SettingsHubScreen extends StatefulWidget {
  const SettingsHubScreen({
    super.key,
    this.healthSeam,
    this.roleOverride,
    this.sosFire,
    this.onSos,
    this.onNavigate,
  });

  /// Injectable device-health seam — null → [stage1DeviceHealthSeam].
  final DeviceHealthSeam? healthSeam;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  final VoidCallback? onSos;

  /// Test seam — intercepts row navigation (screen id).
  final void Function(String screenId)? onNavigate;

  @override
  State<SettingsHubScreen> createState() => SettingsHubScreenState();
}

class SettingsHubScreenState extends State<SettingsHubScreen> {
  var _sosBusy = false;

  AppRole get _role =>
      widget.roleOverride ??
      resolveAuthorizationContext(context, fallbackRole: AppRole.father).role;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isFather => _role == AppRole.father;

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

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  void _goPath(String path) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(path);
      return;
    }
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: SettingsHubKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          key: SettingsHubKeys.title,
          l10n.settingsHubTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: SettingsHubKeys.sosCta,
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
        key: SettingsHubKeys.childLean,
        title: l10n.settingsHubChildLeanTitle,
        message: l10n.settingsHubChildLeanMessage,
      );
    }

    // SingleChildScrollView + Column so every section mounts (tests + a11y).
    return SingleChildScrollView(
      key: SettingsHubKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HubSection(
            key: SettingsHubKeys.familySection,
            title: l10n.settingsHubSectionFamily,
            children: [
              _HubNavRow(
                rowKey: SettingsHubKeys.navRow('SCR-FAT-027'),
                title: l10n.settingsHubRowFamilyMembers,
                subtitle: l10n.settingsHubRowFamilyMembersSub,
                icon: Icons.groups_outlined,
                onTap: () => _go('SCR-FAT-027'),
              ),
              if (_isFather)
                _HubNavRow(
                  rowKey: SettingsHubKeys.motherShareRow,
                  title: l10n.settingsHubRowMotherShare,
                  subtitle: l10n.settingsHubRowMotherShareSub,
                  icon: Icons.tune,
                  onTap: () => _go('SCR-FAT-031'),
                ),
              _HubNavRow(
                rowKey: SettingsHubKeys.navRow('SCR-FAT-030'),
                title: l10n.settingsHubRowParentModeRequests,
                icon: Icons.lock_open_outlined,
                onTap: () => _go('SCR-FAT-030'),
              ),
              if (CurrentIdentity.maybeOf(context)?.needsFamilySelector ??
                  false)
                _HubNavRow(
                  rowKey: SettingsHubKeys.familySelectorRow,
                  title: l10n.sys3SettingsFamilySelector,
                  icon: Icons.swap_horiz,
                  onTap: () => _goPath('/sys3-family-select'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _HubSection(
            key: SettingsHubKeys.devicesSection,
            title: l10n.deviceHealthDevicesHeading,
            children: [
              DeviceHealthDevicesSection(healthSeam: widget.healthSeam),
              const SizedBox(height: 4),
              _HubNavRow(
                rowKey: SettingsHubKeys.linkDeviceRow,
                title: l10n.settingsHubRowLinkDevice,
                subtitle: l10n.settingsHubRowLinkDeviceSub,
                icon: Icons.qr_code_2_outlined,
                onTap: () => _go('SCR-FAT-004'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HubSection(
            key: SettingsHubKeys.emergencySection,
            title: l10n.settingsHubSectionEmergency,
            children: [
              _HubNavRow(
                rowKey: SettingsHubKeys.navRow('SCR-FAT-028'),
                title: l10n.settingsHubRowEmergency,
                subtitle: l10n.settingsHubRowEmergencySub,
                icon: Icons.emergency_outlined,
                onTap: () => _go('SCR-FAT-028'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HubSection(
            key: SettingsHubKeys.privacySection,
            title: l10n.settingsHubSectionPrivacy,
            children: [
              if (_isFather)
                _HubNavRow(
                  rowKey: SettingsHubKeys.brainRow,
                  title: l10n.settingsHubRowBrain,
                  subtitle: l10n.settingsHubRowBrainSub,
                  icon: Icons.psychology_outlined,
                  onTap: () => _go('SCR-FAT-029'),
                ),
              _HubNavRow(
                rowKey: SettingsHubKeys.navRow('SCR-FAT-079'),
                title: l10n.settingsHubRowAdvisor,
                subtitle: l10n.settingsHubRowAdvisorSub,
                icon: Icons.handshake_outlined,
                onTap: () => _go('SCR-FAT-079'),
              ),
              _HubNavRow(
                rowKey: SettingsHubKeys.navRow('SCR-FAT-059'),
                title: l10n.settingsHubRowPrivacy,
                icon: Icons.lock_outline,
                onTap: () => _go('SCR-FAT-059'),
              ),
              _HubNavRow(
                rowKey: SettingsHubKeys.navRow('SCR-FAT-060'),
                title: l10n.settingsHubRowAudit,
                subtitle: l10n.settingsHubRowAuditSub,
                icon: Icons.receipt_long_outlined,
                onTap: () => _go('SCR-FAT-060'),
              ),
              _HubNavRow(
                rowKey: SettingsHubKeys.adultSessionsRow,
                title: l10n.sys3SettingsAdultSessions,
                icon: Icons.devices_outlined,
                onTap: () => _goPath('/sys3-adult-sessions'),
              ),
              _HubNavRow(
                rowKey: SettingsHubKeys.childSessionsRow,
                title: l10n.sys3SettingsChildSessions,
                icon: Icons.phonelink_erase_outlined,
                onTap: () => _goPath('/sys3-child-sessions'),
              ),
              _HubNavRow(
                rowKey: SettingsHubKeys.recoveryRow,
                title: l10n.sys3SettingsRecovery,
                icon: Icons.key_outlined,
                onTap: () => _goPath('/sys3-account-recovery'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HubSection(
            key: SettingsHubKeys.generalSection,
            title: l10n.settingsHubSectionGeneral,
            children: [
              _HubNavRow(
                rowKey: SettingsHubKeys.navRow('SCR-FAT-058'),
                title: l10n.settingsHubRowNotifications,
                icon: Icons.notifications_outlined,
                onTap: () => _go('SCR-FAT-058'),
              ),
              if (_isFather)
                _HubNavRow(
                  rowKey: SettingsHubKeys.billingRow,
                  title: l10n.settingsHubRowBilling,
                  icon: Icons.credit_card_outlined,
                  onTap: () => _go('SCR-FAT-056'),
                ),
              _HubNavRow(
                rowKey: SettingsHubKeys.navRow('SCR-FAT-061'),
                title: l10n.settingsHubRowLanguage,
                icon: Icons.language,
                onTap: () => _go('SCR-FAT-061'),
              ),
              _HubNavRow(
                rowKey: SettingsHubKeys.logoutRow,
                title: l10n.sys3SettingsLogout,
                icon: Icons.logout,
                onTap: () => _goPath('/sys3-logout'),
              ),
              _HubNavRow(
                rowKey: SettingsHubKeys.deactivateRow,
                title: l10n.sys3SettingsDeactivate,
                icon: Icons.person_off_outlined,
                onTap: () => _goPath('/sys3-account-deactivate'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HubSection(
            key: SettingsHubKeys.comingSoonSection,
            title: l10n.settingsHubSectionComingSoon,
            children: [
              _HubNavRow(
                rowKey: SettingsHubKeys.navRow('SCR-FAT-075'),
                title: l10n.settingsHubRowComingSoon,
                subtitle: l10n.settingsHubRowComingSoonSub,
                icon: Icons.auto_awesome_outlined,
                onTap: () => _go('SCR-FAT-075'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HubSection extends StatelessWidget {
  const _HubSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    // Devices section already paints its own card via DeviceHealthDevicesSection;
    // wrap remaining children in a shared surface when the first child is not
    // already a decorated devices panel.
    final hasEmbeddedDevices = children.any(
      (c) => c is DeviceHealthDevicesSection,
    );

    if (hasEmbeddedDevices) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            if (children[i] is DeviceHealthDevicesSection)
              children[i]
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(radii.card),
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: children[i],
                ),
              ),
          ],
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _HubNavRow extends StatelessWidget {
  const _HubNavRow({
    required this.rowKey,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final Key rowKey;
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: rowKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: colors.tealDeep, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: colors.ink2, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
