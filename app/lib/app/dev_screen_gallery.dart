import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/audit_population.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/router.dart' show generatedScreenIds;
import 'package:family_os/app/shell_config.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Debug/QA screen catalog — one button per registry SCR-ID.
///
/// Used by the Gemini UX agent for deterministic navigation via Semantics
/// labels that match the exact SCR-ID (uiautomator content-desc / text).
/// Not a product surface; keep out of release navigation chrome.
class DevScreenGallery extends StatefulWidget {
  const DevScreenGallery({super.key});

  static const String routePath = '/dev-screens';
  static const String routeName = 'dev-screens';

  /// Stable Semantics / ValueKey prefix for automation.
  static String semanticsLabelFor(String screenId) => screenId;

  @override
  State<DevScreenGallery> createState() => _DevScreenGalleryState();
}

class _DevScreenGalleryState extends State<DevScreenGallery> {
  final _filter = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  List<String> get _visibleIds {
    final q = _query.trim().toUpperCase();
    if (q.isEmpty) return generatedScreenIds;
    return generatedScreenIds
        .where((id) => id.toUpperCase().contains(q) || _hubName(id).contains(q))
        .toList(growable: false);
  }

  String _hubName(String screenId) {
    for (final entries in hubIndex.values) {
      for (final e in entries) {
        if (e.screenId == screenId) return e.name;
      }
    }
    return '';
  }

  void _openScreen(String screenId) {
    CurrentRole.maybeNotifierOf(context)?.value = galleryRoleForScreen(
      screenId,
    );
    context.push(galleryLocationForScreen(screenId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<FamilyColors>()!;
    final ids = _visibleIds;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.devScreenGalleryTitle)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
              child: Text(
                l10n.devScreenGalleryHint,
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.ink2),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
              child: Semantics(
                label: l10n.devScreenGallerySearchSemantics,
                textField: true,
                child: TextField(
                  controller: _filter,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: l10n.devScreenGallerySearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
              child: Text(
                l10n.devScreenGalleryCount(ids.length),
                style: theme.textTheme.labelLarge?.copyWith(color: colors.ink2),
              ),
            ),
            Expanded(
              child: ids.isEmpty
                  ? Center(
                      child: Text(
                        l10n.devScreenGalleryEmpty,
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  : ListView.separated(
                      itemCount: ids.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: colors.border),
                      itemBuilder: (context, index) {
                        final id = ids[index];
                        final hub = _hubName(id);
                        final label = DevScreenGallery.semanticsLabelFor(id);
                        return Semantics(
                          key: ValueKey<String>(label),
                          label: label,
                          button: true,
                          excludeSemantics: true,
                          child: ListTile(
                            minVerticalPadding: 16,
                            title: Text(
                              id,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: hub.isEmpty
                                ? null
                                : Text(
                                    hub,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.ink2,
                                    ),
                                  ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: colors.ink2,
                            ),
                            onTap: () => _openScreen(id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
