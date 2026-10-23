import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';

/// Where the day's counted minutes actually went.
///
/// The server has been sending `usage.byApp` with every state read since the wave was
/// written, and nothing drew it: a parent could see \"40 of 60 minutes\" and never learn that
/// 35 of them were one game. This card is that missing half, and it is deliberately narrow:
///
///   * the rows are the server's, sorted by the server's minutes - this widget adds nothing,
///     estimates nothing and never subtracts one app from another;
///   * a package name is not a name, so a row falls back to the last segment of the id
///     (`com.google.android.youtube` → \"Youtube\") when the family's own app list has not
///     been loaded. It is a label, not a fact about usage;
///   * the bar is a share of *these* rows, not of the daily cap. A bar that reached the end
///     would otherwise claim a child had spent the whole allowance on one app;
///   * nothing is shown at all when the server sent no rows - an empty chart is a claim too.
class AppUsageBreakdown extends StatelessWidget {
  const AppUsageBreakdown({
    super.key,
    required this.usage,
    this.displayNames = const <String, String>{},
    this.maxRows = 5,
  });

  static const Key card = Key('screen_time_app_usage_card');
  static const Key empty = Key('screen_time_app_usage_empty');
  static const Key bars = Key('screen_time_app_usage_bars');

  /// The server's per-app minutes, in any order.
  final List<FoundationGateAppUsage> usage;

  /// `appId` → the name the family gave it (from the app list). Optional by design.
  final Map<String, String> displayNames;

  /// How many rows to draw before folding the tail into one honest line.
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final rows = _ranked();
    final total = rows.fold<int>(0, (sum, row) => sum + row.usedMinutes);

    return Card(
      key: card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.screenTimeAppUsageTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ),
                if (rows.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.p50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.p700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (rows.isEmpty)
              Text(
                l10n.screenTimeAppUsageEmpty,
                key: empty,
                style: TextStyle(fontSize: 13, height: 1.5, color: colors.ink2),
              )
            else
              _bars(l10n, colors, rows, total),
          ],
        ),
      ),
    );
  }

  Widget _bars(
    AppLocalizations l10n,
    FamilyColors colors,
    List<FoundationGateAppUsage> rows,
    int total,
  ) {
    // Keep the largest [maxRows] visible and fold the rest, because a parent scanning a
    // phone reads four bars and not forty.
    final visible = rows.length <= maxRows ? rows : rows.take(maxRows - 1).toList();
    final rest = rows.length <= maxRows
        ? const <FoundationGateAppUsage>[]
        : rows.skip(maxRows - 1).toList();
    final restMinutes = rest.fold<int>(0, (sum, row) => sum + row.usedMinutes);

    return Column(
      key: bars,
      children: [
        for (final row in visible)
          _bar(
            colors: colors,
            label: _label(row.appId),
            minutes: row.usedMinutes,
            share: total == 0 ? 0 : row.usedMinutes / total,
            index: visible.indexOf(row),
          ),
        if (rest.isNotEmpty)
          _bar(
            colors: colors,
            label: l10n.screenTimeAppUsageRest,
            minutes: restMinutes,
            share: total == 0 ? 0 : restMinutes / total,
            index: visible.length,
            muted: true,
          ),
      ],
    );
  }

  Widget _bar({
    required FamilyColors colors,
    required String label,
    required int minutes,
    required double share,
    required int index,
    bool muted = false,
  }) {
    // A stair of slightly deepening tints instead of five unrelated colours: the bars belong
    // to one family of minutes, and colour should rank them, not decorate them.
    final tint = [
      colors.p600,
      colors.p500,
      colors.p400,
      colors.teal,
      colors.teal600,
    ][index % 5];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: muted ? colors.ink2 : colors.ink,
                  ),
                ),
              ),
              Text(
                '$minutes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: muted ? colors.ink2 : colors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 7,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: colors.bg)),
                    // The bar grows from the reading edge, so in Arabic it fills from the
                    // right without a second code path.
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: share.clamp(0, 1)),
                        duration: Duration(milliseconds: 420 + index * 60),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Container(
                          width: constraints.maxWidth * value,
                          height: 7,
                          color: muted ? colors.border : tint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The server's order, made stable: minutes first, then the id, so two reads of the same
  /// day never shuffle the list under a parent's eyes.
  List<FoundationGateAppUsage> _ranked() {
    final rows = usage.where((row) => row.usedMinutes > 0).toList()
      ..sort((a, b) {
        final byMinutes = b.usedMinutes.compareTo(a.usedMinutes);
        return byMinutes != 0 ? byMinutes : a.appId.compareTo(b.appId);
      });
    return rows;
  }

  String _label(String appId) {
    final named = displayNames[appId];
    if (named != null && named.trim().isNotEmpty) return named.trim();
    return humanisePackage(appId);
  }

  /// `com.google.android.youtube` → `Youtube`. A derived label, never a guess about usage.
  static String humanisePackage(String appId) {
    final trimmed = appId.trim();
    if (trimmed.isEmpty) return appId;
    final segment = trimmed.split('.').last;
    final spaced = segment.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (spaced.isEmpty) return trimmed;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
